import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/searchpage_view_model.dart';
import '../recipe/recipe_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchViewModel _viewModel = SearchViewModel();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    await _viewModel.searchRecipes(query);

    setState(() {
      _isSearching = true;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _viewModel.clearResults();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _viewModel,
      child: Consumer<SearchViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            body: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search recipes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onSubmitted: (value) {
                      _performSearch(value);
                    },
                    textInputAction: TextInputAction.search,
                  ),
                ),

                // Search Results
                Expanded(
                  child: _isSearching
                      ? _buildSearchResults()
                      : _buildSearchSuggestions(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<SearchViewModel>(
      builder: (context, viewModel, _) {
        final results = viewModel.results;

        if (results.isEmpty) {
          return const Center(child: Text('No recipes found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final recipe = results[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    recipe.coverImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(recipe.title, overflow: TextOverflow.ellipsis),
                subtitle:
                    Text(recipe.description, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: Icon(
                    recipe.isBookmarked == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: recipe.isBookmarked == true
                        ? Colors.redAccent
                        : Colors.grey,
                  ),
                  onPressed: () {
                    viewModel.toggleBookmark(recipe);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailPage(recipe: recipe),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Popular Searches',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSuggestionChip('Breakfast'),
            _buildSuggestionChip('Vegetarian'),
            _buildSuggestionChip('Quick Meals'),
            _buildSuggestionChip('Low Carb'),
            _buildSuggestionChip('Lunch'),
            _buildSuggestionChip('Desserts'),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Recent Searches',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // TODO: Replace with actual recent searches
        _buildRecentSearchItem('Pasta Recipes'),
        _buildRecentSearchItem('Chicken Curry'),
        _buildRecentSearchItem('Salad Ideas'),
      ],
    );
  }

  Widget _buildSuggestionChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _searchController.text = label;
        _performSearch(label);
      },
    );
  }

  Widget _buildRecentSearchItem(String query) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(query),
      onTap: () {
        _searchController.text = query;
        _performSearch(query);
      },
    );
  }
}
