import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:provider/provider.dart';
import 'package:homecare_app/providers/time_provider.dart';
import 'package:homecare_app/providers/signature_provider.dart';
import 'package:homecare_app/widgets/custom_button.dart';
import 'package:homecare_app/widgets/loading_widget.dart';
import 'package:homecare_app/screens/home/home_screen.dart';
import 'package:homecare_app/core/utils/globals.dart';
import 'package:homecare_app/core/theme/app_style.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  late SignatureController _caregiverController;
  late SignatureController _policyholderController;

  bool _caregiverSigned = false;
  bool _policyholderSigned = false;
  bool _isLoading = false;
  bool _saved = false; // true only after signatures are actually saved

  @override
  void initState() {
    super.initState();
    _caregiverController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.blue,
      exportBackgroundColor: Colors.white,
    );
    _policyholderController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.blue,
      exportBackgroundColor: Colors.white,
    );

    _caregiverController.addListener(() {
      if (mounted) {
        setState(() {
          _caregiverSigned = _caregiverController.isNotEmpty;
        });
      }
    });

    _policyholderController.addListener(() {
      if (mounted) {
        setState(() {
          _policyholderSigned = _policyholderController.isNotEmpty;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingSignatures();
    });
  }

  Future<void> _loadExistingSignatures() async {
    final timeProvider = Provider.of<TimeProvider>(context, listen: false);
    final signatureProvider =
        Provider.of<SignatureProvider>(context, listen: false);

    if (timeProvider.currentEntryId != null) {
      await signatureProvider.getSignature(timeProvider.currentEntryId!);

      if (signatureProvider.signature != null && mounted) {
        final cg = signatureProvider.signature!.caregiverSignature;
        final ph = signatureProvider.signature!.policyholderSignature;
        setState(() {
          _caregiverSigned = cg.isNotEmpty;
          _policyholderSigned = ph.isNotEmpty;
          // Only treat as "saved/completed" when BOTH are actually present.
          _saved = cg.isNotEmpty && ph.isNotEmpty;
        });
      }
    }
  }

  @override
  void dispose() {
    _caregiverController.dispose();
    _policyholderController.dispose();
    super.dispose();
  }

  Future<void> _saveSignatures() async {
    final timeProvider = Provider.of<TimeProvider>(context, listen: false);
    final signatureProvider =
        Provider.of<SignatureProvider>(context, listen: false);

    if (timeProvider.currentEntryId == null) {
      Globals.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Please time-in first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_caregiverSigned || !_policyholderSigned) {
      Globals.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Please provide both signatures!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final caregiverSignature = await _caregiverController.toPngBytes();
      final policyholderSignature = await _policyholderController.toPngBytes();

      if (caregiverSignature == null || policyholderSignature == null) {
        Globals.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Failed to capture signatures. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final caregiverBase64 =
          'data:image/png;base64,${base64Encode(caregiverSignature)}';
      final policyholderBase64 =
          'data:image/png;base64,${base64Encode(policyholderSignature)}';

      final response = await signatureProvider.saveSignature(
        timeEntryId: timeProvider.currentEntryId!,
        caregiverSignature: caregiverBase64,
        policyholderSignature: policyholderBase64,
      );

      if (!mounted) return;

      if (!response.status) {
        Globals.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      } else {
        Globals.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('✅ Signatures saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadExistingSignatures();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      Globals.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearSignatures() {
    _caregiverController.clear();
    _policyholderController.clear();
    setState(() {
      _caregiverSigned = false;
      _policyholderSigned = false;
    });
  }

  // Decode a base64 signature safely — never throws on empty/corrupt data.
  Widget _safeSigImage(String base64Image, {BoxFit fit = BoxFit.contain}) {
    try {
      var raw = base64Image.contains(',')
          ? base64Image.split(',').last
          : base64Image;
      raw = raw.trim();
      if (raw.isEmpty) return _sigPlaceholder();
      final mod = raw.length % 4;
      if (mod != 0) raw = raw.padRight(raw.length + (4 - mod), '=');
      return Image.memory(
        base64Decode(raw),
        fit: fit,
        errorBuilder: (_, __, ___) => _sigPlaceholder(),
      );
    } catch (_) {
      return _sigPlaceholder();
    }
  }

  Widget _sigPlaceholder() {
    return Center(
      child: Text(
        'No signature',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildSignaturePreview(String label, String base64Image) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _safeSigImage(base64Image),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final signatureProvider = Provider.of<SignatureProvider>(context);
    final bool canSave = _caregiverSigned && _policyholderSigned;

    if (_isLoading || signatureProvider.isLoading) {
      return const LoadingWidget();
    }

    if (_saved &&
        signatureProvider.signature != null &&
        signatureProvider.signature!.caregiverSignature.isNotEmpty &&
        signatureProvider.signature!.policyholderSignature.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Signatures',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppStyle.primaryDark,
          elevation: 0,
          centerTitle: false,
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppStyle.canvasTop, AppStyle.canvasBottom],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade100, width: 8),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Capture Completed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Signature Capture Completed. Kindly go to the Report page.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildSignaturePreview(
                      'Caregiver',
                      signatureProvider.signature!.caregiverSignature,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSignaturePreview(
                      'Policyholder',
                      signatureProvider.signature!.policyholderSignature,
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: CustomButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HomeScreen(initialIndex: 0)),
                      (route) => false,
                    );
                  },
                  text: '🏠 Go to Dashboard',
                  color: Colors.blue.shade700,
                  isFullWidth: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Signatures',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppStyle.primaryDark,
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _clearSignatures,
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppStyle.canvasTop, AppStyle.canvasBottom],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Caregiver Signature',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _caregiverSigned
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _caregiverSigned
                                    ? Icons.check_circle
                                    : Icons.pending,
                                size: 14,
                                color: _caregiverSigned
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _caregiverSigned ? 'Signed' : 'Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _caregiverSigned
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _caregiverSigned
                          ? '✅ Signature captured successfully'
                          : '✍️ Draw your signature on the pad above',
                      style: TextStyle(
                        fontSize: 12,
                        color: _caregiverSigned
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (signatureProvider.signature != null &&
                        signatureProvider
                            .signature!.caregiverSignature.isNotEmpty &&
                        !_caregiverSigned)
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.green.shade300, width: 2),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _safeSigImage(
                              signatureProvider.signature!.caregiverSignature),
                        ),
                      )
                    else
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _caregiverSigned
                                ? Colors.green.shade300
                                : Colors.grey.shade300,
                            width: _caregiverSigned ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Signature(
                          controller: _caregiverController,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _caregiverController.clear();
                            setState(() {
                              _caregiverSigned = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Policyholder Signature',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _policyholderSigned
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _policyholderSigned
                                    ? Icons.check_circle
                                    : Icons.pending,
                                size: 14,
                                color: _policyholderSigned
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _policyholderSigned ? 'Signed' : 'Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _policyholderSigned
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _policyholderSigned
                          ? '✅ Signature captured successfully'
                          : '✍️ Draw your signature on the pad above',
                      style: TextStyle(
                        fontSize: 12,
                        color: _policyholderSigned
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (signatureProvider.signature != null &&
                        signatureProvider
                            .signature!.policyholderSignature.isNotEmpty &&
                        !_policyholderSigned)
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.green.shade300, width: 2),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _safeSigImage(signatureProvider
                              .signature!.policyholderSignature),
                        ),
                      )
                    else
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _policyholderSigned
                                ? Colors.green.shade300
                                : Colors.grey.shade300,
                            width: _policyholderSigned ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Signature(
                          controller: _policyholderController,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _policyholderController.clear();
                            setState(() {
                              _policyholderSigned = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                onPressed: canSave ? _saveSignatures : null,
                text: '💾 Save Signatures',
                isFullWidth: true,
                color: canSave ? Colors.blue.shade700 : Colors.grey,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please sign using your finger or stylus on the above pads.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
