// lib/presentation/screens/investir/my_sonam_contracts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';

/// Formate un montant : 1250000 -> "1 250 000 FCFA"
String _fcfa(num value) {
  final digits = value.round().abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('\u202F');
    buf.write(digits[i]);
  }
  final sign = value < 0 ? '-' : '';
  return '$sign$buf FCFA';
}

class _StatusStyle {
  final Color color;
  final IconData icon;
  final String label;
  const _StatusStyle(this.color, this.icon, this.label);
}

_StatusStyle _statusStyle(String statut) {
  switch (statut) {
    case 'Actif':
      return const _StatusStyle(
          Color(0xFF2E9E6B), Icons.verified_rounded, 'Actif');
    case 'En attente de paiement':
      return const _StatusStyle(
          Color(0xFFE0A100), Icons.schedule_rounded, 'En attente de paiement');
    case 'Racheté':
      return const _StatusStyle(
          Color(0xFF8A94A6), Icons.history_rounded, 'Racheté');
    default:
      return _StatusStyle(
          const Color(0xFF8A94A6), Icons.help_outline_rounded, statut);
  }
}

class MySonamContractsScreen extends ConsumerStatefulWidget {
  const MySonamContractsScreen({super.key});

  @override
  ConsumerState<MySonamContractsScreen> createState() =>
      _MySonamContractsScreenState();
}

class _MySonamContractsScreenState
    extends ConsumerState<MySonamContractsScreen> {
  static const Color _bg = Color(0xFFF4F6FA);
  static const Color _ink = Color(0xFF1D2433);
  static const Color _muted = Color(0xFF6B7588);
  static const Color _line = Color(0xFFE6EAF1);

  // ───────────────────────── RACHAT ─────────────────────────
  Future<void> _racheterContrat(BuildContext context,
      Map<String, dynamic> contrat, List<dynamic> historique) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final double totalVerse =
        (contrat['totalVerse'] as num?)?.toDouble() ?? 0.0;
    final double cotisation =
        (contrat['contrat']?['cotisation_periodique'] as num?)?.toDouble() ??
            0.0;
    final int nbMoisPayes = historique.length;

    double montantRembourse = totalVerse;
    double penalite = 0;

    if (nbMoisPayes < 12) {
      penalite = cotisation;
      montantRembourse = totalVerse - cotisation;
      if (montantRembourse < 0) montantRembourse = 0;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        title: const Text(
          'Arrêter ce contrat ?',
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Le rachat met fin à votre épargne. Le montant remboursé sera crédité sur votre Wallet.',
              style: TextStyle(fontSize: 13, color: _muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            _dialogRow('Mois payés', '$nbMoisPayes'),
            _dialogRow('Total versé', _fcfa(totalVerse)),
            if (penalite > 0)
              _dialogRow('Pénalité (1 mois)', '- ${_fcfa(penalite)}',
                  valueColor: TAPAColors.red),
            const Divider(height: 24),
            _dialogRow('Vous recevez', _fcfa(montantRembourse), bold: true),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Garder mon contrat',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Racheter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    _showLoader(context);

    try {
      final walletRef =
          FirebaseFirestore.instance.collection('user_wallet').doc(user.id);
      final contractRef = FirebaseFirestore.instance
          .collection('sonam_contracts')
          .doc(contrat['contractId']);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);
        final currentSolde =
            (walletDoc.data()?['solde'] as num?)?.toDouble() ?? 0.0;

        transaction.update(walletRef, {
          'solde': currentSolde + montantRembourse,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(contractRef, {
          'statut': 'Racheté',
          'montantRachat': montantRembourse,
          'dateRachat': FieldValue.serverTimestamp(),
        });

        final txRef =
            FirebaseFirestore.instance.collection('transactions').doc();
        transaction.set(txRef, {
          'userId': user.id,
          'montant': montantRembourse,
          'type': 'revenu',
          'categorieLabel': 'Rachat SONAM',
          'categorieEmoji': '💸',
          'dateTransaction': FieldValue.serverTimestamp(),
          'description':
              'Rachat contrat ${contrat['policeCode']} - $nbMoisPayes mois payés',
        });
      });

      if (context.mounted) {
        Navigator.pop(context);
        _snack(context, '${_fcfa(montantRembourse)} crédités sur votre Wallet.',
            TAPAColors.green);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _snack(context, 'Rachat impossible : $e', TAPAColors.red);
      }
    }
  }

  // ───────────────────────── PAIEMENT ─────────────────────────
  Future<void> _payerCotisation(BuildContext context, String contractId,
      double montant, List<dynamic> historiqueActuel, String dateEffet) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    DateTime prochainMoisDate;
    if (historiqueActuel.isEmpty) {
      final parts = dateEffet.split('/');
      if (parts.length == 3) {
        prochainMoisDate =
            DateTime(int.parse(parts[2]), int.parse(parts[1]), 1);
      } else {
        prochainMoisDate = DateTime.now();
      }
    } else {
      final dernierPaiement = historiqueActuel.last;
      final parts = dernierPaiement['mois'].split('/');
      prochainMoisDate = DateTime(int.parse(parts[1]), int.parse(parts[0]) + 1);
    }

    final moisAPayer = '${prochainMoisDate.month}/${prochainMoisDate.year}';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Payer la cotisation',
            style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogRow('Mois concerné', moisAPayer),
            const Divider(height: 24),
            _dialogRow('Montant débité', _fcfa(montant), bold: true),
            const SizedBox(height: 8),
            const Text(
              'Le montant sera prélevé sur votre Wallet.',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Payer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    _showLoader(context);

    try {
      final walletRef =
          FirebaseFirestore.instance.collection('user_wallet').doc(user.id);
      final walletDoc = await walletRef.get();
      final solde = (walletDoc.data()?['solde'] as num?)?.toDouble() ?? 0.0;

      if (solde < montant) {
        if (!context.mounted) return;
        Navigator.pop(context);
        _snack(context, 'Solde insuffisant. Rechargez votre Wallet pour payer.',
            TAPAColors.red);
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final currentWallet = await transaction.get(walletRef);
        final currentSolde =
            (currentWallet.data()?['solde'] as num?)?.toDouble() ?? 0.0;

        if (currentSolde < montant) throw Exception('Solde insuffisant');

        transaction.update(walletRef, {
          'solde': currentSolde - montant,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(
            FirebaseFirestore.instance
                .collection('sonam_contracts')
                .doc(contractId),
            {
              'totalVerse': FieldValue.increment(montant),
              'dernierPaiement': FieldValue.serverTimestamp(),
              'historiquePaiements': FieldValue.arrayUnion([
                {
                  'mois': moisAPayer,
                  'montant': montant,
                  'date': DateTime.now(),
                }
              ]),
            });

        final txRef =
            FirebaseFirestore.instance.collection('transactions').doc();
        transaction.set(txRef, {
          'userId': user.id,
          'montant': montant,
          'type': 'depense',
          'categorieLabel': 'Cotisation SONAM ($moisAPayer)',
          'categorieEmoji': '💰',
          'dateTransaction': FieldValue.serverTimestamp(),
          'description': 'Paiement anticipé cotisation SONAM - $moisAPayer',
        });
      });

      if (context.mounted) {
        Navigator.pop(context);
        _snack(context, 'Cotisation de $moisAPayer payée.', TAPAColors.green);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _snack(context, 'Paiement impossible : $e', TAPAColors.red);
      }
    }
  }

  // ───────────────────────── HELPERS UI ─────────────────────────
  void _showLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _snack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _dialogRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: bold ? _ink : _muted,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 16 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? _ink)),
        ],
      ),
    );
  }

  // ───────────────────────── BUILD ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Mes contrats SONAM',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: TAPAColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/investir'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sonam_contracts')
            .where('userId', isEqualTo: user.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildMessageState(
              Icons.error_outline_rounded,
              'Chargement impossible',
              'Vérifiez votre connexion puis réessayez.',
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildMessageState(
              Icons.savings_outlined,
              'Aucun contrat SONAM',
              'Vos contrats apparaîtront ici dès votre première souscription.',
            );
          }

          final contracts = snapshot.data!.docs;

          double totalEpargne = 0;
          int nbActifs = 0;
          for (final doc in contracts) {
            final d = doc.data() as Map<String, dynamic>;
            if (d['statut'] != 'Racheté') {
              totalEpargne += (d['totalVerse'] as num?)?.toDouble() ?? 0;
            }
            if (d['statut'] == 'Actif') nbActifs++;
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: contracts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSummary(totalEpargne, nbActifs, contracts.length);
              }
              return _buildContractCard(context, contracts[index - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: TAPAColors.navy.withAlpha(14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: TAPAColors.navy),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, color: _muted, height: 1.4)),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── RÉSUMÉ ─────────────────────────
  Widget _buildSummary(double totalEpargne, int nbActifs, int nbContrats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TAPAColors.navy,
            Color.lerp(TAPAColors.navy, Colors.black, 0.25)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: TAPAColors.navy.withAlpha(60),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Épargne SONAM constituée',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withAlpha(180),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            _fcfa(totalEpargne),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryChip(Icons.description_outlined,
                  '$nbContrats contrat${nbContrats > 1 ? 's' : ''}'),
              const SizedBox(width: 10),
              _summaryChip(Icons.verified_rounded,
                  '$nbActifs actif${nbActifs > 1 ? 's' : ''}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TAPAColors.gold),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ───────────────────────── CARTE CONTRAT ─────────────────────────
  Widget _buildContractCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final statut = (data['statut'] ?? 'Inconnu').toString();
    final policeCode = (data['policeCode'] ?? 'N/A').toString();
    final contrat = (data['contrat'] as Map<String, dynamic>?) ?? {};
    final cotisation =
        (contrat['cotisation_periodique'] as num?)?.toDouble() ?? 0;
    final capital = (contrat['capital_garanti_terme'] as num?)?.toDouble() ?? 0;
    final dateEffet = (contrat['date_effet'] ?? '01/12/2026').toString();
    final totalVerse = (data['totalVerse'] as num?)?.toDouble() ?? 0;
    final historique = (data['historiquePaiements'] as List?) ?? [];

    final style = _statusStyle(statut);
    final progress =
        capital > 0 ? (totalVerse / capital).clamp(0.0, 1.0).toDouble() : 0.0;
    final canPay = statut == 'Actif' || statut == 'En attente de paiement';
    final canRedeem = statut == 'Actif';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D2433).withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête : police + statut ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: TAPAColors.navy.withAlpha(16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: TAPAColors.navy, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contrat SONAM',
                          style: TextStyle(fontSize: 12, color: _muted)),
                      const SizedBox(height: 2),
                      Text('Police $policeCode',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _ink)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: style.color.withAlpha(28),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 14, color: style.color),
                      const SizedBox(width: 5),
                      Text(style.label,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: style.color)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Capital garanti + progression ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Capital garanti à terme',
                    style: TextStyle(fontSize: 12, color: _muted)),
                const SizedBox(height: 4),
                Text(
                  _fcfa(capital),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: TAPAColors.navy,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: _line,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(TAPAColors.gold),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(progress * 100).toStringAsFixed(0)} % atteint',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _ink)),
                    Text('${_fcfa(totalVerse)} versés',
                        style: const TextStyle(fontSize: 12, color: _muted)),
                  ],
                ),
              ],
            ),
          ),

          // ── Statistiques ──
          Container(
            margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _stat(Icons.event_repeat_rounded, 'Cotisation mensuelle',
                    _fcfa(cotisation)),
                Container(width: 1, height: 32, color: _line),
                _stat(Icons.check_circle_outline_rounded, 'Mois payés',
                    '${historique.length}'),
              ],
            ),
          ),

          // ── Historique ──
          if (historique.isNotEmpty)
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                iconColor: _muted,
                collapsedIconColor: _muted,
                title: Text(
                  'Historique des paiements (${historique.length})',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
                ),
                children: historique.reversed.take(12).map<Widget>((p) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: TAPAColors.green.withAlpha(24),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 15, color: TAPAColors.green),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Cotisation ${p['mois']}',
                              style:
                                  const TextStyle(fontSize: 13, color: _ink)),
                        ),
                        Text(_fcfa((p['montant'] as num).toDouble()),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _ink)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else
            const SizedBox(height: 6),

          // ── Actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: canPay
                        ? () => _payerCotisation(
                              context,
                              doc.id,
                              cotisation,
                              historique,
                              dateEffet,
                            )
                        : null,
                    icon: const Icon(Icons.payments_rounded, size: 19),
                    label: Text(
                      statut == 'En attente de paiement'
                          ? 'Payer ma 1ère cotisation'
                          : 'Payer ma cotisation',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAPAColors.gold,
                      foregroundColor: TAPAColors.navy,
                      disabledBackgroundColor: _line,
                      disabledForegroundColor: _muted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                if (canRedeem) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _racheterContrat(
                        context,
                        {
                          ...data,
                          'contractId': doc.id,
                          'policeCode': policeCode,
                        },
                        historique,
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Racheter ce contrat',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TAPAColors.red,
                        side: BorderSide(color: TAPAColors.red.withAlpha(120)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: TAPAColors.navy),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(fontSize: 11, color: _muted, height: 1.25),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: _ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
