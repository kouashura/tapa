// lib/screens/savings/epargne_programmee_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';
import '../../services/link_service.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';  // ✅ IMPORT AJOUTÉ

class EpargneProgrammeeScreen extends ConsumerStatefulWidget {
  const EpargneProgrammeeScreen({super.key});

  @override
  ConsumerState<EpargneProgrammeeScreen> createState() => _EpargneProgrammeeScreenState();
}

class _EpargneProgrammeeScreenState extends ConsumerState<EpargneProgrammeeScreen> {
  int _selectedIndex = 2;
  List<EpargneProgrammeeModel> _epargnes = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    // TODO: Remplacer par un provider
    setState(() {});
  }

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  Future<void> _effectuerDepot(EpargneProgrammeeModel ep) async {
    if (ep.verrouille) {
      _afficherDialogDeverrouillage(ep);
      return;
    }
    if (ep.termine) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Objectif atteint ! Épargne terminée.'),
          backgroundColor: TAPAColors.green,
        ),
      );
      return;
    }

    // ✅ CORRECTION: Utiliser userMonnaieProvider
    final monnaie = ref.watch(userMonnaieProvider);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le dépôt'),
        content: Text(
          'Effectuer un dépôt de '
              '${Fmt.montant(ep.montantParDepot, monnaie: monnaie)} '
              'pour "${ep.titre}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.green,
            ),
            child: const Text(
              'Confirmer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        // TODO: Utiliser un provider
        _charger();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Dépôt effectué ! +${Fmt.montant(ep.montantParDepot, monnaie: monnaie)}',
              ),
              backgroundColor: TAPAColors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: TAPAColors.red,
            ),
          );
        }
      }
    }
  }

  void _afficherDialogDeverrouillage(EpargneProgrammeeModel ep) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compte verrouillé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ce compte est verrouillé. Envoyez un WhatsApp à TAPA Invest '
                  'pour recevoir votre code de déverrouillage.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                LinkService.ouvrirWhatsApp(
                  message: 'Bonjour TAPA Invest ! Je souhaite déverrouiller '
                      'mon épargne programmée "${ep.titre}". '
                      'Pouvez-vous m\'envoyer le code ?',
                );
              },
              icon: const Icon(Icons.message_outlined),
              label: const Text('Contacter sur WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Entrez le code reçu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim() == ep.codeDeverrouillage) {
                  Navigator.pop(ctx);
                  final epMaj = ep.copyWith(verrouille: false);
                  // TODO: Utiliser un provider
                  _charger();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Compte déverrouillé !'),
                        backgroundColor: TAPAColors.green,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Code incorrect'),
                      backgroundColor: TAPAColors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TAPAColors.navy,
              ),
              child: const Text(
                'Déverrouiller',
                style: TextStyle(color: TAPAColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _supprimer(EpargneProgrammeeModel ep) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer l\'épargne "${ep.titre}" ?'),
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
    if (ok == true) {
      // TODO: Utiliser un provider
      _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECTION: Utiliser userMonnaieProvider
    final monnaie = ref.watch(userMonnaieProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Épargne programmée'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: TAPAColors.gold),
            onPressed: () async {
              await context.push('/epargne-programmee/creer');
              _charger();
            },
          ),
        ],
      ),
      body: _epargnes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💰', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Aucune épargne programmée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre première épargne\nprogrammée et atteignez vos objectifs !',
              textAlign: TextAlign.center,
              style: TextStyle(color: TAPAColors.textSecond),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await context.push('/epargne-programmee/creer');
                _charger();
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer une épargne'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TAPAColors.navy,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _epargnes.length,
        itemBuilder: (ctx, i) {
          final ep = _epargnes[i];
          return _carteEpargne(ep, monnaie);
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _carteEpargne(EpargneProgrammeeModel ep, String monnaie) {
    final couleur = ep.termine
        ? TAPAColors.green
        : ep.verrouille
        ? TAPAColors.red
        : TAPAColors.navy;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ep.verrouille
              ? TAPAColors.red.withOpacity(0.3)
              : TAPAColors.border,
          width: ep.verrouille ? 1.5 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ep.titre,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: TAPAColors.navy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (ep.verrouille)
                            const Icon(Icons.lock, size: 16, color: TAPAColors.red),
                          if (ep.termine)
                            const Icon(Icons.check_circle, size: 16, color: TAPAColors.green),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ep.descriptionFrequence,
                        style: const TextStyle(
                          fontSize: 12,
                          color: TAPAColors.textSecond,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: TAPAColors.textHint, size: 20),
                  onPressed: () => _supprimer(ep),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Fmt.montant(ep.montantEpargne, monnaie: monnaie),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: couleur,
                            ),
                          ),
                          Text(
                            '/ ${Fmt.montant(ep.montantObjectif, monnaie: monnaie)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: TAPAColors.textSecond,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ep.pourcentageAtteint / 100,
                          minHeight: 10,
                          backgroundColor: TAPAColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(couleur),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${ep.pourcentageAtteint.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: couleur,
                            ),
                          ),
                          Text(
                            '${ep.joursRestants} jours restants',
                            style: const TextStyle(
                              fontSize: 11,
                              color: TAPAColors.textSecond,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statChip(
                  '${ep.nombreDepotsEffectues}/${ep.nombreDepotsTotal}',
                  'dépôts',
                  Icons.savings_outlined,
                ),
                const SizedBox(width: 8),
                _statChip(
                  Fmt.montant(ep.montantParDepot, monnaie: monnaie),
                  'par dépôt',
                  Icons.payments_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!ep.termine)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _effectuerDepot(ep),
                      icon: Icon(
                        ep.verrouille ? Icons.lock_open : Icons.add,
                        size: 18,
                      ),
                      label: Text(
                        ep.verrouille ? 'Déverrouiller' : 'Faire un dépôt',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ep.verrouille ? TAPAColors.red : TAPAColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TAPAColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: TAPAColors.green, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Objectif atteint !',
                      style: TextStyle(
                        color: TAPAColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String valeur, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TAPAColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TAPAColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: TAPAColors.textSecond),
          const SizedBox(width: 4),
          Text(
            '$valeur ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: TAPAColors.textSecond,
            ),
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