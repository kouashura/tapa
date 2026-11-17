import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/admin/admin_sonam_provider.dart';

class AdminSonamContractsScreen extends ConsumerWidget {
  const AdminSonamContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(adminSonamContractsProvider);
    final filtered = ref.watch(adminSonamFilteredProvider);
    final stats = ref.watch(adminSonamStatsProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Contrats SONAM'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminSonamContractsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statsCard(stats),
            const SizedBox(height: 16),
            _filters(ref),
            const SizedBox(height: 16),
            contractsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: TAPAColors.navy),
                ),
              ),
              error: (e, _) => _errorState(e.toString()),
              data: (_) => filtered.isEmpty
                  ? _emptyState()
                  : Column(
                      children: filtered
                          .map((c) => _ContractCard(
                                contract: c,
                                onValidate: () => _onValidate(context, ref, c),
                                onReject: () => _onReject(context, ref, c),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsCard(AdminSonamStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TAPAColors.navy, Color(0xFF14274E)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total contrats',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '${stats.total}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge('${stats.enAttente} en attente', TAPAColors.gold),
              _badge('${stats.actifs} actifs', const Color(0xFF27AE60)),
              _badge('${stats.rachetes} rachetés', Colors.blueGrey),
              _badge('${stats.rejetes} rejetés', TAPAColors.red),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Montant souscrit (actifs)',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                _formatFcfa(stats.montantTotalActif),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _filters(WidgetRef ref) {
    final current = ref.watch(adminSonamFilterProvider);
    const labels = {
      AdminSonamFilter.tous: 'Tous',
      AdminSonamFilter.enAttente: 'En attente',
      AdminSonamFilter.actif: 'Actifs',
      AdminSonamFilter.rachete: 'Rachetés',
      AdminSonamFilter.rejete: 'Rejetés',
    };

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AdminSonamFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = AdminSonamFilter.values[i];
          final active = current == filter;
          return GestureDetector(
            onTap: () =>
                ref.read(adminSonamFilterProvider.notifier).state = filter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? TAPAColors.navy : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? TAPAColors.navy : Colors.grey.shade300,
                ),
              ),
              child: Text(
                labels[filter] ?? filter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : TAPAColors.navy,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun contrat dans cette catégorie',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Erreur de chargement'),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _onValidate(
      BuildContext context, WidgetRef ref, Map<String, dynamic> c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider ce contrat ?'),
        content: Text(
          'Police ${c['policeCode'] ?? 'N/A'}\n'
          'Assuré : ${_assureName(c)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref
        .read(adminSonamActionsProvider)
        .valider(c['id'] as String);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Contrat validé ✅' : 'Erreur de validation'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _onReject(
      BuildContext context, WidgetRef ref, Map<String, dynamic> c) async {
    final motifCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter ce contrat ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Police ${c['policeCode'] ?? 'N/A'}'),
            const SizedBox(height: 12),
            TextField(
              controller: motifCtrl,
              decoration: const InputDecoration(
                labelText: 'Motif du rejet',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final motif = motifCtrl.text.trim().isEmpty
        ? 'Rejeté par admin'
        : motifCtrl.text.trim();
    final ok = await ref
        .read(adminSonamActionsProvider)
        .rejeter(c['id'] as String, motif);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Contrat rejeté' : 'Erreur'),
        backgroundColor: ok ? Colors.red : Colors.red.shade900,
      ),
    );
  }

  static String _assureName(Map<String, dynamic> c) {
    final assure = c['assure'];
    if (assure is Map) {
      return (assure['nom_prenoms'] ?? 'Inconnu').toString();
    }
    return 'Inconnu';
  }

  static String _formatFcfa(num amount) {
    final digits = amount.round().abs().toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '${amount < 0 ? '-' : ''}$grouped FCFA';
  }
}

class _ContractCard extends StatelessWidget {
  final Map<String, dynamic> contract;
  final VoidCallback onValidate;
  final VoidCallback onReject;

  const _ContractCard({
    required this.contract,
    required this.onValidate,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final statut = contract['statut']?.toString() ?? 'Inconnu';
    final enAttente = statut == 'En attente de paiement';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statutColor(statut).withOpacity(0.3)),
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
                  color: _statutColor(statut).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _statutIcon(statut),
                  color: _statutColor(statut),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract['produit']?.toString() ?? 'Produit SONAM',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TAPAColors.navy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      contract['policeCode']?.toString() ?? 'N/A',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statutColor(statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statut,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _statutColor(statut),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _assureName(),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatFcfa(
                    (contract['totalVerse'] as num?)?.toDouble() ?? 0),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy,
                ),
              ),
            ],
          ),
          if (enAttente) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onValidate,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Rejeter'),
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
        ],
      ),
    );
  }

  String _assureName() {
    final assure = contract['assure'];
    if (assure is Map) {
      return (assure['nom_prenoms'] ?? 'Inconnu').toString();
    }
    return 'Inconnu';
  }

  static Color _statutColor(String statut) {
    switch (statut) {
      case 'Actif':
        return const Color(0xFF27AE60);
      case 'En attente de paiement':
        return TAPAColors.gold;
      case 'Racheté':
        return Colors.blueGrey;
      case 'Rejeté':
        return TAPAColors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData _statutIcon(String statut) {
    switch (statut) {
      case 'Actif':
        return Icons.check_circle;
      case 'En attente de paiement':
        return Icons.hourglass_empty;
      case 'Racheté':
        return Icons.swap_horiz;
      case 'Rejeté':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  static String _formatFcfa(num amount) {
    final digits = amount.round().abs().toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '${amount < 0 ? '-' : ''}$grouped FCFA';
  }
}
