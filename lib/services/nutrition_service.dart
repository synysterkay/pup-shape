import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pupshape/models/food_product.dart';

class NutritionService {
  static const String _openFoodFactsBaseUrl = 'https://world.openfoodfacts.org/api/v0/product';
  static const String _fdaRecallsUrl = 'https://api.fda.gov/food/enforcement.json';

  Future<FoodProduct?> getProductByBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_openFoodFactsBaseUrl/$barcode.json'),
        headers: {
          'User-Agent': 'CalDogsAI/1.0.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          return FoodProduct.fromOpenFoodFacts(data);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch product data: $e');
    }
  }

  Future<List<String>> searchProducts(String query) async {
    try {
      final response = await http.get(
        Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1'),
        headers: {
          'User-Agent': 'CalDogsAI/1.0.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List;
        return products
            .map((product) => product['product_name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .take(10)
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  Future<List<Map<String, dynamic>>> checkFoodRecalls(String productName) async {
    try {
      final response = await http.get(
        Uri.parse('$_fdaRecallsUrl?search=product_description:"$productName"&limit=10'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to check food recalls: $e');
    }
  }

  Map<String, dynamic> getBreedNutritionRecommendations(String breed, double weight, int age, String activityLevel) {
    // Basic nutrition recommendations based on breed characteristics
    final recommendations = <String, dynamic>{};
    
    // Large breed considerations
    final largeBreedsKeywords = ['german shepherd', 'labrador', 'golden retriever', 'rottweiler', 'boxer'];
    final isLargeBreed = largeBreedsKeywords.any((keyword) => breed.toLowerCase().contains(keyword));
    
    if (isLargeBreed) {
      recommendations['specialConsiderations'] = [
        'Large breed formula recommended',
        'Controlled calcium and phosphorus levels',
        'Joint support supplements beneficial',
      ];
    }

    // Small breed considerations
    final smallBreedsKeywords = ['chihuahua', 'yorkshire', 'shih tzu', 'boston terrier'];
    final isSmallBreed = smallBreedsKeywords.any((keyword) => breed.toLowerCase().contains(keyword));
    
    if (isSmallBreed) {
      recommendations['specialConsiderations'] = [
        'Small breed formula with smaller kibble size',
        'Higher calorie density needed',
        'More frequent meals recommended',
      ];
    }

    // Activity-based recommendations
    switch (activityLevel.toLowerCase()) {
      case 'high':
        recommendations['proteinPercentage'] = '25-30%';
        recommendations['fatPercentage'] = '15-20%';
        break;
      case 'low':
        recommendations['proteinPercentage'] = '18-22%';
        recommendations['fatPercentage'] = '8-12%';
        break;
      default:
        recommendations['proteinPercentage'] = '20-25%';
        recommendations['fatPercentage'] = '10-15%';
    }

    // Age-based recommendations
    if (age < 12) { // Puppy
      recommendations['lifestage'] = 'Puppy formula recommended';
      recommendations['feedingFrequency'] = '3-4 times daily';
    } else if (age > 84) { // Senior (7+ years)
      recommendations['lifestage'] = 'Senior formula recommended';
      recommendations['feedingFrequency'] = '2 times daily';
      recommendations['specialConsiderations'] = [
        ...(recommendations['specialConsiderations'] ?? []),
        'Joint support supplements',
        'Easily digestible proteins',
      ];
    } else {
      recommendations['lifestage'] = 'Adult formula';
      recommendations['feedingFrequency'] = '2 times daily';
    }

    return recommendations;
  }
}
