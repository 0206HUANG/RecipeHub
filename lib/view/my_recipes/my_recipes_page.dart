import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import '../recipe/recipe_detail_page.dart';
import '../recipe/recipe_form_page.dart';
//import '../recipe/edit_recipe_page.dart';
import '../recipe/recipe_edit_page.dart';

class MyRecipesPage extends StatefulWidget {
  MyRecipesPage({Key? key}) : super(key: key);

  @override
  _MyRecipesPageState createState() => _MyRecipesPageState();
}

class _MyRecipesPageState extends State<MyRecipesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RecipeService _recipeService = RecipeService();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('My Recipes'),
        actions: [
          IconButton(
            icon: Icon(Icons.cleaning_services),
            tooltip: 'Clean up invalid images',
            onPressed: _cleanupProblematicImages,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Saved Recipes'),
            Tab(text: 'Created Recipes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedRecipes(),
          _buildCreatedRecipes(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          if (_tabController.index == 0) {
            _showCreateCookbookDialog(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecipeFormPage()),
            );
          }
        },
        child: Icon(Icons.add),
        tooltip: _tabController.index == 0
            ? 'Create New Cookbook'
            : 'Create New Recipe',
      ),
    );
  }

  Widget _buildSavedRecipes() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(_currentUserId)
          .collection("bookmarks")
          .orderBy("savedAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final bookmarkDocs = snapshot.data?.docs ?? [];
        if (bookmarkDocs.isEmpty) {
          return Center(child: Text("No saved recipes."));
        }
        return ListView.builder(
          itemCount: bookmarkDocs.length,
          itemBuilder: (context, i) {
            final bookmark = bookmarkDocs[i];
            final recipeId = bookmark.get("recipeId") as String?;
            print('Bookmark recipeId: $recipeId');
            if (recipeId == null) return SizedBox.shrink();

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("recipes")
                  .doc(recipeId)
                  .snapshots(),
              builder: (context, recipeSnapshot) {
                if (recipeSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (recipeSnapshot.hasError || !recipeSnapshot.hasData) {
                  return SizedBox.shrink();
                }
                final recipeData =
                    recipeSnapshot.data!.data() as Map<String, dynamic>?;
                print('Recipe data for $recipeId: $recipeData');
                if (recipeData == null) return SizedBox.shrink();
                final recipe = Recipe.fromFirestore(recipeSnapshot.data!);

                // Debug: Print recipe info to identify problematic data
                print('📱 Recipe: ${recipe.title}');
                print('🖼️ Cover Image: "${recipe.coverImage}"');
                print(
                    '🔍 Image URL valid: ${_isValidImageUrl(recipe.coverImage)}');

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: _buildRecipeImage(recipe.coverImage),
                    title: Text(recipe.title,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(recipe.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                RecipeDetailPage(recipe: recipe))),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCreatedRecipes() {
    return StreamBuilder<List<Recipe>>(
      stream: _recipeService.getMyRecipes(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final myRecipes = snapshot.data ?? [];
        if (myRecipes.isEmpty) {
          return Center(child: Text("No recipes created yet."));
        }
        return ListView.builder(
          itemCount: myRecipes.length,
          itemBuilder: (context, i) {
            final recipe = myRecipes[i];

            // Debug: Print recipe info to identify problematic data
            print('📱 Created Recipe: ${recipe.title}');
            print('🖼️ Cover Image: "${recipe.coverImage}"');
            print('🔍 Image URL valid: ${_isValidImageUrl(recipe.coverImage)}');

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: _buildRecipeImage(recipe.coverImage),
                title: Text(recipe.title,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(recipe.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _navigateToEditRecipePage(recipe),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteRecipe(recipe),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            RecipeDetailPage(recipe: recipe))),
              ),
            );
          },
        );
      },
    );
  }

  // Edit recipe
  void _navigateToEditRecipePage(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecipePage(recipe: recipe),
      ),
    );
  }

  // Delete recipe
  void _deleteRecipe(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Recipe"),
        content: Text("Are you sure you want to delete this recipe?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await _recipeService.userDeleteRecipe(
                  recipe.id, _currentUserId, recipe.coverImage ?? '');
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recipe deleted successfully')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting recipe')));
              }
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showCreateCookbookDialog(BuildContext context) {
    // Implementation of _showCreateCookbookDialog method
  }

  Widget _buildRecipeImage(String? imageUrl) {
    // Check if image URL is valid
    if (imageUrl == null ||
        imageUrl.isEmpty ||
        !(Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false)) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.restaurant, size: 25, color: Colors.grey[600]),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
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
          print('❌ Image loading error for URL: $imageUrl');
          print('Error: $error');
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 16, color: Colors.red[400]),
                Text(
                  'Failed',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return false;
    return Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false;
  }

  // Method to clean up problematic image URLs
  Future<void> _cleanupProblematicImages() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int updateCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final coverImage = data['coverImage'] as String?;

        if (coverImage != null &&
            coverImage.isNotEmpty &&
            !_isValidImageUrl(coverImage)) {
          print(
              '🧹 Cleaning up invalid image URL for recipe: ${data['title']}');
          print('   Invalid URL: "$coverImage"');

          batch.update(doc.reference, {'coverImage': ''});
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        print('✅ Cleaned up $updateCount recipes with invalid image URLs');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Cleaned up $updateCount recipes with invalid images'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error cleaning up images: $e');
    }
  }
}
