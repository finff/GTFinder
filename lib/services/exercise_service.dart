import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for handling exercise-related API calls to the ExerciseDB API
class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Your RapidAPI key for ExerciseDB
  final String apiKey = '5af9e1f082msha4035be15f4871ep15950ajsn8620391a80dc';
  
  /// The RapidAPI host for ExerciseDB
  final String apiHost = 'exercisedb.p.rapidapi.com';

  /// Cache duration in hours
  static const int cacheDurationHours = 24;

  /// All available body parts from ExerciseDB
  static const List<String> allBodyParts = [
    'back',
    'cardio',
    'chest',
    'lower arms',
    'lower legs',
    'neck',
    'shoulders',
    'upper arms',
    'upper legs',
    'waist'
  ];

  /// Maps our exercise categories to ExerciseDB body parts
  String _mapCategoryToBodyPart(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.triceps:
        return 'upper arms';
      case ExerciseCategory.biceps:
        return 'upper arms';
      case ExerciseCategory.legs:
        return 'upper legs';
      case ExerciseCategory.traps:
        return 'back';
      case ExerciseCategory.chest:
        return 'chest';
      case ExerciseCategory.core:
        return 'waist';
      case ExerciseCategory.back:
        return 'back';
      case ExerciseCategory.arms:
        return 'upper arms';
      case ExerciseCategory.shoulder:
        return 'shoulders';
    }
  }

  /// Check if cached data is still valid
  Future<bool> _isCacheValid(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('${key}_timestamp');
      if (timestamp == null) return false;
      
      final cacheAge = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
      return cacheAge.inHours < cacheDurationHours;
    } catch (e) {
      print('Error checking cache validity: $e');
      return false;
    }
  }

  /// Save data to cache
  Future<void> _saveToCache(String key, List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
      print('✅ Cached data for: $key');
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  /// Load data from cache
  Future<List<dynamic>?> _loadFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(key);
      if (cachedData != null) {
        final data = jsonDecode(cachedData) as List<dynamic>;
        print('📦 Loaded cached data for: $key (${data.length} exercises)');
        return data;
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
    return null;
  }

  /// Fetches all available body parts from ExerciseDB API
  Future<List<String>> fetchAllBodyParts() async {
    try {
      final url = Uri.parse('https://exercisedb.p.rapidapi.com/exercises/bodyPartList');

      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': apiHost,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> bodyParts = jsonDecode(response.body);
        return bodyParts.cast<String>();
      } else {
        throw Exception('Failed to load body parts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching body parts: $e');
    }
  }

  /// Fetches exercises for a specific category from the ExerciseDB API
  Future<List<dynamic>> fetchExercisesByCategory(ExerciseCategory category) async {
    final bodyPart = _mapCategoryToBodyPart(category);
    return fetchExercisesByBodyPart(bodyPart);
  }

  /// Fetches exercises for a specific body part from the ExerciseDB API with caching
  /// 
  /// [bodyPart] - The body part to fetch exercises for (e.g., 'chest', 'back', 'legs')
  /// Returns a list of exercises for the specified body part
  /// Throws an exception if the API call fails
  Future<List<dynamic>> fetchExercisesByBodyPart(String bodyPart) async {
    final cacheKey = 'exercises_$bodyPart';
    
    // First, try to load from cache
    if (await _isCacheValid(cacheKey)) {
      final cachedData = await _loadFromCache(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }

    // If cache is invalid or empty, fetch from API
    try {
      final url = Uri.parse('https://exercisedb.p.rapidapi.com/exercises/bodyPart/$bodyPart');

      print('🔍 Fetching exercises for body part: $bodyPart');
      print('🌐 API URL: $url');

      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': apiHost,
        },
      );

      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> exercises = jsonDecode(response.body);
        print('✅ Successfully fetched ${exercises.length} exercises for $bodyPart');
        
        // Cache the data for future use
        await _saveToCache(cacheKey, exercises);
        
        // Debug: Print the first exercise structure to see what fields are available
        if (exercises.isNotEmpty) {
          print('🔍 First exercise structure:');
          final firstExercise = exercises.first;
          firstExercise.forEach((key, value) {
            print('   $key: $value');
          });
          
          // Check if instructions field exists
          if (firstExercise.containsKey('instructions')) {
            print('✅ Instructions field found: ${firstExercise['instructions']}');
          } else {
            print('❌ Instructions field not found. Available fields: ${firstExercise.keys.toList()}');
          }
        }
        
        return exercises;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        
        // If API fails, try to return cached data even if expired
        final cachedData = await _loadFromCache(cacheKey);
        if (cachedData != null) {
          print('⚠️ Using expired cached data due to API failure');
          return cachedData;
        }
        
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception during API call: $e');
      
      // If API call fails, try to return cached data even if expired
      final cachedData = await _loadFromCache(cacheKey);
      if (cachedData != null) {
        print('⚠️ Using expired cached data due to network error');
        return cachedData;
      }
      
      throw Exception('Error fetching exercises: $e');
    }
  }

  /// Fetches exercises for multiple body parts with caching
  Future<Map<String, List<dynamic>>> fetchExercisesForAllBodyParts() async {
    Map<String, List<dynamic>> exercisesByBodyPart = {};
    
    for (String bodyPart in allBodyParts) {
      try {
        final exercises = await fetchExercisesByBodyPart(bodyPart);
        exercisesByBodyPart[bodyPart] = exercises;
      } catch (e) {
        print('Error fetching exercises for $bodyPart: $e');
        exercisesByBodyPart[bodyPart] = [];
      }
    }
    
    return exercisesByBodyPart;
  }

  /// Clear all cached exercise data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (String bodyPart in allBodyParts) {
        final cacheKey = 'exercises_$bodyPart';
        await prefs.remove(cacheKey);
        await prefs.remove('${cacheKey}_timestamp');
      }
      print('🗑️ Cleared all exercise cache');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Preload all exercise data in background
  Future<void> preloadAllExercises() async {
    print('🚀 Preloading all exercise data...');
    try {
      await fetchExercisesForAllBodyParts();
      print('✅ All exercise data preloaded successfully');
    } catch (e) {
      print('❌ Error preloading exercise data: $e');
    }
  }

  // Get all exercises
  Stream<List<Exercise>> getAllExercises() {
    return _firestore
        .collection('exercises')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Exercise.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Get exercises by category
  Stream<List<Exercise>> getExercisesByCategory(ExerciseCategory category) {
    return _firestore
        .collection('exercises')
        .where('category', isEqualTo: category.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Exercise.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Add new exercise
  Future<void> addExercise(Exercise exercise) async {
    await _firestore.collection('exercises').add(exercise.toMap());
  }

  // Update exercise
  Future<void> updateExercise(Exercise exercise) async {
    await _firestore
        .collection('exercises')
        .doc(exercise.id)
        .update(exercise.toMap());
  }

  // Delete exercise
  Future<void> deleteExercise(String exerciseId) async {
    await _firestore.collection('exercises').doc(exerciseId).delete();
  }

  // Get exercises created by a specific trainer
  Stream<List<Exercise>> getExercisesByTrainer(String trainerId) {
    return _firestore
        .collection('exercises')
        .where('createdBy', isEqualTo: trainerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Exercise.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }
} 