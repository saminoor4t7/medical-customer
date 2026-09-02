import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../main.dart';
import '../cart/provider.dart';
import '../pharmacy/provider.dart';
import 'model.dart';
import 'services.dart';

class PrescriptionUploadScreen extends ConsumerStatefulWidget {
  const PrescriptionUploadScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<PrescriptionUploadScreen> createState() =>
      _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState
    extends ConsumerState<PrescriptionUploadScreen> {
  static const Color navy = Color(0xFF061A33);
  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);

  final _picker = ImagePicker();
  final _service = PrescriptionService();

  File? _selectedImage;
  bool _uploading = false;
  String? _resultMessage;
  bool _uploadSuccess = false;
  bool _buildingCart = false;
  Prescription? _prescription;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _resultMessage = null;
        _prescription = null;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedImage == null) return;

    setState(() {
      _uploading = true;
      _resultMessage = null;
      _uploadSuccess = false;
      _prescription = null;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final fileName = _selectedImage!.path.split(Platform.pathSeparator).last;

      // Get selected pharmacy or prompt user
      int? pharmacyId = ref.read(selectedPharmacyProvider);

      if (pharmacyId == null) {
        pharmacyId = autoSelectPharmacy(ref);
        if (pharmacyId == null) {
          setState(() {
            _uploading = false;
            _resultMessage = 'A pharmacy must be selected to upload a prescription.';
          });
          return;
        }
      }

      final prescription = await _service.uploadPrescription(
        widget.token,
        bytes,
        fileName,
        pharmacyId: pharmacyId,
        source: 'gallery',
      );

      setState(() {
        _prescription = prescription;
        _resultMessage = prescription.items.isNotEmpty
            ? 'AI read ${prescription.items.length} medicine(s) from your prescription.\n'
                'A pharmacist will verify before the order is final.'
            : 'Prescription uploaded successfully (status: ${prescription.status ?? 'processing'}).\n'
                'AI could not read medicines from it — a pharmacist will review manually.';
        _uploadSuccess = true;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Upload failed: ${e.toString()}';
        _uploadSuccess = false;
      });
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _buildCart() async {
    final prescription = _prescription;
    if (prescription == null) return;

    setState(() => _buildingCart = true);

    try {
      final unmatched = await _service.buildCartFromPrescription(
        widget.token,
        prescription.id,
      );

      // Invalidate cart so it reloads with new items
      ref.invalidate(cartProvider(widget.token));

      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              unmatched.isEmpty
                  ? 'Cart built from prescription! Check your cart.'
                  : 'Cart built, but these items need a pharmacist: ${unmatched.join(', ')}',
            ),
            backgroundColor: teal,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to build cart: ${e.toString()}'),
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _buildingCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Upload Prescription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF079B83), Color(0xFF0877A0)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI-Powered Prescription Reader',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Upload a photo and our AI will read your\nprescription & build your cart automatically',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Image Preview / Pick Area ──
            GestureDetector(
              onTap: _selectedImage == null
                  ? () => _showImageSourceDialog()
                  : () => _showImageSourceDialog(),
              child: Container(
                width: double.infinity,
                height: _selectedImage != null ? 250 : 180,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: teal.withValues(alpha:0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: teal.withValues(alpha:0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              color: teal,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Tap to select a photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Camera or Gallery',
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Pick source buttons ──
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Upload button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _selectedImage != null && !_uploading
                    ? _upload
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: navy,
                  disabledBackgroundColor: teal.withValues(alpha:0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _uploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: navy,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Upload & Analyze with AI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // ── Result section ──
            if (_resultMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: !_uploadSuccess
                        ? Colors.red.withValues(alpha: 0.3)
                        : teal.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          !_uploadSuccess
                              ? Icons.error_outline
                              : Icons.check_circle,
                          color: !_uploadSuccess ? Colors.redAccent : teal,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          !_uploadSuccess ? 'Error' : 'Result',
                          style: TextStyle(
                            color: !_uploadSuccess ? Colors.redAccent : teal,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _resultMessage!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // ── AI-extracted items + safety flags ──
            if (_prescription != null && _uploadSuccess) ...[
              const SizedBox(height: 16),
              _ExtractionCard(prescription: _prescription!),
            ],
            
            // ── Build Cart button ──
            if (_prescription != null && _uploadSuccess) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _buildingCart ? null : _buildCart,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0877A0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _buildingCart
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Build Cart from Prescription',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'A pharmacist will verify the items before final order',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _DialogOption(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogOption(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
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
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: teal.withValues(alpha:0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: teal, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogOption extends StatelessWidget {
  const _DialogOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const Color teal = Color(0xFF00C9A7);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: teal.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: teal, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the AI-extracted medicine lines and the copilot safety flags
/// (duplicate ingredients / drug interactions) for one prescription.
class _ExtractionCard extends StatelessWidget {
  const _ExtractionCard({required this.prescription});

  final Prescription prescription;

  static const Color cardColor = Color(0xFF09243D);
  static const Color teal = Color(0xFF00C9A7);
  static const Color muted = Color(0xFF9AAEC3);
  static const Color border = Color(0xFF1D3C5B);
  static const Color error = Color(0xFFB8404A);

  @override
  Widget build(BuildContext context) {
    final highRisk = prescription.hasHighRisk;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highRisk ? error.withValues(alpha: 0.5) : teal.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: teal, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Extraction & Safety Check',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusBadge(prescription.status),
            ],
          ),
          if (prescription.doctorName?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Doctor: ${prescription.doctorName}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          ...prescription.items.map(_itemTile),
          ...prescription.riskFlags.map(_riskFlag),
          if (prescription.riskFlags.isEmpty && prescription.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.verified_outlined, color: teal.withValues(alpha: 0.8), size: 15),
                  const SizedBox(width: 6),
                  const Text(
                    'No duplicate-ingredient or interaction flags found.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String? status) {
    final color = switch (status) {
      'verified' => Colors.green,
      'needs_review' => Colors.orange,
      'rejected' => error,
      'processing' => Colors.lightBlueAccent,
      _ => muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        (status ?? 'unknown').replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _itemTile(PrescriptionItem item) {
    final confidence = item.confidence;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF061A33).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
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
                _chip('Check name', Colors.orange)
              else if (confidence != null)
                _chip('${(confidence * 100).round()}%', teal),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            [
              if (item.dosage?.isNotEmpty ?? false) 'Dose: ${item.dosage}',
              if (item.frequency?.isNotEmpty ?? false) 'Freq: ${item.frequency}',
              if (item.duration?.isNotEmpty ?? false) 'Dur: ${item.duration}',
              if (item.quantity != null) 'Qty: ${item.quantity}',
            ].join('  ·  '),
            style: const TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _riskFlag(PrescriptionRiskFlag flag) {
    final color = flag.isHigh ? error : Colors.orange;
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
                flag.type == 'duplicate' ? Icons.content_copy : Icons.warning_amber,
                color: color,
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  flag.title,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),          const SizedBox(height: 4),
          Text(flag.message, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}