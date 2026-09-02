import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../main.dart';
import '../cart/provider.dart';
import '../cart/screen.dart';
import '../catalog/medicine_detail_screen.dart';
import '../orders/screen.dart';
import '../pharmacy/provider.dart';
import '../prescription/model.dart';
import '../prescription/services.dart';
import 'call_screen.dart';
import 'model.dart';
import 'provider.dart';

/// Chat screen for the Panda AI assistant (Gemini backend with tools:
/// search, symptom triage, cart, orders, addresses, profile).
class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({required this.token, this.conversationId, super.key});
  final String token;
  final int? conversationId;

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  final _rxService = PrescriptionService();
  final List<AIChatMessage> _messages = [];
  bool _sending = false;
  bool _uploadingRx = false;
  int? _conversationId;

  // Bilingual quick prompts — Panda replies in English or Roman Urdu.
  static const _quickPrompts = [
    'I have fever and body ache',
    'Mujhe zukaam hai, dawa suggest karein',
    'Search for Panadol',
    'Show my cart',
    'Headache / sar dard ki dawa',
    'Place my order',
  ];

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    if (widget.conversationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadConversation(widget.conversationId!);
      });
    }
  }

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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Center(
                child: Text('🐼', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panda AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _sending ? 'Thinking...' : 'AI doctor · voice · orders',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.phone_in_talk,
              color: AppTheme.primary,
              size: 24,
            ),
            tooltip: 'Call Panda AI (voice)',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AICallScreen(
                  token: widget.token,
                  conversationId: _conversationId,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.history,
              color: AppTheme.mutedText,
              size: 22,
            ),
            tooltip: 'Chat history',
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(
              Icons.add_comment_outlined,
              color: AppTheme.mutedText,
              size: 22,
            ),
            tooltip: 'New chat',
            onPressed: _newChat,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (_, i) => i < _messages.length
                        ? _buildBubble(_messages[i])
                        : _buildTyping(),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Center(
                child: Text('🐼', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Hi! I'm Panda, your AI medical assistant",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tell me your symptoms and I\'ll suggest medicines,\ncheck prices and stock, add them to your cart\nand even place your order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedText,
                fontSize: 13,
                height: 1.6,
              ),
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(
            _quickPrompts[i],
            style: const TextStyle(color: AppTheme.primary, fontSize: 12),
          ),
          backgroundColor: AppTheme.cardColor,
          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
          onPressed: () => _sendRaw(_quickPrompts[i]),
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _pandaAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Panda is thinking...',
                  style: TextStyle(
                    color: AppTheme.mutedText.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pandaAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary.withValues(alpha: 0.15),
      ),
      child: const Center(child: Text('🐼', style: TextStyle(fontSize: 16))),
    );
  }

  Widget _buildBubble(AIChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[_pandaAvatar(), const SizedBox(width: 8)],
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
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? AppTheme.background : Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  if (message.prescription is Prescription)
                    _buildPrescriptionCard(
                      message.prescription! as Prescription,
                    ),
                  ...message.actions.map(_buildActionCard),
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
                color: AppTheme.primary.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.primary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: 'Upload prescription',
              onPressed: _uploadingRx ? null : _openRxUpload,
              icon: _uploadingRx
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : const Icon(
                      Icons.attach_file,
                      color: AppTheme.mutedText,
                      size: 22,
                    ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              maxLength: 2000,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Ask about medicines, symptoms or orders...',
                hintStyle: TextStyle(color: AppTheme.mutedText, fontSize: 13),
                filled: true,
                fillColor: Color(0xFF10354A),
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.background,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // -- Messaging ------------------------------------------------------------

  Future<void> _send() {
    final text = _controller.text.trim();
    _controller.clear();
    return _sendRaw(text);
  }

  Future<void> _sendRaw(String text) async {
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(AIChatMessage(role: 'user', content: text));
      _sending = true;
    });
    _scrollDown();
    try {
      final result = await ref
          .read(aiServiceProvider)
          .sendMessage(
            widget.token,
            message: text,
            conversationId: _conversationId,
          );
      if (!mounted) return;
      setState(() {
        _conversationId = result.conversationId ?? _conversationId;
        _sending = false;
        _messages.add(
          AIChatMessage(
            role: 'model',
            content: result.reply,
            actions: result.actions,
          ),
        );
      });
      _scrollDown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _messages.add(
          const AIChatMessage(
            role: 'model',
            content:
                "Sorry, I'm having trouble right now. Please try again.\n"
                'معذرت، دوبارہ کوشش کریں۔',
          ),
        );
      });
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('AI error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _newChat() {
    setState(() {
      _messages.clear();
      _conversationId = null;
      _sending = false;
    });
  }

  // -- In-chat prescription upload (Rx triage flow) --------------------------

  /// Opens a bottom sheet to pick a prescription image, uploads it for AI
  /// extraction, and appends the result (items + safety flags) to the chat.
  Future<void> _openRxUpload() async {
    File? selected;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload prescription',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Our AI reads it, extracts the medicines and a pharmacist verifies it.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _rxSourceOption(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          final picked = await _picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 85,
                            maxWidth: 1200,
                          );
                          if (picked != null) selected = File(picked.path);
                          await _uploadRx(selected, source: 'camera');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _rxSourceOption(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          final picked = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                            maxWidth: 1200,
                          );
                          if (picked != null) selected = File(picked.path);
                          await _uploadRx(selected, source: 'gallery');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rxSourceOption({
    required IconData icon,
    required String label,
    required Future<void> Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadRx(File? file, {required String source}) async {
    if (file == null) return;
    setState(() => _uploadingRx = true);
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.path.split(Platform.pathSeparator).last;
      final pharmacyId =
          ref.read(selectedPharmacyProvider) ??
          (ref
              .read(pharmaciesProvider)
              .maybeWhen(
                data: (pharmacies) =>
                    pharmacies.isNotEmpty ? pharmacies.first.id : null,
                orElse: () => null,
              ));

      final prescription = await _rxService.uploadPrescription(
        widget.token,
        bytes,
        fileName,
        pharmacyId: pharmacyId,
        source: source,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          AIChatMessage(
            role: 'model',
            content: prescription.items.isNotEmpty
                ? 'I read your prescription. Here\u2019s what I found:'
                : 'I uploaded your prescription, but could not read any medicines from it. A pharmacist will review it manually.',
            prescription: prescription,
          ),
        );
      });
      _scrollDown();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Prescription upload failed: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingRx = false);
    }
  }

  /// Card shown in chat after an Rx upload: AI-extracted items with
  /// confidence, safety risk flags (duplicates / interactions), and a
  /// build-cart action that flows into the pharmacist-verify pipeline.
  Widget _buildPrescriptionCard(Prescription prescription) {
    final highRisk = prescription.hasHighRisk;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highRisk
              ? AppTheme.error.withValues(alpha: 0.5)
              : AppTheme.accentBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: AppTheme.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Prescription #${prescription.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusChip(prescription.status),
            ],
          ),
          if (prescription.items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No medicines extracted yet — waiting for pharmacist review.',
                style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
              ),
            )
          else ...[
            const SizedBox(height: 10),
            ...prescription.items.map(_prescriptionItemTile),
          ],
          ...prescription.riskFlags.map(_buildRiskFlag),
          if (prescription.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            _actionButton(
              label: '🛒 Build Cart from Prescription',
              onPressed: () => _buildCartFromRx(prescription),
            ),
            const SizedBox(height: 6),
            const Text(
              'A pharmacist will verify these items before the order is final.',
              style: TextStyle(
                color: AppTheme.mutedText,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _prescriptionItemTile(PrescriptionItem item) {
    final confidence = item.confidence;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (item.isAmbiguous)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Check name',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (confidence != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(confidence * 100).round()}%',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (item.dosage?.isNotEmpty ?? false)
            Text(
              'Dose: ${item.dosage}',
              style: const TextStyle(color: AppTheme.mutedText, fontSize: 11),
            ),
          if (item.frequency?.isNotEmpty ?? false)
            Text(
              'Frequency: ${item.frequency}',
              style: const TextStyle(color: AppTheme.mutedText, fontSize: 11),
            ),
          if (item.duration?.isNotEmpty ?? false)
            Text(
              'Duration: ${item.duration}',
              style: const TextStyle(color: AppTheme.mutedText, fontSize: 11),
            ),
          if (item.quantity != null)
            Text(
              'Quantity: ${item.quantity}',
              style: const TextStyle(color: AppTheme.mutedText, fontSize: 11),
            ),
        ],
      ),
    );
  }

  /// Safety flag from the backend copilot: duplicate ingredients or a known
  /// drug interaction on the same prescription.
  Widget _buildRiskFlag(PrescriptionRiskFlag flag) {
    final color = flag.isHigh ? AppTheme.error : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                flag.type == 'duplicate'
                    ? Icons.content_copy
                    : Icons.warning_amber,
                color: color,
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '⚠ ${flag.title}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            flag.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buildCartFromRx(Prescription prescription) async {
    setState(() => _sending = true);
    try {
      final unmatched = await _rxService.buildCartFromPrescription(
        widget.token,
        prescription.id,
      );
      ref.invalidate(cartProvider(widget.token));
      if (!mounted) return;
      setState(() {
        _sending = false;
        _messages.add(
          AIChatMessage(
            role: 'model',
            content: unmatched.isEmpty
                ? 'Done! I added all prescription items to your cart. Review it and place the order whenever you\u2019re ready.'
                : 'I added the items I could match to your cart. These could not be found in the catalog: ${unmatched.join(', ')}. A pharmacist can help with alternatives.',
          ),
        );
      });
      _scrollDown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Build cart failed: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // -- Conversation history ---------------------------------------------------

  Future<void> _openHistory() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Text(
                  'Chat history',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FutureBuilder<List<AIConversation>>(
                future: ref
                    .read(aiServiceProvider)
                    .listConversations(widget.token),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'Could not load history.\n${snapshot.error}',
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  final conversations =
                      snapshot.data ?? const <AIConversation>[];
                  if (conversations.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No previous chats yet.',
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: conversations.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: AppTheme.border, height: 1),
                      itemBuilder: (_, i) {
                        final c = conversations[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${c.messageCount} messages · ${_fmtDate(c.updatedAt)}',
                            style: const TextStyle(
                              color: AppTheme.mutedText,
                              fontSize: 11,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.mutedText,
                              size: 20,
                            ),
                            onPressed: () => _deleteConversation(c.id),
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _loadConversation(c.id);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadConversation(int id) async {
    setState(() => _sending = true);
    try {
      final detail = await ref
          .read(aiServiceProvider)
          .getConversation(widget.token, id);
      if (!mounted) return;
      setState(() {
        _conversationId = id;
        _messages
          ..clear()
          ..addAll(detail.messages);
        _sending = false;
      });
      _scrollDown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Could not open chat: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _deleteConversation(int id) async {
    try {
      await ref.read(aiServiceProvider).deleteConversation(widget.token, id);
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Chat deleted'),
          backgroundColor: AppTheme.surface,
        ),
      );
      if (_conversationId == id) _newChat();
      // Refresh the open history sheet by reopening it.
      Navigator.of(context).maybePop();
      _openHistory();
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Delete failed: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // -- Action cards ------------------------------------------------------------

  Widget _buildActionCard(AIAction action) {
    final result = action.result;
    switch (action.tool) {
      case 'search_medicines':
        return _medicinesListCard(result);
      case 'symptom_check':
        return _symptomCard(result);
      case 'get_medicine_details':
        return _medicineDetailCard(result);
      case 'add_to_cart':
      case 'remove_from_cart':
        return result['success'] == true
            ? _successCard(result['message']?.toString() ?? 'Done')
            : _errorCard(result['error']?.toString() ?? 'Action failed');
      case 'get_cart':
        return _cartCard(result);
      case 'prepare_order':
        return result['ready'] == true
            ? _orderPreviewCard(result)
            : _errorCard(result['error']?.toString() ?? 'Order not ready');
      case 'confirm_place_order':
        return result['success'] == true
            ? _orderPlacedCard(result)
            : _errorCard(
                result['error']?.toString() ?? 'Could not place order',
              );
      case 'get_my_orders':
        return _ordersListCard(result);
      case 'get_order_status':
        return _orderStatusCard(result);
      case 'get_my_addresses':
        return _addressesCard(result);
      case 'get_categories':
        return _categoriesCard(result);
      case 'get_user_profile':
        return _profileCard(result);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _card({
    required String title,
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  List<AIMedicine> _medicinesOf(Map<String, dynamic> result) {
    final raw = result['medicines'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => AIMedicine.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Widget _medicinesListCard(Map<String, dynamic> result) {
    final medicines = _medicinesOf(result);
    if (medicines.isEmpty) return _errorCard('No medicines found.');
    final pharmacy = result['pharmacy']?.toString();
    return _card(
      title:
          'Found ${result['found'] ?? medicines.length} medicine(s)'
          '${pharmacy != null && pharmacy.isNotEmpty ? ' — $pharmacy' : ''}',
      child: Column(children: medicines.map(_medicineTile).toList()),
    );
  }

  Widget _symptomCard(Map<String, dynamic> result) {
    if (result['needs_clarification'] == true) {
      return _card(
        title: '💡 A bit more detail needed',
        child: Text(
          result['question']?.toString() ??
              result['follow_up_question']?.toString() ??
              'Please describe your symptoms.',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      );
    }
    final children = <Widget>[
      Text(
        result['advice']?.toString() ?? '',
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
      ),
    ];
    final redFlag =
        result['red_flag']?.toString() ?? result['red_flag_text']?.toString();
    if ((redFlag?.isNotEmpty ?? false) || result['doctor_visit'] == true) {
      children.addAll([
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
          ),
          child: Text(
            '⚠️ See a doctor: ${redFlag ?? 'A doctor visit is recommended for this condition.'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ]);
    }
    final followUp = result['follow_up_question']?.toString();
    if (followUp != null && followUp.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 8),
        Text(
          followUp,
          style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ]);
    }
    final medicines = _medicinesOf(result);
    if (medicines.isNotEmpty) {
      children.addAll([
        const Divider(color: AppTheme.border, height: 20),
        const Text(
          'Recommended medicines',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...medicines.map(_medicineTile),
      ]);
    }
    return _card(
      title: '🩺 ${result['label'] ?? 'Symptom check'}',
      child: Column(children: children),
    );
  }

  Widget _medicineDetailCard(Map<String, dynamic> result) {
    if (result['error'] != null) return _errorCard(result['error'].toString());
    final available = result['available'] == true;
    return _card(
      title: '${result['name'] ?? ''} ${result['strength'] ?? ''}'.trim(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metaRows({
            if (result['generic_name'] != null)
              'Generic': result['generic_name'].toString(),
            if (result['brand'] != null &&
                result['brand'].toString().isNotEmpty)
              'Brand': result['brand'].toString(),
            if (result['category'] != null &&
                result['category'].toString().isNotEmpty)
              'Category': result['category'].toString(),
            'Form': result['form']?.toString() ?? 'N/A',
            'Price': _fmtPrice(_num(result['price'])),
            'Stock': available
                ? 'In stock · ${result['stock']} available'
                : 'Not available at this pharmacy',
            'Pharmacy': result['pharmacy']?.toString() ?? 'N/A',
          }),
          if (result['description']?.toString().isNotEmpty ?? false) ...[
            const Divider(color: AppTheme.border, height: 20),
            Text(
              result['description'].toString(),
              style: const TextStyle(
                color: AppTheme.mutedText,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
          if (available) ...[
            const SizedBox(height: 10),
            _actionButton(
              label: '+ Add to Cart',
              onPressed: () => _sendRaw(
                'Add ${result['name']} (ID: ${result['id']}) to my cart with quantity 1',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _medicineTile(AIMedicine m) {
    final available = m.available && m.stock > 0;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              MedicineDetailScreen(medicineId: m.id, token: widget.token),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${m.name}${m.strength != null && m.strength!.isNotEmpty ? ' ${m.strength}' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _rxBadge(m.requiresPrescription),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (m.genericName?.isNotEmpty ?? false) m.genericName!,
                      if (m.form?.isNotEmpty ?? false) m.form!,
                    ].join(' · '),
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  if (available)
                    Row(
                      children: [
                        Text(
                          _fmtPrice(m.price),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'In stock · ${m.stock}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Not available',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (available) ...[
              if (m.requiresPrescription) ...[
                _actionButton(
                  label: 'Rx',
                  compact: true,
                  primary: false,
                  onPressed: _openRxUpload,
                ),
                const SizedBox(width: 6),
              ],
              _actionButton(
                label: '+ Add',
                compact: true,
                onPressed: () => _sendRaw(
                  'Add ${m.name} (ID: ${m.id}) to my cart with quantity 1',
                ),
              ),
            ] else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _cartCard(Map<String, dynamic> result) {
    final items = _list(result['items']);
    if (items.isEmpty) return _errorCard('Your cart is empty.');
    return _card(
      title:
          '🛒 Cart (${result['item_count'] ?? items.length} items) — ${result['pharmacy'] ?? ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.map(
            (item) => _itemRow(
              '${item['medicine_name']} ${item['strength'] ?? ''} × ${item['quantity']}',
              _fmtPrice(_num(item['line_total'])),
            ),
          ),
          const Divider(color: AppTheme.border, height: 18),
          _itemRow('Subtotal', _fmtPrice(_num(result['subtotal'])), bold: true),
          const SizedBox(height: 10),
          _actionButton(
            label: 'View Cart',
            primary: false,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CartScreen(token: widget.token),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderPreviewCard(Map<String, dynamic> result) {
    final items = _list(result['items']);
    return _card(
      title: '🧾 Order Summary',
      borderColor: AppTheme.accentBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metaRows({
            'Pharmacy': result['pharmacy']?.toString() ?? '',
            'Address': result['address']?.toString() ?? '',
            'Payment': (result['payment_method'] ?? 'cod')
                .toString()
                .toUpperCase(),
          }),
          const Divider(color: AppTheme.border, height: 18),
          ...items.map(
            (item) => _itemRow(
              '${item['medicine_name']} ${item['strength'] ?? ''} × ${item['quantity']}',
              _fmtPrice(_num(item['line_total'])),
            ),
          ),
          const Divider(color: AppTheme.border, height: 18),
          _itemRow('Total', _fmtPrice(_num(result['subtotal'])), bold: true),
          const SizedBox(height: 10),
          _actionButton(
            label: '✔ Confirm & Place Order',
            onPressed: () => _sendRaw('Yes, confirm and place the order now.'),
          ),
        ],
      ),
    );
  }

  Widget _orderPlacedCard(Map<String, dynamic> result) {
    final orderId = result['order_id'];
    return _card(
      title: '✅ Order #$orderId Placed!',
      borderColor: AppTheme.primary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total: ${_fmtPrice(_num(result['total']))} · Status: ${result['status'] ?? ''}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _actionButton(
            label: 'View Orders',
            primary: false,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OrdersScreen(token: widget.token),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ordersListCard(Map<String, dynamic> result) {
    final orders = _list(result['orders']);
    if (orders.isEmpty) return _errorCard('No orders found.');
    return _card(
      title: '📦 Your Recent Orders (${result['count'] ?? orders.length})',
      child: Column(
        children: orders.map((o) {
          final status = o['status']?.toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.background.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${o['id']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusChip(status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${o['items_count']} items · ${_fmtPrice(_num(o['total']))} · ${o['pharmacy'] ?? ''}',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _fmtDate(
                    DateTime.tryParse(o['created_at']?.toString() ?? ''),
                  ),
                  style: TextStyle(
                    color: AppTheme.mutedText.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _orderStatusCard(Map<String, dynamic> result) {
    if (result['error'] != null) return _errorCard(result['error'].toString());
    final history = _list(result['status_history']);
    return _card(
      title: 'Order #${result['id']}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusChip(result['status']?.toString()),
          const SizedBox(height: 8),
          _metaRows({
            'Total': _fmtPrice(_num(result['total'])),
            'Subtotal': _fmtPrice(_num(result['subtotal'])),
            'Delivery fee': _fmtPrice(_num(result['delivery_fee'])),
            'Payment': (result['payment_method'] ?? '')
                .toString()
                .toUpperCase(),
            'Pharmacy': result['pharmacy']?.toString() ?? '',
            'Address': result['address']?.toString() ?? '',
          }),
          if (history.isNotEmpty) ...[
            const Divider(color: AppTheme.border, height: 18),
            ...history.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(h['status']?.toString()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${h['status']} · ${_fmtDate(DateTime.tryParse(h['time']?.toString() ?? ''))}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addressesCard(Map<String, dynamic> result) {
    final addresses = _list(result['addresses']);
    if (addresses.isEmpty) return _errorCard('No saved addresses.');
    return _card(
      title: '🏠 Saved Addresses',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: addresses.map((a) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      a['label']?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (a['is_default'] == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${a['address_line']}, ${a['city']}',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _categoriesCard(Map<String, dynamic> result) {
    final categories = _list(result['categories']);
    if (categories.isEmpty) return _errorCard('No categories found.');
    return _card(
      title: '🗂️ Categories',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories.map((c) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              c['name']?.toString() ?? '',
              style: const TextStyle(color: AppTheme.primary, fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _profileCard(Map<String, dynamic> result) {
    return _card(
      title: '👤 Your Profile',
      child: _metaRows({
        'Username': result['username']?.toString() ?? '',
        'Email': result['email']?.toString() ?? '',
        'Phone': result['phone']?.toString() ?? '',
        'Wallet': _fmtPrice(_num(result['wallet_balance'])),
      }),
    );
  }

  Widget _successCard(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Small shared widgets -----------------------------------------------------

  Widget _actionButton({
    required String label,
    required VoidCallback onPressed,
    bool primary = true,
    bool compact = false,
  }) {
    return SizedBox(
      height: compact ? 32 : 38,
      child: FilledButton(
        onPressed: _sending ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? AppTheme.primary : AppTheme.surface,
          foregroundColor: primary ? AppTheme.background : AppTheme.primary,
          side: primary
              ? null
              : BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _rxBadge(bool requiresPrescription) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: requiresPrescription
            ? AppTheme.error.withValues(alpha: 0.15)
            : AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        requiresPrescription ? 'Rx' : 'OTC',
        style: TextStyle(
          color: requiresPrescription ? AppTheme.error : AppTheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusChip(String? status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        (status ?? 'unknown').replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _itemRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? Colors.white : AppTheme.mutedText,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: bold ? AppTheme.primary : Colors.white,
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRows(Map<String, String> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  '${e.key}:',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  e.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // -- Helpers -------------------------------------------------------------------

  List<Map<String, dynamic>> _list(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map(
          (e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
        )
        .toList();
  }

  double _num(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String _fmtPrice(double price) {
    final hasFraction = price > 0 && price % 1 != 0;
    return 'Rs ${price.toStringAsFixed(hasFraction ? 2 : 0)}';
  }

  static const _months = [
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
    'Dec',
  ];

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${_months[local.month - 1]} ${local.day}, $hour:$minute';
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
        return Colors.lightBlue;
      case 'preparing':
      case 'packed':
        return Colors.purpleAccent;
      case 'out_for_delivery':
      case 'on_the_way':
        return Colors.amber;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.mutedText;
    }
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
