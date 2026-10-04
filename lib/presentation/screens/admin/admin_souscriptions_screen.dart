// lib/presentation/screens/admin/admin_souscriptions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../domain/usecases/souscriptions/admin_souscriptions_usecase.dart';
import '../../providers/providers.dart';

class AdminSouscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSouscriptionsScreen({super.key});

  @override
  ConsumerState<AdminSouscriptionsScreen> createState() =>
      _AdminSouscriptionsScreenState();
}

class _AdminSouscriptionsScreenState
    extends ConsumerState<AdminSouscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminSouscriptionsStateProvider.notifier).loadAllSouscriptions();
    });
  }

  Future<void> _valider(SouscriptionModel s) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider la souscription ?'),
        content: Text('Valider "${s.produitNom}" pour ${_format(s.montant)} FCFA ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await ref
          .read(adminSouscriptionsStateProvider.notifier)
          .updateStatut(s.reference, 'payee');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Souscription validee'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    }
  }

  Future<void> _annuler(SouscriptionModel s) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la souscription ?'),
        content: Text('Annuler "${s.produitNom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.red,
            ),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await ref
          .read(adminSouscriptionsStateProvider.notifier)
          .updateStatut(s.reference, 'annulee');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Souscription annulee'),
            backgroundColor: TAPAColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSouscriptionsStateProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Administration des souscriptions'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(adminSouscriptionsStateProvider.notifier)
              .loadAllSouscriptions();
        },
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(AdminSouscriptionsState state) {
    if (state.isLoading && state.souscriptions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: TAPAColors.gold),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _carteStatistiques(state),
        const SizedBox(height: 20),
        _filtres(state),
        const SizedBox(height: 16),
        if (state.souscriptionsFiltrees.isEmpty)
          _emptyState(state.filtre)
        else
          ...state.souscriptionsFiltrees.map((s) => _carteSouscription(s)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _carteStatistiques(AdminSouscriptionsState state) {
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
            'Total des souscriptions',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '${_format(state.montantTotal)} FCFA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _badge('${state.totalEnCours} en cours', TAPAColors.gold),
              const SizedBox(width: 8),
              _badge('${state.totalPayees} payees', const Color(0xFF27AE60)),
              const SizedBox(width: 8),
              _badge('${state.totalAnnulees} annulees', TAPAColors.red),
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

  Widget _filtres(AdminSouscriptionsState state) {
    final filtres = [
      ('toutes', 'Toutes'),
      ('en_cours', 'En cours'),
      ('payee', 'Payees'),
      ('annulee', 'Annulees'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filtres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filtres[i];
          final actif = state.filtre == f.$1;
          return GestureDetector(
            onTap: () => ref
                .read(adminSouscriptionsStateProvider.notifier)
                .setFiltre(f.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: actif ? TAPAColors.navy : TAPAColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: actif ? TAPAColors.navy : TAPAColors.border,
                ),
              ),
              child: Text(
                f.$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: actif ? TAPAColors.white : TAPAColors.navy,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(String filtre) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: TAPAColors.textSecond,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune souscription "$filtre"',
              style: const TextStyle(
                fontSize: 14,
                color: TAPAColors.textSecond,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteSouscription(SouscriptionModel s) {
    final couleur = s.estEnCours
        ? TAPAColors.gold
        : (s.estPayee ? const Color(0xFF27AE60) : TAPAColors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: couleur.withOpacity(0.3), width: 1.5),
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
                  s.estEnCours
                      ? Icons.hourglass_empty
                      : (s.estPayee ? Icons.check_circle : Icons.cancel),
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
                        fontSize: 10,
                        color: TAPAColors.textSecond,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${_format(s.montant)} F',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: couleur,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: TAPAColors.textSecond),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  s.clientNom.isNotEmpty
                      ? '${s.clientNom} ${s.clientPrenom}'
                      : s.userId,
                  style: const TextStyle(
                    fontSize: 11,
                    color: TAPAColors.textSecond,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${s.dateCreation.day.toString().padLeft(2, '0')}/${s.dateCreation.month.toString().padLeft(2, '0')}/${s.dateCreation.year}',
                style: const TextStyle(
                  fontSize: 11,
                  color: TAPAColors.textSecond,
                ),
              ),
            ],
          ),
          if (s.estEnCours) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _valider(s),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _annuler(s),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TAPAColors.red,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: TAPAColors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _format(double n) {
    final s = n.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
