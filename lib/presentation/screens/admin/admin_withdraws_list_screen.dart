import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/admin/admin_provider.dart';

class AdminWithdrawsListScreen extends ConsumerWidget {
  const AdminWithdrawsListScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(adminWithdrawsProvider);
    await ref.read(adminWithdrawsProvider.future);
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String id,
    String action,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          action == 'approve'
              ? 'Approuver le retrait ?'
              : 'Rejeter le retrait ?',
        ),
        content: Text(
          action == 'approve'
              ? "L'argent sera envoye au client."
              : 'Le montant sera rembourse sur le wallet du client.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? Colors.green : Colors.red,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final repo = ref.read(adminRepositoryProvider);
    final success = action == 'approve'
        ? await repo.approveWithdraw(id)
        : await repo.rejectWithdraw(id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (action == 'approve'
                  ? 'Retrait approuve'
                  : 'Retrait rejete')
              : 'Erreur lors du traitement',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) await _refresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWithdraws = ref.watch(adminWithdrawsProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Demandes de retrait'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: asyncWithdraws.isLoading
                ? null
                : () => _refresh(ref),
          ),
        ],
      ),
      body: asyncWithdraws.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TAPAColors.navy),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _refresh(ref),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (withdraws) {
          if (withdraws.isEmpty) {
            return const Center(
              child: Text(
                'Aucune demande en attente',
                style: TextStyle(
                  fontSize: 16,
                  color: TAPAColors.textSecond,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: withdraws.length,
              itemBuilder: (context, index) {
                final w = withdraws[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${w['amount']} FCFA',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: TAPAColors.navy,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${w['operator'] ?? ''}',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Tel: ${w['phone'] ?? ''}'),
                        Text(
                          'ID: ${w['userId'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _handleAction(
                                  context,
                                  ref,
                                  w['id'].toString(),
                                  'reject',
                                ),
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Rejeter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleAction(
                                  context,
                                  ref,
                                  w['id'].toString(),
                                  'approve',
                                ),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text(
                                  'Approuver',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
