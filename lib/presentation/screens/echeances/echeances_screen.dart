import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../services/notification_service.dart';
import '../../../core/utils/formatters.dart';

class EcheancesScreen extends ConsumerStatefulWidget {
  const EcheancesScreen({super.key});
  @override
  ConsumerState<EcheancesScreen> createState() => _EcheancesScreenState();
}

class _EcheancesScreenState extends ConsumerState<EcheancesScreen> {
  List<EcheanceModel> get _echeances =>
      ref.watch(echeancesStateProvider).echeances;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final uid = ref.read(currentUserProvider)?.id ?? '';
    if (uid.isEmpty) return;
    await ref.read(echeancesStateProvider.notifier).loadEcheances(uid);
  }

  Future<void> _supprimer(EcheanceModel e) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('Supprimer ?'),
            content: Text('Supprimer l echeance "${e.titre}" ?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuler')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Supprimer',
                      style: TextStyle(color: TAPAColors.red))),
            ]));
    if (ok == true) {
      await ref.read(deleteEcheanceProvider(e.id).future);
      await NotificationService.annulerEcheance(e.id);
    }
  }

  Color _couleurType(String type) {
    switch (type) {
      case 'mensuelle': return TAPAColors.navy;
      case 'hebdomadaire': return TAPAColors.green;
      default: return TAPAColors.purple;
    }
  }

  String _labelType(String type) {
    switch (type) {
      case 'mensuelle': return 'Mensuelle';
      case 'hebdomadaire': return 'Hebdomadaire';
      default: return 'Date unique';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(currentUserProvider);
    final monnaie = user?.monnaie ?? 'FCFA';

    return Scaffold(
        backgroundColor: TAPAColors.background,
        appBar: AppBar(
            title: const Text('Mes echeances'),
            backgroundColor: TAPAColors.navy,
            foregroundColor: TAPAColors.white,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => context.pop()),
            actions: [
              IconButton(
                  icon: const Icon(Icons.add, color: TAPAColors.gold),
                  onPressed: () async {
                    await context.push('/echeances/ajouter');
                    _charger();
                  }),
            ]),
        body: _echeances.isEmpty
            ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm_outlined,
                  size: 60, color: TAPAColors.textHint),
              const SizedBox(height: 16),
              const Text('Aucune echeance',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TAPAColors.navy)),
              const SizedBox(height: 8),
              const Text(
                  'Ajoutez vos echeances pour recevoir\ndes rappels automatiques.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TAPAColors.textSecond)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                  onPressed: () async {
                    await context.push('/echeances/ajouter');
                    _charger();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une echeance'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: TAPAColors.navy)),
            ]))
            : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _echeances.length,
            itemBuilder: (ctx, i) {
              final e = _echeances[i];
              final couleur = _couleurType(e.type);
              return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: TAPAColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: TAPAColors.border, width: 0.5)),
                  child: Row(children: [
                    Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                            color: couleur.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.alarm,
                            color: couleur, size: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.titre,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: TAPAColors.navy)),
                          const SizedBox(height: 3),
                          Text(
                              Fmt.montant(e.montant, monnaie: monnaie),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: couleur)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color: couleur.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(_labelType(e.type),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: couleur))),
                            const SizedBox(width: 6),
                            Text(e.descriptionRecurrence,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: TAPAColors.textSecond)),
                          ]),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.notifications_outlined,
                                size: 12, color: TAPAColors.gold),
                            const SizedBox(width: 4),
                            Text('Rappel ${e.descriptionRappel}',
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    color: TAPAColors.gold)),
                          ]),
                        ])),
                    IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: TAPAColors.textHint, size: 20),
                        onPressed: () => _supprimer(e)),
                  ]));
            }));
  }
}