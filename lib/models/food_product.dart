class FoodProduct {
  final String barcode;
  final String name;
  final String brand;
  final double caloriesPer100g;
  final Map<String, dynamic> nutritionalInfo;
  final List<String> ingredients;
  final List<String> allergens;
  final String imageUrl;
  final bool isRecalled;

  FoodProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.caloriesPer100g,
    this.nutritionalInfo = const {},
    this.ingredients = const [],
    this.allergens = const [],
    this.imageUrl = '',
    this.isRecalled = false,
  });

  factory FoodProduct.fromOpenFoodFacts(Map<String, dynamic> data) {
    final product = data['product'] ?? {};
    final nutriments = product['nutriments'] ?? {};
    
    return FoodProduct(
      barcode: product['code'] ?? '',
      name: product['product_name'] ?? 'Unknown Product',
      brand: product['brands'] ?? 'Unknown Brand',
      caloriesPer100g: (nutriments['energy-kcal_100g'] ?? 0.0).toDouble(),
      nutritionalInfo: {
        'protein': (nutriments['proteins_100g'] ?? 0.0).toDouble(),
        'fat': (nutriments['fat_100g'] ?? 0.0).toDouble(),
        'carbohydrates': (nutriments['carbohydrates_100g'] ?? 0.0).toDouble(),
        'fiber': (nutriments['fiber_100g'] ?? 0.0).toDouble(),
      },
      ingredients: List<String>.from(
        product['ingredients_text']?.split(',')?.map((e) => e.trim()) ?? []
      ),
      allergens: List<String>.from(product['allergens_tags'] ?? []),
      imageUrl: product['image_url'] ?? '',
    );
  }

  double calculateCaloriesForPortion(double portionSizeGrams) {
    return (caloriesPer100g * portionSizeGrams) / 100;
  }
}
