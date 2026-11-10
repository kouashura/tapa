// lib/screens/coach/coach_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../services/db_service_mysql.dart';
import '../../../core/utils/logger.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final DBService _db = DBService();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  // ✅ UTILISER LA CLÉ DEPUIS .env
  static String get _apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  static const String _model = 'claude-3-5-sonnet-20241022';

  @override
  void initState() {
    super.initState();
    _ajouterMessageBienvenue();
    _verifierCleApi();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ✅ VÉRIFIER QUE LA CLÉ API EXISTE
  void _verifierCleApi() {
    if (_apiKey.isEmpty) {
      Logger.warning('⚠️ ANTHROPIC_API_KEY non définie dans .env');
      // ✅ CORRIGÉ : Pas de EnvService, on utilise directement _apiKey
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Mode simulation activé (Clé API manquante)'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      Logger.info('✅ ANTHROPIC_API_KEY chargée avec succès');
    }
  }

  Future<void> _ajouterMessageBienvenue() async {
    final user = _db.getUser();
    final prenom = user?['prenom'] ?? 'ami(e)';
    final monnaie = user?['monnaie'] ?? 'FCFA';
    final now = DateTime.now();
    final depMois = await _db.getTotalDepensesReelles(now.month, now.year);
    final revMois = await _db.getTotalRevenusReels(now.month, now.year);
    final soldeTotal = revMois - depMois;

    if (!mounted) return;
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': 'Bonjour $prenom ! 👋\n\n'
            'Je suis TAPA Coach, votre assistant financier personnel. '
            'Je suis là pour vous aider à mieux gérer votre argent, '
            'épargner intelligemment et construire votre avenir.\n\n'
            'Comment vous sentez-vous aujourd\'hui sur le plan financier ? '
            'Dites-moi ce qui vous préoccupe ou ce sur quoi vous voulez '
            'progresser. 💪'
      });
    });
  }

  Future<String> _construireContexte() async {
    final user = _db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';
    final now = DateTime.now();
    final depMois = await _db.getTotalDepensesReelles(now.month, now.year);
    final revMois = await _db.getTotalRevenusReels(now.month, now.year);
    final soldeTotal = revMois - depMois;
    final wallets = await _db.getWallets();
    final goals = _db.getSavingsGoals();

    String walletsStr = '';
    if (wallets.isNotEmpty) {
      final walletStrings = <String>[];
      for (final w in wallets) {
        walletStrings.add(
            '${w.nom ?? 'Inconnu'}: ${(w.solde ?? 0).toStringAsFixed(0)} $monnaie');
      }
      walletsStr = walletStrings.join(', ');
    } else {
      walletsStr = 'Aucun portefeuille';
    }

    return '''Tu es TAPA Coach, un assistant financier personnel bienveillant et expert, 
intégré dans l'application TAPA Invest pour l'Afrique de l'Ouest.

TON RÔLE :
- Coach financier personnel chaleureux et accessible
- Éduquer sur la gestion financière, l'épargne, l'investissement
- Soutenir l'état d'esprit financier (mindset)
- Conseiller sur l'assurance vie, les FCP, le budget
- Parler en français simple et accessible
- Adapter tes conseils au contexte africain (Wave, Orange Money, BRVM, FCFA)
- Être encourageant et positif, jamais condescendant

CONTEXTE UTILISATEUR :
- Prénom : ${user?['prenom'] ?? 'Utilisateur'}
- Monnaie : $monnaie
- Solde total : ${soldeTotal.toStringAsFixed(0)} $monnaie
- Dépenses ce mois : ${depMois.toStringAsFixed(0)} $monnaie
- Revenus ce mois : ${revMois.toStringAsFixed(0)} $monnaie
- Portefeuilles : $walletsStr
- Objectifs épargne : ${goals.length} en cours

RÈGLES :
- Réponds toujours en français
- Sois chaleureux et empathique
- Donne des conseils concrets et applicables
- Utilise des exemples en FCFA et contexte africain
- Maximum 3-4 paragraphes par réponse
- Pose une question de suivi pour engager la conversation
- Ne jamais donner de conseils médicaux ou juridiques
- Si l'utilisateur semble stressé, rassure-le d'abord avant les conseils''';
  }

  // ✅ MÉTHODE _envoyer (CORRIGÉE)
  Future<void> _envoyer() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty || _loading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': msg});
      _loading = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    try {
      final contexte = await _construireContexte();
      final messages = [
        {'role': 'user', 'content': contexte},
        {'role': 'assistant', 'content': 'Compris ! Je suis prêt à aider.'},
        ..._messages.map((m) => {'role': m['role']!, 'content': m['content']!}),
      ];

      // ✅ VÉRIFIER SI LA CLÉ API EXISTE
      if (_apiKey.isEmpty) {
        Logger.warning(
            '⚠️ ANTHROPIC_API_KEY manquante - Utilisation du mode simulation');
        _reponseSimulee(msg);
        return;
      }

      // ✅ APPEL API AVEC LA CLÉ DEPUIS .env
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
          'x-api-key': _apiKey, // ✅ UTILISATION DE LA CLÉ .env
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1000,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reponse = data['content'][0]['text'] as String;

        setState(() {
          _messages.add({'role': 'assistant', 'content': reponse});
          _loading = false;
        });
        _scrollToBottom();
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Erreur inconnue';
        Logger.error('❌ API Erreur: ${response.statusCode} - $errorMessage');

        // ✅ GESTION D'ERREUR : Si erreur API, on utilise la simulation
        if (response.statusCode == 401) {
          Logger.error('❌ Clé API invalide ou expirée');
          _showApiKeyError();
        }
        _reponseSimulee(msg);
      }
    } catch (e) {
      Logger.error('❌ Erreur connexion: $e');
      _reponseSimulee(msg);
    }
  }

  // ✅ AFFICHER UNE ERREUR SI LA CLÉ API EST INVALIDE
  void _showApiKeyError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('❌ Clé API Anthropic invalide. Vérifiez votre fichier .env'),
        backgroundColor: TAPAColors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  // ✅ RÉPONSE SIMULÉE (AMÉLIORÉE)
  void _reponseSimulee(String msg) {
    final user = _db.getUser();
    final prenom = user?['prenom'] ?? 'Utilisateur';
    final monnaie = user?['monnaie'] ?? 'FCFA';

    String reponse;

    if (msg.contains('épargne') || msg.contains('epargne')) {
      reponse = 'Bonjour $prenom ! 💰\n\n'
          'L\'épargne est la clé de la liberté financière. Voici 3 conseils :\n\n'
          '1️⃣ Règle 50/30/20 : 50% besoins, 30% loisirs, 20% épargne\n'
          '2️⃣ Commencez par 10% de vos revenus chaque mois\n'
          '3️⃣ Utilisez les objectifs d\'épargne dans TAPA Invest\n\n'
          'Quels sont vos objectifs d\'épargne actuels ? 🎯';
    } else if (msg.contains('budget') ||
        msg.contains('dépense') ||
        msg.contains('depense')) {
      reponse = 'Bonjour $prenom ! 📊\n\n'
          'Un bon budget est la base d\'une santé financière solide.\n\n'
          '✅ Listez TOUTES vos dépenses\n'
          '✅ Utilisez la règle 50/30/20\n'
          '✅ Suivez vos dépenses en temps réel\n\n'
          'Avez-vous créé votre budget dans TAPA Invest ? 💪';
    } else if (msg.contains('invest') || msg.contains('investissement')) {
      reponse = 'Bonjour $prenom ! 📈\n\n'
          'Investir est une excellente façon de faire fructifier votre argent.\n\n'
          '🌍 En Afrique de l\'Ouest, vous avez plusieurs options :\n'
          '- FCP : à partir de 10 000 FCFA\n'
          '- BRVM : actions cotées\n'
          '- Assurance vie : épargne + protection\n\n'
          'Quelle option vous intéresse ? 🚀';
    } else if (msg.contains('assurance') ||
        msg.contains('protég') ||
        msg.contains('protege')) {
      reponse = 'Bonjour $prenom ! 🛡️\n\n'
          'L\'assurance vie est un outil puissant pour protéger vos proches.\n\n'
          'Avec SONAM VIE, partenaire de TAPA Invest :\n'
          '✅ Assurance décès : jusqu\'à 10 000 000 FCFA\n'
          '✅ ÉPARGNE DE PRÉCAUTIONS : rendement garanti\n'
          '✅ Assurance éducation\n\n'
          'Quel type vous intéresse ? 💡';
    } else if (msg.contains('dette') ||
        msg.contains('credit') ||
        msg.contains('crédit')) {
      reponse = 'Bonjour $prenom ! 💳\n\n'
          'Gérer ses dettes est essentiel pour une santé financière solide.\n\n'
          '✅ Priorisez les dettes avec les taux d\'intérêt les plus élevés\n'
          '✅ Utilisez la méthode "boule de neige" (remboursez la plus petite dette d\'abord)\n'
          '✅ N\'accumulez pas de nouvelles dettes\n\n'
          'Quelles dettes souhaitez-vous rembourser en priorité ? 📊';
    } else {
      reponse = 'Bonjour $prenom ! 👋\n\n'
          'Je suis TAPA Coach, votre assistant financier personnel.\n\n'
          'Je peux vous aider sur :\n'
          '💰 L\'épargne et les objectifs financiers\n'
          '📊 L\'analyse de votre budget\n'
          '📈 L\'investissement (FCP, BRVM)\n'
          '🛡️ L\'assurance vie\n'
          '💳 La gestion des dettes\n'
          '🧠 Le mindset financier\n\n'
          'Posez-moi votre question ! 🎯';
    }

    setState(() {
      _messages.add({'role': 'assistant', 'content': reponse});
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasApiKey = _apiKey.isNotEmpty;

    return Scaffold(
        backgroundColor: TAPAColors.background,
        appBar: AppBar(
            title: const Row(children: [
              CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE8F4FD),
                  child: Text('🎯', style: TextStyle(fontSize: 16))),
              SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TAPA Coach',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text('Coach financier personnel',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ]),
            ]),
            backgroundColor: TAPAColors.navy,
            foregroundColor: TAPAColors.white,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context)),
            // ✅ INDICATEUR DE STATUT API
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasApiKey
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasApiKey ? Icons.check_circle : Icons.warning,
                      size: 12,
                      color: hasApiKey ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasApiKey ? 'API OK' : 'Mode simulation',
                      style: TextStyle(
                        fontSize: 9,
                        color: hasApiKey ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
        body: Column(children: [
          if (_messages.length <= 1)
            Container(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _suggestion('💰 Comment épargner ?'),
                      _suggestion('📊 Analyser mon budget'),
                      _suggestion('🛡️ Assurance vie'),
                      _suggestion('📈 Investir en BRVM'),
                      _suggestion('🧠 Mindset financier'),
                      _suggestion('💳 Gérer mes dettes'),
                    ]))),
          Expanded(
              child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _messages.length) {
                      return _bulleChargement();
                    }
                    final msg = _messages[i];
                    final isUser = msg['role'] == 'user';
                    return _bulle(msg['content']!, isUser);
                  })),
          Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(color: TAPAColors.surface, boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3))
              ]),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: _msgCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                            hintText: hasApiKey
                                ? 'Posez votre question...'
                                : 'Mode simulation...',
                            hintStyle:
                                const TextStyle(color: TAPAColors.textHint),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none),
                            filled: true,
                            fillColor: TAPAColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10)),
                        onSubmitted: (_) => _envoyer())),
                const SizedBox(width: 8),
                GestureDetector(
                    onTap: _envoyer,
                    child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: _loading
                                ? TAPAColors.textHint
                                : TAPAColors.navy,
                            shape: BoxShape.circle),
                        child: Icon(
                            _loading ? Icons.hourglass_empty : Icons.send,
                            color: TAPAColors.white,
                            size: 20))),
              ])),
        ]));
  }

  Widget _bulle(String texte, bool isUser) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF1A2B4A),
                    child: Text('🎯', style: TextStyle(fontSize: 14))),
                const SizedBox(width: 8),
              ],
              Flexible(
                  child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: isUser ? TAPAColors.navy : TAPAColors.surface,
                          borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isUser ? 18 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 18)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ]),
                      child: Text(texte,
                          style: TextStyle(
                              fontSize: 14,
                              color:
                                  isUser ? TAPAColors.white : TAPAColors.navy,
                              height: 1.5)))),
              if (isUser) const SizedBox(width: 8),
            ]));
  }

  Widget _bulleChargement() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1A2B4A),
              child: Text('🎯', style: TextStyle(fontSize: 14))),
          const SizedBox(width: 8),
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: TAPAColors.surface,
                  borderRadius: BorderRadius.circular(18)),
              child: const Row(children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: TAPAColors.navy)),
                SizedBox(width: 8),
                Text('TAPA Coach réfléchit...',
                    style:
                        TextStyle(fontSize: 13, color: TAPAColors.textSecond)),
              ])),
        ]));
  }

  Widget _suggestion(String texte) {
    return GestureDetector(
        onTap: () {
          _msgCtrl.text = texte;
          _envoyer();
        },
        child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: TAPAColors.navy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TAPAColors.navy.withOpacity(0.2))),
            child: Text(texte,
                style: const TextStyle(
                    fontSize: 12,
                    color: TAPAColors.navy,
                    fontWeight: FontWeight.w600))));
  }
}
