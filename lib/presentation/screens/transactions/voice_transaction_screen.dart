import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/db_service_mysql.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/formatters.dart';

class VoiceTransactionScreen extends StatefulWidget {
  const VoiceTransactionScreen({super.key});
  @override
  State<VoiceTransactionScreen> createState() =>
      _VoiceTransactionScreenState();
}

class _VoiceTransactionScreenState
    extends State<VoiceTransactionScreen> {
  final SpeechToText _speech = SpeechToText();
  final DBService _db = DBService();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _texteReconnu = '';
  String _statut = 'Appuie sur le micro pour parler';
  double? _montant;
  TransactionType _type = TransactionType.depense;
  String _categorieId = 'autre';
  String _categorieLabel = 'Autre';
  String _categorieEmoji = '📌';
  String? _walletId;

  // ✅ État pour les portefeuilles
  List<WalletModel> _wallets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initWallet();
  }

  // ✅ CORRIGÉ : async + await
  Future<void> _initWallet() async {
    try {
      final wallets = await _db.getWallets();
      setState(() {
        _wallets = wallets.where((w) => w != null).cast<WalletModel>().toList();
        if (_wallets.isNotEmpty) _walletId = _wallets.first.id;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
          onError: (e) => setState(() =>
          _statut = 'Erreur microphone. Vérifie les permissions.'));
      setState(() {});
    } catch (e) {
      setState(() => _statut = 'Microphone non disponible.');
    }
  }

  Future<void> _ecouter() async {
    if (!_speechAvailable) {
      setState(() => _statut = 'Microphone non disponible. Vérifie les permissions.');
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() {
      _isListening = true;
      _texteReconnu = '';
      _montant = null;
      _statut = 'J écoute... Parle maintenant !';
    });
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _texteReconnu = result.recognizedWords;
          if (result.finalResult) {
            _isListening = false;
            _analyserTexte(_texteReconnu);
          }
        });
      },
      localeId: 'fr_FR',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 4),
    );
  }

  void _analyserTexte(String texte) {
    final t = texte.toLowerCase();
    setState(() => _statut = 'Analyse en cours...');

    final regExp = RegExp(r'(\d[\d\s]*\d|\d+)');
    final match = regExp.firstMatch(t);
    if (match != null) {
      final numStr = match.group(1)!.replaceAll(' ', '');
      _montant = double.tryParse(numStr);
    }

    final motsRevenu = ['reçu','salaire','gagne','revenu','rentre','percu','touche'];
    _type = TransactionType.depense;
    for (final m in motsRevenu) {
      if (t.contains(m)) {
        _type = TransactionType.revenu;
        break;
      }
    }

    final userCats = _db.getCategories();
    final isRevenu = _type == TransactionType.revenu;
    final cats = isRevenu
        ? userCats.where((c) => c['type'] == 'revenu').toList()
        : userCats.where((c) => c['type'] == 'depense' || c['type'] == 'dépense').toList();

    final motsCles = {
      'nourriture': ['repas','manger','dejeuner','diner','restaurant','nourriture','pain','riz','maquis'],
      'transport': ['transport','taxi','bus','carburant','essence','moto','woro'],
      'courses': ['courses','marche','supermarche','achat','shop'],
      'facture': ['facture','electricite','eau','internet','cie','sodeci','abonnement'],
      'ecole': ['ecole','scolarite','formation','livre','cahier','frais scolaire'],
      'sante': ['sante','medecin','pharmacie','medicament','hopital','clinique'],
      'maison': ['maison','loyer','menage','proprio'],
      'loisirs': ['loisir','cinema','fete','sortie','plaisir'],
      'tontine': ['tontine','cotisation','tour'],
      'telephone': ['telephone','credit','recharge','airtime'],
      'salaire': ['salaire','paie','traitement'],
      'business': ['business','vente','commerce','benefice'],
    };

    bool trouve = false;
    for (final cat in cats) {
      final label = (cat['label'] ?? '').toLowerCase();
      if (t.contains(label)) {
        _categorieId = cat['id'] ?? 'autre';
        _categorieLabel = cat['label'] ?? 'Autre';
        _categorieEmoji = cat['emoji'] ?? '📌';
        trouve = true;
        break;
      }
    }

    if (!trouve) {
      for (final entry in motsCles.entries) {
        for (final mot in entry.value) {
          if (t.contains(mot)) {
            final catUser = cats.firstWhere(
                    (c) => (c['id'] ?? '').contains(entry.key) ||
                    (c['label'] ?? '').toLowerCase().contains(entry.key),
                orElse: () => <String, String>{});
            if (catUser.isNotEmpty) {
              _categorieId = catUser['id'] ?? 'autre';
              _categorieLabel = catUser['label'] ?? 'Autre';
              _categorieEmoji = catUser['emoji'] ?? '📌';
            } else {
              _categorieId = entry.key;
              _categorieLabel = entry.key;
              _categorieEmoji = '📌';
            }
            trouve = true;
            break;
          }
        }
        if (trouve) break;
      }
    }

    if (!trouve && cats.isNotEmpty) {
      _categorieId = cats.first['id'] ?? 'autre';
      _categorieLabel = cats.first['label'] ?? 'Autre';
      _categorieEmoji = cats.first['emoji'] ?? '📌';
    }

    setState(() {
      _statut = _montant != null
          ? 'Transaction détectée ! Vérifie et confirme.'
          : 'Montant non détecté. Reessaie en disant le chiffre clairement.';
    });
  }

  Future<void> _enregistrer() async {
    if (_montant == null || _walletId == null) return;
    try {
      final userId = _db.getCurrentUserId();

      final tx = TransactionModel(
        id: Fmt.genId(),
        uid: userId ?? '',
        walletId: _walletId!,
        montant: _montant!,
        type: _type,
        categorieId: _categorieId,
        categorieLabel: _categorieLabel,
        categorieEmoji: _categorieEmoji,
        note: null,
        dateTransaction: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _db.addTransaction(tx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Transaction enregistree !'),
                backgroundColor: TAPAColors.green));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: TAPAColors.red,
                duration: const Duration(seconds: 4)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';
    final isRevenu = _type == TransactionType.revenu;

    // ✅ Utiliser _wallets déjà chargé
    final wallets = _wallets;

    final userCats = _db.getCategories();
    final cats = isRevenu
        ? userCats.where((c) => c['type'] == 'revenu').toList()
        : userCats.where((c) => c['type'] == 'depense' || c['type'] == 'dépense').toList();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: TAPAColors.navy,
        appBar: AppBar(
          backgroundColor: TAPAColors.navy,
          foregroundColor: TAPAColors.white,
          title: const Text('Dictee vocale'),
          leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(false)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        backgroundColor: TAPAColors.navy,
        appBar: AppBar(
            backgroundColor: TAPAColors.navy,
            foregroundColor: TAPAColors.white,
            title: const Text('Dictee vocale'),
            leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false))),
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const SizedBox(height: 16),
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(14)),
                      child: Column(children: [
                        const Text('Exemples de phrases :',
                            style: TextStyle(color: Colors.white70,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...[
                          '"Dépense 2000 pour le repas"',
                          '"Reçu 50000 de salaire"',
                          '"Paye 5000 pour le transport"',
                          '"Gagne 100000 business"',
                        ].map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(e,
                                style: const TextStyle(color: TAPAColors.gold,
                                    fontSize: 12, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center))),
                      ])),
                  const SizedBox(height: 32),

                  GestureDetector(
                      onTap: _ecouter,
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _isListening ? 120 : 100,
                          height: _isListening ? 120 : 100,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening ? TAPAColors.red : TAPAColors.gold,
                              boxShadow: _isListening ? [
                                BoxShadow(color: TAPAColors.red.withOpacity(0.4),
                                    blurRadius: 20, spreadRadius: 5)
                              ] : []),
                          child: Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              size: 48, color: TAPAColors.white))),
                  const SizedBox(height: 16),
                  Text(_statut,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center),

                  if (_texteReconnu.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          const Text('Tu as dit :',
                              style: TextStyle(color: Colors.white54, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('"$_texteReconnu"',
                              style: const TextStyle(color: TAPAColors.white,
                                  fontSize: 14, fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center),
                        ])),
                  ],

                  if (_montant != null) ...[
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: TAPAColors.surface,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(children: [
                          Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_categorieEmoji.length <= 2 ? '📝' : _categorieEmoji,
                                    style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 10),
                                Column(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "${isRevenu ? '+' : '-'}${Fmt.montant(_montant!, monnaie: monnaie)}",
                                          style: TextStyle(fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: isRevenu ? TAPAColors.green : TAPAColors.red)),
                                      Text(
                                          "${isRevenu ? 'Revenu' : 'Dépense'} · $_categorieLabel",
                                          style: const TextStyle(fontSize: 12,
                                              color: TAPAColors.textSecond)),
                                    ]),
                              ]),
                          const SizedBox(height: 12),

                          if (cats.isNotEmpty)
                            DropdownButtonFormField<String>(
                                value: cats.any((c) => c['id'] == _categorieId)
                                    ? _categorieId : cats.first['id'],
                                decoration: const InputDecoration(
                                    labelText: 'Modifier la catégorie',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8)),
                                items: cats.map((c) => DropdownMenuItem<String>(
                                    value: c['id'] as String?,
                                    child: Text("${c['emoji']} ${c['label']}"))).toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  final cat = cats.firstWhere((c) => c['id'] == v);
                                  setState(() {
                                    _categorieId = cat['id'] ?? 'autre';
                                    _categorieLabel = cat['label'] ?? 'Autre';
                                    _categorieEmoji = cat['emoji'] ?? '📌';
                                  });
                                }),
                          const SizedBox(height: 8),

                          DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _walletId,
                              decoration: const InputDecoration(
                                  labelText: 'Portefeuille',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8)),
                              items: wallets.map((w) {
                                final solde = Fmt.montant(w.solde, monnaie: monnaie);
                                return DropdownMenuItem<String>(
                                    value: w.id,
                                    child: Text('${w.emoji ?? '💳'} ${w.nom ?? 'Portefeuille'} ($solde)',
                                        overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: (v) => setState(() => _walletId = v)),
                          const SizedBox(height: 12),

                          ElevatedButton(
                              onPressed: _enregistrer,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: isRevenu
                                      ? TAPAColors.green : TAPAColors.navy),
                              child: const Text('Enregistrer cette transaction')),
                          TextButton(
                              onPressed: () => setState(() {
                                _montant = null;
                                _texteReconnu = '';
                                _statut = 'Appuie sur le micro pour parler';
                              }),
                              child: const Text('Recommencer',
                                  style: TextStyle(color: TAPAColors.textSecond))),
                        ])),
                  ],
                  const SizedBox(height: 40),
                ]))));
  }
}