import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class VoiceTransactionScreen extends StatefulWidget {
  const VoiceTransactionScreen({super.key});

  @override
  State<VoiceTransactionScreen> createState() => _VoiceTransactionScreenState();
}

class _VoiceTransactionScreenState extends State<VoiceTransactionScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _transcript = "";
  double? _detectedAmount;
  String? _detectedType;
  String? _detectedCategory;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (val) => setState(() => _isListening = val == 'listening'),
      onError: (val) => setState(() => _isListening = false),
    );
    if (!available) {
      setState(() => _isListening = false);
    }
  }

  void _startListening() async {
    setState(() {
      _transcript = "";
      _detectedAmount = null;
      _detectedType = null;
      _detectedCategory = null;
    });
    await _speech.listen(
      onResult: (val) => setState(() {
        _transcript = val.recognizedWords;
        _parseTranscript(_transcript);
      }),
      localeId: 'fr_FR', // Force le français
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  // 🧠 Analyse basique de la phrase (Regex)
  void _parseTranscript(String text) {
    final lowerText = text.toLowerCase();

    // 1. Détecter le type
    if (lowerText.contains('dépense') ||
        lowerText.contains('payé') ||
        lowerText.contains('acheté')) {
      _detectedType = 'depense';
    } else if (lowerText.contains('revenu') ||
        lowerText.contains('reçu') ||
        lowerText.contains('gagné')) {
      _detectedType = 'revenu';
    }

    // 2. Détecter le montant (cherche un nombre)
    final numberRegex = RegExp(r'(\d+[\s]?\d*)');
    final match = numberRegex.firstMatch(lowerText.replaceAll(' ', ''));
    if (match != null) {
      final amountStr = match.group(0)?.replaceAll(' ', '');
      _detectedAmount = double.tryParse(amountStr ?? '');
    }

    // 3. Détecter la catégorie (mots-clés simples)
    if (lowerText.contains('transport') ||
        lowerText.contains('taxi') ||
        lowerText.contains('bus')) {
      _detectedCategory = 'Transport';
    } else if (lowerText.contains('nourriture') ||
        lowerText.contains('manger') ||
        lowerText.contains('resto')) {
      _detectedCategory = 'Alimentation';
    } else if (lowerText.contains('salaire') || lowerText.contains('paie')) {
      _detectedCategory = 'Salaire';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Saisie vocale'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Affichage de la transcription
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _transcript.isEmpty
                        ? "Appuyez sur le micro et dictez..."
                        : _transcript,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: _transcript.isEmpty
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color:
                          _transcript.isEmpty ? Colors.grey : TAPAColors.navy,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Résumé de l'analyse
                  if (_detectedAmount != null || _detectedType != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TAPAColors.gold.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (_detectedType != null)
                            Text(
                                "Type : ${_detectedType == 'depense' ? 'Dépense' : 'Revenu'}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          if (_detectedAmount != null)
                            Text(
                                "Montant : ${_detectedAmount!.toStringAsFixed(0)} FCFA",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          if (_detectedCategory != null)
                            Text("Catégorie suggérée : $_detectedCategory"),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            // Bouton Micro
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.red : TAPAColors.gold,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : TAPAColors.gold)
                          .withAlpha(100),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isListening ? "Écoute en cours..." : "Appuyez pour parler",
              style: TextStyle(
                  color: _isListening ? Colors.red : Colors.grey,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // Bouton de confirmation
            if (_transcript.isNotEmpty && !_isListening)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // ✅ Redirection avec les données pré-remplies
                    context.push('/add-transaction', extra: {
                      'montant': _detectedAmount,
                      'type': _detectedType ?? 'depense',
                      'categorieLabel': _detectedCategory,
                      'note': _transcript,
                    });
                    // context.push('/add-transaction', extra: {...}); // À décommenter quand la route sera prête
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TAPAColors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Confirmer et continuer",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
