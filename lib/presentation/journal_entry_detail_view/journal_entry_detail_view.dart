import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/journal_entry_model.dart';
import '../../services/journal_sync_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/ai_insights_panel_widget.dart';
import './widgets/entry_content_widget.dart';
import './widgets/entry_metadata_widget.dart';
import './widgets/mood_selector_widget.dart';
import './widgets/share_export_widget.dart';

class JournalEntryDetailView extends StatefulWidget {
  const JournalEntryDetailView({Key? key}) : super(key: key);

  @override
  State<JournalEntryDetailView> createState() => _JournalEntryDetailViewState();
}

class _JournalEntryDetailViewState extends State<JournalEntryDetailView>
    with TickerProviderStateMixin {
  bool _isEditing = false;
  bool _hasUnsavedChanges = false;
  bool _showAIInsights = false;
  bool _isLoading = true;
  late TextEditingController _contentController;
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Entry data
  JournalEntryModel? _entryModel;
  Map<String, dynamic> _entryData = {};
  String _originalContent = '';
  String _currentMood = '';

  final JournalSyncService _journalService = JournalSyncService.instance;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntryData();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadEntryData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final args = ModalRoute.of(context)?.settings.arguments;

      if (args == null) {
        throw Exception('No entry data provided');
      }

      JournalEntryModel? entry;

      // Handle both String ID and Map arguments for backward compatibility
      if (args is String) {
        // Load entry by ID using JournalSyncService
        entry = await _journalService.getJournalEntry(args);
        if (entry == null) {
          throw Exception('Entry not found');
        }
      } else if (args is Map<String, dynamic>) {
        // Convert Map to JournalEntryModel
        try {
          entry = JournalEntryModel.fromJson(args);
        } catch (e) {
          // If fromJson fails, try to extract ID and load the entry
          final entryId = args['id'] as String?;
          if (entryId != null) {
            entry = await _journalService.getJournalEntry(entryId);
          }
          if (entry == null) {
            throw Exception('Invalid entry data');
          }
        }
      } else {
        throw Exception('Invalid argument type');
      }

      setState(() {
        _entryModel = entry;
        _entryData = entry!.toJson();
        _originalContent = entry.content;
        _contentController.text = _originalContent;
        _currentMood = entry.mood ?? 'neutral';
        _isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading entry: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      // Navigate back if entry couldn't be loaded
      Navigator.pop(context);
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                'Do you want to save your changes before leaving?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Discard'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveEntry();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
      );
      return result ?? false;
    }
    return true;
  }

  Future<void> _saveEntry() async {
    if (_entryModel == null) return;

    try {
      final updatedEntry = await _journalService.updateJournalEntry(
        entryId: _entryModel!.id,
        title: _entryData['title'],
        content: _contentController.text,
        mood: _currentMood,
        entryDate: _entryModel!.entryDate,
        isPinned: _entryModel!.isPinned,
      );

      setState(() {
        _entryModel = updatedEntry;
        _entryData = updatedEntry.toJson();
        _originalContent = _contentController.text;
        _hasUnsavedChanges = false;
        _isEditing = false;
      });

      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entry saved successfully'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save entry: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });

    if (_isEditing) {
      // Focus on text field when entering edit mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus();
      });
    }
  }

  void _onContentChanged(String value) {
    if (!_hasUnsavedChanges && value != _originalContent) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _onMoodChanged(String mood) {
    setState(() {
      _currentMood = mood;
      if (!_hasUnsavedChanges) {
        _hasUnsavedChanges = true;
      }
    });
  }

  void _toggleAIInsights() {
    setState(() {
      _showAIInsights = !_showAIInsights;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_entryModel == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Entry Not Found'),
        ),
        body: const Center(child: Text('Journal entry could not be loaded.')),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
          title: Text(
            _formatDate(_entryModel!.entryDate),
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (_isEditing) ...[
              TextButton(
                onPressed: () {
                  setState(() {
                    _contentController.text = _originalContent;
                    _currentMood = _entryModel!.mood ?? 'neutral';
                    _hasUnsavedChanges = false;
                    _isEditing = false;
                  });
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.error,
                  ),
                ),
              ),
              TextButton(
                onPressed: _saveEntry,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              IconButton(
                onPressed: _toggleEditMode,
                icon: CustomIconWidget(
                  iconName: 'edit',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 5.w,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'share',
                              size: 4.w,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                            SizedBox(width: 3.w),
                            const Text('Share'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'download',
                              size: 4.w,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                            SizedBox(width: 3.w),
                            const Text('Export'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'delete',
                              size: 4.w,
                              color: AppTheme.lightTheme.colorScheme.error,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: AppTheme.lightTheme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Entry Content
              SliverToBoxAdapter(
                child: EntryContentWidget(
                  controller: _contentController,
                  isEditing: _isEditing,
                  onChanged: _onContentChanged,
                  entryTitle: _entryModel!.title,
                ),
              ),

              // Entry Metadata
              SliverToBoxAdapter(
                child: EntryMetadataWidget(
                  entryData: _entryData,
                  currentMood: _currentMood,
                ),
              ),

              // Mood Selector (only in edit mode)
              if (_isEditing)
                SliverToBoxAdapter(
                  child: MoodSelectorWidget(
                    selectedMood: _currentMood,
                    onMoodChanged: _onMoodChanged,
                  ),
                ),

              // AI Insights Panel
              if (_entryModel!.hasAiInsight)
                SliverToBoxAdapter(
                  child: AIInsightsPanelWidget(
                    entryData: _entryData,
                    isExpanded: _showAIInsights,
                    onToggle: _toggleAIInsights,
                  ),
                ),

              // Share & Export Options (only in view mode)
              if (!_isEditing)
                SliverToBoxAdapter(
                  child: ShareExportWidget(entryData: _entryData),
                ),

              // Bottom padding
              SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareEntry();
        break;
      case 'export':
        _exportEntry();
        break;
      case 'delete':
        _deleteEntry();
        break;
    }
  }

  void _shareEntry() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) =>
              ShareExportWidget(entryData: _entryData, isBottomSheet: true),
    );
  }

  void _exportEntry() {
    // Export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export feature coming soon'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  Future<void> _deleteEntry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Entry'),
            content: Text(
              'Are you sure you want to delete "${_entryModel!.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _journalService.deleteJournalEntry(_entryModel!.id);

        Navigator.pop(context, 'deleted'); // Return to dashboard with result

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Entry deleted'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete entry: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
