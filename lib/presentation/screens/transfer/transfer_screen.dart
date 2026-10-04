import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/db_service_mysql.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/formatters.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});
  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final DBService _db = DBService();
  final TextEditingController _montantCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  String? _walletSourceId;
  String? _walletDestId;

  // ✅ État pour les portefeuilles
  List<WalletModel> _wallets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWallets();
  }

  // ✅ CORRIGÉ : ajout de async
  Future<void> _initWallets() async {
    setState(() => _isLoading = true);
    try {
      final wallets = await _db.getWallets();
      setState(() {
        _wallets = wallets.where((w) => w != null).cast<WalletModel>().toList();
        if (_wallets.length >= 2) {
          _walletSourceId = _wallets[0].id;
          _walletDestId = _wallets[1].id;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

    // ✅ Utiliser _wallets déjà chargé
    final source = _wallets.firstWhere(
          (w) => w.id == _walletSourceId,
      orElse: () => throw Exception('Portefeuille source non trouvé'),
    );
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

    final dest = _wallets.firstWhere(
          (w) => w.id == _walletDestId,
      orElse: () => throw Exception('Portefeuille destination non trouvé'),
    );

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
      final userId = _db.getCurrentUserId();
      final int utilisateurId = userId != null ? int.tryParse(userId) ?? 1 : 1;

      // Mettre à jour la source
      final updatedSource = WalletModel(
        id: source.id,
        uid: source.uid,
        nom: source.nom,
        emoji: source.emoji,
        type: source.type,
        solde: source.solde - montant,
        monnaie: source.monnaie,
        description: source.description,
        createdAt: source.createdAt,
        updatedAt: DateTime.now(),
      );
      await _db.saveWallet(updatedSource);

      // Mettre à jour la destination
      final updatedDest = WalletModel(
        id: dest.id,
        uid: dest.uid,
        nom: dest.nom,
        emoji: dest.emoji,
        type: dest.type,
        solde: dest.solde + montant,
        monnaie: dest.monnaie,
        description: dest.description,
        createdAt: dest.createdAt,
        updatedAt: DateTime.now(),
      );
      await _db.saveWallet(updatedDest);

      // Créer la transaction
      final tx = TransactionModel(
        id: Fmt.genId(),
        uid: userId ?? '',
        walletId: _walletSourceId!,
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
    final user = _db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';

    // ✅ Utiliser _wallets au lieu de await
    final wallets = _wallets;

    if (_isLoading) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          DropdownButtonFormField<String>(
            value: _walletSourceId,
            decoration: const InputDecoration(
              labelText: 'Portefeuille source *',
            ),
            items: wallets.map((wallet) {
              return DropdownMenuItem<String>(
                value: wallet.id,
                child: Text('${wallet.emoji ?? '💳'} ${wallet.nom ?? 'Portefeuille'} (${Fmt.montant(wallet.solde, monnaie: monnaie)})'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _walletSourceId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _walletDestId,
            decoration: const InputDecoration(
              labelText: 'Portefeuille destination *',
            ),
            items: wallets.where((w) => w.id != _walletSourceId).map((wallet) {
              return DropdownMenuItem<String>(
                value: wallet.id,
                child: Text('${wallet.emoji ?? '💳'} ${wallet.nom ?? 'Portefeuille'} (${Fmt.montant(wallet.solde, monnaie: monnaie)})'),
              );
            }).toList(),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Transférer',
              style: TextStyle(color: TAPAColors.white),
            ),
          ),
        ],
      ),
    );
  }
}