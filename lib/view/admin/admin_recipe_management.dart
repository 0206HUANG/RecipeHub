import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart' as video_player;

// Video Player Widget
class RecipeVideoPlayer extends StatefulWidget {
  final String videoUrl;
  
  const RecipeVideoPlayer({Key? key, required this.videoUrl}) : super(key: key);
  
  @override
  _RecipeVideoPlayerState createState() => _RecipeVideoPlayerState();
}

class _RecipeVideoPlayerState extends State<RecipeVideoPlayer> {
  late video_player.VideoPlayerController _controller;
  late ChewieController _chewieController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = video_player.VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: false,
        looping: false,
        aspectRatio: _controller.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error loading video',
              style: TextStyle(color: Colors.red),
            ),
          );
        },
      );
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_initialized) {
      _chewieController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Chewie(controller: _chewieController);
  }
}

class AdminRecipeManagement extends StatefulWidget {
  const AdminRecipeManagement({Key? key}) : super(key: key);

  @override
  _AdminRecipeManagementState createState() => _AdminRecipeManagementState();
}

class _AdminRecipeManagementState extends State<AdminRecipeManagement> {
  final RecipeService _recipeService = RecipeService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'title', 'author', 'rating'
  bool _sortAscending = false;
  List<String> _selectedRecipeIds = [];
  bool _isSelectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipe Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search recipes by title, author, or description...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      fillColor: Colors.grey.shade50,
                      filled: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Sort Dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'date',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18),
                            SizedBox(width: 8),
                            Text('Date'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'title',
                        child: Row(
                          children: [
                            Icon(Icons.sort_by_alpha, size: 18),
                            SizedBox(width: 8),
                            Text('Title'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'author',
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 18),
                            SizedBox(width: 8),
                            Text('Author'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'rating',
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 18),
                            SizedBox(width: 8),
                            Text('Rating'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                    },
                    tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
                  ),
                ),
              ],
            ),
          ),

          // Recipe List
          Expanded(
            child: StreamBuilder<List<RecipeModel>>(
              stream: _recipeService.getAllRecipes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading recipes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading recipes...'),
                      ],
                    ),
                  );
                }

                List<RecipeModel> recipes = snapshot.data ?? [];

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  recipes = recipes.where((recipe) {
                    final searchLower = _searchQuery.toLowerCase();
                    final titleMatch = recipe.title.toLowerCase().contains(searchLower);
                    final descMatch = recipe.description.toLowerCase().contains(searchLower);
                    final authorMatch = recipe.authorName.toLowerCase().contains(searchLower);
                    return titleMatch || descMatch || authorMatch;
                  }).toList();
                }

                // Apply sorting
                recipes.sort((a, b) {
                  int comparison;
                  switch (_sortBy) {
                    case 'title':
                      comparison = a.title.compareTo(b.title);
                      break;
                    case 'author':
                      comparison = a.authorName.compareTo(b.authorName);
                      break;
                    case 'rating':
                      comparison = a.rating.compareTo(b.rating);
                      break;
                    case 'date':
                    default:
                      comparison = a.createdAt.compareTo(b.createdAt);
                      break;
                  }
                  return _sortAscending ? comparison : -comparison;
                });

                if (recipes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No recipes found'
                              : 'No recipes match your search',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return _buildRecipeListItem(recipe);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeListItem(RecipeModel recipe) {
    final isSelected = _selectedRecipeIds.contains(recipe.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      color: isSelected ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildAdminRecipeImage(recipe.imageUrl),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.title.isNotEmpty ? recipe.title : 'Untitled Recipe',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        recipe.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  _formatDescription(recipe.description),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FutureBuilder<Map<String, dynamic>>(
                      future: _getAuthorInfo(recipe.authorId),
                      builder: (context, snapshot) {
                        final authorInfo = snapshot.data ?? {};
                        final authorName = authorInfo['fullname'] ?? 'Loading...';
                        final authorEmail = authorInfo['email'] ?? '';
                        return Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  authorEmail.isNotEmpty ? '$authorName ($authorEmail)' : authorName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Text(
                      _formatDateTime(recipe.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showRecipeActions(recipe),
            ),
            onTap: () => _showRecipeDetails(recipe),
          ),
        ],
      ),
    );
  }

  void _toggleRecipeSelection(String recipeId) {
    setState(() {
      if (_selectedRecipeIds.contains(recipeId)) {
        _selectedRecipeIds.remove(recipeId);
      } else {
        _selectedRecipeIds.add(recipeId);
      }
    });
  }

  void _showRecipeDetails(RecipeModel recipe) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Recipe Image
                  if (recipe.imageUrl.isNotEmpty)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(recipe.imageUrl),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                    ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Description
                          Text(
                            _formatDescription(recipe.description),
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                          const SizedBox(height: 20),

                          // Author Info
                          FutureBuilder<Map<String, dynamic>>(
                            future: _getAuthorInfo(recipe.authorId),
                            builder: (context, snapshot) {
                              final authorInfo = snapshot.data ?? {};
                              final fullName = authorInfo['fullname'] ?? authorInfo['name'] ?? '';
                              final email = authorInfo['email'] ?? '';
                              final contactNo = authorInfo['contactno'] ?? '';
                              final userType = authorInfo['usertype'] ?? 'user';
                              
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recipe Author',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Author basic info
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.blue.shade100,
                                          child: Icon(Icons.person, color: Colors.blue.shade700),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fullName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                userType.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Contact information
                                    if (email.isNotEmpty) _buildInfoItem(
                                      icon: Icons.email,
                                      label: 'Email',
                                      value: email,
                                    ),
                                    if (contactNo.isNotEmpty) _buildInfoItem(
                                      icon: Icons.phone,
                                      label: 'Contact',
                                      value: contactNo,
                                    ),
                                    _buildInfoItem(
                                      icon: Icons.calendar_today,
                                      label: 'Recipe Created',
                                      value: _formatDateTime(recipe.createdAt),
                                    ),
                                    _buildInfoItem(
                                      icon: Icons.update,
                                      label: 'Last Updated',
                                      value: _formatDateTime(recipe.updatedAt),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Ingredients
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.restaurant_menu,
                                        color: Colors.green.shade700),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Ingredients',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: recipe.ingredients.length,
                                  itemBuilder: (context, index) {
                                    final ingredient = recipe.ingredients[index];
                                    // 解析数量和单位（如果有）
                                    final parts = ingredient.split(' ');
                                    String quantity = '';
                                    String unit = '';
                                    String name = ingredient;

                                    if (parts.length > 1) {
                                      // 尝试识别数量和单位
                                      if (RegExp(r'^[\d./]+$').hasMatch(parts[0])) {
                                        quantity = parts[0];
                                        if (parts.length > 2) {
                                          unit = parts[1];
                                          name = parts.sublist(2).join(' ');
                                        } else {
                                          name = parts[1];
                                        }
                                      }
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.shade100.withOpacity(0.5),
                                            spreadRadius: 1,
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                if (quantity.isNotEmpty) ...[
                                                  Text(
                                                    quantity,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                if (unit.isNotEmpty) ...[
                                                  Text(
                                                    unit,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Instructions
                          const Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recipe.instructions.length,
                            itemBuilder: (context, index) {
                              final instruction = recipe.instructions[index];
                              bool hasVideo = instruction.contains('videoUrl:') || 
                                            (instruction.contains('http') && 
                                             (instruction.contains('.mp4') || 
                                              instruction.contains('video')));
                              String videoUrl = '';
                              String instructionText = instruction;
                              
                              // Extract video URL and instruction text if available
                              if (hasVideo) {
                                if (instruction.contains('videoUrl:')) {
                                  final parts = instruction.split('videoUrl:');
                                  if (parts.length > 1) {
                                    videoUrl = parts[1].trim().split(' ')[0].replaceAll(RegExp(r'[{},"]'), '');
                                    instructionText = parts[0].contains('description:') ? 
                                                   parts[0].split('description:')[1].trim().replaceAll(RegExp(r'[{},"]'), '') :
                                                   parts[0].trim();
                                  }
                                } else {
                                  videoUrl = instruction.trim();
                                  instructionText = 'Step ${index + 1}';
                                }
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              instructionText,
                                              style: const TextStyle(fontSize: 16, height: 1.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (hasVideo && videoUrl.isNotEmpty) ...[
                                      Container(
                                        height: 200,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(color: Colors.grey.shade200),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            bottom: Radius.circular(12),
                                          ),
                                          child: RecipeVideoPlayer(videoUrl: videoUrl),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Close button
            Positioned(
              right: -16,
              top: -16,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, color: Colors.black),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatDescription(String description) {
    if (description.isEmpty) return 'No description available';

    description = description.trim();

    // Handle format errors like "Instance of '_Map<String, dynamic>'"
    if (description.contains('Instance of ') || description.contains('_Map')) {
      return 'Description not available';
    }

    // Clean up any malformed data
    if (description.contains('{') && description.contains('}')) {
      return 'Recipe description';
    }

    // Return cleaned description
    return description.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '').replaceAll("'", '').trim();
  }

  Future<String> _getAuthorEmail(String authorId) async {
    try {
      if (authorId.isEmpty) return 'No Author ID';
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authorId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['email']?.toString() ?? 'No Email Available';
      } else {
        return 'User Not Found';
      }
    } catch (e) {
      return 'Error Loading Email';
    }
  }

  Future<String> _getAuthorName(String authorId) async {
    try {
      if (authorId.isEmpty) {
        print('Author ID is empty');
        return '';
      }
      
      print('Fetching author name for ID: $authorId');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authorId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        // Try to get the full name from various possible fields
        String fullName = userData['fullname']?.toString() ?? // Admin registration field
                         userData['name']?.toString() ?? // User registration field
                         userData['fullName']?.toString() ?? // Alternative field
                         '';
        
        print('Found author name: $fullName for ID: $authorId');
        return fullName;
      } else {
        print('User document not found for ID: $authorId');
        return '';
      }
    } catch (e) {
      print('Error getting author name for ID $authorId: $e');
      return '';
    }
  }

  String _formatIngredient(String ingredient) {
    if (ingredient.isEmpty) return 'No ingredient specified';

    ingredient = ingredient.trim();

    // Handle different formats that might appear in the data
    
    // Format 1: JSON-like string with Instance of '_Map<String, dynamic>'
    if (ingredient.contains('Instance of ') || ingredient.contains('_Map')) {
      return 'Ingredient (format error)';
    }
    
    // Format 2: Structured data like "name: flour, unit: cups, amount: 2"
    if (ingredient.contains('name:') && ingredient.contains('amount:')) {
      try {
        String name = _extractValue(ingredient, 'name');
        String unit = _extractValue(ingredient, 'unit');
        String amount = _extractValue(ingredient, 'amount');

        if (name.isNotEmpty) {
          String formattedAmount = amount.isNotEmpty ? amount : '1';
          String formattedUnit = unit.isNotEmpty && unit != '1' && unit != 'null' ? ' $unit' : '';
          return '$formattedAmount$formattedUnit $name';
        }
      } catch (e) {
        // If parsing fails, continue to next format
      }
    }
    
    // Format 3: Try to extract readable content from messy data
    if (ingredient.contains('{') && ingredient.contains('}')) {
      // Try to extract name field from map-like string
      RegExp nameRegex = RegExp(r'name[:\s]+([^,}]+)');
      Match? nameMatch = nameRegex.firstMatch(ingredient);
      if (nameMatch != null) {
        return nameMatch.group(1)?.trim() ?? ingredient;
      }
    }

    // Format 4: Clean basic string
    return ingredient.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '').replaceAll("'", '').trim();
  }

  String _formatInstruction(String instruction) {
    if (instruction.isEmpty) return 'No instruction provided';

    instruction = instruction.trim();

    // Handle format errors like "Instance of '_Map<String, dynamic>'"
    if (instruction.contains('Instance of ') || instruction.contains('_Map')) {
      return 'Instruction (format error)';
    }

    // Handle video URLs
    if (instruction.startsWith('http') &&
        (instruction.contains('video') ||
            instruction.contains('youtube') ||
            instruction.contains('.mp4'))) {
      return 'Video instruction: ${_shortenUrl(instruction)}';
    }

    // Handle structured instruction data with description and video
    if (instruction.contains('description:') || instruction.contains('videoUrl:')) {
      String description = _extractValue(instruction, 'description');
      String videoUrl = _extractValue(instruction, 'videoUrl');

      if (description.isNotEmpty) {
        return description +
            (videoUrl.isNotEmpty ? ' (Video: ${_shortenUrl(videoUrl)})' : '');
      } else if (videoUrl.isNotEmpty) {
        return 'Video instruction: ${_shortenUrl(videoUrl)}';
      }
    }

    // Try to extract readable content from messy data
    if (instruction.contains('{') && instruction.contains('}')) {
      // Try to extract description field from map-like string
      RegExp descRegex = RegExp(r'description[:\s]+([^,}]+)');
      Match? descMatch = descRegex.firstMatch(instruction);
      if (descMatch != null) {
        String extracted = descMatch.group(1)?.trim() ?? '';
        return extracted.replaceAll('"', '').replaceAll("'", '');
      }
    }

    // Return cleaned instruction
    return instruction.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '').replaceAll("'", '').trim();
  }

  String _extractValue(String data, String key) {
    try {
      RegExp regex = RegExp('$key:\\s*([^,}]+)');
      Match? match = regex.firstMatch(data);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return '';
  }

  String _shortenUrl(String url) {
    if (url.length <= 50) return url;
    return '${url.substring(0, 30)}...${url.substring(url.length - 15)}';
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getAuthorInfo(String authorId) async {
    try {
      if (authorId.isEmpty) {
        print('Author ID is empty');
        return {};
      }
      
      print('Fetching author info for ID: $authorId');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authorId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        print('Found user data: $userData');
        
        // Try to get the full name from various possible fields
        String fullName = userData['fullname'] ?? // Admin registration field
                         userData['name'] ?? // User registration field
                         userData['fullName'] ?? // Alternative field
                         userData['displayName'] ?? // Firebase Auth display name
                         userData['email'] ?? // Use email as fallback
                         '';
                         
        // Get email from various possible fields
        String email = userData['email'] ??
                      userData['userEmail'] ??
                      '';
                      
        // Get contact from various possible fields
        String contactNo = userData['contactno'] ??
                         userData['phone'] ??
                         userData['contact'] ??
                         '';
                         
        return {
          'fullname': fullName,
          'email': email,
          'contactno': contactNo,
          'usertype': userData['usertype'] ?? 'user'
        };
      } else {
        print('User document not found for ID: $authorId');
        return {};
      }
    } catch (e) {
      print('Error getting author info for ID $authorId: $e');
      return {};
    }
  }

  void _showRecipeActions(RecipeModel recipe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('View Recipe Details'),
              onTap: () {
                Navigator.pop(context);
                _showRecipeDetails(recipe);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Recipe'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(recipe);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(RecipeModel recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecipe(recipe.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteRecipe(String recipeId) async {
    try {
      await _recipeService.deleteRecipe(recipeId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete recipe: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAdminRecipeImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 20,
              color: Colors.white.withOpacity(0.8),
            ),
            SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Image.network(
      imageUrl,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 80,
          height: 80,
          color: Colors.grey[200],
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Admin recipe image loading error: $error');
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEF4444),
                Color(0xFFF97316),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              SizedBox(height: 2),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
