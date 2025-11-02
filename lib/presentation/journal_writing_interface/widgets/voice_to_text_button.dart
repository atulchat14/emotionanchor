import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VoiceToTextButton extends StatefulWidget {
  final Function(String) onTextReceived;

  const VoiceToTextButton({
    Key? key,
    required this.onTextReceived,
  }) : super(key: key);

  @override
  State<VoiceToTextButton> createState() => _VoiceToTextButtonState();
}

class _VoiceToTextButtonState extends State<VoiceToTextButton>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    try {
      if (!await _requestMicrophonePermission()) {
        _showPermissionDialog();
        return;
      }

      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(const RecordConfig(),
            path: 'voice_note.m4a');
        setState(() {
          _isRecording = true;
        });
        _pulseController.repeat(reverse: true);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showErrorMessage('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });
      _pulseController.stop();
      _pulseController.reset();

      if (path != null) {
        // Simulate speech-to-text processing
        await Future.delayed(Duration(seconds: 2));

        // Mock transcribed text based on common journal phrases
        final mockTranscriptions = [
          "Today I'm feeling overwhelmed with work deadlines and need to find better balance.",
          "I had a great conversation with my colleague that made me feel more confident about the project.",
          "The stress from this week is really getting to me, but I'm trying to stay positive.",
          "I'm grateful for the support from my team during this challenging time.",
          "Need to remember to take breaks and not push myself too hard.",
        ];

        final transcribedText = mockTranscriptions[
            DateTime.now().millisecond % mockTranscriptions.length];

        widget.onTextReceived(transcribedText);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorMessage('Failed to process recording');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Microphone Permission'),
        content: Text(
          'Please allow microphone access to use voice-to-text feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isProcessing
          ? null
          : _isRecording
              ? _stopRecording
              : _startRecording,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: _isRecording
                    ? AppTheme.lightTheme.colorScheme.error
                    : _isProcessing
                        ? AppTheme.lightTheme.colorScheme.secondary
                        : AppTheme.lightTheme.colorScheme.primary,
                borderRadius: BorderRadius.circular(6.w),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.onSecondary,
                        ),
                      ),
                    )
                  : CustomIconWidget(
                      iconName: _isRecording ? 'stop' : 'mic',
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          );
        },
      ),
    );
  }
}
