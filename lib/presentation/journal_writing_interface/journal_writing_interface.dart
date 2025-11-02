import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/journal_sync_service.dart';
import './widgets/mood_selector.dart';
import './widgets/voice_to_text_button.dart';
import './widgets/writing_toolbar.dart';

class JournalWritingInterface extends StatefulWidget {
  const JournalWritingInterface({Key? key}) : super(key: key);

  @override
  State<JournalWritingInterface> createState() =>
      _JournalWritingInterfaceState();
}

class _JournalWritingInterfaceState extends State<JournalWritingInterface> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final AuthService _authService = AuthService.instance;
  final JournalSyncService _journalService = JournalSyncService.instance;

  String _selectedMood = 'neutral';
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  String? _entryId;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _checkForExistingEntry();
    _setupAutoSave();
  }

  void _checkForExistingEntry() {
    // Check if we have an entry ID passed as argument for editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) {
        _loadExistingEntry(args);
      }
    });
  }

  Future<void> _loadExistingEntry(String entryId) async {
    try {
      setState(() => _isLoading = true);
      final entries = await _journalService.getJournalEntries();
      final entry = entries.firstWhere((e) => e.id == entryId);

      setState(() {
        _entryId = entryId;
        _titleController.text = entry.title ?? '';
        _contentController.text = entry.content;
        _selectedMood = entry.mood ?? 'neutral';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load entry: ${e.toString()}');
    }
  }

  void _setupAutoSave() {
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    setState(() => _hasUnsavedChanges = true);

    // Cancel previous timer
    _autoSaveTimer?.cancel();

    // Set new timer for auto-save
    _autoSaveTimer = Timer(Duration(seconds: 3), () {
      if (_hasUnsavedChanges &&
          (_titleController.text.isNotEmpty ||
              _contentController.text.isNotEmpty)) {
        _saveEntry(showSuccess: false);
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text('Write'),
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            // Auto-save indicator
            if (_hasUnsavedChanges)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Unsaved',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // Save button
            TextButton(
              onPressed:
                  _isLoading ? null : () => _saveEntry(showSuccess: true),
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mood Selector
                    MoodSelector(
                      selectedMood: _selectedMood,
                      onMoodSelected: (mood) {
                        setState(() {
                          _selectedMood = mood;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),

                    SizedBox(height: 24),

                    // Title Field
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Entry title (optional)',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textDisabledLight,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.words,
                    ),

                    SizedBox(height: 16),

                    // Content Field
                    TextField(
                      controller: _contentController,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textPrimaryLight,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'How are you feeling today? What\'s on your mind?',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textDisabledLight,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      minLines: 10,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                    ),

                    SizedBox(height: 24),

                    // Writing Toolbar
                    WritingToolbar(
                      onFormatAction: (format) {
                        // Handle text formatting
                        _applyTextFormat(format);
                      },
                      onMoodTag: (tag) {
                        // Handle mood tag insertion
                        setState(() {
                          if (_contentController.text.isEmpty) {
                            _contentController.text = tag;
                          } else {
                            _contentController.text += ' $tag';
                          }
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),

                    SizedBox(height: 16),

                    // Voice to Text Button
                    VoiceToTextButton(
                      onTextReceived: (text) {
                        setState(() {
                          if (_contentController.text.isEmpty) {
                            _contentController.text = text;
                          } else {
                            _contentController.text += '\n\n$text';
                          }
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _applyTextFormat(String format) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid && selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      String formattedText = '';

      switch (format) {
        case 'bold':
          formattedText = '**$selectedText**';
          break;
        case 'italic':
          formattedText = '_${selectedText}_';
          break;
        case 'underline':
          formattedText = '<u>$selectedText</u>';
          break;
        default:
          formattedText = selectedText;
      }

      final newText =
          text.replaceRange(selection.start, selection.end, formattedText);
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: selection.start + formattedText.length,
      );
    }
  }

  Future<bool> _handleBackPress() async {
    if (_hasUnsavedChanges) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unsaved Changes'),
          content: Text(
              'You have unsaved changes. Would you like to save before leaving?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Discard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Save'),
            ),
          ],
        ),
      );

      if (shouldSave == true) {
        await _saveEntry(showSuccess: false);
      }
    }

    return true;
  }

  Future<void> _saveEntry({required bool showSuccess}) async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      if (showSuccess) {
        _showErrorSnackBar('Please add some content before saving');
      }
      return;
    }

    try {
      setState(() => _isLoading = true);

      if (_entryId != null) {
        // Update existing entry
        await _journalService.updateJournalEntry(
          entryId: _entryId!,
          title: _titleController.text.isEmpty ? null : _titleController.text,
          content: _contentController.text,
          mood: _selectedMood,
          entryDate: DateTime.now(),
        );
      } else {
        // Create new entry
        final createdEntry = await _journalService.createJournalEntry(
          title: _titleController.text.isEmpty
              ? 'Untitled Entry'
              : _titleController.text,
          content: _contentController.text,
          mood: _selectedMood,
          entryDate: DateTime.now(),
        );
        _entryId = createdEntry.id;
      }

      setState(() {
        _isLoading = false;
        _hasUnsavedChanges = false;
      });

      if (showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Entry saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Clear the form for a new entry
        _clearForm();
      }
    } catch (e) {
      setState(() => _isLoading = false);

      // More specific error handling
      String errorMessage = 'Failed to save entry';
      if (e.toString().contains('User profile not found')) {
        errorMessage =
            'User profile setup required. Please check your account settings.';
      } else if (e.toString().contains('No authenticated user')) {
        errorMessage = 'Please log in to save entries.';
      } else if (e.toString().contains('Authentication verification failed')) {
        errorMessage = 'Authentication issue. Please try logging in again.';
      } else {
        errorMessage = 'Failed to save entry: ${e.toString()}';
      }

      _showErrorSnackBar(errorMessage);
    }
  }

  void _clearForm() {
    setState(() {
      _titleController.clear();
      _contentController.clear();
      _selectedMood = 'neutral';
      _entryId = null;
      _hasUnsavedChanges = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
