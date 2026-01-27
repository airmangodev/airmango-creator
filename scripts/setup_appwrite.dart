// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

const String endpoint = 'https://appwrite.airmango.com/v1';
const String projectId = '6973940a000d2c9835c5';
const String apiKey = 'standard_098c7b15ea1a5fd1ee8f6685db4ee8af0bc52c723eb2ab6679970652a5eddd8fbcead93ec10c78da6685d617959a4b4cc5389e8fa41ac7ce6a781b1a8455316c293d6938e788026f7c1ee2024b6b4a664b134f1b7d53028d13f15a01476de88575ce40b8ad1771f1709ee8d1fdb5a5e559313799ca57d988baa090789459fde4';
const String databaseId = 'airmango_main';

Future<void> main() async {
  print('Starting Appwrite Backend Setup...');

  // 1. Create Database
  await createDatabase();

  // 2. Create Collections
  await createCollection('trips', 'Trips');
  await createCollection('days', 'Days');
  await createCollection('stops', 'Stops');
  await createCollection('media', 'Media');

  // 3. Add Attributes to Trips
  await addStringAttribute('trips', 'name', 255, true);
  await addStringAttribute('trips', 'start_date', 64, true);
  await addStringAttribute('trips', 'end_date', 64, true);
  await addIntegerAttribute('trips', 'travelers', true);
  await addStringAttribute('trips', 'status', 32, true);
  await addStringAttribute('trips', 'hero_image_path', 500, false);
  await addStringAttribute('trips', 'user_id', 64, true);
  await addBooleanAttribute('trips', 'is_synced', true);
  await addStringAttribute('trips', 'updated_at', 64, true);
  await addStringAttribute('trips', 'created_at', 64, true);

  // 4. Add Attributes to Days
  await addStringAttribute('days', 'trip_id', 64, true);
  await addStringAttribute('days', 'date', 64, true);
  await addIntegerAttribute('days', 'day_number', true);
  await addStringAttribute('days', 'user_id', 64, true);
  await addBooleanAttribute('days', 'is_synced', true);
  await addStringAttribute('days', 'updated_at', 64, true);

  // 5. Add Attributes to Stops
  await addStringAttribute('stops', 'trip_id', 64, true);
  await addStringAttribute('stops', 'day_id', 64, false);
  await addStringAttribute('stops', 'name', 255, true);
  await addStringAttribute('stops', 'type', 64, true);
  await addFloatAttribute('stops', 'lat', false);
  await addFloatAttribute('stops', 'lng', false);
  await addStringAttribute('stops', 'visit_time', 64, true);
  await addStringAttribute('stops', 'notes', 1000, false);
  await addStringAttribute('stops', 'place_id', 255, false);
  await addStringAttribute('stops', 'user_id', 64, true);
  await addBooleanAttribute('stops', 'is_synced', true);
  await addStringAttribute('stops', 'updated_at', 64, true);

  // 6. Add Attributes to Media
  await addStringAttribute('media', 'trip_id', 64, false);
  await addStringAttribute('media', 'stop_id', 64, false);
  await addStringAttribute('media', 'type', 32, true);
  await addStringAttribute('media', 'file_path', 500, true);
  await addFloatAttribute('media', 'lat', false);
  await addFloatAttribute('media', 'lng', false);
  await addStringAttribute('media', 'captured_at', 64, true);
  await addStringAttribute('media', 'note', 1000, false);
  await addIntegerAttribute('media', 'duration_seconds', false);
  await addStringAttribute('media', 'remote_url', 1000, false);
  await addStringAttribute('media', 'user_id', 64, true);
  await addBooleanAttribute('media', 'is_synced', true);
  await addStringAttribute('media', 'updated_at', 64, true);

  print('Appwrite Backend Setup Completed!');
}

Future<void> createDatabase() async {
  print('Creating database: $databaseId...');
  final response = await http.post(
    Uri.parse('$endpoint/databases'),
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    },
    body: jsonEncode({
      'databaseId': databaseId,
      'name': 'Airmango Main Database',
    }),
  );
  if (response.statusCode == 201) {
    print('Database created successfully.');
  } else {
    print('Database creation skipped or failed: ${response.body}');
  }
}

Future<void> createCollection(String id, String name) async {
  print('Creating collection: $name ($id)...');
  final response = await http.post(
    Uri.parse('$endpoint/databases/$databaseId/collections'),
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    },
    body: jsonEncode({
      'collectionId': id,
      'name': name,
      'permissions': [
        'read("users")',
        'create("users")',
        'update("users")',
        'delete("users")',
      ],
      'documentSecurity': true,
    }),
  );
  if (response.statusCode == 201) {
    print('Collection $id created successfully.');
  } else {
    print('Collection $id creation skipped or failed: ${response.body}');
  }
}

Future<void> addStringAttribute(String collectionId, String key, int size, bool required) async {
  print('Adding string attribute $key to $collectionId...');
  await http.post(
    Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/attributes/string'),
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    },
    body: jsonEncode({
      'key': key,
      'size': size,
      'required': required,
    }),
  );
}

Future<void> addIntegerAttribute(String collectionId, String key, bool required) async {
  print('Adding integer attribute $key to $collectionId...');
  await http.post(
    Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/attributes/integer'),
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    },
    body: jsonEncode({
      'key': key,
      'required': required,
    }),
  );
}

Future<void> addBooleanAttribute(String collectionId, String key, bool required) async {
  print('Adding boolean attribute $key to $collectionId...');
  await http.post(
    Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/attributes/boolean'),
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    },
    body: jsonEncode({
      'key': key,
      'required': required,
    }),
  );
}

Future<void> addFloatAttribute(String collectionId, String key, bool required) async {
  print('Adding float attribute $key to $collectionId...');
  await http.post(
    Uri.parse('$endpoint/databases/$databaseId/collections/$collectionId/attributes/float'),
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    },
    body: jsonEncode({
      'key': key,
      'required': required,
    }),
  );
}
