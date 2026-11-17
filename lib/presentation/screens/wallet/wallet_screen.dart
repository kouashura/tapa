import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../../services/digital_pay_service.dart';
import '../../providers/payment_wallet_provider.dart';

/// Opérateur de paiement : frais + identité visuelle.
class _Operator {
  final String code; // WAVE, ORANGE, MTN, MOOV
  final String label;
  final String dpCode; // code DigitalPay
  final Color color;
  final Color onColor;
  final double pourcentage;
  final double fixe;

  const _Operator({
    required this.code,
    required this.label,
    required this.dpCode,
    required this.color,
    required this.onColor,
    required this.pourcentage,
    required this.fixe,
  });
}

const List<_Operator> _operators = [
  _Operator(
    code: 'WAVE',
    label: 'Wave',
    dpCode: 'WAVE_MONEY_CI',
    color: Color(0xFF1DC8F2),
    onColor: Colors.white,
    pourcentage: 0.018,
    fixe: 100,
  ),
  _Operator(
    code: 'ORANGE',
    label: 'Orange Money',
    dpCode: 'ORANGE_MONEY_CI',
    color: Color(0xFFFF7900),
    onColor: Colors.white,
    pourcentage: 0.025,
    fixe: 250,
  ),
  _Operator(
    code: 'MTN',
    label: 'MTN MoMo',
    dpCode: 'MTN_MONEY_CI',
    color: Color(0xFFFFCC00),
    onColor: Color(0xFF1A1A1A),
    pourcentage: 0.020,
    fixe: 250,
  ),
  _Operator(
    code: 'MOOV',
    label: 'Moov Flooz',
    dpCode: 'MOOV_MONEY_CI',
    color: Color(0xFF0072BC),
    onColor: Colors.white,
    pourcentage: 0.025,
    fixe: 250,
  ),
];

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with WidgetsBindingObserver {
  static const int _montantMin = 500;
  static const List<int> _montantsRapides = [1000, 2000, 5000, 10000];

  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _montantRecuController = TextEditingController();
  String _selectedOperator = 'WAVE';
  bool _isLoading = false;

  _Operator get _operator =>
      _operators.firstWhere((o) => o.code == _selectedOperator);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'utilisateur revient dans l'app (ex: apres un paiement Wave/Orange)
      // On rafraichit les donnees du wallet.
      Logger.info('WalletScreen: retour au premier plan, refresh');
      // Force un rebuild du widget pour relire les providers
      if (mounted) setState(() {});
      // Si tu as un provider de solde, invalide-le ici :
      // ref.invalidate(walletProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _montantController.dispose();
    _montantRecuController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOGIQUE (inchangée)
  // ---------------------------------------------------------------------------

  double _calculerFrais(int montant, String operator) {
    final op = _operators.firstWhere((o) => o.code == operator);
    return (montant * op.pourcentage) + op.fixe;
  }

  int _calculerBrutDepuisNet(double net, String operator) {
    final op = _operators.firstWhere((o) => o.code == operator);
    return ((net + op.fixe) / (1 - op.pourcentage)).round();
  }

  void _onMontantEnvoyeChange(String val) {
    final montantSaisi = int.tryParse(val) ?? 0;
    if (montantSaisi > 0) {
      final frais = _calculerFrais(montantSaisi, _selectedOperator);
      final net = (montantSaisi - frais).round();
      _montantRecuController.text = net > 0 ? net.toString() : '0';
    } else {
      _montantRecuController.text = '';
    }
    setState(() {});
  }

  void _onMontantRecuChange(String val) {
    final netSaisi = int.tryParse(val) ?? 0;
    if (netSaisi > 0) {
      final brut =
      _calculerBrutDepuisNet(netSaisi.toDouble(), _selectedOperator);
      _montantController.text = brut.toString();
    } else {
      _montantController.text = '';
    }
    setState(() {});
  }

  void _selectionnerMontantRapide(int montant) {
    _montantController.text = montant.toString();
    _onMontantEnvoyeChange(montant.toString());
  }

  void _changerOperateur(String code) {
    setState(() => _selectedOperator = code);
    // Recalcule le montant reçu avec les frais du nouvel opérateur
    _onMontantEnvoyeChange(_montantController.text);
  }

  Future<void> _ajouterFonds() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showSnackBar('Utilisateur non connecté');
      return;
    }

    final montantText = _montantController.text.trim();
    if (montantText.isEmpty) {
      _showSnackBar('Saisissez un montant');
      return;
    }

    final montant = int.tryParse(montantText);
    if (montant == null || montant < _montantMin) {
      _showSnackBar('Montant minimum : $_montantMin FCFA');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final digitalPay = DigitalPayService();

      final success = await digitalPay.payerAvecDigitalPay(
        userId: currentUser.id,
        amount: montant,
        operator: _operator.dpCode,
        phone: currentUser.phoneNumber.trim().isNotEmpty
            ? currentUser.phoneNumber
            : '+2250700000000',
        sourceWalletId: '',
        description: 'Rechargement wallet',
      );

      if (success && mounted) {
        _showSnackBar('Paiement initié. Votre wallet sera crédité.',
            isSuccess: true);
        _montantController.clear();
        _montantRecuController.clear();
        setState(() {});
      } else if (mounted) {
        _showSnackBar('Impossible d\'ouvrir la page de paiement.');
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _retirerFonds() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showSnackBar('Utilisateur non connecté');
      return;
    }

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(
        userId: currentUser.id,
        initialPhone: currentUser.phoneNumber,
      ),
    );

    if (success == true && mounted) {
      _showSnackBar('Demande de retrait initiée avec succès.', isSuccess: true);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor:
          isSuccess ? const Color(0xFF1E8E5A) : const Color(0xFFD64545),
          content: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  String _fcfa(num value) {
    final s = value.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(' ');
    }
    return '${buf.toString()} FCFA';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: TAPAColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            _buildHeader(userId),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('Recharger mon wallet'),
                    const SizedBox(height: 12),
                    _buildOperatorSelector(),
                    const SizedBox(height: 16),
                    _buildAjoutFondsCard(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Mes portefeuilles'),
                    const SizedBox(height: 12),
                    _buildWalletsList(userId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EN-TÊTE + CARTE DE SOLDE
  // ---------------------------------------------------------------------------

  Widget _buildHeader(String userId) {
    final walletAsync = ref.watch(tapaWalletBalanceProvider(userId));
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [TAPAColors.navy, Color(0xFF152A47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Cercle décoratif discret
          Positioned(
            right: -50,
            top: 30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: TAPAColors.gold.withOpacity(0.18),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Ma réserve',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Solde disponible',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              walletAsync.when(
                data: (solde) => Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _fcfa(solde).replaceAll(' FCFA', ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'FCFA',
                        style: TextStyle(
                          color: TAPAColors.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: TAPAColors.gold,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
                error: (_, __) => const Text(
                  'Solde indisponible',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: TAPAColors.gold, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Utilisable pour tous vos paiements',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: TAPAColors.navy,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OPÉRATEURS
  // ---------------------------------------------------------------------------

  Widget _buildOperatorSelector() {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _operators.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final op = _operators[index];
          final selected = op.code == _selectedOperator;
          return GestureDetector(
            onTap: () => _changerOperateur(op.code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 104,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? TAPAColors.navy : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: TAPAColors.navy.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: op.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          op.label[0],
                          style: TextStyle(
                            color: op.onColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: TAPAColors.navy, size: 18),
                    ],
                  ),
                  Text(
                    op.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: TAPAColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORMULAIRE
  // ---------------------------------------------------------------------------

  Widget _buildAjoutFondsCard() {
    final montantSaisi = int.tryParse(_montantController.text) ?? 0;
    final frais = _calculerFrais(montantSaisi, _selectedOperator);
    final net = (montantSaisi - frais).round();
    final sousMinimum = montantSaisi > 0 && montantSaisi < _montantMin;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TAPAColors.navy.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAmountField(
            controller: _montantController,
            label: 'Vous payez',
            hint: '0',
            onChanged: _onMontantEnvoyeChange,
            highlighted: true,
            errorText:
            sousMinimum ? 'Minimum $_montantMin FCFA' : null,
          ),
          const SizedBox(height: 12),

          // Séparateur avec icône
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: TAPAColors.navy.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_vert_rounded,
                      size: 18, color: TAPAColors.navy),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade200)),
            ],
          ),
          const SizedBox(height: 12),

          _buildAmountField(
            controller: _montantRecuController,
            label: 'Vous recevez',
            hint: '0',
            onChanged: _onMontantRecuChange,
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: montantSaisi > 0
                ? Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TAPAColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _summaryRow('Montant payé', _fcfa(montantSaisi)),
                    const SizedBox(height: 8),
                    _summaryRow(
                      'Frais ${_operator.label}',
                      '- ${_fcfa(frais)}',
                      valueColor: const Color(0xFFD64545),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(
                          height: 1, color: Colors.grey.shade300),
                    ),
                    _summaryRow(
                      'Crédité sur le wallet',
                      _fcfa(net > 0 ? net : 0),
                      bold: true,
                    ),
                  ],
                ),
              ),
            )
                : const SizedBox(width: double.infinity),
          ),

          const SizedBox(height: 18),
          Text(
            'Montants rapides',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _montantsRapides.map((m) {
              final actif = montantSaisi == m;
              return GestureDetector(
                onTap: () => _selectionnerMontantRapide(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: actif ? TAPAColors.navy : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: actif ? TAPAColors.navy : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    _fcfa(m).replaceAll(' FCFA', ''),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: actif ? Colors.white : TAPAColors.navy,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    bool highlighted = false,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: highlighted ? TAPAColors.navy : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixText: 'FCFA',
        suffixStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: TAPAColors.navy,
        ),
        filled: true,
        fillColor: highlighted ? Colors.white : TAPAColors.background,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: TAPAColors.navy,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: TAPAColors.navy, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD64545)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD64545), width: 1.8),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              color: bold ? TAPAColors.navy : Colors.grey.shade700,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: bold ? 15 : 13.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? TAPAColors.navy,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BOUTONS
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _ajouterFonds,
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.gold,
              foregroundColor: TAPAColors.navy,
              disabledBackgroundColor: TAPAColors.gold.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: TAPAColors.navy,
              ),
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 18),
                SizedBox(width: 10),
                Text(
                  'Payer en toute sécurité',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _retirerFonds,
            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            label: const Text(
              'Retirer des fonds',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: TAPAColors.navy, width: 1.4),
              foregroundColor: TAPAColors.navy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LISTE DES PORTEFEUILLES
  // ---------------------------------------------------------------------------

  Widget _buildWalletsList(String userId) {
    final walletsAsync = ref.watch(walletListProvider(userId));
    return walletsAsync.when(
      data: (wallets) {
        if (wallets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                Text(
                  'Aucun portefeuille virtuel',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: wallets.map<Widget>((w) => _buildWalletItem(w)).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFD64545).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFD64545)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Impossible de charger vos portefeuilles.',
                style: TextStyle(color: Color(0xFFD64545)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletItem(dynamic w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: TAPAColors.navy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: TAPAColors.navy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(w.emoji ?? '💼', style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              w.nom ?? 'Portefeuille',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
                color: TAPAColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _fcfa(w.solde),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                color: TAPAColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// =============================================================================
// FEUILLE DE RETRAIT
// =============================================================================

class _WithdrawSheet extends StatefulWidget {
  final String userId;
  final String? initialPhone;

  const _WithdrawSheet({required this.userId, this.initialPhone});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  static const int _min = 500;
  static const List<int> _quick = [1000, 2000, 5000, 10000];

  final TextEditingController _montantCtrl = TextEditingController();
  late final TextEditingController _phoneCtrl;

  String _operator = 'WAVE';
  bool _loading = false;
  String? _montantError;
  String? _phoneError;
  String? _globalError;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  int get _montant => int.tryParse(_montantCtrl.text) ?? 0;

  static String _fmt(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(' ');
    }
    return buf.toString();
  }

  Future<void> _submit() async {
    final montant = _montant;
    final phone = _phoneCtrl.text.trim();

    setState(() {
      _montantError = montant < _min ? 'Montant minimum : $_min FCFA' : null;
      _phoneError =
      phone.startsWith('+225') ? null : 'Format attendu : +225XXXXXXXXXX';
      _globalError = null;
    });
    if (_montantError != null || _phoneError != null) return;

    setState(() => _loading = true);
    try {
      final ok = await DigitalPayService().retirerAvecDigitalPay(
        userId: widget.userId,
        amount: montant,
        operator: _operator,
        phone: phone,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _loading = false;
          _globalError = 'La demande de retrait a échoué. Réessayez.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _globalError = 'Erreur réseau. Vérifiez votre connexion et réessayez.';
      });
    }
  }

  InputDecoration _fieldDecoration({
    String? hint,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(TAPAColors.navy, 1.5),
      errorBorder: border(const Color(0xFFD64545)),
      focusedErrorBorder: border(const Color(0xFFD64545), 1.5),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final montant = _montant;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TAPAColors.gold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded,
                        color: TAPAColors.navy, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Retirer des fonds',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: TAPAColors.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vers votre compte Mobile Money',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                    _loading ? null : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Montant
              _label('Montant à retirer'),
              TextField(
                controller: _montantCtrl,
                enabled: !_loading,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() => _montantError = null),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                ),
                decoration: _fieldDecoration(
                  hint: '0',
                  errorText: _montantError,
                  suffix: const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        'FCFA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TAPAColors.gold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quick.map((m) {
                  final actif = montant == m;
                  return GestureDetector(
                    onTap: _loading
                        ? null
                        : () => setState(() {
                      _montantCtrl.text = m.toString();
                      _montantCtrl.selection = TextSelection.collapsed(
                          offset: _montantCtrl.text.length);
                      _montantError = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: actif ? TAPAColors.navy : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                          actif ? TAPAColors.navy : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        _fmt(m),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: actif ? Colors.white : TAPAColors.navy,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // Opérateur
              _label('Opérateur'),
              LayoutBuilder(
                builder: (context, c) {
                  final w = (c.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _operators.map((op) {
                      final selected = op.code == _operator;
                      return GestureDetector(
                        onTap: _loading
                            ? null
                            : () => setState(() => _operator = op.code),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: w,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? TAPAColors.navy.withOpacity(0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? TAPAColors.navy
                                  : Colors.grey.shade300,
                              width: selected ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: op.color,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  op.label[0],
                                  style: TextStyle(
                                    color: op.onColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  op.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: TAPAColors.navy,
                                  ),
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check_circle_rounded,
                                    size: 18, color: TAPAColors.navy),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 22),

              // Numéro
              _label('Numéro de réception'),
              TextField(
                controller: _phoneCtrl,
                enabled: !_loading,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                onChanged: (_) => setState(() => _phoneError = null),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TAPAColors.navy,
                ),
                decoration: _fieldDecoration(
                  hint: '+2250700000000',
                  errorText: _phoneError,
                  prefixIcon: const Icon(Icons.phone_iphone_rounded,
                      color: TAPAColors.navy, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Montant minimum : ${_fmt(_min)} FCFA. Vérifiez le numéro '
                          'avant de confirmer.',
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),

              // Erreur globale
              if (_globalError != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD64545).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_rounded,
                          size: 18, color: Color(0xFFD64545)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _globalError!,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFFD64545)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Bouton
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TAPAColors.navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: TAPAColors.navy.withOpacity(0.6),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                      : Text(
                    montant > 0
                        ? 'Retirer ${_fmt(montant)} FCFA'
                        : 'Confirmer le retrait',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context, false),
                child: Text('Annuler',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}