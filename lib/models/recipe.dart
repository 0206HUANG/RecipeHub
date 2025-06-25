import 'package:cloud_firestore/cloud_firestore.dart';
import 'ingredient_model.dart';
import 'instruction_model.dart';
import 'nutrition_model.dart';

// Original Recipe class for user view.
class Recipe {
  final String id;
  final String title;
  final String coverImage;
  int servings;
  final int prepTime; // in minutes
  final List<String> categories;
  final int cookTime; // in minutes
  final int totalTime; // in minutes
  final String description;
  final List<Ingredient> ingredients;
  final List<Instruction> instructions;
  NutritionInfo nutritionInfo;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdByName;
  final double rating;  
  List<String> searchKeywords;
  bool? isBookmarked;

  Recipe({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.servings,
    required this.prepTime,
    required this.categories,
    required this.cookTime,
    required this.totalTime,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.nutritionInfo,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByName,
    this.rating = 0.0,
    this.searchKeywords = const [],
    this.isBookmarked,
  });

  // Add the copyWith method to update a recipe fields
  Recipe copyWith({
    String? title,
    String? coverImage,
    int? servings,
    int? prepTime,
    List<String>? categories,
    int? cookTime,
    int? totalTime,
    String? description,
    List<Ingredient>? ingredients,
    List<Instruction>? instructions,
    NutritionInfo? nutritionInfo,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByName,
    bool? isBookmarked,
  }) {
    return Recipe(
      id: this.id,
      title: title ?? this.title,
      coverImage: coverImage ?? this.coverImage,
      servings: servings ?? this.servings,
      prepTime: prepTime ?? this.prepTime,
      categories: categories ?? this.categories,
      cookTime: cookTime ?? this.cookTime,
      totalTime: totalTime ?? this.totalTime,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByName: createdByName ?? this.createdByName,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Debug: Print the raw data to understand the structure
    print('🔍 Recipe.fromFirestore data: $data');

    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      coverImage: data['coverImage'] ?? '',
      servings: data['servings'] ?? 0,
      prepTime: data['prepTime'] ?? 0,
      categories: List<String>.from(data['categories'] ?? []),
      cookTime: data['cookTime'] ?? 0,
      totalTime: data['totalTime'] ?? 0,
      description: data['description'] ?? '',
      ingredients: (data['ingredients'] as List?)?.map((e) {
            if (e is Map<String, dynamic>) return Ingredient.fromMap(e);
            return Ingredient(name: e.toString(), amount: 0.0, unit: '');
          }).toList() ??
          [],
      instructions: (data['instructions'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => Instruction.fromMap(e))
              .toList() ??
          [],
      nutritionInfo: NutritionInfo.fromMap(data['nutritionInfo'] ?? {}),
      // Try both userId and createdBy fields for compatibility
      userId: data['userId'] ?? data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdByName: data['createdByName'] ?? '-',
      rating: (data['rating'] ?? 0).toDouble(),
      searchKeywords: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'coverImage': coverImage,
      'servings': servings,
      'prepTime': prepTime,
      'categories': categories,
      'cookTime': cookTime,
      'totalTime': totalTime,
      'description': description,
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
      'instructions': instructions.map((e) => e.toMap()).toList(),
      'nutritionInfo': nutritionInfo.toMap(),
      'userId': userId,
      'createdBy': userId, // Add createdBy field for compatibility
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdByName': createdByName,
      'createdByEmail': createdByName, // Add createdByEmail field
      'searchKeywords': _generateSearchKeywords(),
      'rating': rating,
      
    };
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[];

    keywords.addAll(title.toLowerCase().split(' '));
    keywords.addAll(description.toLowerCase().split(' '));
    keywords.addAll(categories.map((c) => c.toLowerCase()));

    // Ingredient names and units
    for (var ingredient in ingredients) {
      keywords.add(ingredient.name.toLowerCase());
      keywords.add('${ingredient.amount} ${ingredient.unit}'.toLowerCase());
      keywords.add(ingredient.toQueryString().toLowerCase());
    }

    // Instructions
    for (var instruction in instructions) {
      keywords.addAll(instruction.description.toLowerCase().split(' '));
    }

    // Nutrition
    final nutrition = nutritionInfo;
    keywords.addAll([
      nutrition.calories.toString(),
      nutrition.protein_g.toString(),
      nutrition.carbohydrates_total_g.toString(),
      nutrition.fat_total_g.toString(),
      nutrition.fiber_g.toString(),
      nutrition.sugar_g.toString(),
      'calories',
      'protein',
      'carbs',
      'fat',
      'fiber',
      'sugar'
    ]);

    return keywords.toSet().toList(); // remove duplicates
  }
}
