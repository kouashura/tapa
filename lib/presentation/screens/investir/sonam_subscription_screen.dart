// lib/presentation/screens/investir/sonam_subscription_screen.dart
// Souscription Épargne SONAM — calquée sur le Bulletin d'Adhésion Epargne.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import 'sonam_calc.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';

class SonamSubscriptionScreen extends ConsumerStatefulWidget {
  final double cotisation;
  final int dureeAns;
  final double capitalGaranti;

  const SonamSubscriptionScreen({
    super.key,
    required this.cotisation,
    required this.dureeAns,
    required this.capitalGaranti,
  });

  @override
  ConsumerState<SonamSubscriptionScreen> createState() =>
      _SonamSubscriptionScreenState();
}

class _Benef {
  final nom = TextEditingController();
  final naissance = TextEditingController();
  final lieu = TextEditingController();
  final adresse = TextEditingController();
  final cni = TextEditingController();
  final tel = TextEditingController();

  void dispose() {
    nom.dispose();
    naissance.dispose();
    lieu.dispose();
    adresse.dispose();
    cni.dispose();
    tel.dispose();
  }

  Map<String, String> toMap() => {
        'nom_prenoms': nom.text.trim(),
        'date_naissance': naissance.text.trim(),
        'lieu_naissance': lieu.text.trim(),
        'adresse': adresse.text.trim(),
        'cni': cni.text.trim(),
        'telephone': tel.text.trim(),
      };
}

class _SonamSubscriptionScreenState
    extends ConsumerState<SonamSubscriptionScreen> {
  static const _titres = [
    'Votre contrat',
    'Souscripteur',
    'Assuré',
    'Bénéficiaires',
    'Validation',
  ];

  final _scroll = ScrollController();
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());

  int _step = 0;
  bool _submitting = false;
  String? _policeCode;
  bool _done = false;
  bool _showConsentError = false;

  // Contrat
  final _dateEffet = TextEditingController();

  // Souscripteur
  final _sNom = TextEditingController();
  final _sNaissance = TextEditingController();
  final _sProfession = TextEditingController();
  final _sAdresse = TextEditingController();
  final _sTel = TextEditingController();
  final _sEmail = TextEditingController();
  String? _sCivilite;

  // Assuré
  bool _assureEstSouscripteur = true;
  final _aNom = TextEditingController();
  final _aNaissance = TextEditingController();
  final _aProfession = TextEditingController();
  final _aAdresse = TextEditingController();
  final _aTel = TextEditingController();
  final _aEmail = TextEditingController();
  final _aAdressePro = TextEditingController();
  final _aTelPro = TextEditingController();
  final _aEmailPro = TextEditingController();
  String? _aCivilite;

  // Bénéficiaires
  final List<_Benef> _benefs = [_Benef()];

  // Personne à contacter
  final _cNom = TextEditingController();
  final _cNaissance = TextEditingController();
  final _cAdresse = TextEditingController();
  final _cTel = TextEditingController();
  final _cEmail = TextEditingController();

  // Déclarations
  bool _okCG = false;
  bool _okDecl = false;
  bool _okNote = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateEffet.text = _fmtDate(DateTime(now.year, now.month + 1, 1));
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [
      _dateEffet,
      _sNom,
      _sNaissance,
      _sProfession,
      _sAdresse,
      _sTel,
      _sEmail,
      _aNom,
      _aNaissance,
      _aProfession,
      _aAdresse,
      _aTel,
      _aEmail,
      _aAdressePro,
      _aTelPro,
      _aEmailPro,
      _cNom,
      _cNaissance,
      _cAdresse,
      _cTel,
      _cEmail,
    ]) {
      c.dispose();
    }
    for (final b in _benefs) {
      b.dispose();
    }
    super.dispose();
  }

  // ───────────────────────── Helpers ─────────────────────────

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime? _parse(String s) {
    final p = s.split('/');
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  int _age(DateTime dob) {
    final now = DateTime.now();
    var a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a;
  }

  DateTime? get _effet => _parse(_dateEffet.text);
  DateTime? get _terme {
    final e = _effet;
    if (e == null) return null;
    return DateTime(e.year + widget.dureeAns, e.month, e.day);
  }

  double get _totalVerse => widget.cotisation * widget.dureeAns * 12;

  String? _vTel(String t) {
    final d = t.replaceAll(RegExp(r'\D'), '');
    return d.length >= 8 ? null : 'Numéro invalide';
  }

  String? _vEmail(String t) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
      ? null
      : 'Email invalide';

  InputDecoration _deco(String label, bool required) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: const TextStyle(fontSize: 13, color: TAPAColors.textSecond),
      filled: true,
      fillColor: TAPAColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TAPAColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TAPAColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TAPAColors.gold, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TAPAColors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TAPAColors.red, width: 1.6),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = true,
    TextInputType? keyboard,
    String? Function(String)? extra,
    TextCapitalization cap = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        textCapitalization: cap,
        decoration: _deco(label, required),
        style: const TextStyle(fontSize: 14, color: TAPAColors.navy),
        validator: (v) {
          final t = (v ?? '').trim();
          if (t.isEmpty) return required ? 'Champ obligatoire' : null;
          return extra?.call(t);
        },
      ),
    );
  }

  Widget _dateField(
    TextEditingController c,
    String label, {
    required DateTime first,
    required DateTime last,
    DateTime? initial,
    bool required = true,
    String? Function(DateTime)? check,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        readOnly: true,
        style: const TextStyle(fontSize: 14, color: TAPAColors.navy),
        decoration: _deco(label, required).copyWith(
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        onTap: () async {
          var start = _parse(c.text) ?? initial ?? last;
          if (start.isBefore(first)) start = first;
          if (start.isAfter(last)) start = last;
          final d = await showDatePicker(
            context: context,
            initialDate: start,
            firstDate: first,
            lastDate: last,
          );
          if (d != null) setState(() => c.text = _fmtDate(d));
        },
        validator: (v) {
          final t = (v ?? '').trim();
          if (t.isEmpty) return required ? 'Champ obligatoire' : null;
          final d = _parse(t);
          if (d == null) return 'Date invalide';
          return check?.call(d);
        },
      ),
    );
  }

  Widget _civiliteField(String? value, ValueChanged<String> onChanged) {
    return FormField<String>(
      initialValue: value,
      validator: (v) => v == null ? 'Choisissez Homme ou Femme' : null,
      builder: (state) {
        Widget chip(String code, String label) {
          final selected = state.value == code;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            selectedColor: TAPAColors.navy,
            backgroundColor: TAPAColors.surface,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? TAPAColors.white : TAPAColors.textSecond,
            ),
            side: BorderSide(
              color: selected ? TAPAColors.navy : TAPAColors.border,
            ),
            showCheckmark: false,
            onSelected: (_) {
              onChanged(code);
              state.didChange(code);
            },
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Civilité *',
                    style:
                        TextStyle(fontSize: 13, color: TAPAColors.textSecond),
                  ),
                  chip('H', 'Homme'),
                  chip('F', 'Femme'),
                ],
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(fontSize: 12, color: TAPAColors.red),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TAPAColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      );

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TAPAColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                color: bold ? TAPAColors.navy : TAPAColors.textSecond,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: bold ? 16 : 13,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: bold ? TAPAColors.gold : TAPAColors.navy,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TAPAColors.gold.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAPAColors.gold.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: TAPAColors.navy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: TAPAColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Navigation ─────────────────────────

  void _goTo(int step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _back() {
    if (_step > 0) {
      _goTo(_step - 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _next() {
    final ok = _formKeys[_step].currentState?.validate() ?? false;
    if (!ok) return;
    if (_step < 4) {
      // Assuré = souscripteur : on saute la saisie
      _goTo(_step + 1);
    } else {
      _submit();
    }
  }

  // ───────────────────────── Envoi ─────────────────────────

  Map<String, dynamic> _buildPayload() {
    final souscripteur = {
      'nom_prenoms': _sNom.text.trim(),
      'civilite': _sCivilite,
      'date_naissance': _sNaissance.text.trim(),
      'profession': _sProfession.text.trim(),
      'adresse': _sAdresse.text.trim(),
      'telephone': _sTel.text.trim(),
      'email': _sEmail.text.trim(),
    };
    final assure = _assureEstSouscripteur
        ? souscripteur
        : {
            'nom_prenoms': _aNom.text.trim(),
            'civilite': _aCivilite,
            'date_naissance': _aNaissance.text.trim(),
            'profession': _aProfession.text.trim(),
            'adresse': _aAdresse.text.trim(),
            'telephone': _aTel.text.trim(),
            'email': _aEmail.text.trim(),
            'adresse_professionnelle': _aAdressePro.text.trim(),
            'telephone_professionnel': _aTelPro.text.trim(),
            'email_professionnel': _aEmailPro.text.trim(),
          };

    return {
      'produit': 'EPARGNE',
      'contrat': {
        'cotisation_periodique': widget.cotisation.round(),
        'periodicite': 'mensuelle',
        'cotisation_annuelle': (widget.cotisation * 12).round(),
        'duree_paiement_ans': widget.dureeAns,
        'date_effet': _dateEffet.text.trim(),
        'terme': _terme == null ? null : _fmtDate(_terme!),
        'capital_garanti_terme': widget.capitalGaranti.round(),
        'taux_garanti': SonamCalc.tauxAnnuel,
        'chargement': SonamCalc.tauxFrais,
      },
      'souscripteur': souscripteur,
      'assure': assure,
      'assure_est_souscripteur': _assureEstSouscripteur,
      'beneficiaires_deces': _benefs.map((b) => b.toMap()).toList(),
      'personne_a_contacter': {
        'nom_prenoms': _cNom.text.trim(),
        'date_naissance': _cNaissance.text.trim(),
        'adresse': _cAdresse.text.trim(),
        'telephone': _cTel.text.trim(),
        'email': _cEmail.text.trim(),
      },
      'declarations': {
        'conditions_generales_recues': _okCG,
        'declarations_sinceres': _okDecl,
        'note_information_lue': _okNote,
      },
    };
  }

  /// ✅ Enregistre le contrat et débite le Wallet

  Future<void> _envoyer(Map<String, dynamic> payload) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('Utilisateur non connecté');

    // ✅ Générer un code de police unique (ex: POL-2026-X8Y2Z)
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final code =
        'POL-${DateTime.now().year}-${random.substring(random.length - 5)}';

    // Créer le contrat en attente de paiement
    final contractRef =
        FirebaseFirestore.instance.collection('sonam_contracts').doc();

    await contractRef.set({
      ...payload,
      'userId': user.id,
      'contractId': contractRef.id,
      'policeCode': code, // ✅ Code unique sauvegardé
      'dateSouscription': FieldValue.serverTimestamp(),
      'statut': 'En attente de paiement',
      'totalVerse': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ✅ Sauvegarder le code pour l'afficher sur l'écran de succès
    if (mounted) {
      setState(() {
        _policeCode = code;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _showConsentError = true);
    if (!(_okCG && _okDecl && _okNote)) return;

    setState(() => _submitting = true);
    try {
      await _envoyer(_buildPayload());
      if (!mounted) return;
      setState(() => _done = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: TAPAColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_done) return _buildSuccess();

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: TAPAColors.background,
        appBar: AppBar(
          title: const Text(
            'Souscription SONAM',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: TAPAColors.navy,
          foregroundColor: TAPAColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _back,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildProgress(),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: _buildStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      color: TAPAColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(_titres.length, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin:
                      EdgeInsets.only(right: i == _titres.length - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color:
                        i <= _step ? TAPAColors.gold : const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Étape ${_step + 1}/${_titres.length} · ${_titres[_step]}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final last = _step == 4;
    return Container(
      decoration: const BoxDecoration(
        color: TAPAColors.surface,
        border: Border(top: BorderSide(color: TAPAColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (_step > 0) ...[
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _submitting ? null : _back,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TAPAColors.navy,
                      side: const BorderSide(color: TAPAColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Retour'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAPAColors.gold,
                      foregroundColor: TAPAColors.navy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: TAPAColors.navy,
                            ),
                          )
                        : Text(
                            last ? 'Confirmer la souscription' : 'Continuer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _stepContrat();
      case 1:
        return _stepSouscripteur();
      case 2:
        return _stepAssure();
      case 3:
        return _stepBeneficiaires();
      default:
        return _stepValidation();
    }
  }

  // ───────────────────────── Étape 1 : contrat ─────────────────────────

  Widget _stepContrat() {
    final now = DateTime.now();
    final terme = _terme;
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionCard(
            icon: Icons.description_outlined,
            title: 'Récapitulatif du contrat',
            children: [
              _row('Produit', 'Épargne SONAM'),
              _row('Cotisation mensuelle',
                  SonamCalc.formatMontant(widget.cotisation)),
              _row('Cotisation annuelle',
                  SonamCalc.formatMontant(widget.cotisation * 12)),
              _row('Durée de paiement',
                  '${widget.dureeAns} an${widget.dureeAns > 1 ? 's' : ''}'),
              _row('Total des cotisations',
                  SonamCalc.formatMontant(_totalVerse)),
              _row('Terme du contrat', terme == null ? '—' : _fmtDate(terme)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: TAPAColors.border),
              ),
              _row('Capital garanti au terme',
                  SonamCalc.formatMontant(widget.capitalGaranti),
                  bold: true),
            ],
          ),
          _sectionCard(
            icon: Icons.event_outlined,
            title: 'Date d\'effet',
            children: [
              _dateField(
                _dateEffet,
                'Date d\'effet du contrat',
                first: DateTime(now.year, now.month, now.day),
                last: now.add(const Duration(days: 365)),
                initial: DateTime(now.year, now.month + 1, 1),
                check: (d) => d.isBefore(DateTime(now.year, now.month, now.day))
                    ? 'La date doit être aujourd\'hui ou plus tard'
                    : null,
              ),
              const Text(
                'Les garanties sont acquises dès le premier versement '
                'et la signature du contrat.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: TAPAColors.textSecond,
                ),
              ),
            ],
          ),
          _infoBox(
            Icons.undo_rounded,
            'Délai de renonciation de 30 jours à compter du prélèvement '
            'de la première prime. La prime versée est restituée, déduction '
            'faite du coût de police, sous 15 jours.',
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Étape 2 : souscripteur ─────────────────────────

  Widget _stepSouscripteur() {
    final now = DateTime.now();
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoBox(
            Icons.person_outline,
            'Le souscripteur est la personne qui signe le contrat '
            'et paie les cotisations.',
          ),
          _sectionCard(
            icon: Icons.person_outline,
            title: 'Souscripteur',
            children: [
              _field(_sNom, 'Nom et prénoms', cap: TextCapitalization.words),
              _civiliteField(_sCivilite, (v) => _sCivilite = v),
              _dateField(
                _sNaissance,
                'Date de naissance',
                first: DateTime(now.year - 100),
                last: now,
                initial: DateTime(now.year - 30, 1, 1),
                check: (d) =>
                    _age(d) < 18 ? 'Le souscripteur doit être majeur' : null,
              ),
              _field(_sProfession, 'Profession',
                  cap: TextCapitalization.sentences),
              _field(_sAdresse, 'Adresse', cap: TextCapitalization.sentences),
              _field(_sTel, 'Téléphone',
                  keyboard: TextInputType.phone, extra: _vTel),
              _field(_sEmail, 'Email',
                  required: false,
                  keyboard: TextInputType.emailAddress,
                  extra: _vEmail),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Étape 3 : assuré ─────────────────────────

  Widget _stepAssure() {
    final now = DateTime.now();
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoBox(
            Icons.shield_outlined,
            'L\'assuré est la personne dont la vie ou le décès déclenche '
            'le paiement du capital.',
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: _cardDecoration(),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              activeColor: TAPAColors.gold,
              title: const Text(
                'L\'assuré est le souscripteur',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TAPAColors.navy,
                ),
              ),
              value: _assureEstSouscripteur,
              onChanged: (v) => setState(() => _assureEstSouscripteur = v),
            ),
          ),
          if (!_assureEstSouscripteur) ...[
            _sectionCard(
              icon: Icons.shield_outlined,
              title: 'Assuré',
              children: [
                _field(_aNom, 'Nom et prénoms', cap: TextCapitalization.words),
                _civiliteField(_aCivilite, (v) => _aCivilite = v),
                _dateField(
                  _aNaissance,
                  'Date de naissance',
                  first: DateTime(now.year - 100),
                  last: now,
                  initial: DateTime(now.year - 30, 1, 1),
                ),
                _field(_aProfession, 'Profession',
                    cap: TextCapitalization.sentences),
                _field(_aAdresse, 'Adresse', cap: TextCapitalization.sentences),
                _field(_aTel, 'Téléphone',
                    keyboard: TextInputType.phone, extra: _vTel),
                _field(_aEmail, 'Email',
                    required: false,
                    keyboard: TextInputType.emailAddress,
                    extra: _vEmail),
              ],
            ),
            _sectionCard(
              icon: Icons.business_center_outlined,
              title: 'Coordonnées professionnelles',
              children: [
                _field(_aAdressePro, 'Adresse professionnelle',
                    required: false, cap: TextCapitalization.sentences),
                _field(_aTelPro, 'Téléphone professionnel',
                    required: false,
                    keyboard: TextInputType.phone,
                    extra: _vTel),
                _field(_aEmailPro, 'Email professionnel',
                    required: false,
                    keyboard: TextInputType.emailAddress,
                    extra: _vEmail),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────── Étape 4 : bénéficiaires ─────────────────────────

  Widget _stepBeneficiaires() {
    final now = DateTime.now();
    return Form(
      key: _formKeys[3],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoBox(
            Icons.family_restroom_outlined,
            'Bénéficiaires en cas de décès (3 maximum). À défaut de '
            'désignation, le capital est versé aux héritiers légaux.',
          ),
          for (var i = 0; i < _benefs.length; i++)
            _sectionCard(
              icon: Icons.person_add_alt_1_outlined,
              title: '${i + 1}${i == 0 ? 'er' : 'e'} bénéficiaire',
              trailing: i == 0
                  ? null
                  : IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: TAPAColors.red),
                      onPressed: () => setState(() {
                        _benefs.removeAt(i).dispose();
                      }),
                    ),
              children: [
                _field(_benefs[i].nom, 'Nom et prénoms',
                    cap: TextCapitalization.words),
                _dateField(
                  _benefs[i].naissance,
                  'Date de naissance',
                  first: DateTime(now.year - 120),
                  last: now,
                  initial: DateTime(now.year - 30, 1, 1),
                ),
                _field(_benefs[i].lieu, 'Lieu de naissance',
                    cap: TextCapitalization.words),
                _field(_benefs[i].adresse, 'Adresse',
                    required: false, cap: TextCapitalization.sentences),
                _field(_benefs[i].cni, 'N° CNI', required: false),
                _field(_benefs[i].tel, 'Téléphone',
                    keyboard: TextInputType.phone, extra: _vTel),
              ],
            ),
          if (_benefs.length < 3)
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _benefs.add(_Benef())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter un bénéficiaire'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TAPAColors.navy,
                  side: const BorderSide(color: TAPAColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────── Étape 5 : validation ─────────────────────────

  Widget _consent(String text, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: TAPAColors.gold,
      checkColor: TAPAColors.navy,
      dense: true,
      value: value,
      onChanged: (v) => setState(() => onChanged(v ?? false)),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.4,
          color: TAPAColors.navy,
        ),
      ),
    );
  }

  Widget _stepValidation() {
    final now = DateTime.now();
    final consentManquant = _showConsentError && !(_okCG && _okDecl && _okNote);
    return Form(
      key: _formKeys[4],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionCard(
            icon: Icons.contact_phone_outlined,
            title: 'Personne à contacter en cas de nécessité',
            children: [
              _field(_cNom, 'Nom et prénoms', cap: TextCapitalization.words),
              _dateField(
                _cNaissance,
                'Date de naissance',
                required: false,
                first: DateTime(now.year - 120),
                last: now,
                initial: DateTime(now.year - 30, 1, 1),
              ),
              _field(_cAdresse, 'Adresse',
                  required: false, cap: TextCapitalization.sentences),
              _field(_cTel, 'Téléphone',
                  keyboard: TextInputType.phone, extra: _vTel),
              _field(_cEmail, 'Email',
                  required: false,
                  keyboard: TextInputType.emailAddress,
                  extra: _vEmail),
            ],
          ),
          _sectionCard(
            icon: Icons.fact_check_outlined,
            title: 'Récapitulatif',
            children: [
              _row('Souscripteur',
                  _sNom.text.trim().isEmpty ? '—' : _sNom.text.trim()),
              _row(
                  'Assuré',
                  _assureEstSouscripteur
                      ? 'Identique au souscripteur'
                      : (_aNom.text.trim().isEmpty ? '—' : _aNom.text.trim())),
              _row('Bénéficiaires', '${_benefs.length}'),
              _row('Cotisation mensuelle',
                  SonamCalc.formatMontant(widget.cotisation)),
              _row('Durée', '${widget.dureeAns} ans'),
              _row('Date d\'effet', _dateEffet.text),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: TAPAColors.border),
              ),
              _row('Capital garanti',
                  SonamCalc.formatMontant(widget.capitalGaranti),
                  bold: true),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: consentManquant ? TAPAColors.red : TAPAColors.border,
              ),
            ),
            child: Column(
              children: [
                _consent(
                  'Je reconnais avoir reçu un exemplaire des conditions '
                  'générales d\'assurance.',
                  _okCG,
                  (v) => _okCG = v,
                ),
                _consent(
                  'Je certifie que mes déclarations sont sincères et '
                  'véritables. Une déclaration fausse ou réticente entraîne '
                  'la nullité du contrat (art. 18 du Code CIMA).',
                  _okDecl,
                  (v) => _okDecl = v,
                ),
                _consent(
                  'J\'ai pris connaissance de la note d\'information '
                  '(rachat, renonciation, risques exclus).',
                  _okNote,
                  (v) => _okNote = v,
                ),
              ],
            ),
          ),
          if (consentManquant)
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Veuillez accepter les trois déclarations pour continuer.',
                style: TextStyle(fontSize: 12, color: TAPAColors.red),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────── Succès ─────────────────────────

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: TAPAColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TAPAColors.green.withAlpha(30),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 48, color: TAPAColors.green),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Demande enregistrée',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: TAPAColors.navy,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Votre demande a bien été enregistrée.\n\n'
                  'Voici votre code de police :',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: TAPAColors.textSecond,
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Affichage du Code de Police
                if (_policeCode != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: TAPAColors.navy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'CODE DE POLICE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _policeCode!,
                          style: const TextStyle(
                            color: TAPAColors.gold,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Conservez ce code. Il vous sera demandé pour '
                          'finaliser votre paiement.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAPAColors.gold,
                      foregroundColor: TAPAColors.navy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Retour à l\'accueil',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
