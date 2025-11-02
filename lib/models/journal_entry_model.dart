class JournalEntryModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String? mood;
  final DateTime entryDate;
  final int wordCount;
  final bool hasAiInsight;
  final bool isPinned;
  final String syncStatus;
  final DateTime? localCreatedAt;
  final DateTime? localUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.mood,
    required this.entryDate,
    required this.wordCount,
    required this.hasAiInsight,
    required this.isPinned,
    required this.syncStatus,
    this.localCreatedAt,
    this.localUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      mood: json['mood'],
      entryDate: json['entry_date'] != null
          ? DateTime.parse(json['entry_date'])
          : DateTime.now(),
      wordCount: json['word_count'] ?? 0,
      hasAiInsight: json['has_ai_insight'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      syncStatus: json['sync_status'] ?? 'local_only',
      localCreatedAt: json['local_created_at'] != null
          ? DateTime.parse(json['local_created_at'])
          : null,
      localUpdatedAt: json['local_updated_at'] != null
          ? DateTime.parse(json['local_updated_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'mood': mood,
      'entry_date': entryDate.toIso8601String().split('T')[0], // Date only
      'word_count': wordCount,
      'has_ai_insight': hasAiInsight,
      'is_pinned': isPinned,
      'sync_status': syncStatus,
      'local_created_at': localCreatedAt?.toIso8601String(),
      'local_updated_at': localUpdatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'mood': mood,
      'entry_date': entryDate.millisecondsSinceEpoch,
      'word_count': wordCount,
      'has_ai_insight': hasAiInsight ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'sync_status': syncStatus,
      'local_created_at': localCreatedAt?.millisecondsSinceEpoch,
      'local_updated_at': localUpdatedAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory JournalEntryModel.fromLocalJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      mood: json['mood'],
      entryDate: DateTime.fromMillisecondsSinceEpoch(json['entry_date'] ?? 0),
      wordCount: json['word_count'] ?? 0,
      hasAiInsight: (json['has_ai_insight'] ?? 0) == 1,
      isPinned: (json['is_pinned'] ?? 0) == 1,
      syncStatus: json['sync_status'] ?? 'local_only',
      localCreatedAt: json['local_created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['local_created_at'])
          : null,
      localUpdatedAt: json['local_updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['local_updated_at'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] ?? 0),
    );
  }

  JournalEntryModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? mood,
    DateTime? entryDate,
    int? wordCount,
    bool? hasAiInsight,
    bool? isPinned,
    String? syncStatus,
    DateTime? localCreatedAt,
    DateTime? localUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      entryDate: entryDate ?? this.entryDate,
      wordCount: wordCount ?? this.wordCount,
      hasAiInsight: hasAiInsight ?? this.hasAiInsight,
      isPinned: isPinned ?? this.isPinned,
      syncStatus: syncStatus ?? this.syncStatus,
      localCreatedAt: localCreatedAt ?? this.localCreatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to create preview text
  String get preview {
    if (content.length <= 150) return content;
    return '${content.substring(0, 150)}...';
  }

  // Helper method to check if entry needs sync
  bool get needsSync {
    return syncStatus == 'pending' ||
        syncStatus == 'failed' ||
        syncStatus == 'local_only';
  }

  // Helper method to format date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(entryDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[entryDate.month - 1]} ${entryDate.day}, ${entryDate.year}';
    }
  }
}
