import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/recipe.dart';

class SearchViewModel extends ChangeNotifier {
  String query = "";
  List<Recipe> results = [];
  late String currentUserId;

  List<Recipe> get getResults => results;

  SearchViewModel() {
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<void> searchRecipes(String query) async {
    final terms = parseSearchQuery(query);
    final includeTerms = terms['include']!;
    final excludeTerms = terms['exclude']!;

    if (query.trim().isEmpty) {
      results = [];
      notifyListeners();
      return;
    }

    final snapshot =
        await FirebaseFirestore.instance.collection('recipes').get();

    List<Recipe> allResults =
        snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();

    allResults = allResults.where((recipe) {
      final allKeywords = (recipe.toMap()['searchKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          [];

      final hasAllIncludes =
          includeTerms.every((term) => allKeywords.contains(term));

      final hasExcluded =
          excludeTerms.any((term) => allKeywords.contains(term));

      print('🔍 ${recipe.title} keywords: $allKeywords');
      print('IncludeTerms: $includeTerms');
      print('ExcludeTerms: $excludeTerms');

      return hasAllIncludes && !hasExcluded;
    }).toList();

    final updatedResults = await Future.wait(allResults.map((recipe) async {
      final bookmarked = await isBookmark(recipe.id);
      return recipe.copyWith(isBookmarked: bookmarked);
    }));

    results = updatedResults;

    notifyListeners();
  }

  Map<String, List<String>> parseSearchQuery(String query) {
    final lowerQuery = query.toLowerCase();
    final words = lowerQuery.split(RegExp(r'\s+'));
    final include = <String>[];
    final exclude = <String>[];

    for (int i = 0; i < words.length; i++) {
      if (words[i] == 'no' || words[i] == 'without') {
        if (i + 1 < words.length) {
          exclude.add(words[i + 1]);
          i++; // Skip the next word
        }
      } else {
        include.add(words[i]);
      }
    }

    return {'include': include, 'exclude': exclude};
  }

  Future<bool> isBookmark(recipeId) async {
    if (currentUserId.isEmpty) return false;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("bookmarks")
        .doc(recipeId)
        .get();
    if (doc.exists) {
      return true;
    }
    return false;
  }

  Future<void> toggleBookmark(Recipe recipe) async {
    if (currentUserId.isEmpty) {
      return;
    }
    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("bookmarks")
        .doc(recipe.id);

    if (recipe.isBookmarked == true) {
      await docRef.delete();
    } else {
      await docRef.set(
          {"recipeId": recipe.id, "savedAt": FieldValue.serverTimestamp()});
    }
    recipe.isBookmarked = !(recipe.isBookmarked ?? false);

    final updatedResults = await Future.wait(results.map((recipe) async {
      final bookmarked = await isBookmark(recipe.id);
      return recipe.copyWith(isBookmarked: bookmarked);
    }));

    results = updatedResults;
    notifyListeners();
  }

  void clearResults() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('recipes').get();
    results = snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    notifyListeners();
    return;
  }
}
