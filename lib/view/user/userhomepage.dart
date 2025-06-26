import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../login.dart';
import '../banned_account.dart';
import '../user/ai.dart';
import 'userprofilepage.dart';
import 'searchpage.dart';
import '../my_recipes/my_recipes_page.dart';
import '../../view_models/home_view_model.dart';
import '../../models/recipe.dart';
import '../recipe/recipe_detail_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  bool _isVerifying = true;
  bool _hasAccess = false;
  late HomeViewModel _viewModel;

  final List<Widget> _pages = [
    Container(),
    const SearchPage(),
    MyRecipesPage(),
    ChatScreen(),
    UserProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel()..initialize();
    _verifyUserAccess();
  }

  Future<void> _verifyUserAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return _redirectToLogin();

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!snapshot.exists) return _kickOut();

      final data = snapshot.data() as Map<String, dynamic>;
      final userType = (data['usertype'] ?? '').toString().toLowerCase().trim();

      if (userType != 'user') return _kickOut();

      final isBanned = data['isBanned'] == true ||
          data['banned'] == true ||
          data['is_banned'] == true;
      if (isBanned) {
        final reason = await _authService.getBanReason(user.uid);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => BannedAccountPage(
                  reason: reason ?? 'Your account has been suspended.')),
          (_) => false,
        );
        return;
      }

      setState(() {
        _hasAccess = true;
        _isVerifying = false;
      });
    } catch (e) {
      await _kickOut();
    }
  }

  Future<void> _kickOut() async {
    await _authService.signout();
    _redirectToLogin();
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerifying) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasAccess) {
      return const Scaffold(
        body: Center(child: Text('Access denied')),
      );
    }

    _pages[0] = _buildHomeContent();

    return Scaffold(
      appBar: AppBar(
        title: const Text('iBites'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmationDialog(context),
          ),
        ],
      ),
      body: _pages[_currentIndex],
    );
  }

  Widget _buildHomeContent() {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDailyInspiration(),
            ),
          ),
          // categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Categories'),
                  _buildCategories(),
                ],
              ),
            ),
          ),
          // latest
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Latest Recipes', onViewAll: () {}),
                  _buildRecipeList(_viewModel.latestRecipes),
                ],
              ),
            ),
          ),
          // recently viewed
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Recently Viewed', onViewAll: () {}),
                  _buildRecipeList(_viewModel.recentlyViewed),
                ],
              ),
            ),
          ),
          // popular
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Most Popular', onViewAll: () {}),
                  _buildRecipeList(_viewModel.popularRecipes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyInspiration() {
    return Consumer<HomeViewModel>(
      builder: (_, vm, __) {
        if (vm.dailyInspiration.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Inspiration',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller:
                    PageController(initialPage: vm.currentInspirationIndex),
                itemCount: vm.dailyInspiration.length,
                onPageChanged: vm.setCurrentInspirationIndex,
                itemBuilder: (_, i) =>
                    _buildInspirationCard(vm.dailyInspiration[i]),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                vm.dailyInspiration.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: vm.currentInspirationIndex == i
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInspirationCard(Recipe recipe) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              recipe.coverImage,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Colors.transparent
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(recipe.description,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: Theme.of(context).primaryColor),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecipeList(List<Recipe> recipes) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        itemBuilder: (_, i) {
          final r = recipes[i];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailPage(recipe: r),
                ),
              );
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        r.coverImage,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    size: 16, color: Colors.amber[700]),
                                const SizedBox(width: 4),
                                Text(
                                  r.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {
        'name': 'Breakfast',
        'icon': Icons.breakfast_dining,
        'color': Colors.orange
      },
      {'name': 'Lunch', 'icon': Icons.lunch_dining, 'color': Colors.green},
      {'name': 'Dinner', 'icon': Icons.dinner_dining, 'color': Colors.purple},
      {'name': 'Dessert', 'icon': Icons.cake, 'color': Colors.pink},
      {'name': 'Snacks', 'icon': Icons.cookie, 'color': Colors.brown},
      {'name': 'Drinks', 'icon': Icons.local_drink, 'color': Colors.blue},
      {'name': 'Vegetarian', 'icon': Icons.eco, 'color': Colors.lightGreen},
      {'name': 'Healthy', 'icon': Icons.favorite, 'color': Colors.red},
    ];

    return SizedBox(
      height: 180,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final c = categories[i];
          return InkWell(
            onTap: () {
              // TODO: navigate to category
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: c['color'] as Color,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(c['icon'] as IconData, size: 28),
                ),
                const SizedBox(height: 8),
                Text(c['name'] as String,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _authService.signout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginPage()), (_) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
