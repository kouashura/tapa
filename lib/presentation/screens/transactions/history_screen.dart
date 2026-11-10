// lib/screens/transactions/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../core/theme/app_theme.dart';

import '../../../data/models/models.dart'; // ✅ CORRIGÉ
import '../../../core/utils/constants.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String _filtre = 'tout';
  String _periode = 'tout';
  String? _filtreCategorie;
  int _refreshKey = 0;

  List<TransactionModel> get _transactions {
    final uid = ref.read(currentUserProvider)?.id ?? '';
    if (uid.isEmpty) return [];
    return ref.watch(transactionListProvider(uid)).value ?? [];
  }

  List<WalletModel> get _wallets {
    final uid = ref.read(currentUserProvider)?.id ?? '';
    if (uid.isEmpty) return [];
    return ref.watch(walletListProvider(uid)).value ?? [];
  }

  List<Map<String, dynamic>> get _categories =>
      ref.watch(allCategoriesProvider);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Les providers gerent le chargement automatiquement
    if (mounted) setState(() {});
  }

  List<TransactionModel> get _filteredTransactions {
    var txs = _transactions;
    if (_dateDebut != null) {
      txs = txs
          .where((t) => t.dateTransaction
              .isAfter(_dateDebut!.subtract(const Duration(days: 1))))
          .toList();
    }
    if (_dateFin != null) {
      txs = txs
          .where((t) => t.dateTransaction
              .isBefore(_dateFin!.add(const Duration(days: 1))))
          .toList();
    }
    if (_filtre == 'depenses') {
      txs = txs.where((t) => t.isDepense).toList();
    } else if (_filtre == 'revenus') {
      txs = txs.where((t) => t.isRevenu).toList();
    }
    if (_filtreCategorie != null) {
      txs = txs.where((t) => t.categorieId == _filtreCategorie).toList();
    }
    final now = DateTime.now();
    if (_periode == 'jour') {
      txs = txs
          .where((t) =>
              t.dateTransaction.year == now.year &&
              t.dateTransaction.month == now.month &&
              t.dateTransaction.day == now.day)
          .toList();
    } else if (_periode == 'semaine') {
      final debut = now.subtract(const Duration(days: 7));
      txs = txs.where((t) => t.dateTransaction.isAfter(debut)).toList();
    } else if (_periode == 'mois') {
      txs = txs
          .where((t) =>
              t.dateTransaction.month == now.month &&
              t.dateTransaction.year == now.year)
          .toList();
    }
    txs.sort((a, b) => b.dateTransaction.compareTo(a.dateTransaction));
    return txs;
  }

  void _modifier(TransactionModel tx) {
    final ctrl = TextEditingController(text: tx.montant.round().toString());
    DateTime selectedDate = tx.dateTransaction;
    final monnaie = ref.watch(userMonnaieProvider);
    final userCats = _categories;
    final catsRevenu = userCats.where((c) => c['type'] == 'revenu').toList();
    final catsDepense = userCats
        .where((c) => c['type'] == 'depense' || c['type'] == 'dépense')
        .toList();
    final catsRevenuFinal = catsRevenu.isNotEmpty
        ? catsRevenu
        : AppConstants.categoriesRevenu
            .map((c) => {
                  'id': c['id'] as String,
                  'label': c['label'] as String,
                  'emoji': c['emoji'] as String,
                  'type': 'revenu'
                })
            .toList();
    final catsDepenseFinal = catsDepense.isNotEmpty
        ? catsDepense
        : AppConstants.categoriesDepense
            .map((c) => {
                  'id': c['id'] as String,
                  'label': c['label'] as String,
                  'emoji': c['emoji'] as String,
                  'type': 'depense'
                })
            .toList();
    final cats = tx.isRevenu ? catsRevenuFinal : catsDepenseFinal;
    var selCat = tx.categorieId;
    var selLabel = tx.categorieLabel;
    var selEmoji = tx.categorieEmoji;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Text(selEmoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  const Text('Modifier la transaction',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Montant',
                    suffixText: monnaie,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: cats.any((c) => c['id'] == selCat)
                      ? selCat
                      : cats.first['id'] as String,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Catégorie', border: OutlineInputBorder()),
                  items: cats
                      .map((c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text('${c['emoji']} ${c['label']}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final cat = cats.firstWhere((c) => c['id'] == v);
                    setModal(() {
                      selCat = cat['id'] as String? ?? selCat;
                      selLabel = cat['label'] as String? ?? selLabel;
                      selEmoji = cat['emoji'] as String? ?? selEmoji;
                    });
                  },
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setModal(() => selectedDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.black, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style:
                            const TextStyle(fontSize: 15, color: Colors.black),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final montant = double.tryParse(ctrl.text) ?? tx.montant;
                      // ✅ CORRECTION : Utiliser le bon constructeur
                      final nouvelle = TransactionModel(
                        id: tx.id,
                        uid: tx.uid,
                        walletId: tx.walletId,
                        montant: montant,
                        type: tx.type,
                        categorieId: selCat,
                        categorieLabel: selLabel,
                        categorieEmoji: selEmoji,
                        note: tx.note,
                        dateTransaction: selectedDate,
                        createdAt: tx.createdAt,
                      );
                      try {
                        // TODO: Utiliser un provider
                        // await ref.read(transactionRepositoryProvider).updateTransaction(tx, nouvelle);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          _loadData();
                          setState(() => _refreshKey++);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Transaction modifiée !'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Enregistrer',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _supprimer(TransactionModel tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content:
            const Text('La transaction sera supprimée et le solde corrigé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        // TODO: Utiliser un provider
        // await ref.read(transactionRepositoryProvider).deleteTransaction(tx);
        if (mounted) {
          _loadData();
          setState(() => _refreshKey++);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Transaction supprimée !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);
    final txs = _filteredTransactions;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: TAPAColors.navy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_outlined, color: TAPAColors.gold),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme:
                        const ColorScheme.light(primary: TAPAColors.navy),
                  ),
                  child: child!,
                ),
              );
              if (range != null) {
                setState(() {
                  _dateDebut = range.start;
                  _dateFin = range.end;
                  _periode = 'custom';
                });
              }
            },
          ),
          if (_dateDebut != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white54),
              onPressed: () => setState(() {
                _dateDebut = null;
                _dateFin = null;
                _periode = 'tout';
              }),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtres période
          Container(
            color: TAPAColors.navy,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filtreBtn('Tout', 'tout', isPeriode: true),
                  _filtreBtn('Auj.', 'jour', isPeriode: true),
                  _filtreBtn('7 jours', 'semaine', isPeriode: true),
                  _filtreBtn('Ce mois', 'mois', isPeriode: true),
                ],
              ),
            ),
          ),
          // Filtres type
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filtreBtn('Tout', 'tout'),
                _filtreBtn('Dépenses', 'depenses'),
                _filtreBtn('Revenus', 'revenus'),
              ],
            ),
          ),
          // Filtre par catégorie
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _filtreCategorie = null),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _filtreCategorie == null
                            ? TAPAColors.navy
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _filtreCategorie == null
                              ? TAPAColors.navy
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        'Toutes',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _filtreCategorie == null
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  ..._categories.map((cat) {
                    final isActive = _filtreCategorie == cat['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _filtreCategorie =
                          isActive ? null : cat['id'] as String?),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive ? TAPAColors.navy : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? TAPAColors.navy
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '${cat['emoji']} ${cat['label']}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                isActive ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Total si filtre catégorie actif
          if (_filtreCategorie != null)
            Builder(builder: (ctx) {
              final total = txs.fold(0.0, (s, t) => s + t.montant);
              final cat = _categories.firstWhere(
                (c) => c['id'] == _filtreCategorie,
                orElse: () => {'label': '', 'emoji': ''},
              );
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TAPAColors.navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TAPAColors.navy.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Text(
                      '${cat['emoji']} ${cat['label']}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TAPAColors.navy),
                    ),
                    const Spacer(),
                    Text(
                      '${txs.length} transaction(s) — ',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      '${total.toStringAsFixed(0)} $monnaie',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TAPAColors.navy),
                    ),
                  ],
                ),
              );
            }),
          // Liste
          Expanded(
            child: txs.isEmpty
                ? const Center(
                    child: Text('Aucune transaction',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    key: ValueKey(_refreshKey),
                    padding: const EdgeInsets.all(12),
                    itemCount: txs.length,
                    itemBuilder: (ctx, i) {
                      final tx = txs[i];
                      // ✅ CORRECTION : Utiliser walletId pour trouver le wallet
                      final wallet = _wallets.firstWhere(
                        (w) => w.id == tx.walletId,
                        orElse: () => _wallets.isNotEmpty
                            ? _wallets.first
                            : WalletModel(
                                id: '',
                                uid: '',
                                nom: 'Inconnu',
                                emoji: '💰',
                                type: 'compte',
                                solde: 0,
                                monnaie: monnaie,
                                description: '',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.grey.shade200, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: tx.isRevenu
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                        child: Text(tx.categorieEmoji,
                                            style:
                                                const TextStyle(fontSize: 20))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.categorieLabel,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black),
                                        ),
                                        Text(
                                          '${wallet.emoji} ${wallet.nom}',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          '${tx.dateTransaction.day}/${tx.dateTransaction.month}/${tx.dateTransaction.year}',
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.grey),
                                        ),
                                        if (tx.note != null &&
                                            tx.note!.isNotEmpty)
                                          Text(
                                            tx.note!,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                                fontStyle: FontStyle.italic),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${tx.isRevenu ? '+' : '-'}${tx.montant.toStringAsFixed(0)} $monnaie',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: tx.isRevenu
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _modifier(tx),
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 14, color: Colors.black),
                                    label: const Text('Modifier',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.black)),
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.grey.shade200),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _supprimer(tx),
                                    icon: const Icon(Icons.delete_outlined,
                                        size: 14, color: Colors.red),
                                    label: const Text('Supprimer',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.red)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filtreBtn(String label, String val, {bool isPeriode = false}) {
    final current = isPeriode ? _periode : _filtre;
    final isActive = current == val;
    return GestureDetector(
      onTap: () => setState(() {
        if (isPeriode) {
          _periode = val;
        } else {
          _filtre = val;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? TAPAColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: isActive ? TAPAColors.gold : Colors.white30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? TAPAColors.navy : Colors.white70,
          ),
        ),
      ),
    );
  }
}
