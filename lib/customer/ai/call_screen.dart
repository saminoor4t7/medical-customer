import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/app_theme.dart';
import '../prescription/screen.dart';
import 'provider.dart';

/// Full-screen voice conversation with Panda AI ("AI Call Mode").
///
/// Mirrors the web widget's call overlay: tap the orb to speak, Panda replies
/// aloud via TTS, then auto-listens again. English and Urdu (ur-PK) are
/// supported; the backend replies in Roman Urdu for Urdu speech.
class AICallScreen extends ConsumerStatefulWidget {
  const AICallScreen({
    required this.token,
    this.conversationId,
    super.key,
  });

  final String token;
  final int? conversationId;

  @override
  ConsumerState<AICallScreen> createState() => _AICallScreenState();
}

enum _CallState { idle, listening, thinking, speaking, error }

class _AICallScreenState extends ConsumerState<AICallScreen>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  final _tts = FlutterTts();

  late final AnimationController _orbController;

  bool _speechAvailable = false;
  _CallState _state = _CallState.idle;
  bool _muted = false;
  bool _showTranscript = false;
  bool _isUrdu = false;

  String _liveText = '';
  int? _conversationId;

  final List<MapEntry<String, String>> _transcript = []; // (speaker, text)

  Timer? _autoListenTimer;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _autoListenTimer?.cancel();
    _speech.stop();
    _tts.stop();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );
    } catch (_) {
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage(_isUrdu ? 'ur-PK' : 'en-US');
    await _tts.setSpeechRate(0.5); // web widget uses rate 1.05 (0-2 scale)
    await _tts.setPitch(1.05);
    await _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _state = _CallState.idle);
      _scheduleAutoListen();
    });
    _tts.setErrorHandler((msg) {
      if (!mounted) return;
      setState(() => _state = _CallState.idle);
      _scheduleAutoListen();
    });
  }

  void _onSpeechStatus(String status) {
    if (status == 'notListening' && _state == _CallState.listening) {
      if (mounted) setState(() => _state = _CallState.idle);
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    if (error.errorMsg == 'no_match' || error.errorMsg == 'listen_failed') {
      setState(() => _state = _CallState.idle);
      return;
    }
    setState(() {
      _state = _CallState.error;
      _liveText = error.errorMsg == 'permissions_refused'
          ? 'Microphone permission denied. Enable it in app settings.'
          : 'Voice error: ${error.errorMsg}';
    });
  }

  Future<void> _toggleListen() async {
    if (!_speechAvailable) {
      setState(() => _state = _CallState.error);
      _liveText = 'Speech recognition not available on this device.';
      return;
    }
    if (_state == _CallState.listening) {
      await _speech.stop();
      setState(() => _state = _CallState.idle);
      return;
    }
    await _tts.stop();
    _autoListenTimer?.cancel();
    setState(() {
      _state = _CallState.listening;
      _liveText = '';
    });
    await _speech.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        localeId: _isUrdu ? 'ur-PK' : 'en-US',
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;
    if (!mounted) return;
    setState(() => _liveText = text);
    if (result.finalResult && text.trim().isNotEmpty) {
      _speech.stop();
      _sendSpoken(text.trim());
    }
  }

  Future<void> _sendSpoken(String text) async {
    setState(() {
      _state = _CallState.thinking;
      _liveText = '';
    });
    _addToTranscript('user', text);
    try {
      final result = await ref.read(aiServiceProvider).sendMessage(
            widget.token,
            message: text,
            conversationId: _conversationId,
          );
      if (!mounted) return;
      _conversationId = result.conversationId ?? _conversationId;
      _addToTranscript('panda', result.reply);
      _showTranscript = true;
      setState(() => _state = _CallState.speaking);
      await _speak(result.reply);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _CallState.error;
        _liveText = 'Connection problem. Tap the orb to try again.';
      });
      _addToTranscript('panda', 'Sorry, something went wrong.');
    }
  }

  /// Speak the reply. Cleans markdown/JSON noise the way the web widget does
  /// and reads "Rs 120" aloud properly.
  Future<void> _speak(String text) async {
    if (_muted) {
      setState(() => _state = _CallState.idle);
      _scheduleAutoListen();
      return;
    }
    final clean = text
        .replaceAll(RegExp(r'[*_`#]'), '')
        .replaceAll(RegExp(r'\{[^}]*\}'), '')
        .replaceAllMapped(RegExp(r'Rs\s?(\d+)'), (m) => '${m[1]} rupees')
        .trim();
    if (clean.length < 3) {
      setState(() => _state = _CallState.idle);
      _scheduleAutoListen();
      return;
    }
    await _tts.setLanguage(_isUrdu ? 'ur-PK' : 'en-US');
    await _tts.speak(clean);
  }

  void _scheduleAutoListen() {
    if (!mounted) return;
    _autoListenTimer?.cancel();
    _autoListenTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted &&
          _state == _CallState.idle &&
          _speechAvailable &&
          !_muted &&
          _showTranscript) {
        _toggleListen();
      }
    });
  }

  void _addToTranscript(String speaker, String text) {
    setState(() => _transcript.add(MapEntry(speaker, text)));
  }

  void _toggleLanguage() {
    setState(() => _isUrdu = !_isUrdu);
    _tts.setLanguage(_isUrdu ? 'ur-PK' : 'en-US');
    _speech.stop();
    if (_state == _CallState.listening) {
      setState(() => _state = _CallState.idle);
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    if (_muted) {
      _tts.stop();
      if (_state == _CallState.speaking) _state = _CallState.idle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient background glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.10),
                    AppTheme.background,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _showTranscript
                      ? _buildTranscript()
                      : _buildCallCenter(),
                ),
                _buildBottomControls(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 26),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          _languageToggle(),
          const SizedBox(width: 10),
          IconButton(
            tooltip: _showTranscript ? 'Hide transcript' : 'Show transcript',
            icon: Icon(
              _showTranscript ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: _showTranscript ? AppTheme.primary : AppTheme.mutedText,
              size: 22,
            ),
            onPressed: () => setState(() => _showTranscript = !_showTranscript),
          ),
        ],
      ),
    );
  }

  Widget _languageToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langChip('EN', !_isUrdu),
          _langChip('اردو', _isUrdu),
        ],
      ),
    );
  }

  Widget _langChip(String label, bool selected) {
    return GestureDetector(
      onTap: selected ? null : _toggleLanguage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.background : AppTheme.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCallCenter() {
    final stateText = switch (_state) {
      _CallState.listening => 'Listening...',
      _CallState.thinking => 'Thinking...',
      _CallState.speaking => 'Speaking...',
      _CallState.error => 'Tap the orb to retry',
      _CallState.idle => _showTranscript || _transcript.isNotEmpty
          ? 'Tap the orb to speak'
          : 'Tap the orb and speak to Panda',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOrb(),
          const SizedBox(height: 34),
          Text(
            stateText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Text(
                _liveText.isEmpty ? ' ' : _liveText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.mutedText, fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb() {
    final listening = _state == _CallState.listening;
    final thinking = _state == _CallState.thinking;
    final speaking = _state == _CallState.speaking;

    final orbColor = listening
        ? AppTheme.primary
        : thinking
            ? Colors.deepPurpleAccent
            : speaking
                ? Colors.lightBlueAccent
                : AppTheme.surface;

    return GestureDetector(
      onTap: _state == _CallState.idle || _state == _CallState.error
          ? _toggleListen
          : _state == _CallState.listening
              ? _toggleListen
              : null,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.06).animate(
          CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
        ),
        child: Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: orbColor.withValues(alpha: 0.12),
            border: Border.all(color: orbColor.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: orbColor.withValues(alpha: 0.35),
                blurRadius: listening ? 48 : 26,
                spreadRadius: listening ? 8 : 3,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_state == _CallState.thinking)
                const SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.deepPurpleAccent),
                )
              else
                const Text('🐼', style: TextStyle(fontSize: 62)),
              if (listening)
                Positioned(
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic, color: AppTheme.background, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(color: AppTheme.background, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranscript() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _transcript.length,
            itemBuilder: (_, i) {
              final entry = _transcript[i];
              final isUser = entry.key == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primary : AppTheme.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUser ? 'You' : 'Panda',
                        style: TextStyle(
                          color: isUser
                              ? AppTheme.background.withValues(alpha: 0.7)
                              : AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.value,
                        style: TextStyle(
                          color: isUser ? AppTheme.background : Colors.white,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_liveText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 24, right: 24),
            child: Text(
              _liveText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlButton(
          icon: _muted ? Icons.volume_off : Icons.volume_up,
          label: _muted ? 'Unmute' : 'Mute',
          onTap: _toggleMute,
        ),
        const SizedBox(width: 26),
        GestureDetector(
          onTap: _state == _CallState.idle || _state == _CallState.error
              ? _toggleListen
              : _state == _CallState.listening
                  ? _toggleListen
                  : null,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _state == _CallState.listening ? AppTheme.error : AppTheme.primary,
              boxShadow: [
                BoxShadow(
                  color: (_state == _CallState.listening ? AppTheme.error : AppTheme.primary)
                      .withValues(alpha: 0.4),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _state == _CallState.listening ? Icons.stop : Icons.mic,
              color: AppTheme.background,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 26),
        _controlButton(
          icon: Icons.upload_file_outlined,
          label: 'Rx',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PrescriptionUploadScreen(token: widget.token),
            ),
          ),
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, color: AppTheme.mutedText, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppTheme.mutedText, fontSize: 11)),
        ],
      ),
    );
  }
}
