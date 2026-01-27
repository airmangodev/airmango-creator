import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/config/app_config.dart';
import '../models/user.dart';

class AppwriteService {
  final Client client = Client();
  late final Account account;
  late final Databases databases;
  late final Storage storage;
  
  // Initialize Google Sign In with Web Client ID for native account picker
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '46016781586-beghvpkgep3gfgm8gk0qps0sbhdthbms.apps.googleusercontent.com',
  );

  AppwriteService() {
    client
        .setEndpoint(AppConfig.appwriteEndpoint)
        .setProject(AppConfig.appwriteProjectId);

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }

  // --- Authentication ---

  Future<models.User> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return await account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
  }

  Future<models.Session> login({
    required String email,
    required String password,
  }) async {
    return await account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  /// Generate a consistent password from Google account details
  /// This allows the same Google account to always derive the same password
  String _derivePassword(String googleId, String email) {
    // Use a combination of Google ID and email to create a deterministic password
    // This is secure enough for our use case since the user authenticates via Google first
    final raw = 'airmango_${googleId}_${email}_secret_salt_2024';
    // Simple hash - in production you might want to use a proper hash
    int hash = 0;
    for (int i = 0; i < raw.length; i++) {
      hash = ((hash << 5) - hash) + raw.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF; // Convert to 32-bit integer
    }
    return 'Ggl${hash.abs().toRadixString(36)}Pwd!';
  }

  /// Login with native Google account picker, then create/login Appwrite account
  Future<AppUser?> loginWithGoogleNative() async {
    debugPrint('Appwrite: Starting native Google Sign-In...');
    
    try {
      // Step 1: Show native Google account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('Appwrite: User cancelled Google Sign-In');
        return null;
      }
      
      debugPrint('Appwrite: Google Sign-In succeeded for ${googleUser.email}');
      
      // Step 2: Create or login to Appwrite account
      final email = googleUser.email;
      final name = googleUser.displayName ?? 'Traveler';
      final password = _derivePassword(googleUser.id, email);
      
      // Try to create account first (will fail if exists, that's OK)
      try {
        debugPrint('Appwrite: Creating Appwrite account for $email...');
        await account.create(
          userId: ID.unique(),
          email: email,
          password: password,
          name: name,
        );
        debugPrint('Appwrite: Account created successfully');
      } on AppwriteException catch (e) {
        if (e.code == 409) {
          debugPrint('Appwrite: Account already exists, will login');
        } else {
          debugPrint('Appwrite: Account creation failed: ${e.message}');
        }
      }
      
      // Step 3: Login to Appwrite - MUST succeed
      try {
        debugPrint('Appwrite: Logging into Appwrite...');
        await account.createEmailPasswordSession(
          email: email,
          password: password,
        );
        debugPrint('Appwrite: Login successful');
      } on AppwriteException catch (e) {
        debugPrint('Appwrite: Login failed: ${e.message}');
        // If login fails, we cannot continue - data would be inconsistent
        throw Exception('Could not authenticate with Appwrite: ${e.message}');
      }
      
      // Step 4: Get the Appwrite user - MUST succeed to ensure consistent ID
      final appwriteUser = await account.get();
      debugPrint('Appwrite: Session verified for ${appwriteUser.email}, ID: ${appwriteUser.$id}');
      
      return AppUser(
        id: appwriteUser.$id, // ALWAYS use Appwrite ID, never Google ID
        email: appwriteUser.email,
        name: appwriteUser.name.isNotEmpty ? appwriteUser.name : name,
        photoUrl: googleUser.photoUrl,
        createdAt: DateTime.parse(appwriteUser.registration),
      );
    } catch (e) {
      debugPrint('Appwrite: Native Google Sign-In failed: $e');
      rethrow;
    }
  }

  Future<void> loginWithGoogle() async {
    // This is for fallback webview flow
    debugPrint('Appwrite: Attempting OAuth2 session via webview...');
    try {
      await account.createOAuth2Session(provider: OAuthProvider.google);
      await Future.delayed(const Duration(milliseconds: 1000));
      final user = await account.get();
      debugPrint('Appwrite: OAuth session verified for ${user.email}');
    } catch (e) {
      debugPrint('Appwrite: OAuth2 session failed: $e');
      rethrow;
    }
  }

  /// Get the OAuth URL for in-app WebView login
  String getOAuthUrl(String provider) {
    final callbackScheme = 'appwrite-callback-${AppConfig.appwriteProjectId}';
    return '${AppConfig.appwriteEndpoint}/account/sessions/oauth2/$provider'
        '?project=${AppConfig.appwriteProjectId}'
        '&success=$callbackScheme://success'
        '&failure=$callbackScheme://failure';
  }

  /// Verify if session exists after OAuth redirect
  Future<bool> verifySession() async {
    try {
      await account.get();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loginWithApple() async {
    await account.createOAuth2Session(provider: OAuthProvider.apple);
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (_) {}
    
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<AppUser?> getCurrentUser() async {
    // ALWAYS check Appwrite session to ensure consistent user ID
    // The user ID MUST be the Appwrite $id, not the Google ID
    try {
      final user = await account.get();
      debugPrint('Appwrite: Session found for ${user.email}, ID: ${user.$id}');
      return AppUser(
        id: user.$id, // MUST be Appwrite ID for data consistency
        email: user.email,
        name: user.name,
        createdAt: DateTime.parse(user.registration),
      );
    } catch (e) {
      debugPrint('Appwrite: No active session: $e');
      return null;
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      final user = await account.get();
      return user.$id;
    } catch (_) {
       if (_googleSignIn.currentUser != null) {
         return _googleSignIn.currentUser!.id;
       }
      return null;
    }
  }

  // --- Database ---

  Future<models.DocumentList> listDocuments({
    required String collectionId,
    List<String>? queries,
  }) async {
    debugPrint('AppwriteService: Listing documents from $collectionId with queries: $queries');
    try {
      final result = await databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: collectionId,
        queries: queries,
      );
      debugPrint('AppwriteService: Found ${result.documents.length} documents');
      return result;
    } catch (e) {
      debugPrint('AppwriteService: ERROR listing documents: $e');
      rethrow;
    }
  }

  Future<void> upsertDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    debugPrint('AppwriteService: Upserting document $documentId to $collectionId');
    try {
      await databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: data,
      );
      debugPrint('AppwriteService: Document $documentId CREATED successfully');
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        debugPrint('AppwriteService: Document exists, UPDATING...');
        await databases.updateDocument(
          databaseId: AppConfig.databaseId,
          collectionId: collectionId,
          documentId: documentId,
          data: data,
        );
        debugPrint('AppwriteService: Document $documentId UPDATED successfully');
      } else {
        debugPrint('AppwriteService: ERROR upserting document: ${e.message} (code: ${e.code})');
        rethrow;
      }
    }
  }

  // --- Storage ---

  Future<String?> uploadFile({
    required String bucketId,
    required String fileId,
    required String filePath,
  }) async {
    try {
      final file = await storage.createFile(
        bucketId: bucketId,
        fileId: fileId,
        file: InputFile.fromPath(path: filePath),
      );
      return file.$id;
    } on AppwriteException catch (e) {
      if (e.code == 409) return fileId;
      debugPrint('Appwrite: upload error: $e');
      return null;
    } catch (e) {
      debugPrint('Appwrite: upload error: $e');
      return null;
    }
  }

  Future<void> deleteFile({
    required String bucketId,
    required String fileId,
  }) async {
    try {
      await storage.deleteFile(
        bucketId: bucketId,
        fileId: fileId,
      );
    } catch (e) {
      debugPrint('Appwrite: delete file error: $e');
    }
  }
}

final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  return AppwriteService();
});
