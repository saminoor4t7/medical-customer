import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../main.dart';
import '../cart/provider.dart';
import '../pharmacy/provider.dart';
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
  int? _prescriptionId;

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
        _prescriptionId = null;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedImage == null) return;

    setState(() {
      _uploading = true;
      _resultMessage = null;
      _uploadSuccess = false;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final fileName = _selectedImage!.path.split(Platform.pathSeparator).last;

      // Get selected pharmacy or prompt user
      final selectedNotifier = ref.read(selectedPharmacyProvider);
      int? pharmacyId = selectedNotifier.value;

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

      final result = await _service.uploadPrescription(
        widget.token,
        bytes,
        fileName,
        pharmacyId: pharmacyId,
        source: 'gallery',
      );

      _prescriptionId = result['id'] is num
          ? (result['id'] as num).toInt()
          : int.tryParse(result['id'].toString());

      final aiResponse = result['ai_raw_response'];
      final status = result['status']?.toString() ?? '';

      setState(() {
        _resultMessage = aiResponse != null
            ? 'AI Analysis Complete!\n\n$aiResponse'
            : 'Prescription uploaded successfully. '
                'Status: $status\n'
                'A pharmacist will review and verify your prescription.';
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
    if (_prescriptionId == null) return;

    setState(() => _buildingCart = true);

    try {
      await _service.buildCartFromPrescription(
        widget.token,
        _prescriptionId!,
      );

      // Invalidate cart so it reloads with new items
      ref.invalidate(cartProvider(widget.token));

      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Cart built from prescription! Check your cart.'),
            backgroundColor: teal,
            duration: Duration(seconds: 2),
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
                    color: teal.withOpacity(0.3),
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
                              color: teal.withOpacity(0.10),
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
                  disabledBackgroundColor: teal.withOpacity(0.3),
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
                        ? Colors.red.withOpacity(0.3)
                        : teal.withOpacity(0.3),
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
                          color: !_uploadSuccess
                              ? Colors.redAccent
                              : teal,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          !_uploadSuccess
                              ? 'Error'
                              : 'Result',
                          style: TextStyle(
                            color: !_uploadSuccess
                                ? Colors.redAccent
                                : teal,
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
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Build Cart button ──
            if (_prescriptionId != null && _uploadSuccess) ...[
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
          border: Border.all(color: teal.withOpacity(0.25)),
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
          color: teal.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: teal.withOpacity(0.25)),
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