import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class HomeViewModel extends ChangeNotifier {
  // Internal data
  List<Recipe> _dailyInspiration = [];
  List<Recipe> _latestRecipes = [];
  List<Recipe> _recentlyViewed = [];
  List<Recipe> _popularRecipes = [];

  int _currentInspirationIndex = 0;
  Timer? _slideshowTimer;

  // Getters
  List<Recipe> get dailyInspiration => _dailyInspiration;
  List<Recipe> get latestRecipes => _latestRecipes;
  List<Recipe> get recentlyViewed => _recentlyViewed;
  List<Recipe> get popularRecipes => _popularRecipes;
  int get currentInspirationIndex => _currentInspirationIndex;

  void setCurrentInspirationIndex(int index) {
    _currentInspirationIndex = index;
    notifyListeners();
  }

  /// Main initializer
  Future<void> initialize() async {
    await Future.wait([
      _loadDailyInspiration(),
      _loadLatestRecipes(),
      _loadRecentlyViewed(),
      _loadPopularRecipes(),
    ]);
    _startSlideshow();
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    super.dispose();
  }

  /// --- Loaders for each section ---

  Future<void> _loadDailyInspiration() async {
    _dailyInspiration = await _fetchRecipes(
      orderBy: 'rating',
      descending: true,
      limit: 5,
    );
    notifyListeners();
  }

  Future<void> _loadLatestRecipes() async {
    _latestRecipes = await _fetchRecipes(
      orderBy: 'createdAt',
      descending: true,
      limit: 20,
    );
    notifyListeners();
  }

  Future<void> _loadRecentlyViewed() async {
    // Replace this logic later with locally stored IDs
    _recentlyViewed = await _fetchRecipes(
      orderBy: 'createdBy',
      descending: true,
      limit: 8,
    );
    notifyListeners();
  }

  Future<void> _loadPopularRecipes() async {
    _popularRecipes = await _fetchRecipes(
      orderBy: 'rating',
      descending: true,
      limit: 8,
    );
    notifyListeners();
  }

  /// Shared Firestore fetcher
  Future<List<Recipe>> _fetchRecipes({
    required String orderBy,
    bool descending = false,
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .orderBy(orderBy, descending: descending)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Recipe.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching recipes: $e');
      return [];
    }
  }

  /// Auto slide inspiration
  void _startSlideshow() {
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_dailyInspiration.isNotEmpty) {
        _currentInspirationIndex =
            (_currentInspirationIndex + 1) % _dailyInspiration.length;
        notifyListeners();
      }
    });
  }
}
