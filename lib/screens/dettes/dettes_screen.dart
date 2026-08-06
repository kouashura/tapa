// lib/screens/dettes/dettes_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../services/db_service_mysql.dart';
import '../../models/models.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';

class DettesScreen extends ConsumerStatefulWidget {
  const DettesScreen({super.key});

  @override
  ConsumerState<DettesScreen> createState() => _DettesScreenState();
}

class _DettesScreenState extends ConsumerState<DettesScreen> {
  final DBService _db = DBService();
  int _selectedIndex = 4;
  List<DetteModel> _dettes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chargerDettes();
  }

  Future<void> _chargerDettes() async {
    setState(() => _loading = true);
    // TODO: Remplacer par un provider
    // _dettes = await ref.read(detteListProvider.future);
    _dettes = _db.getDettes();
    setState(() => _loading = false);
  }

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  Future<void> _ajouterDette() async {
    final typeCtrl = TextEditingController();
    final montantCtrl = TextEditingController();
    final modaliteCtrl = TextEditingController();
    final periodesCtrl = TextEditingController();
    String type = 'dette'; // 'dette' ou 'creance'
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
            decoration: const BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TAPAColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Ajouter une dette',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => type = 'dette'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: type == 'dette'
                                ? TAPAColors.red
                                : TAPAColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: type == 'dette'
                                  ? TAPAColors.red
                                  : TAPAColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Dette',
                              style: TextStyle(
                                color: type == 'dette'
                                    ? Colors.white
                                    : TAPAColors.textSecond,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => type = 'creance'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: type == 'creance'
                                ? TAPAColors.green
                                : TAPAColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: type == 'creance'
                                  ? TAPAColors.green
                                  : TAPAColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Créance',
                              style: TextStyle(
                                color: type == 'creance'
                                    ? Colors.white
                                    : TAPAColors.textSecond,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: typeCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    hintText: 'ex : Dette scolaire',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montantCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Montant total',
                    hintText: '100 000',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modaliteCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Modalité de remboursement',
                    hintText: 'ex : Mensuel',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: periodesCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Nombre de périodes (mois)',
                    hintText: '12',
                    border: OutlineInputBorder(),
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
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: TAPAColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date début',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: TAPAColors.textSecond,
                                ),
                              ),
                              Text(
                                '${dateDebut.day}/${dateDebut.month}/${dateDebut.year}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: TAPAColors.navy,
                                  fontWeight: FontWeight.w600,
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
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: TAPAColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date fin',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: TAPAColors.textSecond,
                                ),
                              ),
                              Text(
                                '${dateFin.day}/${dateFin.month}/${dateFin.year}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: TAPAColors.navy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
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
                      backgroundColor: TAPAColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Ajouter',
                      style: TextStyle(color: TAPAColors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
        final userId = await ref.read(userRepositoryProvider).getCurrentUserId();
        final dette = DetteModel(
          id: Fmt.genId(),
          uuid: Fmt.genId(),
          utilisateurId: int.tryParse(userId) ?? 1,
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

        // TODO: Utiliser un provider
        // await ref.read(detteRepositoryProvider).addDette(dette);
        Logger.info('📝 Dette ajoutée: ${dette.type}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dette ajoutée avec succès !'),
              backgroundColor: TAPAColors.green,
            ),
          );
          _chargerDettes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: TAPAColors.red,
            ),
          );
        }
        Logger.error('❌ Erreur ajout dette: $e');
      }
    }
  }

  Future<void> _rembourser(DetteModel dette) async {
    final montantCtrl = TextEditingController();
    String? walletId;

    // TODO: Récupérer les wallets
    final wallets = _db.getWallets();

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
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TAPAColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Rembourser',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Montant restant: ${Fmt.montant(dette.montantRestant, monnaie: ref.watch(userMonnaieProvider))}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: TAPAColors.textSecond,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montantCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Montant du remboursement',
                    hintText: '0',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: walletId,
                  decoration: const InputDecoration(
                    labelText: 'Portefeuille',
                    border: OutlineInputBorder(),
                  ),
                  items: wallets.map((w) =>
                      DropdownMenuItem<String>(
                        value: w.id?.toString(),
                        child: Text('${w.emoji} ${w.nom}'),
                      ),
                  ).toList(),
                  onChanged: (v) => setModalState(() => walletId = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
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
                      backgroundColor: TAPAColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Confirmer le remboursement',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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

        // TODO: Utiliser un provider
        // await ref.read(detteRepositoryProvider).rembourser(dette.id, remboursement);
        Logger.info('📝 Remboursement effectué: $montant');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Remboursement effectué avec succès !'),
              backgroundColor: TAPAColors.green,
            ),
          );
          _chargerDettes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: TAPAColors.red,
            ),
          );
        }
        Logger.error('❌ Erreur remboursement: $e');
      }
    }
  }

  Future<void> _supprimerDette(DetteModel dette) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer la dette "${dette.type}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: TAPAColors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // TODO: Utiliser un provider
        // await ref.read(detteRepositoryProvider).deleteDette(dette.id);
        Logger.info('🗑️ Dette supprimée: ${dette.type}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dette supprimée !'),
              backgroundColor: TAPAColors.green,
            ),
          );
          _chargerDettes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: TAPAColors.red,
            ),
          );
        }
        Logger.error('❌ Erreur suppression dette: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Mes dettes'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
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
          : _buildDetteList(monnaie),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.credit_card_outlined,
            size: 60,
            color: TAPAColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune dette enregistrée',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: TAPAColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez vos dettes pour suivre\nvos remboursements.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TAPAColors.textSecond),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _ajouterDette,
            icon: const Icon(Icons.add, color: TAPAColors.gold),
            label: const Text('Ajouter une dette'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetteList(String monnaie) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dettes.length,
      itemBuilder: (ctx, index) {
        final dette = _dettes[index];
        final progress = dette.progression;
        final isDette = dette.type == 'dette';
        final color = isDette ? TAPAColors.red : TAPAColors.green;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dette.estSolde ? TAPAColors.green : color.withOpacity(0.3),
              width: dette.estSolde ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDette
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
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
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: TAPAColors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Soldé',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: TAPAColors.green,
                        ),
                      ),
                    ),
                  if (dette.enAttente)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: TAPAColors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'En attente',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: TAPAColors.red,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
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
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: TAPAColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!dette.estSolde)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rembourser(dette),
                        icon: const Icon(Icons.payments_outlined, size: 16),
                        label: const Text('Rembourser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TAPAColors.navy,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  if (!dette.estSolde) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _supprimerDette(dette),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TAPAColors.red,
                        side: const BorderSide(color: TAPAColors.red),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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