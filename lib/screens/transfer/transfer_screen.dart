import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/db_service_mysql.dart';
import '../../models/models.dart';
import '../../core/utils/formatters.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});
  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final DBService _db = DBService();
  final TextEditingController _montantCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  int? _walletSourceId;
  int? _walletDestId;

  @override
  void initState() {
    super.initState();
    final wallets = _db.getWallets();
    if (wallets.length >= 2) {
      _walletSourceId = wallets[0].id;
      _walletDestId = wallets[1].id;
    }
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _transfer() async {
    final montant = double.tryParse(_montantCtrl.text);
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrez un montant valide'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }
    if (_walletSourceId == null || _walletDestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez les portefeuilles'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }
    if (_walletSourceId == _walletDestId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source et destination doivent être différents'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    final wallets = _db.getWallets();
    final source = wallets.firstWhere((w) => w.id == _walletSourceId);
    final user = _db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';

    if (source.solde < montant) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solde insuffisant: ${Fmt.montant(source.solde, monnaie: monnaie)}'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    final dest = wallets.firstWhere((w) => w.id == _walletDestId);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le transfert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De: ${source.emoji} ${source.nom}'),
            Text('Vers: ${dest.emoji} ${dest.nom}'),
            Text('Montant: ${Fmt.montant(montant, monnaie: monnaie)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Transférer'),
          ),
        ],
      ),
    );

    if (ok == true) {
      // ✅ CORRECTION : Convertir l'ID utilisateur en int
      final userId = _db.getCurrentUserId();
      final int utilisateurId = userId != null ? int.tryParse(userId) ?? 1 : 1;

      // Débiter la source
      final updatedSource = source.copyWith(
        solde: source.solde - montant,
        updatedAt: DateTime.now(),
      );
      await _db.updateWallet(updatedSource);

      // Créditer la destination
      final updatedDest = dest.copyWith(
        solde: dest.solde + montant,
        updatedAt: DateTime.now(),
      );
      await _db.updateWallet(updatedDest);

      // Créer la transaction
      final tx = TransactionModel(
        id: null,
        uuid: Fmt.genId(),
        utilisateurId: utilisateurId,
        portefeuilleId: _walletSourceId!,
        portefeuilleDestId: _walletDestId,
        montant: montant,
        type: TransactionType.transfert,
        categorieId: 'transfert',
        categorieLabel: 'Transfert',
        categorieEmoji: '🔄',
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        dateTransaction: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _db.addTransaction(tx);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfert effectué avec succès !'),
            backgroundColor: TAPAColors.green,
          ),
        );
        context.pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = _db.getWallets();
    final user = _db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';

    if (wallets.length < 2) {
      return Scaffold(
        backgroundColor: TAPAColors.background,
        appBar: AppBar(
          title: const Text('Transfert'),
          backgroundColor: TAPAColors.navy,
          foregroundColor: TAPAColors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: TAPAColors.textSecond),
              SizedBox(height: 16),
              Text(
                'Vous avez besoin d\'au moins 2 portefeuilles',
                style: TextStyle(
                  fontSize: 16,
                  color: TAPAColors.textSecond,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Transfert'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Transférer de l\'argent',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'D\'un portefeuille à un autre',
            style: TextStyle(
              color: TAPAColors.textSecond,
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<int>(
            value: _walletSourceId,
            decoration: const InputDecoration(
              labelText: 'Portefeuille source *',
            ),
            items: wallets.map((w) =>
                DropdownMenuItem<int>(
                  value: w.id!,
                  child: Text('${w.emoji} ${w.nom} (${Fmt.montant(w.solde, monnaie: monnaie)})'),
                ),
            ).toList(),
            onChanged: (v) => setState(() => _walletSourceId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _walletDestId,
            decoration: const InputDecoration(
              labelText: 'Portefeuille destination *',
            ),
            items: wallets.where((w) => w.id != _walletSourceId).map((w) =>
                DropdownMenuItem<int>(
                  value: w.id!,
                  child: Text('${w.emoji} ${w.nom} (${Fmt.montant(w.solde, monnaie: monnaie)})'),
                ),
            ).toList(),
            onChanged: (v) => setState(() => _walletDestId = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _montantCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Montant *',
              suffixText: monnaie,
              hintText: '0',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optionnelle)',
              hintText: 'ex : Virement Wave',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _transfer,
            child: const Text('Transférer'),
          ),
        ],
      ),
    );
  }
}
