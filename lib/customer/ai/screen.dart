import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../main.dart';
import '../catalog/model.dart';
import '../catalog/medicine_detail_screen.dart';
import 'provider.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({required this.token, super.key});
  final String token;

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatBubble> _messages = [];
  bool _sending = false;
  int? _sessionId;

  // Bilingual quick prompts — backend handles Roman Urdu, English, and mixed
  static const _quickPrompts = [
    'Fever / بخار کی دوا',
    'Headache / سر درد',
    'Cough / کھانسی کی دوا',
    'Paracetamol کیا ہے؟',
    'Cold & Flu / نزلہ زکام',
    'Stomach pain / پیٹ درد',
    'Allergy / الرجی',
    'Antibiotic / اینٹی بائیوٹک',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primary, size: 22),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Health Assistant',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'دوا / علامت پوچھیں  •  Ask about medicines',
                  style: TextStyle(color: AppTheme.mutedText, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_sessionId != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.mutedText, size: 22),
              tooltip: 'New conversation',
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _sessionId = null;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildBubble(_messages[i]),
                  ),
          ),
          if (_messages.isEmpty) _buildQuickPrompts(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 38),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hi! میں آپ کا AI Health Assistant ہوں',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'دوائیں، علامات یا خوراک کے بارے میں پوچھیں\nAsk about medicines, symptoms or dosages.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mutedText, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(
            _quickPrompts[i],
            style: const TextStyle(color: AppTheme.primary, fontSize: 12),
          ),
          backgroundColor: AppTheme.cardColor,
          side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
          onPressed: () {
            _controller.text = _quickPrompts[i];
            _send();
          },
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatBubble bubble) {
    final isUser = bubble.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.15),
              ),
              child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    bubble.content,
                    style: TextStyle(
                      color: isUser ? AppTheme.background : Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (bubble.medicines.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Matched Medicines / دوائیں:',
                      style: TextStyle(
                        color: isUser ? AppTheme.background.withOpacity(0.7) : AppTheme.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...bubble.medicines.map(_buildMedicineChip),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.15),
              ),
              child: const Icon(Icons.person, color: AppTheme.primary, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicineChip(Medicine m) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MedicineDetailScreen(medicineId: m.id, token: widget.token),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.background.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medication_liquid, color: AppTheme.primary, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                m.name,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (m.strength != null) ...[
              const SizedBox(width: 6),
              Text(m.strength!, style: const TextStyle(color: AppTheme.mutedText, fontSize: 11)),
            ],
            if (m.price > 0) ...[
              const SizedBox(width: 8),
              Text(
                'PKR ${m.price.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.mutedText, size: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: AppTheme.primary.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'دوا یا علامت پوچھیں... / Ask about a medicine...',
                hintStyle: const TextStyle(color: AppTheme.mutedText, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF10354A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            height: 48,
            child: FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.background,
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.background),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatBubble(role: 'user', content: text));
      _sending = true;
    });
    _controller.clear();
    _scrollDown();
    try {
      final result = await ref.read(aiServiceProvider).sendMessage(
            widget.token,
            message: text,
            sessionId: _sessionId,
          );
      if (result['session_id'] is int) _sessionId = result['session_id'];
      final reply = result['response']?.toString() ??
          result['reply']?.toString() ??
          result['content']?.toString() ??
          result['message']?.toString() ??
          _extractReply(result);
      final medicines = <Medicine>[];
      final medicinesRaw = result['medicines'] ?? result['matched_medicines'] ?? result['results'];
      if (medicinesRaw is List) {
        for (final item in medicinesRaw) {
          if (item is Map) {
            try {
              medicines.add(Medicine.fromJson(Map<String, dynamic>.from(item)));
            } catch (_) {}
          }
        }
      }
      setState(() {
        _messages.add(_ChatBubble(role: 'assistant', content: reply, medicines: medicines));
      });
    } catch (e) {
      setState(() {
        _messages.add(const _ChatBubble(
          role: 'assistant',
          content: 'Sorry, I encountered an error. Please try again.\nمعذرت، دوبارہ کوشش کریں۔',
        ));
      });
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('AI error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollDown();
      }
    }
  }

  String _extractReply(Map<String, dynamic> result) {
    for (final key in ['response', 'reply', 'content', 'message', 'text', 'answer']) {
      if (result[key] != null) return result[key].toString();
    }
    final keys = result.keys.where((k) => k != 'session_id').toList();
    if (keys.length == 1 && result[keys.first] is String) return result[keys.first] as String;
    return 'I processed your request. Here are the results.\nنتائج یہ ہیں۔';
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _ChatBubble {
  const _ChatBubble({required this.role, required this.content, this.medicines = const []});
  final String role;
  final String content;
  final List<Medicine> medicines;
}
