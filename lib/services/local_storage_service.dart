import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry_model.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance =>
      _instance ??= LocalStorageService._();

  LocalStorageService._();

  static const String _journalEntriesKey = 'journal_entries';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _userIdKey = 'current_user_id';
  static const String _pendingSyncKey = 'pending_sync_entries';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception(
          'LocalStorageService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // User management
  Future<void> setCurrentUserId(String userId) async {
    await prefs.setString(_userIdKey, userId);
  }

  Future<String?> getCurrentUserId() async {
    return prefs.getString(_userIdKey);
  }

  Future<void> clearCurrentUserId() async {
    await prefs.remove(_userIdKey);
  }

  // Journal entries local storage
  Future<List<JournalEntryModel>> getLocalJournalEntries() async {
    final userId = await getCurrentUserId();
    if (userId == null) return [];

    final entriesJson = prefs.getString('${_journalEntriesKey}_$userId');
    if (entriesJson == null) return [];

    try {
      final List<dynamic> entriesList = json.decode(entriesJson);
      return entriesList
          .map((json) => JournalEntryModel.fromLocalJson(json))
          .toList()
        ..sort((a, b) =>
            b.entryDate.compareTo(a.entryDate)); // Sort by date descending
    } catch (e) {
      print('Error loading local journal entries: $e');
      return [];
    }
  }

  Future<void> saveJournalEntry(JournalEntryModel entry) async {
    final entries = await getLocalJournalEntries();

    // Remove existing entry with same ID if exists
    entries.removeWhere((e) => e.id == entry.id);

    // Add updated entry
    entries.add(entry);

    await _saveEntriesToStorage(entries);
  }

  Future<void> saveJournalEntries(List<JournalEntryModel> entries) async {
    await _saveEntriesToStorage(entries);
  }

  Future<void> _saveEntriesToStorage(List<JournalEntryModel> entries) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    try {
      final entriesJson =
          json.encode(entries.map((e) => e.toLocalJson()).toList());
      await prefs.setString('${_journalEntriesKey}_$userId', entriesJson);
    } catch (e) {
      print('Error saving journal entries locally: $e');
      throw Exception('Failed to save journal entries locally');
    }
  }

  Future<void> deleteJournalEntry(String entryId) async {
    final entries = await getLocalJournalEntries();
    entries.removeWhere((e) => e.id == entryId);
    await _saveEntriesToStorage(entries);
  }

  Future<JournalEntryModel?> getJournalEntry(String entryId) async {
    final entries = await getLocalJournalEntries();
    try {
      return entries.firstWhere((e) => e.id == entryId);
    } catch (e) {
      return null;
    }
  }

  // Pending sync management
  Future<void> markEntryForSync(String entryId) async {
    final pendingIds = await getPendingSyncEntryIds();
    if (!pendingIds.contains(entryId)) {
      pendingIds.add(entryId);
      await _savePendingSyncIds(pendingIds);
    }
  }

  Future<void> removeFromPendingSync(String entryId) async {
    final pendingIds = await getPendingSyncEntryIds();
    pendingIds.remove(entryId);
    await _savePendingSyncIds(pendingIds);
  }

  Future<List<String>> getPendingSyncEntryIds() async {
    final userId = await getCurrentUserId();
    if (userId == null) return [];

    final pendingJson = prefs.getString('${_pendingSyncKey}_$userId');
    if (pendingJson == null) return [];

    try {
      final List<dynamic> pendingList = json.decode(pendingJson);
      return pendingList.cast<String>();
    } catch (e) {
      print('Error loading pending sync IDs: $e');
      return [];
    }
  }

  Future<void> _savePendingSyncIds(List<String> ids) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    try {
      final idsJson = json.encode(ids);
      await prefs.setString('${_pendingSyncKey}_$userId', idsJson);
    } catch (e) {
      print('Error saving pending sync IDs: $e');
    }
  }

  Future<List<JournalEntryModel>> getPendingSyncEntries() async {
    final pendingIds = await getPendingSyncEntryIds();
    final allEntries = await getLocalJournalEntries();

    return allEntries
        .where((entry) => pendingIds.contains(entry.id) || entry.needsSync)
        .toList();
  }

  // Sync timestamp management
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await prefs.setInt(_lastSyncKey, timestamp.millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastSyncTimestamp() async {
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  // Clear all local data (for logout)
  Future<void> clearAllData() async {
    final userId = await getCurrentUserId();
    if (userId != null) {
      await prefs.remove('${_journalEntriesKey}_$userId');
      await prefs.remove('${_pendingSyncKey}_$userId');
    }
    await prefs.remove(_userIdKey);
    await prefs.remove(_lastSyncKey);
  }

  // Statistics and analytics
  Future<Map<String, dynamic>> getLocalStatistics() async {
    final entries = await getLocalJournalEntries();

    if (entries.isEmpty) {
      return {
        'totalEntries': 0,
        'currentStreak': 0,
        'averageWordCount': 0,
        'moodDistribution': {},
        'pendingSyncCount': 0,
      };
    }

    // Calculate streak
    int currentStreak = 0;
    final today = DateTime.now();
    final sortedEntries = entries
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));

    DateTime checkDate = today;
    for (final entry in sortedEntries) {
      final entryDate = DateTime(
          entry.entryDate.year, entry.entryDate.month, entry.entryDate.day);
      final currentCheckDate =
          DateTime(checkDate.year, checkDate.month, checkDate.day);

      if (entryDate.isAtSameMomentAs(currentCheckDate) ||
          entryDate
              .isAtSameMomentAs(currentCheckDate.subtract(Duration(days: 1)))) {
        currentStreak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      } else {
        break;
      }
    }

    // Calculate mood distribution
    final moodCount = <String, int>{};
    for (final entry in entries) {
      if (entry.mood != null) {
        moodCount[entry.mood!] = (moodCount[entry.mood!] ?? 0) + 1;
      }
    }

    // Average word count
    final totalWords = entries.fold(0, (sum, entry) => sum + entry.wordCount);
    final averageWordCount =
        entries.isNotEmpty ? (totalWords / entries.length).round() : 0;

    final pendingSyncCount = await getPendingSyncEntryIds();

    return {
      'totalEntries': entries.length,
      'currentStreak': currentStreak,
      'averageWordCount': averageWordCount,
      'moodDistribution': moodCount,
      'pendingSyncCount': pendingSyncCount.length,
    };
  }

  // Search functionality
  Future<List<JournalEntryModel>> searchEntries(String query) async {
    if (query.trim().isEmpty) return [];

    final entries = await getLocalJournalEntries();
    final searchQuery = query.toLowerCase();

    return entries.where((entry) {
      return entry.title.toLowerCase().contains(searchQuery) ||
          entry.content.toLowerCase().contains(searchQuery) ||
          (entry.mood?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  }

  // Filter entries by date range
  Future<List<JournalEntryModel>> getEntriesInDateRange(
      DateTime startDate, DateTime endDate) async {
    final entries = await getLocalJournalEntries();

    return entries.where((entry) {
      final entryDate = DateTime(
          entry.entryDate.year, entry.entryDate.month, entry.entryDate.day);
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      return (entryDate.isAtSameMomentAs(start) || entryDate.isAfter(start)) &&
          (entryDate.isAtSameMomentAs(end) || entryDate.isBefore(end));
    }).toList();
  }

  // Get entries by mood
  Future<List<JournalEntryModel>> getEntriesByMood(String mood) async {
    final entries = await getLocalJournalEntries();
    return entries.where((entry) => entry.mood == mood).toList();
  }
}
