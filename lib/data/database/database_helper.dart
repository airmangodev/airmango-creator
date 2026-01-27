import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('airmango_creator.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9, // Incremented to v9 to force migration for story_narrative
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }
 
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Database: Upgrading from version $oldVersion to $newVersion');
    
    try {
      // Run migrations if moving from an older version
      // We check < 9 to catch any users who might have stuck on v8 without the column
      if (oldVersion < 9) {
        // Step 1: Ensure basic columns exist in all tables
        await _ensureColumnExists(db, 'trips', 'user_id', 'TEXT');
        await _ensureColumnExists(db, 'trips', 'is_synced', 'INTEGER DEFAULT 0');
        await _ensureColumnExists(db, 'trips', 'updated_at', "TEXT DEFAULT (datetime('now'))");
        await _ensureColumnExists(db, 'trips', 'created_at', "TEXT DEFAULT (datetime('now'))");
        
        await _ensureColumnExists(db, 'days', 'user_id', 'TEXT');
        await _ensureColumnExists(db, 'days', 'is_synced', 'INTEGER DEFAULT 0');
        await _ensureColumnExists(db, 'days', 'updated_at', "TEXT DEFAULT (datetime('now'))");
        // Ensure story_narrative exists (Fix for "no column named story_narrative" error)
        await _ensureColumnExists(db, 'days', 'story_narrative', 'TEXT');
        
        await _ensureColumnExists(db, 'stops', 'user_id', 'TEXT');
        await _ensureColumnExists(db, 'stops', 'is_synced', 'INTEGER DEFAULT 0');
        await _ensureColumnExists(db, 'stops', 'updated_at', "TEXT DEFAULT (datetime('now'))");
        
        // Step 2: Handle media table
        await _safeMediaMigration(db, oldVersion);
        await _ensureColumnExists(db, 'media', 'user_id', 'TEXT');
        await _ensureColumnExists(db, 'media', 'remote_url', 'TEXT');
        
        // Step 3: Create indexes for performance
        await db.execute('CREATE INDEX IF NOT EXISTS idx_trips_user ON trips (user_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_days_user ON days (user_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_stops_user ON stops (user_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_media_user ON media (user_id)');
      }
    } catch (e) {
      debugPrint('Database: Migration error: $e');
    }
  }

  Future<void> _ensureColumnExists(Database db, String tableName, String columnName, String columnType) async {
    try {
      final info = await db.rawQuery("PRAGMA table_info($tableName)");
      final columns = info.map((col) => col['name'] as String).toSet();
      
      if (!columns.contains(columnName)) {
        debugPrint('Database: Adding $columnName to $tableName');
        await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
      }
    } catch (e) {
      debugPrint('Database: Error adding $columnName to $tableName: $e');
    }
  }

  /// Safely migrate media table handling all version scenarios
  Future<void> _safeMediaMigration(Database db, int oldVersion) async {
    // Check if media table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='media'"
    );
    
    if (tables.isEmpty) {
      // No media table exists, nothing to migrate
      debugPrint('Database: No media table found, skipping migration');
      return;
    }

    // Get current columns in media table
    final mediaInfo = await db.rawQuery("PRAGMA table_info(media)");
    final existingColumns = mediaInfo.map((col) => col['name'] as String).toSet();
    
    debugPrint('Database: Existing columns in media: $existingColumns');

    // Check if we need to migrate (does it have is_synced and is trip_id nullable?)
    final hasIsSynced = existingColumns.contains('is_synced');
    final hasRemoteUrl = existingColumns.contains('remote_url');
    
    // If already has all columns, no migration needed for media table
    if (hasIsSynced && hasRemoteUrl) {
      debugPrint('Database: Media table already has correct schema');
      return;
    }

    // Need to migrate - do it safely
    debugPrint('Database: Migrating media table...');
    
    // Drop any leftover temp table
    await db.execute('DROP TABLE IF EXISTS media_old');
    await db.execute('DROP TABLE IF EXISTS media_backup');
    
    // Rename current table
    await db.execute('ALTER TABLE media RENAME TO media_backup');
    
    // Create new table with correct schema
    await db.execute('''
      CREATE TABLE media (
        id TEXT PRIMARY KEY,
        trip_id TEXT,
        stop_id TEXT,
        type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        lat REAL,
        lng REAL,
        captured_at TEXT NOT NULL,
        note TEXT,
        duration_seconds INTEGER,
        is_synced INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL,
        remote_url TEXT,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (stop_id) REFERENCES stops (id) ON DELETE SET NULL
      )
    ''');

    // Build dynamic column list for copy (only copy columns that exist in both)
    final newColumns = {'id', 'trip_id', 'stop_id', 'type', 'file_path', 'lat', 'lng', 
                        'captured_at', 'note', 'duration_seconds', 'is_synced', 'updated_at', 'remote_url'};
    final copyColumns = existingColumns.intersection(newColumns).toList();
    
    if (copyColumns.isNotEmpty) {
      // Build select with defaults for missing columns
      final selectParts = <String>[];
      for (final col in newColumns) {
        if (existingColumns.contains(col)) {
          selectParts.add(col);
        } else if (col == 'is_synced') {
          selectParts.add('0 as is_synced');
        } else if (col == 'remote_url') {
          selectParts.add('NULL as remote_url');
        } else if (col == 'updated_at') {
          selectParts.add("datetime('now') as updated_at");
        } else {
          selectParts.add('NULL as $col');
        }
      }
      
      final selectList = selectParts.join(', ');
      final targetColumns = newColumns.join(', ');
      
      await db.execute('''
        INSERT INTO media ($targetColumns)
        SELECT $selectList FROM media_backup
      ''');
    }
    
    // Drop backup table
    await db.execute('DROP TABLE media_backup');
    
    // Recreate index
    await db.execute('DROP INDEX IF EXISTS idx_media_location');
    await db.execute('CREATE INDEX idx_media_location ON media (lat, lng)');
    
    debugPrint('Database: Media table migration completed successfully');
  }

 
  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const integerNullable = 'INTEGER';
    const realType = 'REAL';
 
    // TRIPS Table
    await db.execute('''
      CREATE TABLE trips (
        id $idType,
        user_id $textNullable,
        name $textType,
        start_date $textType,
        end_date $textType,
        travelers $integerType,
        status $textType,
        hero_image_path $textNullable,
        is_synced INTEGER DEFAULT 0,
        updated_at $textType,
        created_at $textType
      )
    ''');
    await db.execute('CREATE INDEX idx_trips_user ON trips (user_id)');
 
    // DAYS Table
    await db.execute('''
      CREATE TABLE days (
        id $idType,
        user_id $textNullable,
        trip_id $textType,
        date $textType,
        day_number INTEGER,
        story_narrative $textNullable,
        is_synced INTEGER DEFAULT 0,
        updated_at $textType,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_days_user ON days (user_id)');
 
    // STOPS Table
    await db.execute('''
      CREATE TABLE stops (
        id $idType,
        user_id $textNullable,
        trip_id $textType,
        day_id $textNullable,
        name $textType,
        type $textType,
        lat $realType,
        lng $realType,
        visit_time $textType,
        notes $textNullable,
        place_id $textNullable,
        is_accommodation INTEGER DEFAULT 0,
        stop_order INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        updated_at $textType,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (day_id) REFERENCES days (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_stops_location ON stops (lat, lng)');
    await db.execute('CREATE INDEX idx_stops_user ON stops (user_id)');
 
    // MEDIA Table
    await db.execute('''
      CREATE TABLE media (
        id $idType,
        user_id $textNullable,
        trip_id $textNullable, -- REPRESENTING INBOX
        stop_id $textNullable,
        type $textType,
        file_path $textType,
        lat $realType,
        lng $realType,
        captured_at $textType,
        note $textNullable,
        duration_seconds $integerNullable,
        is_synced INTEGER DEFAULT 0,
        updated_at $textType,
        remote_url $textNullable,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (stop_id) REFERENCES stops (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_media_location ON media (lat, lng)');
    await db.execute('CREATE INDEX idx_media_user ON media (user_id)');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
