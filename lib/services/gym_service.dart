import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/gym_location.dart';
import '../config/mapbox_config.dart';
import '../config/foursquare_config.dart';
import '../config/google_config.dart';
import 'package:dio/dio.dart';
import 'places_service.dart';

class GymService {
  static const String _baseUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places';
  static final Dio _dio = Dio();
  
  // Search gyms in a specific location (by location name/address)
  static Future<List<GymLocation>> searchGymsByLocation(String locationQuery, {Position? fallbackPosition}) async {
    try {
      print('🌍 Searching gyms in location: "$locationQuery"');
      
      // First, get coordinates for the location using Google Places Geocoding
      final coordinates = await _getLocationCoordinates(locationQuery);
      
      if (coordinates != null) {
        print('📍 Found coordinates for "$locationQuery": ${coordinates['lat']}, ${coordinates['lng']}');
        
        // Create a Position object for the new location
        final searchPosition = Position(
          latitude: coordinates['lat']!,
          longitude: coordinates['lng']!,
          timestamp: DateTime.now(),
          accuracy: 100.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        
        // Search for gyms in that location
        return await getNearbyGyms(searchPosition);
      } else if (fallbackPosition != null) {
        // If location not found, fall back to current position search
        print('⚠️ Location "$locationQuery" not found, falling back to current position search');
        return await searchGyms(locationQuery, fallbackPosition);
      } else {
        print('❌ Could not find location "$locationQuery" and no fallback position provided');
        return [];
      }
    } catch (e) {
      print('Error searching gyms by location: $e');
      return fallbackPosition != null ? await searchGyms(locationQuery, fallbackPosition) : [];
    }
  }
  
  // Helper method to get coordinates from location name/address
  static Future<Map<String, double>?> _getLocationCoordinates(String locationQuery) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(locationQuery)}'
        '&key=${GoogleConfig.apiKey}'
      );
      
      print('🔍 Geocoding request: $url');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return {
            'lat': location['lat'].toDouble(),
            'lng': location['lng'].toDouble(),
          };
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting location coordinates: $e');
      return null;
    }
  }
  
  // Helper function to calculate bounding box for radius in km
  static String _calculateBbox(double lat, double lng, double radiusKm) {
    // Approximate degrees per km (this is rough but works for most locations)
    final double latDegreesPerKm = 1 / 111.0;
    final double lngDegreesPerKm = 1 / (111.0 * math.cos(lat * math.pi / 180));
    
    final double latOffset = radiusKm * latDegreesPerKm;
    final double lngOffset = radiusKm * lngDegreesPerKm;
    
    final double minLng = lng - lngOffset;
    final double minLat = lat - latOffset;
    final double maxLng = lng + lngOffset;
    final double maxLat = lat + latOffset;
    
    return '$minLng,$minLat,$maxLng,$maxLat';
  }
  
  static Future<List<GymLocation>> getNearbyGyms(Position position) async {
    try {
      print('🎯 Starting gym search for location: ${position.latitude}, ${position.longitude}');
      
      // Get gyms from multiple sources
      final mapboxGyms = await _getMapboxGyms(position);
      print('🗺️ Mapbox returned ${mapboxGyms.length} gyms');
      
      final placesGyms = await PlacesService.searchGyms(
        position.latitude,
        position.longitude,
        radius: 35000, // 35km radius
      );
      print('📍 Google Places returned ${placesGyms.length} gyms');
      
      // Combine and deduplicate gyms
      final allGyms = [...mapboxGyms];
      
      for (final placesGym in placesGyms) {
        // Check if this gym is already in the list (within 100 meters)
        bool isDuplicate = false;
        for (final existingGym in allGyms) {
          final distance = Geolocator.distanceBetween(
            existingGym.latitude,
            existingGym.longitude,
            placesGym.latitude,
            placesGym.longitude,
          );
          if (distance < 100) {
            isDuplicate = true;
            break;
          }
        }
        
        if (!isDuplicate) {
          allGyms.add(placesGym);
        }
      }
      
      print('🔄 Combined ${allGyms.length} gyms after deduplication');
      
      // Calculate distances and filter gyms within 35km
      final gymsWithDistance = allGyms.map((gym) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          gym.latitude,
          gym.longitude,
        );
        return GymLocation(
          id: gym.id,
          name: gym.name,
          address: gym.address,
          latitude: gym.latitude,
          longitude: gym.longitude,
          distance: distance,
          rating: gym.rating,
          isOpen: gym.isOpen,
          phoneNumber: gym.phoneNumber,
          website: gym.website,
          photos: gym.photos,
          amenities: gym.amenities,
        );
      }).where((gym) {
        final isWithin35km = gym.distance <= 35000;
        if (!isWithin35km) {
          print('🚫 Gym "${gym.name}" is ${(gym.distance / 1000).toStringAsFixed(1)}km away (filtered out)');
        }
        return isWithin35km;
      }).toList(); // Filter gyms within 35km
      
      print('✅ Final result: ${gymsWithDistance.length} gyms within 35km');
      
      gymsWithDistance.sort((a, b) => a.distance.compareTo(b.distance));
      return gymsWithDistance;
    } catch (e) {
      print('Error fetching nearby gyms: $e');
      return [];
    }
  }

  static Future<List<GymLocation>> _getMapboxGyms(Position position) async {
    try {
      print('🗺️ Mapbox API Request for position: ${position.latitude}, ${position.longitude}');
      final response = await _dio.get(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/gym.json',
        queryParameters: {
          'access_token': MapboxConfig.accessToken,
          'proximity': '${position.longitude},${position.latitude}',
          'bbox': _calculateBbox(position.latitude, position.longitude, 35), // 35km radius
          'country': 'MY',
          'limit': 50,
          'types': 'poi',
        },
      );

      print('📡 Mapbox API Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final features = response.data['features'] as List;
        print('🏋️ Found ${features.length} gyms from Mapbox API');
        return features.map((feature) {
          final properties = feature['properties'] ?? {};
          final coordinates = feature['geometry']['coordinates'];
          
          return GymLocation(
            id: feature['id'] ?? '',
            name: feature['text'] ?? properties['name'] ?? 'Unknown Gym',
            address: feature['place_name'] ?? properties['address'] ?? 'No address available',
            latitude: coordinates[1]?.toDouble() ?? 0.0,
            longitude: coordinates[0]?.toDouble() ?? 0.0,
            distance: 0,
            rating: 0.0, // Geocoding API doesn't provide ratings
            isOpen: false, // Geocoding API doesn't provide opening hours
            phoneNumber: properties['tel'] ?? '',
            website: '',
            photos: [],
            amenities: [],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching gyms from Mapbox: $e');
      return [];
    }
  }

  static Future<List<GymLocation>> searchGyms(String query, Position position) async {
    try {
      print('🔍 Searching gyms with query: "$query"');
      
      if (query.trim().isEmpty) {
        // If empty query, return nearby gyms
        return await getNearbyGyms(position);
      }
      
      // Get gyms from all sources
      final placesGyms = await PlacesService.searchGyms(
        position.latitude,
        position.longitude,
        radius: 50000,
      );
      
      final foursquareGyms = await getNearbyGymsFromFoursquare(position);
      final mapboxGyms = await _getMapboxGyms(position);
      
      // Combine all gyms
      final allGyms = <GymLocation>[];
      allGyms.addAll(placesGyms);
      
      // Add Foursquare gyms (check for duplicates)
      for (final foursquareGym in foursquareGyms) {
        bool isDuplicate = false;
        for (final existingGym in allGyms) {
          final distance = Geolocator.distanceBetween(
            existingGym.latitude,
            existingGym.longitude,
            foursquareGym.latitude,
            foursquareGym.longitude,
          );
          if (distance < 100) {
            isDuplicate = true;
            break;
          }
        }
        if (!isDuplicate) {
          allGyms.add(foursquareGym);
        }
      }
      
      // Add Mapbox gyms (check for duplicates)
      for (final mapboxGym in mapboxGyms) {
        bool isDuplicate = false;
        for (final existingGym in allGyms) {
          final distance = Geolocator.distanceBetween(
            existingGym.latitude,
            existingGym.longitude,
            mapboxGym.latitude,
            mapboxGym.longitude,
          );
          if (distance < 100) {
            isDuplicate = true;
            break;
          }
        }
        if (!isDuplicate) {
          allGyms.add(mapboxGym);
        }
      }
      
      final queryLower = query.toLowerCase();
      
      // Enhanced search: by name, address, and location proximity
      List<GymLocation> filteredGyms = allGyms.where((gym) {
        final nameMatch = gym.name.toLowerCase().contains(queryLower);
        final addressMatch = gym.address.toLowerCase().contains(queryLower);
        
        // Check if query might be a location (basic check)
        final isLocationQuery = queryLower.contains('km') || 
                              queryLower.contains('near') || 
                              queryLower.contains('close') ||
                              RegExp(r'\d+').hasMatch(queryLower);
        
        if (isLocationQuery) {
          // For location queries, prioritize closer gyms
          return gym.distance <= 35000; // Within 35km
        }
        
        return nameMatch || addressMatch;
      }).map((gym) {
        // Calculate distance if not already calculated
        final distance = gym.distance > 0 ? gym.distance : Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          gym.latitude,
          gym.longitude,
        );
        
        return GymLocation(
          id: gym.id,
          name: gym.name,
          address: gym.address,
          latitude: gym.latitude,
          longitude: gym.longitude,
          distance: distance,
          rating: gym.rating,
          isOpen: gym.isOpen,
          phoneNumber: gym.phoneNumber,
          website: gym.website,
          photos: gym.photos,
          amenities: gym.amenities,
        );
      }).toList();
      
      // If no exact matches found, fall back to nearby gyms
      if (filteredGyms.isEmpty && allGyms.isNotEmpty) {
        print('⚠️ No exact matches for "$query", showing nearby gyms instead');
        filteredGyms = allGyms.where((gym) => gym.distance <= 35000).map((gym) {
          return GymLocation(
            id: gym.id,
            name: gym.name,
            address: gym.address,
            latitude: gym.latitude,
            longitude: gym.longitude,
            distance: gym.distance,
            rating: gym.rating,
            isOpen: gym.isOpen,
            phoneNumber: gym.phoneNumber,
            website: gym.website,
            photos: gym.photos,
            amenities: gym.amenities,
          );
        }).toList();
      }
      
      // Sort by relevance: exact name matches first, then by distance
      filteredGyms.sort((a, b) {
        final aExactMatch = a.name.toLowerCase() == queryLower;
        final bExactMatch = b.name.toLowerCase() == queryLower;
        final aPartialMatch = a.name.toLowerCase().contains(queryLower);
        final bPartialMatch = b.name.toLowerCase().contains(queryLower);
        
        if (aExactMatch && !bExactMatch) return -1;
        if (!aExactMatch && bExactMatch) return 1;
        if (aPartialMatch && !bPartialMatch) return -1;
        if (!aPartialMatch && bPartialMatch) return 1;
        
        // Then sort by distance
        return a.distance.compareTo(b.distance);
      });
      
      print('🎯 Search found ${filteredGyms.length} gyms matching "$query"');
      return filteredGyms.take(50).toList(); // Limit to 50 results
    } catch (e) {
      print('Error searching gyms: $e');
      return [];
    }
  }

  static Future<List<dynamic>> fetchFoursquarePlaces(double lat, double lng) async {
    final url = Uri.parse(
      '${FoursquareConfig.baseUrl}/places/search?ll=$lat,$lng&query=gym&radius=50000&country=MY',
    );

    print('🏢 Foursquare API Request: $url');
    final response = await http.get(
      url,
      headers: {
        'Authorization': FoursquareConfig.apiKey,
        'Accept': 'application/json',
      },
    );

    print('📡 Foursquare API Response Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      print('🏋️ Found ${results.length} gyms from Foursquare API');
      return results;
    } else {
      print('❌ Foursquare API Error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load places: ${response.statusCode}');
    }
  }

  static Future<List<GymLocation>> getNearbyGymsFromFoursquare(Position userPosition) async {
    try {
      final results = await fetchFoursquarePlaces(userPosition.latitude, userPosition.longitude);
      
      final gyms = <GymLocation>[];
      for (final place in results) {
        // Debug: Print the entire place structure
        print('🔍 Foursquare place: ${place.toString()}');
        
        final location = place['location'] as Map<String, dynamic>?;
        
        // Skip if location data is missing
        if (location == null) {
          print('⚠️ Skipping Foursquare gym "${place['name']}" - missing location data');
          continue;
        }
        
        // Debug: Print location structure
        print('📍 Location data: ${location.toString()}');
        
        // Safe casting with null checks
        final lat = location['lat'] as num?;
        final lng = location['lng'] as num?;
        
        if (lat == null || lng == null) {
          print('⚠️ Skipping Foursquare gym "${place['name']}" - invalid coordinates (lat: $lat, lng: $lng)');
          continue;
        }
        
        final latitude = lat.toDouble();
        final longitude = lng.toDouble();
        
        final distanceInMeters = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          latitude,
          longitude,
        );

        // Fetch photo for this gym
        final fsqId = place['fsq_id'] as String?;
        final photoUrl = fsqId != null ? await _getFoursquarePhotoUrl(fsqId) : null;
        
        final gymName = place['name'] as String? ?? 'Unknown Gym';
        gyms.add(GymLocation(
          id: fsqId ?? '',
          name: gymName,
          address: location['formatted_address'] as String? ?? '',
          latitude: latitude,
          longitude: longitude,
          distance: distanceInMeters,
          rating: (place['rating'] as num?)?.toDouble() ?? 0.0,
          isOpen: place['hours']?['is_open'] as bool? ?? false,
          phoneNumber: place['tel'] as String? ?? '',
          website: place['website'] as String? ?? '',
          photos: photoUrl != null ? [photoUrl] : [], // Add the fetched photo URL
          amenities: [],
        ));
        
        print('✅ Added Foursquare gym: $gymName (${(distanceInMeters / 1000).toStringAsFixed(1)}km away)');
      }

      gyms.sort((a, b) => a.distance.compareTo(b.distance));
      print('🏢 Successfully processed ${gyms.length} Foursquare gyms');
      return gyms;
    } catch (e) {
      print('Error fetching nearby gyms from Foursquare: $e');
      return [];
    }
  }

  static Future<String?> _getFoursquarePhotoUrl(String fsqId) async {
    try {
      final url = Uri.parse('${FoursquareConfig.baseUrl}/places/$fsqId/photos?limit=1');
      final response = await http.get(
        url,
        headers: {
          'Authorization': FoursquareConfig.apiKey,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final photo = data.first;
          return '${photo['prefix']}original${photo['suffix']}';
        }
      }
      return null;
    } catch (e) {
      print('Error fetching photo for Foursquare place $fsqId: $e');
      return null;
    }
  }
} 