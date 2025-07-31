import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'exercise_service.dart';

class CaloriesService {
  // Updated to use direct API Ninjas endpoint
  final String apiKey = 'qlIK/dLA9yofwW5XQQAm2Q==8LIXq2mfdUJVRHIO';
  final String baseUrl = 'https://api.api-ninjas.com/v1/caloriesburned';

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

  /// Fetches calories burned for a specific activity and duration
  /// 
  /// [activity] - The name of the activity/exercise
  /// [duration] - Duration in minutes
  /// Returns a list of calorie data including total calories burned
  Future<List<dynamic>> fetchCaloriesBurned(String activity, int duration) async {
    try {
      final url = Uri.parse(
        '$baseUrl?activity=$activity&duration=$duration',
      );

      print('🌐 Making API request to: ${url.toString()}');
      print('🔑 Using API Key: ${apiKey.substring(0, 10)}...');
      print('🏠 Using API Base URL: $baseUrl');

      final response = await http.get(
        url,
        headers: {
          'X-Api-Key': apiKey,
        },
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API Response: $data');
        return data;
      } else if (response.statusCode == 403) {
        print('❌ 403 Forbidden - Possible issues:');
        print('   - API key is invalid or expired');
        print('   - API key doesn\'t have access to this endpoint');
        print('   - Rate limit exceeded');
        print('   - Account suspended');
        print('📄 Response Body: ${response.body}');
        throw Exception('API Access Denied (403): Check API key and permissions');
      } else if (response.statusCode == 401) {
        print('❌ 401 Unauthorized - Invalid API key');
        throw Exception('Invalid API key (401)');
      } else if (response.statusCode == 429) {
        print('❌ 429 Too Many Requests - Rate limit exceeded');
        throw Exception('Rate limit exceeded (429)');
      } else {
        print('❌ Unexpected status code: ${response.statusCode}');
        print('📄 Response Body: ${response.body}');
        throw Exception('Failed to load calorie data: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception during API call: $e');
      throw Exception('Error fetching calorie data: $e');
    }
  }

  /// Enhanced exercise-to-activity mapping with more comprehensive exercise recognition
  String mapExerciseToActivity(String exerciseName, String bodyPart) {
    // Convert exercise name to lowercase for better matching
    final name = exerciseName.toLowerCase();
    
    // Comprehensive exercise name mapping
    if (name.contains('push-up') || name.contains('pushup') || name.contains('press-up')) {
      return 'push-ups';
    } else if (name.contains('sit-up') || name.contains('situp') || name.contains('crunch')) {
      return 'sit-ups';
    } else if (name.contains('pull-up') || name.contains('pullup') || name.contains('chin-up')) {
      return 'pull-ups';
    } else if (name.contains('squat')) {
      return 'squats';
    } else if (name.contains('plank')) {
      return 'plank';
    } else if (name.contains('jump') || name.contains('jumping')) {
      return 'jumping jacks';
    } else if (name.contains('run') || name.contains('jog') || name.contains('sprint')) {
      return 'running';
    } else if (name.contains('walk')) {
      return 'walking';
    } else if (name.contains('swim')) {
      return 'swimming';
    } else if (name.contains('bike') || name.contains('cycling') || name.contains('cycle')) {
      return 'cycling';
    } else if (name.contains('burpee')) {
      return 'burpees';
    } else if (name.contains('lunge')) {
      return 'lunges';
    } else if (name.contains('mountain climber')) {
      return 'mountain climbers';
    } else if (name.contains('dumbbell') || name.contains('weight') || name.contains('barbell')) {
      return 'weight training';
    } else if (name.contains('yoga')) {
      return 'yoga';
    } else if (name.contains('stretch') || name.contains('flexibility')) {
      return 'stretching';
    } else if (name.contains('cardio') || name.contains('aerobic') || name.contains('hiit')) {
      return 'aerobic exercise';
    } else if (name.contains('deadlift')) {
      return 'weight training';
    } else if (name.contains('bench press') || name.contains('chest press')) {
      return 'push-ups';
    } else if (name.contains('row') || name.contains('rowing')) {
      return 'pull-ups';
    } else if (name.contains('curl')) {
      return 'weight training';
    } else if (name.contains('extension') || name.contains('tricep')) {
      return 'weight training';
    } else if (name.contains('shoulder press') || name.contains('overhead press')) {
      return 'weight training';
    } else if (name.contains('leg press') || name.contains('calf raise')) {
      return 'squats';
    } else if (name.contains('bridge') || name.contains('glute')) {
      return 'squats';
    } else if (name.contains('ab') || name.contains('core') || name.contains('abs')) {
      return 'sit-ups';
    } else if (name.contains('burpee') || name.contains('thruster')) {
      return 'burpees';
    }
    
    // Body part-specific fallback mapping
    return mapBodyPartToActivity(bodyPart);
  }

  /// Enhanced body part to activity mapping with more accurate defaults
  String mapBodyPartToActivity(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'chest':
        return 'push-ups';
      case 'back':
        return 'pull-ups';
      case 'upper legs':
        return 'squats';
      case 'lower legs':
        return 'squats';
      case 'waist':
        return 'sit-ups';
      case 'shoulders':
        return 'push-ups';
      case 'upper arms':
        return 'weight training';
      case 'lower arms':
        return 'weight training';
      case 'cardio':
        return 'jumping jacks';
      case 'neck':
        return 'stretching';
      default:
        return 'calisthenics';
    }
  }

  /// Get body part-specific calorie multiplier for more accurate calculations
  double getBodyPartCalorieMultiplier(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'chest':
        return 1.0; // Standard intensity
      case 'back':
        return 1.1; // Slightly higher due to compound movements
      case 'upper legs':
        return 1.2; // Higher due to large muscle groups
      case 'lower legs':
        return 1.0; // Standard intensity
      case 'waist':
        return 0.9; // Slightly lower for core exercises
      case 'shoulders':
        return 1.0; // Standard intensity
      case 'upper arms':
        return 0.9; // Slightly lower for isolated movements
      case 'lower arms':
        return 0.8; // Lower for smaller muscle groups
      case 'cardio':
        return 1.3; // Higher for cardiovascular exercises
      case 'neck':
        return 0.7; // Lower for neck exercises
      default:
        return 1.0;
    }
  }

  /// Calculate calories with body part-specific adjustments
  int calculateCaloriesWithBodyPartAdjustment(
    String exerciseName, 
    String bodyPart, 
    int duration, 
    String intensity
  ) {
    // Get base activity
    final activity = mapExerciseToActivity(exerciseName, bodyPart);
    
    // Get body part multiplier
    final bodyPartMultiplier = getBodyPartCalorieMultiplier(bodyPart);
    
    // Get intensity multiplier
    final intensityMultiplier = getIntensityMultiplier(intensity);
    
    // Base calories per minute for the activity
    final baseCaloriesPerMinute = getBaseCaloriesPerMinute(activity);
    
    // Calculate total calories
    final totalCalories = (baseCaloriesPerMinute * duration * bodyPartMultiplier * intensityMultiplier).round();
    
    return totalCalories;
  }

  /// Get intensity multiplier
  double getIntensityMultiplier(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'low':
        return 0.8;
      case 'medium':
        return 1.0;
      case 'high':
        return 1.3;
      default:
        return 1.0;
    }
  }

  /// Enhanced base calories per minute for different activities
  double getBaseCaloriesPerMinute(String activity) {
    switch (activity.toLowerCase()) {
      // Bodyweight exercises
      case 'push-ups':
        return 6.0;
      case 'pull-ups':
        return 7.0;
      case 'squats':
        return 8.0;
      case 'sit-ups':
        return 4.0;
      case 'plank':
        return 3.0;
      case 'jumping jacks':
        return 10.0;
      case 'burpees':
        return 12.0;
      case 'lunges':
        return 7.0;
      case 'mountain climbers':
        return 9.0;
      case 'calisthenics':
        return 5.0;
      
      // Cardio exercises
      case 'running':
        return 12.0;
      case 'walking':
        return 5.0;
      case 'swimming':
        return 9.0;
      case 'cycling':
        return 8.0;
      case 'aerobic exercise':
        return 8.0;
      
      // Strength training
      case 'weight training':
        return 6.0;
      case 'bench press':
        return 5.0;
      case 'deadlift':
        return 8.0;
      case 'overhead press':
        return 6.0;
      case 'bicep curl':
        return 4.0;
      case 'tricep extension':
        return 4.0;
      case 'leg press':
        return 7.0;
      case 'calf raise':
        return 3.0;
      case 'shoulder press':
        return 6.0;
      case 'row':
        return 6.0;
      case 'lat pulldown':
        return 6.0;
      case 'dumbbell press':
        return 6.0;
      case 'barbell curl':
        return 4.0;
      case 'hammer curl':
        return 4.0;
      case 'tricep dip':
        return 5.0;
      case 'leg curl':
        return 5.0;
      case 'leg extension':
        return 5.0;
      case 'hip thrust':
        return 6.0;
      case 'glute bridge':
        return 4.0;
      
      // Core exercises
      case 'ab crunch':
        return 4.0;
      case 'russian twist':
        return 5.0;
      case 'mountain climber':
        return 9.0;
      case 'thruster':
        return 8.0;
      
      // Flexibility and recovery
      case 'yoga':
        return 3.0;
      case 'stretching':
        return 2.0;
      
      default:
        return 5.0; // Default moderate intensity
    }
  }

  /// Enhanced calorie calculation with smart fallback priority
  Future<int> calculateCaloriesBurned(
    String exerciseName, 
    String bodyPart, 
    int duration, 
    String intensity
  ) async {
    // Check if API subscription is available
    bool apiAvailable = false;
    
    try {
      print('🔥 Attempting API calorie calculation for: $exerciseName ($bodyPart)');
      
      // Map exercise to API activity
      final activity = mapExerciseToActivity(exerciseName, bodyPart);
      print('📊 Mapped to API activity: $activity');
      
      // Quick API test to check subscription
      final caloriesData = await fetchCaloriesBurned(activity, duration);
      
      if (caloriesData.isNotEmpty) {
        apiAvailable = true;
        final baseCalories = caloriesData[0]['total_calories'] as int;
        final intensityMultiplier = getIntensityMultiplier(intensity);
        final bodyPartMultiplier = getBodyPartCalorieMultiplier(bodyPart);
        
        final finalCalories = (baseCalories * intensityMultiplier * bodyPartMultiplier).round();
        
        print('✅ API calculation successful: $baseCalories base × $intensityMultiplier intensity × $bodyPartMultiplier body part = $finalCalories calories');
        
        return finalCalories;
      }
    } catch (e) {
      print('❌ API not available: $e');
      print('🔄 Using enhanced fallback calculation system');
    }
    
    // Enhanced fallback calculation with more accurate formulas
    final fallbackCalories = calculateCaloriesWithBodyPartAdjustment(exerciseName, bodyPart, duration, intensity);
    print('📈 Enhanced fallback calculation: $fallbackCalories calories');
    print('💡 Tip: Subscribe to Calories Burned API for even more accurate calculations');
    
    return fallbackCalories;
  }

  /// Direct API calorie calculation without fallback
  Future<int?> calculateCaloriesBurnedDirectAPI(
    String exerciseName, 
    String bodyPart, 
    int duration
  ) async {
    try {
      final activity = mapExerciseToActivity(exerciseName, bodyPart);
      final caloriesData = await fetchCaloriesBurned(activity, duration);
      
      if (caloriesData.isNotEmpty) {
        return caloriesData[0]['total_calories'] as int;
      }
    } catch (e) {
      print('API direct calculation failed: $e');
    }
    
    return null; // Return null if API fails
  }

  /// Get available activities from the API (for debugging/testing)
  Future<List<String>> getAvailableActivities() async {
    // This would require the API to support listing available activities
    // For now, return common activities that the API supports
    return [
      'push-ups',
      'pull-ups',
      'squats',
      'sit-ups',
      'plank',
      'jumping jacks',
      'running',
      'walking',
      'swimming',
      'cycling',
      'burpees',
      'lunges',
      'mountain climbers',
      'weight training',
      'yoga',
      'stretching',
      'aerobic exercise',
      'calisthenics'
    ];
  }

  /// Test API connection and get sample calorie data
  Future<Map<String, dynamic>?> testAPIConnection() async {
    try {
      print('🧪 Testing API connection...');
      
      // Test with a simple activity
      final testActivity = 'push-ups';
      final testDuration = 10;
      
      final caloriesData = await fetchCaloriesBurned(testActivity, testDuration);
      
      if (caloriesData.isNotEmpty) {
        print('✅ API connection successful!');
        print('📊 Sample data for $testActivity for $testDuration minutes:');
        print('   Calories: ${caloriesData[0]['total_calories']}');
        print('   Activity: ${caloriesData[0]['activity']}');
        print('   Duration: ${caloriesData[0]['duration_minutes']} minutes');
        
        return {
          'success': true,
          'data': caloriesData[0],
          'message': 'API connection successful'
        };
      } else {
        print('⚠️ API returned empty data');
        return {
          'success': false,
          'message': 'API returned empty data'
        };
      }
    } catch (e) {
      print('❌ API connection failed: $e');
      return {
        'success': false,
        'message': 'API connection failed: $e'
      };
    }
  }

  /// Get detailed calorie calculation breakdown
  Future<Map<String, dynamic>> getCalorieCalculationBreakdown(
    String exerciseName, 
    String bodyPart, 
    int duration, 
    String intensity
  ) async {
    final activity = mapExerciseToActivity(exerciseName, bodyPart);
    final bodyPartMultiplier = getBodyPartCalorieMultiplier(bodyPart);
    final intensityMultiplier = getIntensityMultiplier(intensity);
    
    Map<String, dynamic> breakdown = {
      'exercise_name': exerciseName,
      'body_part': bodyPart,
      'mapped_activity': activity,
      'duration_minutes': duration,
      'intensity': intensity,
      'body_part_multiplier': bodyPartMultiplier,
      'intensity_multiplier': intensityMultiplier,
      'calculation_method': 'fallback',
      'api_success': false,
      'final_calories': 0,
    };
    
    try {
      // Try API first
      final caloriesData = await fetchCaloriesBurned(activity, duration);
      
      if (caloriesData.isNotEmpty) {
        final baseCalories = caloriesData[0]['total_calories'] as int;
        final finalCalories = (baseCalories * intensityMultiplier * bodyPartMultiplier).round();
        
        breakdown['calculation_method'] = 'api';
        breakdown['api_success'] = true;
        breakdown['api_base_calories'] = baseCalories;
        breakdown['final_calories'] = finalCalories;
        breakdown['api_data'] = caloriesData[0];
      } else {
        // Use fallback calculation
        final fallbackCalories = calculateCaloriesWithBodyPartAdjustment(
          exerciseName, bodyPart, duration, intensity
        );
        breakdown['final_calories'] = fallbackCalories;
        breakdown['fallback_base_calories_per_minute'] = getBaseCaloriesPerMinute(activity);
      }
    } catch (e) {
      // Use fallback calculation
      final fallbackCalories = calculateCaloriesWithBodyPartAdjustment(
        exerciseName, bodyPart, duration, intensity
      );
      breakdown['final_calories'] = fallbackCalories;
      breakdown['fallback_base_calories_per_minute'] = getBaseCaloriesPerMinute(activity);
      breakdown['api_error'] = e.toString();
    }
    
    return breakdown;
  }

  /// Test all body parts to ensure they're using the API
  Future<Map<String, dynamic>> testAllBodyPartsAPIUsage() async {
    Map<String, dynamic> results = {
      'total_tested': 0,
      'api_success': 0,
      'fallback_used': 0,
      'body_parts': {},
      'summary': ''
    };

    // Test all available body parts
    for (String bodyPart in allBodyParts) {
      print('\n🧪 Testing body part: $bodyPart');
      
      // Test with a sample exercise for each body part
      String sampleExercise = _getSampleExerciseForBodyPart(bodyPart);
      int duration = 15; // 15 minutes test
      String intensity = 'medium';
      
      results['total_tested']++;
      results['body_parts'][bodyPart] = {
        'sample_exercise': sampleExercise,
        'mapped_activity': '',
        'api_success': false,
        'calories': 0,
        'calculation_method': 'unknown'
      };
      
      try {
        // Test the full calculation process
        final breakdown = await getCalorieCalculationBreakdown(
          sampleExercise, bodyPart, duration, intensity
        );
        
        results['body_parts'][bodyPart]['mapped_activity'] = breakdown['mapped_activity'];
        results['body_parts'][bodyPart]['calories'] = breakdown['final_calories'];
        results['body_parts'][bodyPart]['calculation_method'] = breakdown['calculation_method'];
        results['body_parts'][bodyPart]['api_success'] = breakdown['api_success'];
        
        if (breakdown['api_success']) {
          results['api_success']++;
          print('✅ $bodyPart: API SUCCESS - ${breakdown['final_calories']} calories');
        } else {
          results['fallback_used']++;
          print('⚠️ $bodyPart: FALLBACK USED - ${breakdown['final_calories']} calories');
        }
        
      } catch (e) {
        results['fallback_used']++;
        results['body_parts'][bodyPart]['calculation_method'] = 'error';
        print('❌ $bodyPart: ERROR - $e');
      }
    }
    
    // Generate summary
    double apiSuccessRate = (results['api_success'] / results['total_tested']) * 100;
    results['summary'] = '''
API Usage Summary:
- Total body parts tested: ${results['total_tested']}
- API successful: ${results['api_success']}
- Fallback used: ${results['fallback_used']}
- API success rate: ${apiSuccessRate.toStringAsFixed(1)}%
''';
    
    print('\n📊 ${results['summary']}');
    return results;
  }

  /// Get a sample exercise for each body part
  String _getSampleExerciseForBodyPart(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'chest':
        return 'Push-ups';
      case 'back':
        return 'Pull-ups';
      case 'upper legs':
        return 'Squats';
      case 'lower legs':
        return 'Calf Raises';
      case 'waist':
        return 'Sit-ups';
      case 'shoulders':
        return 'Shoulder Press';
      case 'upper arms':
        return 'Bicep Curls';
      case 'lower arms':
        return 'Wrist Curls';
      case 'cardio':
        return 'Jumping Jacks';
      case 'neck':
        return 'Neck Stretches';
      default:
        return 'General Exercise';
    }
  }

  /// Verify API activity mapping for all body parts
  Map<String, String> verifyBodyPartActivityMapping() {
    Map<String, String> mapping = {};
    
    for (String bodyPart in allBodyParts) {
      String sampleExercise = _getSampleExerciseForBodyPart(bodyPart);
      String mappedActivity = mapExerciseToActivity(sampleExercise, bodyPart);
      mapping[bodyPart] = mappedActivity;
      
      print('📍 $bodyPart: "$sampleExercise" → "$mappedActivity"');
    }
    
    return mapping;
  }

  /// Comprehensive API connection test to diagnose issues
  Future<Map<String, dynamic>> diagnoseAPI() async {
    Map<String, dynamic> diagnosis = {
      'api_key_valid': false,
      'api_host_valid': false,
      'endpoint_accessible': false,
      'rate_limit_status': 'unknown',
      'error_details': '',
      'recommendations': []
    };

    try {
              print('\n🔍 Starting API Diagnosis...');
        print('🔑 API Key: ${apiKey.substring(0, 10)}...');
        print('🏠 API Base URL: $baseUrl');
      
      // Test 1: Basic connectivity
      final testUrl = Uri.parse('$baseUrl?activity=push-ups&duration=10');
      
      print('\n📡 Testing basic connectivity...');
      final response = await http.get(
        testUrl,
        headers: {
          'X-Api-Key': apiKey,
        },
      );

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Headers: ${response.headers}');
      print('📄 Response Body: ${response.body}');

      // Analyze response
      if (response.statusCode == 200) {
        diagnosis['api_key_valid'] = true;
        diagnosis['api_host_valid'] = true;
        diagnosis['endpoint_accessible'] = true;
        diagnosis['rate_limit_status'] = 'ok';
        diagnosis['recommendations'].add('API is working correctly');
      } else if (response.statusCode == 403) {
        diagnosis['error_details'] = '403 Forbidden - Access denied';
        diagnosis['recommendations'].addAll([
          'Check if API key is valid and not expired',
          'Verify API key has access to this endpoint',
          'Check if account is suspended',
          'Contact RapidAPI support if issue persists'
        ]);
      } else if (response.statusCode == 401) {
        diagnosis['error_details'] = '401 Unauthorized - Invalid API key';
        diagnosis['recommendations'].add('Get a new API key from RapidAPI');
      } else if (response.statusCode == 429) {
        diagnosis['rate_limit_status'] = 'exceeded';
        diagnosis['error_details'] = '429 Too Many Requests - Rate limit exceeded';
        diagnosis['recommendations'].add('Wait before making more requests or upgrade plan');
      } else {
        diagnosis['error_details'] = 'Unexpected status code: ${response.statusCode}';
        diagnosis['recommendations'].add('Check API documentation for status code meaning');
      }

    } catch (e) {
      diagnosis['error_details'] = 'Exception: $e';
      diagnosis['recommendations'].add('Check internet connection and API endpoint availability');
    }

    // Print diagnosis summary
    print('\n📋 API Diagnosis Summary:');
    print('   API Key Valid: ${diagnosis['api_key_valid']}');
    print('   API Host Valid: ${diagnosis['api_host_valid']}');
    print('   Endpoint Accessible: ${diagnosis['endpoint_accessible']}');
    print('   Rate Limit Status: ${diagnosis['rate_limit_status']}');
    print('   Error Details: ${diagnosis['error_details']}');
    print('   Recommendations:');
    for (String rec in diagnosis['recommendations']) {
      print('     - $rec');
    }

    return diagnosis;
  }
} 