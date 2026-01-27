import 'package:appwrite/appwrite.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../remote/appwrite_service.dart';
import '../models/trip.dart';
import '../models/day.dart';
import '../models/stop.dart';
import '../models/media.dart';
import '../../core/config/app_config.dart';

class TripRepository {
  final DatabaseHelper _dbHelper;
  final AppwriteService? _appwriteService;

  TripRepository({
    required DatabaseHelper dbHelper,
    AppwriteService? appwriteService,
  })  : _dbHelper = dbHelper,
        _appwriteService = appwriteService;

  bool _validateTrip(Trip trip) {
    if (trip.name.isEmpty) return false;
    if (trip.id.isEmpty) return false;
    return true;
  }

  // --- Cloud Operations (Cloud Only) ---

  Future<String> createTrip(Trip trip) async {
    if (!_validateTrip(trip)) throw Exception("Invalid trip data");
    if (trip.userId == null) throw Exception("Trip must have a valid user ID");
    
    debugPrint('TripRepository: Creating trip ${trip.id} for user ${trip.userId}');
    
    // Cloud Only: Create directly in Appwrite
    if (_appwriteService != null) {
      try {
        final data = trip.toMap();
        data.remove('id'); // Appwrite uses $id, not 'id' attribute
        data['is_synced'] = true; // Satisfy legacy DB requirement
        debugPrint('TripRepository: Upserting to Appwrite with data: $data');
        await _appwriteService.upsertDocument(
          collectionId: 'trips',
          documentId: trip.id,
          data: data,
        );
        debugPrint('TripRepository: Trip ${trip.id} created successfully in cloud');
      } catch (e) {
        debugPrint('TripRepository: ERROR creating trip: $e');
        rethrow;
      }
    } else {
      debugPrint('TripRepository: WARNING - AppwriteService is null, trip not saved to cloud!');
    }
    return trip.id;
  }

  Future<List<Trip>> getAllTrips(String userId) async {
    debugPrint('TripRepository: Fetching all trips for user $userId');
    if (_appwriteService == null) {
      debugPrint('TripRepository: WARNING - AppwriteService is null!');
      return [];
    }
    
    // Cloud Only: Fetch from Appwrite
    try {
      final remoteTrips = await _appwriteService.listDocuments(
        collectionId: 'trips',
        queries: [
          Query.equal('user_id', userId),
          Query.orderDesc('created_at'),
        ],
      );
      
      debugPrint('TripRepository: Found ${remoteTrips.documents.length} trips in cloud');
      
      return remoteTrips.documents.map((doc) {
        final data = doc.data;
        data['id'] = doc.$id;
        debugPrint('TripRepository: Loaded trip: ${data['name']} (${doc.$id})');
        // Appwrite returns native types, ensuring map is correct
        return Trip.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('TripRepository: ERROR fetching trips: $e');
      return [];
    }
  }

  Future<Trip?> getTripById(String id, String userId) async {
     if (_appwriteService == null) return null;

     try {
       // Since we don't have a direct getDocument in generic service yet (or assuming we do), 
       // lets use list with ID filter or just fetch all and find (optimizable later).
       // Or better: assuming we can just list with ID query if we don't have getDocument exposed cleanly
       final remoteTrips = await _appwriteService.listDocuments(
        collectionId: 'trips',
        queries: [Query.equal('\$id', id)],
      );
      
      if (remoteTrips.documents.isNotEmpty) {
        final data = remoteTrips.documents.first.data;
        data['id'] = remoteTrips.documents.first.$id;
        return Trip.fromMap(data);
      }
      return null;
     } catch (e) {
       return null;
     }
  }

  Future<void> updateTrip(Trip trip) async {
    // Cloud Only: Update Appwrite
    if (_appwriteService != null) {
       final data = trip.toMap();
       data.remove('id'); // Appwrite uses $id, not 'id' attribute
       data['is_synced'] = true; // Satisfy legacy DB requirement
       await _appwriteService.upsertDocument(
        collectionId: 'trips',
        documentId: trip.id,
        data: data,
      );
    }
  }

  Future<void> deleteTrip(String id, String userId) async {
    // Cloud Only
     if (_appwriteService != null) {
       await _deleteTripFromRemote(id);
     }
  }

  // --- Day Operations ---

  Future<void> createDays(List<TripDay> days) async {
    if (_appwriteService == null) return;
    
    // Cloud Only
    for (var day in days) {
      final data = day.toMap();
      data.remove('id'); // Appwrite uses $id, not 'id' attribute
      data['is_synced'] = true; // Satisfy legacy DB requirement
      await _appwriteService.upsertDocument(
        collectionId: 'days',
        documentId: day.id,
        data: data,
      );
    }
  }

  Future<void> updateDay(TripDay day) async {
     if (_appwriteService == null) return;
     final data = day.toMap();
     data.remove('id'); // Appwrite uses $id, not 'id' attribute
     data['is_synced'] = true; // Satisfy legacy DB requirement
     await _appwriteService.upsertDocument(
        collectionId: 'days',
        documentId: day.id,
        data: data,
      );
  }

  Future<List<TripDay>> getDaysForTrip(String tripId, String userId) async {
     if (_appwriteService == null) return [];
     
     final remoteDays = await _appwriteService.listDocuments(
        collectionId: 'days',
        queries: [
          Query.equal('trip_id', tripId),
          Query.equal('user_id', userId),
          Query.orderAsc('day_number'),
        ],
      );

      return remoteDays.documents.map((doc) {
        final data = doc.data;
        data['id'] = doc.$id;
        return TripDay.fromMap(data);
      }).toList();
  }
  
  // --- Deprecated / No-Op methods for backward compatibility if needed ---
  Future<void> syncPending(String userId) async {
    // No-op: No local pending state
  }
  
  Future<void> migrateAnonymousData(String userId) async {
    // No-op: If using cloud only, anonymous data is harder to migrate unless we tracked it in cloud anonymously
  }
  
  Future<void> fetchRemoteData(String userId) async {
    // No-op: Data is always fetched live
  }

  // --- Internal Helpers ---

  Future<void> _deleteTripFromRemote(String id) async {
    if (_appwriteService == null) return;
    try {
      await _appwriteService.databases.deleteDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'trips',
        documentId: id,
      );
    } catch (_) {}
  }

  // --- Webhook Submission ---
  
  Future<void> submitTripToWebhook(String tripId, String userId) async {
    if (_appwriteService == null) return;
    
    try {
      debugPrint('Submission: Gathering data for trip $tripId...');
      
      // 1. Fetch Trip Details
      final trip = await getTripById(tripId, userId);
      if (trip == null) throw Exception("Trip not found");
      
      // 2. Fetch Days
      final daysList = await _appwriteService!.listDocuments(
        collectionId: 'days',
        queries: [
           Query.equal('trip_id', tripId),
           Query.orderAsc('day_number'),
        ],
      );
      final days = daysList.documents.map((d) => d.data).toList();
      
      // 3. Fetch Stops
      final stopsList = await _appwriteService!.listDocuments(
        collectionId: 'stops',
        queries: [Query.equal('trip_id', tripId)],
      );
      final stops = stopsList.documents.map((d) => d.data).toList();
      
      // 4. Fetch Media
      // Media might be linked to Trip OR Stops. We want all media associated with this trip context.
      // Usually media query by trip_id. If stopped-based media doesn't have trip_id, we need complex query.
      // Assuming media has trip_id populated even if stop_id is present (denormalized) OR we query by trip_id.
      // Based on schema, media has trip_id.
      final mediaList = await _appwriteService!.listDocuments(
        collectionId: 'media',
        queries: [Query.equal('trip_id', tripId)],
      );
      final media = mediaList.documents.map((d) => d.data).toList();
      
      // 5. Construct Payload
      final payload = {
        'trip': trip.toMap(),
        'days': days,
        'stops': stops,
        'media': media,
        'submitted_at': DateTime.now().toIso8601String(),
        'submitter_id': userId,
      };
      
      debugPrint('Submission: Sending data to webhook...');
      
      final response = await http.post(
        Uri.parse('https://n8n.restaurantreykjavik.com/webhook/airmango-creator-trip-submission'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Submission: Success! Webhook responded with ${response.statusCode}');
      } else {
        debugPrint('Submission: Webhook failed with ${response.statusCode}: ${response.body}');
        throw Exception('Webhook submission failed: ${response.statusCode}');
      }
      
    } catch (e) {
      debugPrint('Submission: Error: $e');
      rethrow;
    }
  }
}

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(
    dbHelper: DatabaseHelper.instance,
    appwriteService: ref.watch(appwriteServiceProvider),
  );
});
