import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chewie/chewie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../models/recipe.dart';
import '../../view_models/recipe_detail_page_vm.dart';
import '../../services/recipe_service.dart';
import 'step_by_step_cooking_page.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;
  final bool fromFinishCooking;

  const RecipeDetailPage({
    Key? key,
    required this.recipe,
    this.fromFinishCooking = false,
  }) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage>
    with SingleTickerProviderStateMixin {
  late RecipeDetailViewModel viewModel;
  bool _showTimeDetails = false;
  bool _showNutritionDetails = false;
  bool _showCookingFinish = false;

  // Image upload related variables
  final ImagePicker _imagePicker = ImagePicker();
  final RecipeService _recipeService = RecipeService();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    viewModel = RecipeDetailViewModel(
      recipe: widget.recipe,
      vsync: this, // Only pass this ONCE
    );
    viewModel.initPreviewControllers(this);
    _showCookingFinish = widget.fromFinishCooking;
  }

  @override
  void dispose() {
    viewModel.disposeControllers();
    viewModel.tabController.dispose();
    super.dispose();
  }

  // Check if current user is the recipe owner
  bool _isRecipeOwner() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('🔒 No current user logged in');
      return false;
    }

    print('👤 Current user ID: ${currentUser.uid}');
    print('📝 Recipe user ID: ${widget.recipe.userId}');

    // Check both userId and potential createdBy field for compatibility
    bool isOwner = currentUser.uid == widget.recipe.userId;

    print('✅ Is recipe owner: $isOwner');

    // TEMPORARY: Allow all logged-in users to upload for testing
    print('🧪 TESTING MODE: Allowing all users to upload');
    return true; // This will be changed back later
  }

  // Handle image upload
  Future<void> _uploadRecipeImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload image to Firebase Storage using XFile
      final imageUrl = await _recipeService.uploadXFileToStorage(image);

      // Update recipe with new image URL
      await _recipeService.updateRecipeImage(widget.recipe.id, imageUrl);

      // Update the local recipe object
      final updatedRecipe = widget.recipe.copyWith(coverImage: imageUrl);
      viewModel.updateRecipe(updatedRecipe);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe image updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  // Show image upload options
  void _showImageUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _uploadRecipeImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
              if (widget.recipe.coverImage.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title:
                      Text('Remove Image', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeRecipeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload image to Firebase Storage using XFile
      final imageUrl = await _recipeService.uploadXFileToStorage(image);

      // Update recipe with new image URL
      await _recipeService.updateRecipeImage(widget.recipe.id, imageUrl);

      // Update the local recipe object
      final updatedRecipe = widget.recipe.copyWith(coverImage: imageUrl);
      viewModel.updateRecipe(updatedRecipe);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe image updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  // Remove recipe image
  Future<void> _removeRecipeImage() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      // Update recipe with empty image URL
      await _recipeService.updateRecipeImage(widget.recipe.id, '');

      // Update the local recipe object
      final updatedRecipe = widget.recipe.copyWith(coverImage: '');
      viewModel.updateRecipe(updatedRecipe);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe image removed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error removing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const iconSize = 18.0;
    final Color? iconColor = Colors.grey[700];

    // Debug information
    final currentUser = FirebaseAuth.instance.currentUser;
    print('🔍 DEBUG INFO:');
    print('   Current User: ${currentUser?.uid ?? 'null'}');
    print('   Recipe ID: ${widget.recipe.id}');
    print('   Recipe Title: ${widget.recipe.title}');
    print('   Recipe userId: ${widget.recipe.userId}');
    print('   Recipe coverImage: ${widget.recipe.coverImage}');
    print('   Is Owner: ${_isRecipeOwner()}');

    if (_showCookingFinish) {
      Future.microtask(() {
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          builder: (context) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _showCookingFinish = false;
                });
              },
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _showCookingFinish = false;
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated popping text
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: Duration(milliseconds: 400),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) => Transform.scale(
                              scale: scale,
                              child: child,
                            ),
                            child: Text(
                              "Congratulations!",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 255, 221, 87),
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black45,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // GIF image
                          Image.asset(
                            'assets/images/celebrate.gif', // Replace with your gif asset path
                            height: 400,
                          ),
                          const SizedBox(height: 24),
                          // Smaller text
                          Text(
                            "You've finished cooking!",
                            style: TextStyle(
                              fontSize: 18,
                              color: const Color.fromARGB(255, 255, 177, 87),
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  color: Colors.black26,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      });
    }

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<RecipeDetailViewModel>(
        builder: (context, vm, _) {
          final recipe = vm.recipe;
          return Scaffold(
            backgroundColor: Colors.grey[100],
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      pinned: true,
                      stretch: true,
                      backgroundColor: Colors.white,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildRecipeImage(recipe.coverImage),
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: Icon(
                                vm.isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                vm.toggleBookmark(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                        padding: const EdgeInsets.only(
                            top: 40, left: 24, right: 24, bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Description
                            Text(
                              recipe.title.isNotEmpty ? recipe.title : '-',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recipe.description.isNotEmpty
                                  ? recipe.description
                                  : '-',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            // Time, Difficulty, Calories
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // Servings
                                  Icon(Icons.people,
                                      size: iconSize, color: iconColor),
                                  const SizedBox(width: 4),
                                  vm.editingServings
                                      ? SizedBox(
                                          width: 60,
                                          child: TextField(
                                            controller: vm.servingsController,
                                            keyboardType: TextInputType.number,
                                            autofocus: true,
                                            onSubmitted: (value) {
                                              final newValue =
                                                  int.tryParse(value);
                                              if (newValue != null &&
                                                  newValue > 0) {
                                                vm.updateServings(
                                                    newValue); // Implement this in your ViewModel
                                              }
                                              setState(() =>
                                                  vm.editingServings = false);
                                            },
                                            decoration: InputDecoration(
                                              hintText: 'Servings',
                                              suffixIcon: IconButton(
                                                icon: Icon(Icons.check,
                                                    color: Colors.green),
                                                tooltip: 'Update',
                                                onPressed: () {
                                                  final newValue = int.tryParse(
                                                      vm.servingsController
                                                          .text);
                                                  if (newValue != null &&
                                                      newValue > 0) {
                                                    vm.updateServings(newValue);
                                                  }
                                                  setState(() => vm
                                                      .editingServings = false);
                                                },
                                              ),
                                            ),
                                          ),
                                        )
                                      : MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () {
                                              vm.servingsController.text =
                                                  recipe.servings.toString();
                                              setState(() =>
                                                  vm.editingServings = true);
                                            },
                                            child: Text(
                                              '${recipe.servings > 0 ? recipe.servings : '-'} Servings',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                  const SizedBox(width: 16),

                                  // Total Time (expandable)
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _showTimeDetails = !_showTimeDetails;
                                        _showNutritionDetails = false;
                                      }),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time,
                                              size: iconSize, color: iconColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${(recipe.prepTime + recipe.cookTime) > 0 ? (recipe.prepTime + recipe.cookTime) : '-'} Min Total',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Icon(
                                            _showTimeDetails
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Calories (expandable)
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _showNutritionDetails =
                                            !_showNutritionDetails;
                                        _showTimeDetails = false;
                                      }),
                                      child: Row(
                                        children: [
                                          Icon(Icons.local_fire_department,
                                              size: iconSize, color: iconColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${recipe.nutritionInfo.calories > 0 ? recipe.nutritionInfo.calories.round() : '-'} Cal',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Icon(
                                            _showNutritionDetails
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Categories
                                  Icon(Icons.signal_cellular_alt,
                                      size: iconSize, color: iconColor),
                                  const SizedBox(width: 4),
                                  Text(recipe.categories.isNotEmpty
                                      ? recipe.categories.first
                                      : '-'),
                                ],
                              ),
                            ),
                            // Expanded Time Details
                            if (_showTimeDetails)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 32, top: 4, bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.timer,
                                        size: 16, color: iconColor),
                                    const SizedBox(width: 4),
                                    Text(
                                        'Prep: ${recipe.prepTime > 0 ? recipe.prepTime : '-'} min'),
                                    const SizedBox(width: 16),
                                    Icon(Icons.timer_outlined,
                                        size: 16, color: iconColor),
                                    const SizedBox(width: 4),
                                    Text(
                                        'Cook: ${recipe.cookTime > 0 ? recipe.cookTime : '-'} min'),
                                  ],
                                ),
                              ),
                            // Expanded Nutrition Details
                            if (_showNutritionDetails)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 32, top: 4, bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.fastfood,
                                        size: 16, color: iconColor),
                                    const SizedBox(width: 4),
                                    Text(
                                        'Carbs: ${recipe.nutritionInfo.carbohydrates_total_g > 0 ? recipe.nutritionInfo.carbohydrates_total_g.round() : '-'} g'),
                                    const SizedBox(width: 16),
                                    Icon(Icons.local_dining,
                                        size: 16, color: iconColor),
                                    const SizedBox(width: 4),
                                    Text(
                                        'Protein: ${recipe.nutritionInfo.protein_g > 0 ? recipe.nutritionInfo.protein_g.round() : '-'} g'),
                                    const SizedBox(width: 16),
                                    Icon(Icons.restaurant,
                                        size: 16, color: iconColor),
                                    const SizedBox(width: 4),
                                    Text(
                                        'Fat: ${recipe.nutritionInfo.fat_total_g > 0 ? recipe.nutritionInfo.fat_total_g.round() : '-'} g'),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),
                            // Author
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.grey[300],
                                  child:
                                      Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (recipe.createdByName.isNotEmpty
                                          ? recipe.createdByName
                                          : (recipe.userId.isNotEmpty
                                              ? recipe.userId
                                              : '-')),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text('Recipe Author',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12)),
                                  ],
                                ),
                                Spacer(),
                                // hide when recipe owner is the current user
                                if (recipe.userId != vm.currentUserId)
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[200],
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24)),
                                      elevation: 0,
                                    ),
                                    child: Text('+ Follow'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Tab Bar
                            TabBar(
                              controller: vm.tabController,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.black,
                              indicator: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(24), // Less rounded
                                color: const Color.fromARGB(255, 255, 57, 57),
                              ),
                              indicatorPadding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              indicatorSize: TabBarIndicatorSize.tab,
                              tabs: const [
                                Tab(text: 'Ingredients'),
                                Tab(text: 'Instructions'),
                                Tab(text: 'Review'),
                              ],
                            ),
                            SizedBox(
                              height: 320,
                              child: TabBarView(
                                controller: vm.tabController,
                                children: [
                                  // Ingredients Tab
                                  recipe.ingredients.isNotEmpty
                                      ? ListView.separated(
                                          itemCount: recipe.ingredients.length,
                                          separatorBuilder: (context, i) =>
                                              Divider(),
                                          itemBuilder: (context, i) {
                                            final ing = recipe.ingredients[i];
                                            final isEditing =
                                                vm.editingIngredientsIndex == i;
                                            final controller =
                                                vm.editingController;

                                            return MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: isEditing
                                                  ? ListTile(
                                                      leading: Text('${i + 1}'
                                                          .padLeft(2, '0')),
                                                      title: Text(
                                                          ing.name.isNotEmpty
                                                              ? ing.name
                                                              : '-'),
                                                      subtitle: Row(
                                                        children: [
                                                          SizedBox(
                                                            width: 80,
                                                            child: TextField(
                                                              controller:
                                                                  controller,
                                                              keyboardType: TextInputType
                                                                  .numberWithOptions(
                                                                      decimal:
                                                                          true),
                                                              autofocus: true,
                                                              decoration:
                                                                  InputDecoration(
                                                                hintText:
                                                                    'Enter amount',
                                                                suffixText:
                                                                    ing.unit,
                                                              ),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                                Icons.check,
                                                                color: Colors
                                                                    .green),
                                                            tooltip: 'Update',
                                                            onPressed: () {
                                                              vm.updateIngredientAmount(
                                                                  i,
                                                                  controller
                                                                      .text);
                                                            },
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                                Icons.close,
                                                                color:
                                                                    Colors.red),
                                                            tooltip: 'Cancel',
                                                            onPressed: () {
                                                              vm.cancelEditing();
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : ListTile(
                                                      leading: Text('${i + 1}'
                                                          .padLeft(2, '0')),
                                                      title: Text(
                                                          ing.name.isNotEmpty
                                                              ? ing.name
                                                              : '-'),
                                                      subtitle: Text(
                                                        (ing.amount > 0
                                                                ? ing.amount
                                                                    .toString()
                                                                : '-') +
                                                            (ing.unit.isNotEmpty
                                                                ? ' ${ing.unit}'
                                                                : ''),
                                                      ),
                                                      onTap: () {
                                                        vm.startEditingIngredient(
                                                            i, ing.amount);
                                                      },
                                                    ),
                                            );
                                          },
                                        )
                                      : Center(child: Text('No ingredients.')),
                                  // Instructions Tab
                                  recipe.instructions.isNotEmpty
                                      ? ListView.separated(
                                          itemCount: recipe.instructions.length,
                                          separatorBuilder: (context, i) =>
                                              Divider(),
                                          itemBuilder: (context, i) {
                                            final step = recipe.instructions[i];
                                            final controller =
                                                vm.previewControllers[i];
                                            return ExpansionTile(
                                              leading: Text(
                                                  '${i + 1}'.padLeft(2, '0')),
                                              title: Text(
                                                  step.description.isNotEmpty
                                                      ? step.description
                                                      : '-'),
                                              children: [
                                                if (controller != null &&
                                                    controller
                                                        .value.isInitialized)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: AspectRatio(
                                                      aspectRatio: controller
                                                          .value.aspectRatio,
                                                      child: Chewie(
                                                        controller:
                                                            ChewieController(
                                                          videoPlayerController:
                                                              controller,
                                                          autoPlay: false,
                                                          looping: false,
                                                          aspectRatio: 16 / 9,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                if (step.duration != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                        'Duration: ${step.duration} seconds'),
                                                  ),
                                              ],
                                            );
                                          },
                                        )
                                      : Center(child: Text('No instructions.')),
                                  // Review Tab
                                  Center(child: Text('No reviews yet.')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StepByStepCookingPage(recipe: recipe),
                  ),
                );
              },
              backgroundColor: Color.fromARGB(255, 252, 175, 21),
              icon: Icon(Icons.play_arrow),
              label: Text('Cook Mode'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeImage(String imageUrl) {
    return GestureDetector(
      onTap: _showImageUploadOptions,
      child: Stack(
        children: [
          // Main image or placeholder
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('❌ Recipe detail image loading error: $error');
                return _buildPlaceholderImage();
              },
            )
          else
            _buildPlaceholderImage(),

          // Upload button overlay
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(25),
              ),
              child: _isUploadingImage
                  ? Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _showImageUploadOptions,
                      icon: Icon(
                        imageUrl.isNotEmpty ? Icons.edit : Icons.add_a_photo,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip:
                          imageUrl.isNotEmpty ? 'Change Image' : 'Add Image',
                    ),
            ),
          ),

          // Upload hint for empty state
          if (imageUrl.isEmpty && !_isUploadingImage)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap anywhere to upload',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF2E7D32),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 80,
            color: Colors.white.withOpacity(0.8),
          ),
          SizedBox(height: 16),
          Text(
            'Add Recipe Image',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Tap anywhere to upload a photo',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border:
                  Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: 24,
                  color: Colors.white.withOpacity(0.9),
                ),
                SizedBox(width: 12),
                Text(
                  'Upload Image',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt,
                        size: 16, color: Colors.white.withOpacity(0.8)),
                    SizedBox(width: 6),
                    Text(
                      'Camera',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library,
                        size: 16, color: Colors.white.withOpacity(0.8)),
                    SizedBox(width: 6),
                    Text(
                      'Gallery',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
