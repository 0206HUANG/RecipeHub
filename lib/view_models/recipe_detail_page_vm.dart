import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:ibites/models/nutrition_model.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../models/recipe.dart';
import '../../models/ingredient_model.dart';
import '../../services/caloriesninja_service.dart';

class RecipeDetailViewModel extends ChangeNotifier {
  Recipe recipe;
  late TabController tabController;
  ChewieController? chewieController;
  int currentStep = 0;
  bool isBookmarked = false;
  late String currentUserId;
  int? editingIngredientsIndex;
  final TextEditingController editingController = TextEditingController();
  CaloriesNinjaService caloriesNinjaService = CaloriesNinjaService();
  final TextEditingController servingsController = TextEditingController();
  bool editingServings = false;

  RecipeDetailViewModel({
    required this.recipe,
    required TickerProvider vsync,
  }) {
    tabController = TabController(length: 3, vsync: vsync);
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    checkBookmark();
    initPreviewControllers(vsync);
  }

  final Map<int, VideoPlayerController?> previewControllers = {};

  Future<void> initPreviewControllers(TickerProvider vsync) async {
    for (var i = 0; i < recipe.instructions.length; i++) {
      final instruction = recipe.instructions[i];
      VideoPlayerController? controller;
      final localVideoPath = instruction.localVideoPath;
      final videoUrl = instruction.videoUrl;

      if (localVideoPath != null && localVideoPath.isNotEmpty) {
        controller = VideoPlayerController.file(File(localVideoPath));
      } else if (videoUrl != null && videoUrl.isNotEmpty) {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }
      if (controller != null) {
        await controller.initialize();
        previewControllers[i] = controller;
      } else {
        previewControllers[i] = null;
      }
    }
    notifyListeners();
  }

  void disposeControllers() {
    for (final controller in previewControllers.values) {
      controller?.dispose();
    }
  }

  Future<void> checkBookmark() async {
    if (currentUserId.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("bookmarks")
        .doc(recipe.id)
        .get();
    isBookmarked = doc.exists;
    notifyListeners();
  }

  Future<void> toggleBookmark(BuildContext context) async {
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please log in to bookmark.")));
      return;
    }
    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("bookmarks")
        .doc(recipe.id);
    if (isBookmarked) {
      await docRef.delete();
    } else {
      await docRef.set(
          {"recipeId": recipe.id, "savedAt": FieldValue.serverTimestamp()});
    }
    isBookmarked = !isBookmarked;
    notifyListeners();
  }

  void startEditingServings(int servings) {
    servingsController.text = servings.toString();
    notifyListeners();
  }

  void updateServings(int value) {
    if (value <= 0) return;

    // Calculate the ratio
    final ratio = value / recipe.servings;

    // Update all ingredient amounts based on the ratio
    for (var ing in recipe.ingredients) {
      ing.amount = (ing.amount * ratio);
    }

    recipe.servings = value;
    editingController.clear();
    updateNutritionInfo();
    notifyListeners();
  }

  void startEditingIngredient(int index, num currentAmount) {
    editingIngredientsIndex = index;
    editingController.text = currentAmount.toString();
    notifyListeners();
  }

  void cancelEditing() {
    editingIngredientsIndex = null;
    editingController.clear();
    notifyListeners();
  }

  void updateIngredientAmount(int index, String value) {
    final newAmount = num.tryParse(value);
    if (newAmount == null || newAmount <= 0) return;

    final oldAmount = recipe.ingredients[index].amount;
    if (oldAmount == 0) return;

    // Calculate the ratio
    final ratio = newAmount / oldAmount;

    // Update all ingredient amounts based on the ratio
    for (var ing in recipe.ingredients) {
      ing.amount = (ing.amount * ratio);
    }

    // Update servings
    recipe.servings = (recipe.servings * ratio).toInt();
    servingsController.text = recipe.servings.toString();

    editingIngredientsIndex = null;
    editingController.clear();
    updateNutritionInfo();
    notifyListeners();
  }

  void updateNutritionInfo() async {
    // make ingredients list into a string
    NutritionInfo? nutritionInfo = recipe.nutritionInfo;
    List<Ingredient> ingredients = recipe.ingredients;
    final ingredientsList =
        caloriesNinjaService.convertToQueryString(ingredients);

    if (ingredientsList.isNotEmpty) {
      nutritionInfo =
          await caloriesNinjaService.fetchNutritionInfo(ingredientsList);
    }
    recipe.nutritionInfo = nutritionInfo;

    notifyListeners();
  }

  // Update recipe object (for image updates, etc.)
  void updateRecipe(Recipe newRecipe) {
    recipe = newRecipe;
    notifyListeners();
  }
}
