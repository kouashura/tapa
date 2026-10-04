// lib/screens/transactions/scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/db_service_mysql.dart';
import '../../data/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final DBService _db = DBService();
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isProcessing = false;
  String _result = '';
  List<Map<String, dynamic>> _detectedItems = [];

  @override
  void initState() {
    super.initState();
    // Initialiser le TextRecognizer
    _textRecognizer;
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    await _processImage(image);
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    await _processImage(image);
  }

  Future<void> _processImage(XFile image) async {
    // ✅ CORRECTION: Vérifier mounted avant setState
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _result = 'Analyse en cours...';
      _detectedItems = [];
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text;

      // ✅ CORRECTION: Vérifier mounted après await
      if (!mounted) return;

      setState(() {
        _result = text;
        _detectedItems = _parseText(text);
        _isProcessing = false;
      });
    } catch (e) {
      Logger.error('❌ Erreur analyse image: $e');

      // ✅ CORRECTION: Vérifier mounted après await
      if (!mounted) return;

      setState(() {
        _result = 'Erreur: $e';
        _isProcessing = false;
      });
    }
  }

  List<Map<String, dynamic>> _parseText(String text) {
    final items = <Map<String, dynamic>>[];
    final lines = text.split('\n');
    for (final line in lines) {
      final regExp = RegExp(r'(\d[\d\s]*\d|\d+)');
      final match = regExp.firstMatch(line);
      if (match != null) {
        final numStr = match.group(1)!.replaceAll(' ', '');
        final montant = double.tryParse(numStr);
        if (montant != null && montant > 0) {
          items.add({
            'montant': montant,
            'description': line.replaceAll(regExp, '').trim(),
          });
        }
      }
    }
    return items;
  }

  // ==========================================================
  // ✅ MÉTHODE CREATE TRANSACTION - COMPLÈTEMENT CORRIGÉE
  // ==========================================================
  Future<void> _createTransaction(Map<String, dynamic> item) async {
    final wallets = await _db.getWallets();

    // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
    if (!mounted) return;

    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Créez d\'abord un portefeuille'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    final montant = item['montant'] as double;
    final description = item['description'] as String? ?? '';
    final userId = _db.getCurrentUserId() ?? '';

    final tx = TransactionModel(
      id: Fmt.genId(),
      uid: userId,
      walletId: wallets.first.id,
      montant: montant,
      type: TransactionType.depense,
      categorieId: 'autre',
      categorieLabel: 'Autre',
      categorieEmoji: '📌',
      note: description.isNotEmpty ? description : null,
      dateTransaction: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await _db.addTransaction(tx);

    // ✅ CORRECTION: Vérifier mounted après await
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction enregistrée !'),
        backgroundColor: TAPAColors.green,
      ),
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final user = _db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Scanner'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAPAColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Appareil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAPAColors.gold,
                      foregroundColor: TAPAColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isProcessing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text('Analyse en cours...'),
            ],
            if (_result.isNotEmpty) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Texte reconnu :',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: TAPAColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TAPAColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _result,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_detectedItems.isNotEmpty) ...[
                        const Text(
                          'Montants détectés :',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: TAPAColors.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._detectedItems.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TAPAColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: TAPAColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Fmt.montant(item['montant'], monnaie: monnaie),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: TAPAColors.red,
                                      ),
                                    ),
                                    if (item['description'] != null &&
                                        item['description'].toString().isNotEmpty)
                                      Text(
                                        item['description'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: TAPAColors.textSecond,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: TAPAColors.green,
                                ),
                                onPressed: () => _createTransaction(item),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}