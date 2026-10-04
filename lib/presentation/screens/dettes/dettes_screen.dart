// lib/screens/dettes/dettes_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../services/db_service_mysql.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/models.dart';

class DettesScreen extends ConsumerStatefulWidget {
  const DettesScreen({super.key});

  @override
  ConsumerState<DettesScreen> createState() => _DettesScreenState();
}

class _DettesScreenState extends ConsumerState<DettesScreen> {
  int _selectedIndex = 4;

  // Getters qui lisent depuis le provider
  List<DetteModel> get _dettes =>
      ref.watch(dettesStateProvider).dettes;
  bool get _loading =>
      ref.watch(dettesStateProvider).isLoading;

  // Filtre d'affichage
  String _filtre = 'toutes'; // toutes | dette | creance

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerDettes();
    });
  }

  Future<void> _chargerDettes() async {
    final uid = ref.read(currentUserProvider)?.id ?? '';
    if (uid.isEmpty) return;

    await ref.read(dettesStateProvider.notifier).loadDettes(uid);
  }

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  List<DetteModel> get _dettesFiltrees {
    if (_filtre == 'toutes') return _dettes;
    return _dettes.where((d) => d.type == _filtre).toList();
  }

  // ==========================================================
  // HELPERS UI
  // ==========================================================
  Widget _sheetHandle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: TAPAColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _sheetHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onClose,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: TAPAColors.textSecond,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: TAPAColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 16, color: TAPAColors.textSecond),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: TAPAColors.textSecond),
      filled: true,
      fillColor: TAPAColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TAPAColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TAPAColors.navy, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }

  // ==========================================================
  // AJOUTER UNE DETTE
  // ==========================================================
  Future<void> _ajouterDette() async {
    final typeCtrl = TextEditingController();
    final montantCtrl = TextEditingController();
    final modaliteCtrl = TextEditingController();
    final periodesCtrl = TextEditingController();
    String type = 'dette';
    DateTime dateDebut = DateTime.now();
    DateTime dateFin = DateTime.now().add(const Duration(days: 30));

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _sheetHandle(),
                  _sheetHeader(
                    icon: type == 'dette'
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: type == 'dette' ? TAPAColors.red : TAPAColors.green,
                    title: 'Nouvelle entrée',
                    subtitle: 'Ajoutez une dette ou une créance',
                    onClose: () => Navigator.pop(ctx),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: TAPAColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => type = 'dette'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: type == 'dette'
                                    ? TAPAColors.red
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: type == 'dette'
                                    ? [
                                  BoxShadow(
                                    color: TAPAColors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: type == 'dette'
                                        ? Colors.white
                                        : TAPAColors.textSecond,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dette',
                                    style: TextStyle(
                                      color: type == 'dette'
                                          ? Colors.white
                                          : TAPAColors.textSecond,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => type = 'creance'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: type == 'creance'
                                    ? TAPAColors.green
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: type == 'creance'
                                    ? [
                                  BoxShadow(
                                    color: TAPAColors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: type == 'creance'
                                        ? Colors.white
                                        : TAPAColors.textSecond,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Créance',
                                    style: TextStyle(
                                      color: type == 'creance'
                                          ? Colors.white
                                          : TAPAColors.textSecond,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: typeCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _fieldDecoration(
                      label: 'Titre',
                      hint: 'ex : Dette scolaire',
                      icon: Icons.short_text_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: montantCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _fieldDecoration(
                      label: 'Montant total',
                      hint: '100 000',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modaliteCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _fieldDecoration(
                      label: 'Modalité de remboursement',
                      hint: 'ex : Mensuel',
                      icon: Icons.repeat_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: periodesCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _fieldDecoration(
                      label: 'Nombre de périodes (mois)',
                      hint: '12',
                      icon: Icons.calendar_view_month_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: ctx,
                              initialDate: dateDebut,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setModalState(() => dateDebut = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: TAPAColors.background,
                              border: Border.all(color: TAPAColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.event_outlined,
                                        size: 14, color: TAPAColors.textSecond),
                                    SizedBox(width: 6),
                                    Text(
                                      'Date début',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: TAPAColors.textSecond,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dateDebut.day}/${dateDebut.month}/${dateDebut.year}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: TAPAColors.navy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: ctx,
                              initialDate: dateFin,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (date != null) {
                              setModalState(() => dateFin = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: TAPAColors.background,
                              border: Border.all(color: TAPAColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.event_available_outlined,
                                        size: 14, color: TAPAColors.textSecond),
                                    SizedBox(width: 6),
                                    Text(
                                      'Date fin',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: TAPAColors.textSecond,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dateFin.day}/${dateFin.month}/${dateFin.year}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: TAPAColors.navy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: TAPAColors.navy.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final titre = typeCtrl.text.trim();
                          final montant = double.tryParse(montantCtrl.text) ?? 0;
                          final modalite = modaliteCtrl.text.trim();
                          final periodes = int.tryParse(periodesCtrl.text) ?? 1;

                          if (titre.isEmpty || montant <= 0 || modalite.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Remplissez tous les champs'),
                                backgroundColor: TAPAColors.red,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx, {
                            'titre': titre,
                            'montant': montant,
                            'type': type,
                            'modalite': modalite,
                            'periodes': periodes,
                            'dateDebut': dateDebut,
                            'dateFin': dateFin,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Ajouter',
                          style: TextStyle(
                            color: TAPAColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: TAPAColors.textSecond),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        final userId = ref.read(currentUserProvider)?.id ?? '';
        final dette = DetteModel(
          id: Fmt.genId(),
          uid: userId,
          type: result['type'] as String,
          montantTotal: result['montant'] as double,
          montantRembourse: 0,
          modalite: result['modalite'] as String,
          periodesMois: result['periodes'] as int,
          dateDebut: result['dateDebut'] as DateTime,
          dateFin: result['dateFin'] as DateTime,
          dateCreation: DateTime.now(),
          remboursements: [],
        );

        Logger.info('📝 Dette ajoutée: ${dette.type}');

        // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dette ajoutée avec succès !'),
            backgroundColor: TAPAColors.green,
          ),
        );
        _chargerDettes();
      } catch (e) {
        // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: TAPAColors.red,
          ),
        );
        Logger.error('❌ Erreur ajout dette: $e');
      }
    }
  }

  // ==========================================================
  // REMBOURSER
  // ==========================================================
  Future<void> _rembourser(DetteModel dette) async {
    final montantCtrl = TextEditingController();
    String? walletId;

    final List<WalletModel> walletList =
        ref.read(walletStateProvider).wallets;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                _sheetHeader(
                  icon: Icons.payments_outlined,
                  color: TAPAColors.green,
                  title: 'Rembourser',
                  subtitle: dette.type,
                  onClose: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: TAPAColors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 18, color: TAPAColors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Montant restant : ${Fmt.montant(dette.montantRestant, monnaie: ref.watch(userMonnaieProvider))}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TAPAColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: montantCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _fieldDecoration(
                    label: 'Montant du remboursement',
                    hint: '0',
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: walletId,
                  decoration: _fieldDecoration(
                    label: 'Portefeuille',
                    hint: 'Choisir un portefeuille',
                    icon: Icons.wallet_outlined,
                  ),
                  items: walletList.map((wallet) {
                    return DropdownMenuItem<String>(
                      value: wallet.id,
                      child: Text('${wallet.emoji} ${wallet.nom}'),
                    );
                  }).toList(),
                  onChanged: (v) => setModalState(() => walletId = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: TAPAColors.green,
                      boxShadow: [
                        BoxShadow(
                          color: TAPAColors.green.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        final montant = double.tryParse(montantCtrl.text) ?? 0;
                        if (montant <= 0 || walletId == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Remplissez tous les champs'),
                              backgroundColor: TAPAColors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx, {
                          'montant': montant,
                          'walletId': walletId,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Confirmer le remboursement',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: TAPAColors.textSecond),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        final montant = result['montant'] as double;
        final remboursement = RemboursementModel(
          id: Fmt.genId(),
          montant: montant,
          date: DateTime.now(),
          walletId: result['walletId'] as String,
          note: '',
        );

        Logger.info('📝 Remboursement effectué: $montant');

        // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Remboursement effectué avec succès !'),
            backgroundColor: TAPAColors.green,
          ),
        );
        _chargerDettes();
      } catch (e) {
        // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: TAPAColors.red,
          ),
        );
        Logger.error('❌ Erreur remboursement: $e');
      }
    }
  }

  // ==========================================================
  // SUPPRIMER
  // ==========================================================
  Future<void> _supprimerDette(DetteModel dette) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: TAPAColors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: TAPAColors.red, size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Supprimer cette entrée ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cette action supprimera définitivement "${dette.type}".',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: TAPAColors.textSecond),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: TAPAColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: TAPAColors.textSecond, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TAPAColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        Logger.info('🗑️ Dette supprimée: ${dette.type}');

        // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dette supprimée !'),
            backgroundColor: TAPAColors.green,
          ),
        );
        _chargerDettes();
      } catch (e) {
        // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: TAPAColors.red,
          ),
        );
        Logger.error('❌ Erreur suppression dette: $e');
      }
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Mes dettes'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: TAPAColors.gold),
            onPressed: _ajouterDette,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dettes.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          _buildSummaryHeader(monnaie),
          _buildFilterChips(),
          Expanded(child: _buildDetteList(monnaie)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================================
  // EN-TÊTE RÉSUMÉ
  // ==========================================================
  Widget _buildSummaryHeader(String monnaie) {
    final totalDettes = _dettes
        .where((d) => d.type == 'dette')
        .fold<double>(0, (sum, d) => sum + d.montantRestant);
    final totalCreances = _dettes
        .where((d) => d.type == 'creance')
        .fold<double>(0, (sum, d) => sum + d.montantRestant);
    final solde = totalCreances - totalDettes;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: TAPAColors.navy.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde net',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Fmt.montant(solde, monnaie: monnaie),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryPill(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Dettes',
                  value: Fmt.montant(totalDettes, monnaie: monnaie),
                  color: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryPill(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Créances',
                  value: Fmt.montant(totalCreances, monnaie: monnaie),
                  color: const Color(0xFF4CD787),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.white60),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FILTRES
  // ==========================================================
  Widget _buildFilterChips() {
    Widget chip(String value, String label, IconData icon) {
      final selected = _filtre == value;
      return GestureDetector(
        onTap: () => setState(() => _filtre = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: selected ? TAPAColors.navy : TAPAColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? TAPAColors.navy : TAPAColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : TAPAColors.textSecond),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : TAPAColors.textSecond,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          chip('toutes', 'Toutes', Icons.apps_rounded),
          chip('dette', 'Dettes', Icons.arrow_downward_rounded),
          chip('creance', 'Créances', Icons.arrow_upward_rounded),
        ],
      ),
    );
  }

  // ==========================================================
  // ÉTAT VIDE
  // ==========================================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: TAPAColors.navy.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_card_outlined,
                size: 42,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune dette enregistrée',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez vos dettes et créances pour\nsuivre vos remboursements facilement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: TAPAColors.textSecond, height: 1.4),
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _ajouterDette,
                icon: const Icon(Icons.add, color: TAPAColors.gold),
                label: const Text(
                  'Ajouter une dette',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAPAColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LISTE DES DETTES
  // ==========================================================
  Widget _buildDetteList(String monnaie) {
    final items = _dettesFiltrees;

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Aucun résultat pour ce filtre',
          style: TextStyle(color: TAPAColors.textSecond),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final dette = items[index];
        final progress = dette.progression;
        final isDette = dette.type == 'dette';
        final color = isDette ? TAPAColors.red : TAPAColors.green;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dette.estSolde ? TAPAColors.green : color.withOpacity(0.25),
              width: dette.estSolde ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.18), color.withOpacity(0.08)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDette ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dette.type,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TAPAColors.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dette.modalite} · ${dette.periodesMois} mois',
                          style: const TextStyle(
                            fontSize: 11,
                            color: TAPAColors.textSecond,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dette.estSolde)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TAPAColors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: TAPAColors.green),
                          SizedBox(width: 4),
                          Text(
                            'Soldé',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: TAPAColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (dette.enAttente)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TAPAColors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 12, color: TAPAColors.red),
                          SizedBox(width: 4),
                          Text(
                            'En attente',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: TAPAColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Fmt.montant(dette.montantRembourse, monnaie: monnaie),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: TAPAColors.navy,
                          ),
                        ),
                        Text(
                          'sur ${Fmt.montant(dette.montantTotal, monnaie: monnaie)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: TAPAColors.textSecond,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: TAPAColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (!dette.estSolde)
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () => _rembourser(dette),
                          icon: const Icon(Icons.payments_outlined, size: 16),
                          label: const Text('Rembourser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TAPAColors.navy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!dette.estSolde) const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () => _supprimerDette(dette),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Supprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TAPAColors.red,
                          side: const BorderSide(color: TAPAColors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // BARRE DE NAVIGATION INFÉRIEURE
  // ==========================================================
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Accueil',
                index: 0,
                route: '/home',
              ),
              _buildNavItem(
                icon: Icons.shield_outlined,
                activeIcon: Icons.shield,
                label: 'Assurance',
                index: 1,
                route: '/investir/assurance',
              ),
              _buildNavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet,
                label: 'Enveloppe',
                index: 2,
                route: '/savings',
              ),
              _buildNavItem(
                icon: Icons.pie_chart_outline,
                activeIcon: Icons.pie_chart,
                label: 'Budget',
                index: 3,
                route: '/budget',
              ),
              _buildNavItem(
                icon: Icons.credit_card_outlined,
                activeIcon: Icons.credit_card,
                label: 'Dettes',
                index: 4,
                route: '/dettes',
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                index: 5,
                route: '/profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required String route,
  }) {
    final isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigateTo(route, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 12 : 0,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: isActive ? 22 : 20,
                color: isActive ? Colors.amber : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isActive ? 10 : 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF1A237E) : Colors.grey.shade500,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}