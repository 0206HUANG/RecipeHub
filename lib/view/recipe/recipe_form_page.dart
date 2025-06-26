import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../../services/auth_service.dart';
import '../../models/recipe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../view_models/recipe_form_page_vm.dart';
import 'recipe_preview.dart';
import '../../view_models/recipe_preview.dart'; // Import the RecipePreviewPage widget
import '../../widgets/water_loading_animation.dart';
// Add this import if RecipePreviewPage is defined in this file, otherwise define the widget below.

class RecipeFormPage extends StatelessWidget {
  final Recipe? recipe; // If provided, we're editing an existing recipe

  const RecipeFormPage({Key? key, this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecipeFormViewModel(),
      child: const _RecipeFormPageBody(),
    );
  }
}

class _RecipeFormPageBody extends StatefulWidget {
  const _RecipeFormPageBody({Key? key}) : super(key: key);

  @override
  State<_RecipeFormPageBody> createState() => _RecipeFormPageBodyState();
}

class _RecipeFormPageBodyState extends State<_RecipeFormPageBody> {
  final Map<int, VideoPlayerController?> _previewControllers = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    Provider.of<RecipeFormViewModel>(context, listen: false)
        .disposeControllers();
    for (final controller in _previewControllers.values) {
      controller?.dispose();
    }
    Provider.of<RecipeFormViewModel>(context, listen: false)
        .disposeControllers();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Provider.of<RecipeFormViewModel>(context, listen: false)
          .setCoverImage(image);
    }
  }

  void _addIngredient(BuildContext context) {
    final viewModel = Provider.of<RecipeFormViewModel>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final amountController = TextEditingController();
        final unitController = TextEditingController();

        return AlertDialog(
          title: Text('Add Ingredient'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Ingredient Name'),
              ),
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitController,
                decoration:
                    InputDecoration(labelText: 'Unit (e.g., g, ml, cups)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  viewModel.addIngredient({
                    'name': nameController.text,
                    'amount': double.tryParse(amountController.text) ?? 0,
                    'unit': unitController.text,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addInstruction(BuildContext context) {
    final viewModel = Provider.of<RecipeFormViewModel>(context, listen: false);
    XFile? _selectedVideo;
    final instructionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Instruction'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: instructionController,
                    decoration: InputDecoration(labelText: 'Step Description'),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.videocam),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickVideo(
                              source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() {
                              _selectedVideo = picked;
                            });
                          }
                        },
                      ),
                      Text(_selectedVideo != null
                          ? "Video selected"
                          : "No video"),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final index = viewModel.instructions.length + 1;

                    viewModel.addInstruction({
                      'stepNumber': index,
                      'video': _selectedVideo,
                      'description': instructionController.text,
                      'localVideoPath':
                          _selectedVideo?.path, // store path as String
                    });
                    // Immediately pop the dialog
                    Navigator.pop(context);
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveRecipe(BuildContext context) async {
    final viewModel = Provider.of<RecipeFormViewModel>(context, listen: false);
    viewModel.setLoading(true);
    if (viewModel.formKey.currentState!.validate()) {
      viewModel.formKey.currentState!.save();

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;

        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You must be logged in to save a recipe')),
          );
          return;
        }

        // Upload cover image to Supabase
        String? imageUrl;
        if (viewModel.coverImage != null) {
          if (kIsWeb) {
            final bytes = await viewModel.coverImage!.readAsBytes();
            imageUrl = await supabaseUpload(
              bucket: 'recipeimages',
              path: '${DateTime.now().millisecondsSinceEpoch}.jpg',
              fileOrBytes: bytes,
              contentType: 'image/jpeg',
            );
          } else {
            final file = File(viewModel.coverImage!.path);
            imageUrl = await supabaseUpload(
              bucket: 'recipeimages',
              path: '${DateTime.now().millisecondsSinceEpoch}.jpg',
              fileOrBytes: file,
              contentType: 'image/jpeg',
            );
          }
        }

        // Upload instruction videos
        for (var instruction in viewModel.instructions) {
          if (instruction.video != null && instruction.video is XFile) {
            final xfile = instruction.video as XFile;

            if (kIsWeb) {
              final fileSize = await xfile.length();

              if (fileSize > 50 * 1024 * 1024) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Video too large (max 50MB). Please compress.')),
                );
                continue;
              }

              final bytes = await xfile.readAsBytes();
              final response = await supabaseUpload(
                bucket: 'instructionvideos',
                path:
                    '${DateTime.now().millisecondsSinceEpoch}_${instruction.stepNumber}.mp4',
                fileOrBytes: bytes,
                contentType: 'video/mp4',
              );

              instruction.videoUrl = response; // 🟢 store the URL string
              // showDialog(
              //     context: context,
              //     builder: (context) => AlertDialog(
              //           title: Text('Video Uploaded'),
              //           content: Text(
              //               'The video for step ${instruction.stepNumber} has been uploaded successfully.$response'),
              //           actions: [
              //             TextButton(
              //               onPressed: () => Navigator.pop(context),
              //               child: Text('OK'),
              //             ),
              //           ],
              //         ));
            } else {
              final file = File(xfile.path);
              int fileSize = await file.length();

              File fileToUpload = file;

              if (fileSize > 50 * 1024 * 1024) {
                final compressed = await VideoCompress.compressVideo(
                  xfile.path,
                  quality: VideoQuality.MediumQuality,
                  deleteOrigin: false,
                );

                if (compressed != null && compressed.path != null) {
                  fileToUpload = File(compressed.path!);
                }
              }

              final response = await supabaseUpload(
                bucket: 'instructionvideos',
                path:
                    '${DateTime.now().millisecondsSinceEpoch}_${instruction.stepNumber}.mp4',
                fileOrBytes: fileToUpload,
                contentType: 'video/mp4',
              );

              instruction.videoUrl = response; // 🟢 store the URL string
              // showDialog(
              //     context: context,
              //     builder: (context) => AlertDialog(
              //           title: Text('Video Uploaded'),
              //           content: Text(
              //               'The video for step ${instruction.stepNumber} has been uploaded successfully.$response'),
              //           actions: [
              //             TextButton(
              //               onPressed: () => Navigator.pop(context),
              //               child: Text('OK'),
              //             ),
              //           ],
              //         ));
            }
          }
        }

        // Prepare instructions for Firestore
        final sanitizedInstructions = viewModel.instructions.map((instruction) {
          return {
            'step': instruction.stepNumber,
            'description': instruction.description,
            'videoUrl': instruction.videoUrl,
          };
        }).toList();

        // Prepare nutrition info
        final nutritionInfo = {
          'calories': viewModel.nutritionInfo.calories,
          'protein_g': viewModel.nutritionInfo.protein_g,
          'carbohydrates_total_g':
              viewModel.nutritionInfo.carbohydrates_total_g,
          'fat_total_g': viewModel.nutritionInfo.fat_total_g,
          'fiber_g': viewModel.nutritionInfo.fiber_g,
          'sugar_g': viewModel.nutritionInfo.sugar_g,
        };

        // Save to Firestore
        await FirebaseFirestore.instance.collection('recipes').add({
          'title': viewModel.titleController.text,
          'description': viewModel.descriptionController.text,
          'coverImage': imageUrl,
          'servings': int.tryParse(viewModel.servingsController.text) ?? 0,
          'prepTime': int.tryParse(viewModel.prepTimeController.text) ?? 0,
          'cookTime': int.tryParse(viewModel.cookTimeController.text) ?? 0,
          'categories': viewModel.selectedCategories,
          'ingredients': viewModel.ingredients.map((ingredient) {
            return {
              'name': ingredient.name,
              'amount': ingredient.amount,
              'unit': ingredient.unit,
            };
          }).toList(),
          'instructions': sanitizedInstructions,
          'nutritionInfo': nutritionInfo,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': currentUser.uid,
          'createdByEmail': currentUser.email,
          'createdByName': currentUser.displayName ?? currentUser.email ?? '-',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recipe saved successfully!')),
        );
        // Automatically navigate back to the recipe list page
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving recipe: $e')),
        );
      } finally {
        viewModel.setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeFormViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Create Recipe'),
            actions: [
              IconButton(
                icon: Icon(Icons.preview),
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                        // Go to preview page
                        final returnedViewModel = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipePreviewPage(
                                viewModel: RecipePreviewViewModel(
                                    formViewModel: viewModel)),
                          ),
                        );
                        setState(() {});
                        viewModel.togglePreviewMode();
                      },
                tooltip: 'Preview Recipe',
              ),
              IconButton(
                  icon: Icon(Icons.save),
                  onPressed:
                      viewModel.isLoading ? null : () => _saveRecipe(context),
                  tooltip: "Save"),
            ],
          ),
          body:
              // viewModel.isPreviewMode
              //     ? _buildPreview(context, viewModel)
              //     :
              Stack(children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: viewModel.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Image
                    GestureDetector(
                      onTap: () => _pickImage(context),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: viewModel.coverImage != null
                            ? (kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: viewModel.coverImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                              ConnectionState.done &&
                                          snapshot.hasData) {
                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.memory(snapshot.data!,
                                              fit: BoxFit.cover),
                                        );
                                      } else {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }
                                    },
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                        File(viewModel.coverImage!.path),
                                        fit: BoxFit.cover),
                                  ))
                            : Icon(Icons.add_photo_alternate, size: 50),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: viewModel.titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a title'
                          : null,
                    ),
                    SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: viewModel.descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a description'
                          : null,
                    ),
                    SizedBox(height: 16),

                    // Servings and Time
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: viewModel.servingsController,
                            decoration: InputDecoration(labelText: 'Servings'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Please enter servings';
                              if (int.tryParse(value!) == null)
                                return 'Please enter a valid number';
                              if (int.parse(value) <= 0)
                                return 'Servings must be greater than 0';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: viewModel.prepTimeController,
                            decoration:
                                InputDecoration(labelText: 'Prep Time (min)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Please enter prep time';
                              if (int.tryParse(value!) == null)
                                return 'Please enter a valid number';
                              if (int.parse(value) < 0)
                                return 'Time cannot be negative';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: viewModel.cookTimeController,
                            decoration:
                                InputDecoration(labelText: 'Cook Time (min)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Please enter cook time';
                              if (int.tryParse(value!) == null)
                                return 'Please enter a valid number';
                              if (int.parse(value) < 0)
                                return 'Time cannot be negative';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Categories
                    Text('Categories',
                        style: Theme.of(context).textTheme.titleMedium),
                    Wrap(
                      spacing: 8,
                      children: viewModel.availableCategories.map((category) {
                        final isSelected =
                            viewModel.selectedCategories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            viewModel.toggleCategory(category, selected);
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),

                    // Nutrition Info
                    Text('Nutrition Information',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                        'Now Nutrition Information will auto calculate based on ingredients',
                        style: Theme.of(context).textTheme.labelSmall),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Calories (kcal)',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                Text(
                                  viewModel.caloriesController.text.isEmpty
                                      ? '0'
                                      : viewModel.caloriesController.text,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Protein (g)',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                Text(
                                  viewModel.proteinController.text.isEmpty
                                      ? '0'
                                      : viewModel.proteinController.text,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Carbs (g)',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                Text(
                                  viewModel.carbsController.text.isEmpty
                                      ? '0'
                                      : viewModel.carbsController.text,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Fat (g)',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                Text(
                                  viewModel.fatController.text.isEmpty
                                      ? '0'
                                      : viewModel.fatController.text,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Ingredients
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ingredients',
                            style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => _addIngredient(context),
                        ),
                      ],
                    ),
                    if (viewModel.ingredients.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Add at least one ingredient',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: viewModel.ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = viewModel.ingredients[index];
                        return ListTile(
                          title: Text(ingredient.name),
                          subtitle:
                              Text('${ingredient.amount} ${ingredient.unit}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              viewModel.removeIngredient(index);
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),

                    // Instructions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Instructions',
                            style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => _addInstruction(context),
                        ),
                      ],
                    ),
                    if (viewModel.instructions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Add at least one instruction',
                            style: TextStyle(color: Colors.red)),
                      ),
                    if (viewModel.instructions.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: viewModel.instructions.length,
                        itemBuilder: (context, index) {
                          final instruction = viewModel.instructions[index];
                          return ListTile(
                            leading: CircleAvatar(
                                child: Text('${instruction.stepNumber}')),
                            title: Text(instruction.description),
                            subtitle: instruction.videoUrl != null
                                ? (instruction.videoUrl is String
                                    ? Container(
                                        height: 150,
                                        child: VideoPlayerWidget(
                                            url: instruction.videoUrl!),
                                      )
                                    : (kIsWeb
                                        ? Row(
                                            children: [
                                              Icon(Icons.videocam,
                                                  color: Colors.green),
                                              SizedBox(width: 4),
                                              Flexible(
                                                  child: Text(
                                                      'Video will be available after saving')),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Icon(Icons.videocam,
                                                  color: Colors.green),
                                              SizedBox(width: 4),
                                              Flexible(
                                                  child:
                                                      Text('Video attached')),
                                            ],
                                          )))
                                : null,
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                viewModel.removeInstruction(index);
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            WaterLoadingAnimation(isVisible: viewModel.isLoading),
          ]),
        );
      },
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({required this.url});
  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Center(child: CircularProgressIndicator());
  }
}

Future<String> supabaseUpload({
  required String bucket,
  required String path,
  required dynamic fileOrBytes,
  required String contentType,
}) async {
  if (kIsWeb) {
    final url =
        'https://sfkimpdnpxghevcpxvnj.supabase.co/storage/v1/object/$bucket/$path';
    final anonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNma2ltcGRucHhnaGV2Y3B4dm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg2Nzk0NjAsImV4cCI6MjA2NDI1NTQ2MH0.CSBv7uodAcyco-UaoC4OFSEqQE-z9gXG0ygH49FnnpQ';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
        'Content-Type': contentType,
        'x-upsert': 'true',
      },
      body: fileOrBytes,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return 'https://sfkimpdnpxghevcpxvnj.supabase.co/storage/v1/object/public/$bucket/$path';
    } else {
      throw Exception('Failed to upload: ${response.body}');
    }
  } else {
    // Mobile/Desktop: Use Supabase client
    final response = await Supabase.instance.client.storage.from(bucket).upload(
        path, fileOrBytes,
        fileOptions: FileOptions(contentType: contentType));
    return Supabase.instance.client.storage.from(bucket).getPublicUrl(response);
  }
}
