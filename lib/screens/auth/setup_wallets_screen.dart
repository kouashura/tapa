import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/db_service_mysql.dart';
import '../../models/models.dart';

class SetupWalletsScreen extends StatefulWidget {
  const SetupWalletsScreen({super.key});
  @override
  State<SetupWalletsScreen> createState() => _SetupWalletsScreenState();
}

class _SetupWalletsScreenState extends State<SetupWalletsScreen> {
  final Map<int, TextEditingController> _ctrls = {};
  late List<WalletModel> _wallets;
  final DBService _db = DBService();

  @override
  void initState() {
    super.initState();
    _wallets = _db.getWallets();
    for (final w in _wallets) {
      _ctrls[w.id!] = TextEditingController(
        text: w.solde > 0 ? w.solde.round().toString() : '',
      );
    }
  }

  @override
  void dispose() {
    for (final ctrl in _ctrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    for (final w in _wallets) {
      final val = double.tryParse(_ctrls[w.id!]?.text ?? '0') ?? 0;
      await _db.saveWallet(w.copyWith(
        solde: val,
        updatedAt: DateTime.now(),
      ));
    }
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final user = _db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Mes portefeuilles'),
        automaticallyImplyLeading: true,
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Bonjour ${user?['prenom'] ?? ''} ! 👋',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Entre le solde actuel de chacun '
                'de tes portefeuilles.\n'
                'Mets 0 si tu ne l\'utilises pas.',
            style: TextStyle(
              color: TAPAColors.textSecond,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ..._wallets.map((w) => _walletInput(w, monnaie)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            child: const Text('C\'est parti ! Ouvrir mon budget'),
          ),
        ],
      ),
    );
  }

  Widget _walletInput(WalletModel w, String monnaie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: TAPAColors.border, width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: TAPAColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                w.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.nom,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TAPAColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _ctrls[w.id!],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: monnaie,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}