// lib/presentation/screens/profile/historique_paiements_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';

class HistoriquePaiementsScreen extends ConsumerStatefulWidget {
  const HistoriquePaiementsScreen({super.key});

  @override
  ConsumerState<HistoriquePaiementsScreen> createState() =>
      _HistoriquePaiementsScreenState();
}

class _HistoriquePaiementsScreenState
    extends ConsumerState<HistoriquePaiementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref
            .read(souscriptionsStateProvider.notifier)
            .loadSouscriptions(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(souscriptionsStateProvider);
    final user = ref.watch(currentUserProvider);
    final monnaie = user?.monnaie ?? 'FCFA';

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Historique des paiements'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await ref
                .read(souscriptionsStateProvider.notifier)
                .loadSouscriptions(user.id);
          }
        },
        child: _buildBody(state, monnaie),
      ),
    );
  }

  Widget _buildBody(SouscriptionsState state, String monnaie) {
    if (state.isLoading && state.souscriptions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: TAPAColors.gold),
      );
    }

    if (state.error != null && state.souscriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 60, color: TAPAColors.red),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: TAPAColors.textSecond),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final user = ref.read(currentUserProvider);
                  if (user != null) {
                    ref
                        .read(souscriptionsStateProvider.notifier)
                        .loadSouscriptions(user.id);
                  }
                },
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.souscriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: TAPAColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 50,
                  color: TAPAColors.gold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucun paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vos souscriptions et paiements apparaitront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: TAPAColors.textSecond,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _carteTotaux(state, monnaie),
        const SizedBox(height: 20),
        const Text(
          'Historique',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: TAPAColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        ...state.souscriptions.map((s) => _carteSouscription(s, monnaie)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _carteTotaux(SouscriptionsState state, String monnaie) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TAPAColors.navy, Color(0xFF14274E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total paye',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            Fmt.montant(state.montantTotal, monnaie: monnaie),
            style: const TextStyle(
              color: TAPAColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _badge('${state.totalEnCours} en cours', TAPAColors.gold),
              const SizedBox(width: 8),
              _badge('${state.totalPayees} payees', TAPAColors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String texte, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texte,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: couleur,
        ),
      ),
    );
  }

  Widget _carteSouscription(SouscriptionModel s, String monnaie) {
    final couleur = s.estEnCours
        ? TAPAColors.gold
        : (s.estPayee ? TAPAColors.green : TAPAColors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TAPAColors.border, width: 0.5),
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
                  color: couleur.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  s.estEnCours ? Icons.hourglass_empty : Icons.check_circle,
                  color: couleur,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.produitNom,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TAPAColors.navy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      s.reference,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TAPAColors.textSecond,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Fmt.montant(s.montant, monnaie: monnaie),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: couleur.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.estEnCours ? 'En cours' : (s.estPayee ? 'Payee' : 'Annulee'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: couleur,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${s.dateCreation.day.toString().padLeft(2, '0')}/${s.dateCreation.month.toString().padLeft(2, '0')}/${s.dateCreation.year}',
            style: const TextStyle(
              fontSize: 11,
              color: TAPAColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }
}
