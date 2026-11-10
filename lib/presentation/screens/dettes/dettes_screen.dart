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
import '../../../domain/usecases/dettes/create_dette_usecase.dart';
import '../../../domain/usecases/dettes/rembourser_dette_usecase.dart';
import '../../../domain/usecases/dettes/delete_dette_usecase.dart';

class DettesScreen extends ConsumerStatefulWidget {
  const DettesScreen({super.key});

  @override
  ConsumerState<DettesScreen> createState() => _DettesScreenState();
}

class _DettesScreenState extends ConsumerState<DettesScreen> {
  int _selectedIndex = 4;

  // Filtre d'affichage : toutes | dette | creance
  String _filtre = 'toutes';

  static const LinearGradient _heroGradient = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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

  List<DetteModel> _filtrer(List<DetteModel> all) {
    if (_filtre == 'toutes') return all;
    return all.where((d) => d.type == _filtre).toList();
  }

  // ==========================================================
  // HELPERS GÉNÉRAUX
  // ==========================================================
  String _typeLabel(String type) => type == 'dette' ? 'Dette' : 'Créance';

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: error ? TAPAColors.red : TAPAColors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ==========================================================
  // HELPERS UI (feuilles modales)
  // ==========================================================

  /// Conteneur commun des bottom sheets : scrollable, borné en hauteur et
  /// qui tient compte du clavier → plus aucun RenderFlex overflow.
  Widget _sheetShell(BuildContext ctx, Widget child) {
    final mq = MediaQuery.of(ctx);
    final maxH = (mq.size.height - mq.viewInsets.bottom) * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          decoration: const BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: TAPAColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
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
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: TAPAColors.textSecond,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onClose,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: TAPAColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: TAPAColors.textSecond,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: isRequired ? '$label *' : label,
      hintText: hint,
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        color: TAPAColors.textSecond,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, size: 20, color: TAPAColors.textSecond),
      filled: true,
      fillColor: TAPAColors.background,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TAPAColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TAPAColors.navy, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      labelStyle: const TextStyle(
        fontSize: 14,
        color: TAPAColors.textSecond,
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: 13,
        color: TAPAColors.navy,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TAPAColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAPAColors.red.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: TAPAColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                color: TAPAColors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? TAPAColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: TAPAColors.border,
          disabledForegroundColor: TAPAColors.textSecond,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _typeToggle({
    required String type,
    required ValueChanged<String> onChanged,
  }) {
    Widget option(String value, IconData icon, Color color) {
      final selected = type == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: selected ? Colors.white : TAPAColors.textSecond,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _typeLabel(value),
                    style: TextStyle(
                      color: selected ? Colors.white : TAPAColors.textSecond,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TAPAColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          option('dette', Icons.arrow_downward_rounded, TAPAColors.red),
          option('creance', Icons.arrow_upward_rounded, TAPAColors.green),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required IconData icon,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: TAPAColors.background,
            border: Border.all(color: TAPAColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: TAPAColors.textSecond),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: TAPAColors.textSecond,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _fmtDate(date),
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: TAPAColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // AJOUTER UNE DETTE
  // ==========================================================
  Future<void> _ajouterDette() async {
    final monnaie = ref.read(userMonnaieProvider);
    final typeCtrl = TextEditingController();
    final montantCtrl = TextEditingController();
    final modaliteCtrl = TextEditingController();
    final periodesCtrl = TextEditingController();
    const modalites = ['Mensuel', 'Hebdomadaire', 'Trimestriel', 'Unique'];

    String type = 'dette';
    DateTime dateDebut = DateTime.now();
    DateTime dateFin = DateTime.now().add(const Duration(days: 30));
    String? erreur;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDette = type == 'dette';

          return _sheetShell(
            ctx,
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sheetHandle(),
                _sheetHeader(
                  icon: isDette
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isDette ? TAPAColors.red : TAPAColors.green,
                  title: 'Nouvelle entrée',
                  subtitle: 'Ajoutez une dette ou une créance',
                  onClose: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 20),
                _typeToggle(
                  type: type,
                  onChanged: (v) => setModalState(() => type = v),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: typeCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _fieldDecoration(
                    label: 'Titre',
                    hint: 'ex : Dette scolaire',
                    icon: Icons.short_text_rounded,
                    isRequired: true,
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
                    isRequired: true,
                    suffixText: monnaie,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modaliteCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setModalState(() {}),
                  decoration: _fieldDecoration(
                    label: 'Modalité de remboursement',
                    hint: 'ex : Mensuel',
                    icon: Icons.repeat_rounded,
                    isRequired: true,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: modalites.map((m) {
                    final selected = modaliteCtrl.text.trim().toLowerCase() ==
                        m.toLowerCase();
                    return ChoiceChip(
                      label: Text(m),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => setModalState(() {
                        modaliteCtrl.text = m;
                      }),
                      selectedColor: TAPAColors.navy,
                      backgroundColor: TAPAColors.surface,
                      side: BorderSide(
                        color: selected ? TAPAColors.navy : TAPAColors.border,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : TAPAColors.textSecond,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
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
                    _dateField(
                      label: 'Date de début',
                      icon: Icons.event_outlined,
                      date: dateDebut,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: dateDebut,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() {
                            dateDebut = date;
                            if (dateFin.isBefore(dateDebut)) {
                              dateFin = dateDebut.add(const Duration(days: 30));
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    _dateField(
                      label: 'Date de fin',
                      icon: Icons.event_available_outlined,
                      date: dateFin,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: dateFin,
                          firstDate: dateDebut,
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (date != null) {
                          setModalState(() => dateFin = date);
                        }
                      },
                    ),
                  ],
                ),
                if (erreur != null) _errorBanner(erreur!),
                const SizedBox(height: 20),
                _primaryButton(
                  label: 'Ajouter',
                  onPressed: () {
                    final titre = typeCtrl.text.trim();
                    final montant = double.tryParse(montantCtrl.text) ?? 0;
                    final modalite = modaliteCtrl.text.trim();
                    final p = int.tryParse(periodesCtrl.text);
                    final periodes = (p == null || p < 1) ? 1 : p;

                    if (titre.isEmpty || montant <= 0 || modalite.isEmpty) {
                      setModalState(() {
                        erreur =
                            'Renseignez le titre, un montant valide et la modalité.';
                      });
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
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: TAPAColors.textSecond),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result == null) return;

    try {
      final userId = ref.read(currentUserProvider)?.id ?? '';

      final params = CreateDetteParams(
        uid: userId,
        type: result['type'] as String,
        montantTotal: result['montant'] as double,
        modalite: result['modalite'] as String,
        periodesMois: result['periodes'] as int,
        dateDebut: result['dateDebut'] as DateTime,
        dateFin: result['dateFin'] as DateTime,
      );

      Logger.info('Creation dette: ${params.type} ${params.montantTotal}');

      final createResult = await ref.read(createDetteProvider(params).future);

      if (!mounted) return;

      if (createResult.success) {
        _snack('Entrée ajoutée avec succès');
        await ref.read(dettesStateProvider.notifier).loadDettes(userId);
      } else {
        _snack(createResult.message ?? 'Erreur', error: true);
      }
    } catch (e) {
      Logger.error('Erreur ajout dette: $e');
      _snack('Erreur : ${e.toString().replaceAll('Exception: ', '')}',
          error: true);
    }
  }

  // ==========================================================
  // REMBOURSER
  // ==========================================================
  Future<void> _rembourser(DetteModel dette) async {
    // Charger les wallets AVANT d'ouvrir la feuille
    final uid = ref.read(currentUserProvider)?.id ?? '';
    if (uid.isNotEmpty) {
      try {
        await ref.read(walletStateProvider.notifier).loadWallets(uid);
      } catch (e) {
        Logger.error('Erreur chargement wallets: $e');
      }
    }

    if (!mounted) return;

    // Lu ici (et non dans le builder de la feuille) : ref.watch n'est
    // autorisé que pendant le build du widget.
    final monnaie = ref.read(userMonnaieProvider);
    final montantCtrl = TextEditingController();
    String? walletId;
    String? erreur;

    final List<WalletModel> walletList = ref.read(walletStateProvider).wallets;

    Logger.info('Wallets chargés pour remboursement: ${walletList.length}');

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final canSubmit = walletId != null && walletList.isNotEmpty;

          return _sheetShell(
            ctx,
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sheetHandle(),
                _sheetHeader(
                  icon: Icons.payments_outlined,
                  color: TAPAColors.green,
                  title: 'Rembourser',
                  subtitle: _typeLabel(dette.type),
                  onClose: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TAPAColors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 20, color: TAPAColors.green),
                      const SizedBox(width: 10),
                      const Text(
                        'Montant restant',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TAPAColors.textSecond,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            Fmt.montant(dette.montantRestant, monnaie: monnaie),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: TAPAColors.navy,
                            ),
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
                    hint: 'Ex : 10000',
                    icon: Icons.payments_outlined,
                    isRequired: true,
                    suffixText: monnaie,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setModalState(() {
                      montantCtrl.text =
                          dette.montantRestant.toStringAsFixed(0);
                    }),
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Solder la totalité'),
                    style: TextButton.styleFrom(
                      foregroundColor: TAPAColors.navy,
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: walletId,
                  isExpanded: true,
                  decoration: _fieldDecoration(
                    label: 'Portefeuille',
                    hint: walletList.isEmpty
                        ? 'Créez un portefeuille d\'abord'
                        : 'Choisir un portefeuille',
                    icon: Icons.wallet_outlined,
                    isRequired: true,
                  ),
                  items: walletList.map((wallet) {
                    return DropdownMenuItem<String>(
                      value: wallet.id,
                      child: Text(
                        '${wallet.emoji} ${wallet.nom}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: walletList.isEmpty
                      ? null
                      : (v) => setModalState(() => walletId = v),
                ),
                if (walletList.isEmpty)
                  _errorBanner(
                      'Aucun portefeuille disponible. Créez-en un d\'abord.'),
                if (erreur != null) _errorBanner(erreur!),
                const SizedBox(height: 20),
                _primaryButton(
                  label: canSubmit
                      ? 'Confirmer le remboursement'
                      : 'Sélectionnez un portefeuille',
                  color: TAPAColors.green,
                  onPressed: canSubmit
                      ? () {
                          final montant =
                              double.tryParse(montantCtrl.text) ?? 0;
                          if (montant <= 0) {
                            setModalState(
                                () => erreur = 'Saisissez un montant valide.');
                            return;
                          }
                          if (montant > dette.montantRestant) {
                            setModalState(() =>
                                erreur = 'Le montant dépasse le restant dû.');
                            return;
                          }
                          Navigator.pop(ctx, {
                            'montant': montant,
                            'walletId': walletId,
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: TAPAColors.textSecond),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result == null) return;

    try {
      final montant = result['montant'] as double;
      final walletIdValue = result['walletId'] as String;

      Logger.info('Remboursement: $montant sur wallet $walletIdValue');

      final params = RembourserDetteParams(
        detteId: dette.id,
        montant: montant,
        walletId: walletIdValue,
      );

      final rembourserResult =
          await ref.read(rembourserDetteProvider(params).future);

      if (!mounted) return;

      if (rembourserResult.success) {
        _snack('Remboursement effectué avec succès');
        final uid = ref.read(currentUserProvider)?.id ?? '';
        if (uid.isNotEmpty) {
          // 1. Invalider le cache des dettes
          ref.invalidate(getDettesProvider(uid));

          // 2. Invalider le cache du StreamProvider des portefeuilles
          ref.invalidate(walletListProvider(uid));

          // 3. Laisser la modification se propager dans Firestore
          await Future.delayed(const Duration(milliseconds: 300));

          // 4. Recharger les dettes
          await ref.read(dettesStateProvider.notifier).loadDettes(uid);

          // 5. Recharger le StateNotifier des portefeuilles (CRUCIAL)
          await ref.read(walletStateProvider.notifier).loadWallets(uid);
        }
      } else {
        _snack(rembourserResult.message ?? 'Erreur', error: true);
      }
    } catch (e) {
      Logger.error('Erreur remboursement: $e');
      _snack('Erreur : ${e.toString().replaceAll('Exception: ', '')}',
          error: true);
    }
  }

  // ==========================================================
  // SUPPRIMER
  // ==========================================================
  Future<void> _supprimerDette(DetteModel dette) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: TAPAColors.red.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: TAPAColors.red, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Supprimer cette entrée ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cette ${_typeLabel(dette.type).toLowerCase()} sera supprimée définitivement. Cette action est irréversible.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: TAPAColors.textSecond,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: TAPAColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: TAPAColors.textSecond,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TAPAColors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Supprimer',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
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

    if (confirm != true) return;

    try {
      Logger.info('Suppression dette: ${dette.id}');

      final deleteResult = await ref.read(deleteDetteProvider(dette.id).future);

      if (!mounted) return;

      if (deleteResult.success) {
        _snack('Entrée supprimée');
        final uid = ref.read(currentUserProvider)?.id ?? '';
        if (uid.isNotEmpty) {
          await ref.read(dettesStateProvider.notifier).loadDettes(uid);
        }
      } else {
        _snack(deleteResult.message ?? 'Erreur', error: true);
      }
    } catch (e) {
      Logger.error('Erreur suppression dette: $e');
      _snack('Erreur : ${e.toString().replaceAll('Exception: ', '')}',
          error: true);
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);
    final state = ref.watch(dettesStateProvider);
    final dettes = state.dettes;
    final loading = state.isLoading;

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Mes dettes',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: TAPAColors.navy),
            )
          : _buildBody(dettes, monnaie),
      floatingActionButton: (loading || dettes.isEmpty)
          ? null
          : FloatingActionButton.extended(
              onPressed: _ajouterDette,
              backgroundColor: TAPAColors.navy,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_rounded, color: TAPAColors.gold),
              label: const Text(
                'Ajouter',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody(List<DetteModel> dettes, String monnaie) {
    if (dettes.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          ),
        ],
      );
    }

    final totalDettes = dettes
        .where((d) => d.type == 'dette')
        .fold<double>(0, (sum, d) => sum + d.montantRestant);
    final totalCreances = dettes
        .where((d) => d.type == 'creance')
        .fold<double>(0, (sum, d) => sum + d.montantRestant);

    final items = _filtrer(dettes);

    return RefreshIndicator(
      color: TAPAColors.navy,
      onRefresh: _chargerDettes,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildSummaryHeader(totalDettes, totalCreances, monnaie),
          ),
          SliverToBoxAdapter(child: _buildFilter(dettes)),
          SliverToBoxAdapter(child: _buildListTitle(items.length)),
          if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucun résultat pour ce filtre',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TAPAColors.textSecond),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) => _buildDetteCard(items[index], monnaie),
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // EN-TÊTE RÉSUMÉ
  // ==========================================================
  Widget _buildSummaryHeader(
    double totalDettes,
    double totalCreances,
    String monnaie,
  ) {
    final solde = totalCreances - totalDettes;
    final total = totalDettes + totalCreances;

    final IconData soldeIcon = solde > 0
        ? Icons.trending_up_rounded
        : solde < 0
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;
    final String soldeCaption = solde > 0
        ? 'Position positive'
        : solde < 0
            ? 'Position négative'
            : 'Position équilibrée';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      decoration: const BoxDecoration(
        gradient: _heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Solde net',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(soldeIcon, size: 14, color: TAPAColors.gold),
                    const SizedBox(width: 5),
                    Text(
                      soldeCaption,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.montant(solde, monnaie: monnaie),
              maxLines: 1,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    Expanded(
                      flex:
                          ((totalDettes / total) * 1000).round().clamp(1, 999),
                      child: Container(color: const Color(0xFFFF6B6B)),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: ((totalCreances / total) * 1000)
                          .round()
                          .clamp(1, 999),
                      child: Container(color: const Color(0xFF4CD787)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _summaryTile(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Je dois',
                  value: Fmt.montant(totalDettes, monnaie: monnaie),
                  color: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryTile(
                  icon: Icons.arrow_upward_rounded,
                  label: 'On me doit',
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

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FILTRE (contrôle segmenté)
  // ==========================================================
  Widget _buildFilter(List<DetteModel> all) {
    final nbDettes = all.where((d) => d.type == 'dette').length;
    final nbCreances = all.where((d) => d.type == 'creance').length;

    Widget segment(String value, String label, int count) {
      final selected = _filtre == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _filtre = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? TAPAColors.navy : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : TAPAColors.textSecond,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withOpacity(0.2)
                          : TAPAColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : TAPAColors.textSecond,
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TAPAColors.border),
      ),
      child: Row(
        children: [
          segment('toutes', 'Toutes', all.length),
          segment('dette', 'Dettes', nbDettes),
          segment('creance', 'Créances', nbCreances),
        ],
      ),
    );
  }

  Widget _buildListTitle(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Mes entrées',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: TAPAColors.navy,
              ),
            ),
          ),
          Text(
            count > 1 ? '$count entrées' : '$count entrée',
            style: const TextStyle(
              fontSize: 12,
              color: TAPAColors.textSecond,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 22),
            const Text(
              'Aucune dette enregistrée',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez vos dettes et créances pour suivre vos remboursements facilement.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TAPAColors.textSecond,
                height: 1.45,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _ajouterDette,
                icon: const Icon(Icons.add_rounded, color: TAPAColors.gold),
                label: const Text(
                  'Ajouter une entrée',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAPAColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
  // CARTE D'UNE DETTE
  // ==========================================================
  Widget _statusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetteCard(DetteModel dette, String monnaie) {
    final progress = dette.progression.clamp(0.0, 1.0).toDouble();
    final pct = (progress * 100).round();
    final isDette = dette.type == 'dette';
    final color = isDette ? TAPAColors.red : TAPAColors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dette.estSolde
              ? TAPAColors.green.withOpacity(0.5)
              : TAPAColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: TAPAColors.navy.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête : icône, titre, statut ──
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isDette
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _typeLabel(dette.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: TAPAColors.navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${dette.modalite} · ${dette.periodesMois} mois',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TAPAColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ),
              if (dette.estSolde) ...[
                const SizedBox(width: 8),
                _statusChip(
                    'Soldé', Icons.check_circle_rounded, TAPAColors.green),
              ] else if (dette.enAttente) ...[
                const SizedBox(width: 8),
                _statusChip(
                    'En attente', Icons.schedule_rounded, TAPAColors.red),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // ── Bloc montants + progression ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TAPAColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reste à régler',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: TAPAColors.textSecond,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              Fmt.montant(dette.montantRestant,
                                  monnaie: monnaie),
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: TAPAColors.navy,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: dette.estSolde ? TAPAColors.green : color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: TAPAColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      dette.estSolde ? TAPAColors.green : color,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Remboursé ${Fmt.montant(dette.montantRembourse, monnaie: monnaie)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: TAPAColors.textSecond,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total ${Fmt.montant(dette.montantTotal, monnaie: monnaie)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: TAPAColors.textSecond,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Actions ──
          Row(
            children: [
              Expanded(
                child: dette.estSolde
                    ? Container(
                        height: 46,
                        alignment: Alignment.centerLeft,
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 18, color: TAPAColors.green),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Entièrement réglé',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: TAPAColors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => _rembourser(dette),
                          icon: const Icon(Icons.payments_outlined, size: 18),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Rembourser',
                              maxLines: 1,
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TAPAColors.navy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 46,
                height: 46,
                child: OutlinedButton(
                  onPressed: () => _supprimerDette(dette),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: TAPAColors.red,
                    side: BorderSide(color: TAPAColors.red.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BARRE DE NAVIGATION INFÉRIEURE
  // ==========================================================
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: TAPAColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
                index: 0,
                route: '/home',
              ),
              _buildNavItem(
                icon: Icons.shield_outlined,
                activeIcon: Icons.shield_rounded,
                label: 'Assurance',
                index: 1,
                route: '/investir/assurance',
              ),
              _buildNavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Enveloppe',
                index: 2,
                route: '/savings',
              ),
              _buildNavItem(
                icon: Icons.pie_chart_outline_rounded,
                activeIcon: Icons.pie_chart_rounded,
                label: 'Budget',
                index: 3,
                route: '/budget',
              ),
              _buildNavItem(
                icon: Icons.credit_card_outlined,
                activeIcon: Icons.credit_card_rounded,
                label: 'Dettes',
                index: 4,
                route: '/dettes',
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
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
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: isActive ? 46 : 36,
              height: 30,
              decoration: BoxDecoration(
                color: isActive
                    ? TAPAColors.navy.withOpacity(0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? TAPAColors.navy : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                    color: isActive ? TAPAColors.navy : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
