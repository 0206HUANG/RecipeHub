import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import '../../services/auth_service.dart';
import 'recipe_detail_page.dart';
import 'recipe_form_page.dart';
import '../../widgets/smart_recipe_filter.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({Key? key}) : super(key: key);

  @override
  _RecipeListPageState createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final _recipeService = RecipeService();
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _includedIngredients = [];
  List<String> _excludedIngredients = [];

  Stream<List<Recipe>> _getRecipeStream() {
    // Always use the combined search and filter method to handle all filters together
    return _recipeService.searchAndFilterRecipes(_searchQuery,
        _includedIngredients, _excludedIngredients, _selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...[
                  'Breakfast',
                  'Lunch',
                  'Dinner',
                  'Dessert',
                  'Snack',
                  'Vegetarian',
                  'Vegan',
                  'Gluten-Free'
                ].map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Smart Recipe Filter
          SmartRecipeFilter(
            onFilterChanged: (included, excluded) {
              setState(() {
                _includedIngredients = List.from(included);
                _excludedIngredients = List.from(excluded);
              });
            },
          ),

          const SizedBox(height: 8),

          // Recipe List
          Expanded(
            child: StreamBuilder<List<Recipe>>(
              stream: _getRecipeStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final recipes = snapshot.data!;

                if (recipes.isEmpty) {
                  return const Center(
                    child: Text('No recipes found'),
                  );
                }

                return ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Row(
                        children: [
                          // Image with duration overlay
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: _buildRecipeListImage(recipe.coverImage),
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    // Show total time as duration (hh:mm:ss)
                                    _formatDuration(
                                        recipe.prepTime + recipe.cookTime),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Info
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    recipe.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  // Meta row
                                  Row(
                                    children: [
                                      Icon(Icons.visibility,
                                          size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 2),
                                      Text('-',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600])),
                                      const SizedBox(width: 10),
                                      Text(
                                        recipe.createdAt != null
                                            ? _timeAgo(recipe.createdAt)
                                            : '-',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Author row
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundImage: NetworkImage(
                                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(recipe.createdByName)}'),
                                        child: Icon(Icons.person, size: 16),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        recipe.createdByName.isNotEmpty
                                            ? recipe.createdByName
                                            : '-',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecipeFormPage()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Recipe',
      ),
    );
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes <= 0) return '00:00';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';
    } else {
      return '00:${minutes.toString().padLeft(2, '0')}:00';
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildRecipeListImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 110,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B6B),
              Color(0xFFFF8E53),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 24,
              color: Colors.white.withOpacity(0.8),
            ),
            SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Image.network(
      imageUrl,
      width: 110,
      height: 80,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 110,
          height: 80,
          color: Colors.grey[200],
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Recipe list image loading error: $error');
        return Container(
          width: 110,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFFFF8E53),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 20,
                color: Colors.white.withOpacity(0.8),
              ),
              SizedBox(height: 4),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
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
