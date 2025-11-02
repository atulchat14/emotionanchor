import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/journal_entry_model.dart';
import './local_storage_service.dart';
import './supabase_service.dart';

class JournalSyncService {
  static JournalSyncService? _instance;
  static JournalSyncService get instance =>
      _instance ??= JournalSyncService._();

  JournalSyncService._();

  final LocalStorageService _localStorage = LocalStorageService.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;
  Timer? _backgroundSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Stream controllers for sync status
  final StreamController<bool> _syncStatusController =
      StreamController<bool>.broadcast();
  final StreamController<String> _syncMessageController =
      StreamController<String>.broadcast();

  Stream<bool> get isSyncingStream => _syncStatusController.stream;
  Stream<String> get syncMessageStream => _syncMessageController.stream;

  Future<void> initialize() async {
    // Initialize LocalStorageService first
    await _localStorage.initialize();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Start background sync timer (sync every 5 minutes when online)
    _startBackgroundSync();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _backgroundSyncTimer?.cancel();
    _syncStatusController.close();
    _syncMessageController.close();
  }

  void _onConnectivityChanged(List<ConnectivityResult> result) {
    if (!result.contains(ConnectivityResult.none)) {
      // Connection restored, attempt sync
      syncJournalEntries();
    }
  }

  void _startBackgroundSync() {
    _backgroundSyncTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      if (!_isSyncing) {
        syncJournalEntries();
      }
    });
  }

  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> syncJournalEntries() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping...');
      return;
    }

    final online = await isOnline();
    if (!online) {
      debugPrint('Device is offline, skipping sync');
      _syncMessageController.add('Offline - entries saved locally');
      return;
    }

    _isSyncing = true;
    _syncStatusController.add(true);
    _syncMessageController.add('Syncing entries...');

    try {
      final currentUser = SupabaseService.instance.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('No authenticated user, skipping sync');
        return;
      }

      await _localStorage.setCurrentUserId(currentUser.id);

      // Step 1: Upload local entries to Supabase
      await _uploadLocalEntries();

      // Step 2: Download remote entries from Supabase
      await _downloadRemoteEntries();

      // Step 3: Update last sync timestamp
      await _localStorage.setLastSyncTimestamp(DateTime.now());

      _syncMessageController.add('Sync completed successfully');
      debugPrint('Journal sync completed successfully');
    } catch (e) {
      debugPrint('Sync error: $e');
      _syncMessageController.add('Sync failed: ${e.toString()}');

      // Mark failed entries for retry
      await _markFailedEntriesForRetry();
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);

      // Clear sync message after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        _syncMessageController.add('');
      });
    }
  }

  Future<void> _uploadLocalEntries() async {
    final client = SupabaseService.instance.client;
    final pendingEntries = await _localStorage.getPendingSyncEntries();

    debugPrint('Uploading ${pendingEntries.length} pending entries');

    for (final entry in pendingEntries) {
      try {
        if (entry.syncStatus == 'local_only' || entry.syncStatus == 'pending') {
          // This is a new entry, insert it
          final response = await client
              .from('journal_entries')
              .insert(entry.toJson())
              .select()
              .single();

          // Update local entry with server data
          final updatedEntry = JournalEntryModel.fromJson(response).copyWith(
            syncStatus: 'synced',
            localCreatedAt: entry.localCreatedAt,
            localUpdatedAt: entry.localUpdatedAt,
          );

          await _localStorage.saveJournalEntry(updatedEntry);
          await _localStorage.removeFromPendingSync(entry.id);
        } else if (entry.syncStatus == 'failed') {
          // This entry failed before, try to update it
          final response = await client
              .from('journal_entries')
              .update(entry.toJson())
              .eq('id', entry.id)
              .select()
              .single();

          final updatedEntry = JournalEntryModel.fromJson(response).copyWith(
            syncStatus: 'synced',
            localCreatedAt: entry.localCreatedAt,
            localUpdatedAt: entry.localUpdatedAt,
          );

          await _localStorage.saveJournalEntry(updatedEntry);
          await _localStorage.removeFromPendingSync(entry.id);
        }

        debugPrint('Successfully synced entry: ${entry.id}');
      } catch (e) {
        debugPrint('Failed to sync entry ${entry.id}: $e');

        // Mark entry as failed
        final failedEntry = entry.copyWith(syncStatus: 'failed');
        await _localStorage.saveJournalEntry(failedEntry);
      }
    }
  }

  Future<void> _downloadRemoteEntries() async {
    final client = SupabaseService.instance.client;
    final lastSync = await _localStorage.getLastSyncTimestamp();

    try {
      var query = client
          .from('journal_entries')
          .select()
          .eq('user_id', client.auth.currentUser!.id);

      // Only get entries updated since last sync
      if (lastSync != null) {
        query = query.gte('updated_at', lastSync.toIso8601String());
      }

      final response = await query.order('updated_at', ascending: true);

      debugPrint('Downloaded ${response.length} remote entries');

      final localEntries = await _localStorage.getLocalJournalEntries();
      final localEntryMap = {for (var e in localEntries) e.id: e};

      for (final remoteData in response) {
        final remoteEntry = JournalEntryModel.fromJson(remoteData);
        final localEntry = localEntryMap[remoteEntry.id];

        if (localEntry == null) {
          // New entry from server
          final entryToSave = remoteEntry.copyWith(syncStatus: 'synced');
          await _localStorage.saveJournalEntry(entryToSave);
        } else if (localEntry.syncStatus == 'synced' &&
            remoteEntry.updatedAt.isAfter(localEntry.updatedAt)) {
          // Server version is newer
          final entryToSave = remoteEntry.copyWith(
            syncStatus: 'synced',
            localCreatedAt: localEntry.localCreatedAt,
            localUpdatedAt: localEntry.localUpdatedAt,
          );
          await _localStorage.saveJournalEntry(entryToSave);
        }
        // If local entry has pending changes, don't overwrite
      }
    } catch (e) {
      debugPrint('Error downloading remote entries: $e');
      throw Exception('Failed to download remote entries: $e');
    }
  }

  Future<void> _markFailedEntriesForRetry() async {
    final pendingIds = await _localStorage.getPendingSyncEntryIds();
    final allEntries = await _localStorage.getLocalJournalEntries();

    for (final entry in allEntries) {
      if (pendingIds.contains(entry.id) && entry.syncStatus != 'failed') {
        final failedEntry = entry.copyWith(syncStatus: 'failed');
        await _localStorage.saveJournalEntry(failedEntry);
      }
    }
  }

  // Create new journal entry (saves locally first, then syncs)
  Future<JournalEntryModel> createJournalEntry({
    required String title,
    required String content,
    required String mood,
    required DateTime entryDate,
  }) async {
    final currentUser = SupabaseService.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception(
          'No authenticated user. Please log in to save journal entries.');
    }

    // Ensure user profile exists first
    try {
      final userExists = await _verifyUserProfile(currentUser.id);
      if (!userExists) {
        throw Exception(
            'User profile not found. Please complete profile setup.');
      }
    } catch (e) {
      throw Exception('Authentication verification failed: ${e.toString()}');
    }

    final entryId = _generateUniqueId();
    final now = DateTime.now();

    final entry = JournalEntryModel(
      id: entryId,
      userId: currentUser.id,
      title: title,
      content: content,
      mood: mood,
      entryDate: entryDate,
      wordCount: _calculateWordCount(content),
      hasAiInsight: false,
      isPinned: false,
      syncStatus: 'pending',
      localCreatedAt: now,
      localUpdatedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    // Save locally first
    await _localStorage.saveJournalEntry(entry);
    await _localStorage.markEntryForSync(entryId);

    debugPrint('Created journal entry locally for user: ${currentUser.id}');

    // Try to sync immediately if online
    if (await isOnline()) {
      syncJournalEntries(); // Don't await, let it run in background
    }

    return entry;
  }

  // Verify user profile exists in database
  Future<bool> _verifyUserProfile(String userId) async {
    try {
      final client = SupabaseService.instance.client;
      final response = await client
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .single();

      return response != null;
    } catch (e) {
      debugPrint('User profile verification failed: $e');
      return false;
    }
  }

  // Update existing journal entry
  Future<JournalEntryModel> updateJournalEntry({
    required String entryId,
    String? title,
    String? content,
    String? mood,
    DateTime? entryDate,
    bool? isPinned,
  }) async {
    final currentUser = SupabaseService.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception(
          'No authenticated user. Please log in to update journal entries.');
    }

    final existingEntry = await _localStorage.getJournalEntry(entryId);
    if (existingEntry == null) {
      throw Exception('Entry not found');
    }

    // Verify user owns this entry
    if (existingEntry.userId != currentUser.id) {
      throw Exception('Access denied. You can only edit your own entries.');
    }

    final now = DateTime.now();
    final updatedEntry = existingEntry.copyWith(
      title: title ?? existingEntry.title,
      content: content ?? existingEntry.content,
      mood: mood ?? existingEntry.mood,
      entryDate: entryDate ?? existingEntry.entryDate,
      isPinned: isPinned ?? existingEntry.isPinned,
      wordCount: content != null
          ? _calculateWordCount(content)
          : existingEntry.wordCount,
      syncStatus: 'pending',
      localUpdatedAt: now,
      updatedAt: now,
    );

    // Save locally first
    await _localStorage.saveJournalEntry(updatedEntry);
    await _localStorage.markEntryForSync(entryId);

    debugPrint('Updated journal entry locally for user: ${currentUser.id}');

    // Try to sync immediately if online
    if (await isOnline()) {
      syncJournalEntries(); // Don't await, let it run in background
    }

    return updatedEntry;
  }

  // Delete journal entry
  Future<void> deleteJournalEntry(String entryId) async {
    final currentUser = SupabaseService.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception(
          'No authenticated user. Please log in to delete journal entries.');
    }

    final existingEntry = await _localStorage.getJournalEntry(entryId);
    if (existingEntry != null && existingEntry.userId != currentUser.id) {
      throw Exception('Access denied. You can only delete your own entries.');
    }

    final client = SupabaseService.instance.client;

    // Delete locally first
    await _localStorage.deleteJournalEntry(entryId);
    await _localStorage.removeFromPendingSync(entryId);

    debugPrint('Deleted journal entry locally for user: ${currentUser.id}');

    // Try to delete from server if online
    if (await isOnline()) {
      try {
        await client.from('journal_entries').delete().eq('id', entryId);
        debugPrint('Successfully deleted entry from server: $entryId');
      } catch (e) {
        debugPrint('Failed to delete entry from server: $e');
        // Entry is already deleted locally, so this is not critical
      }
    }
  }

  // Get all journal entries (from local storage)
  Future<List<JournalEntryModel>> getJournalEntries() async {
    return await _localStorage.getLocalJournalEntries();
  }

  // Get single journal entry
  Future<JournalEntryModel?> getJournalEntry(String entryId) async {
    return await _localStorage.getJournalEntry(entryId);
  }

  // Force sync now (for manual sync button)
  Future<void> forceSyncNow() async {
    await syncJournalEntries();
  }

  // Get sync status information
  Future<Map<String, dynamic>> getSyncStatus() async {
    final pendingIds = await _localStorage.getPendingSyncEntryIds();
    final lastSync = await _localStorage.getLastSyncTimestamp();
    final isConnected = await isOnline();

    return {
      'pendingEntries': pendingIds.length,
      'lastSyncAt': lastSync,
      'isOnline': isConnected,
      'isSyncing': _isSyncing,
    };
  }

  // Helper methods
  String _generateUniqueId() {
    // Generate a proper UUID v4 format using crypto random
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));

    // Set version (4) and variant bits according to UUID v4 spec
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // Variant bits

    // Convert to hex string with proper formatting
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  int _calculateWordCount(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  // Clear all data on logout
  Future<void> clearAllData() async {
    await _localStorage.clearAllData();
  }
}
