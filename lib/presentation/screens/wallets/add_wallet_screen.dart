import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../data/models/models.dart';
import '../../../domain/usecases/wallet/create_wallet_usecase.dart';

class AddWalletScreen extends ConsumerStatefulWidget {
  const AddWalletScreen({super.key});

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final _nomController = TextEditingController();
  final _soldeController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Types disponibles
  final List<Map<String, dynamic>> _types = [
    {'id': 'bank', 'label': 'Banque', 'emoji': '🏦', 'color': Colors.blue},
    {
      'id': 'wave',
      'label': 'Wave',
      'emoji': '🌊',
      'color': const Color(0xFF1DC8F2)
    },
    {
      'id': 'orange',
      'label': 'Orange Money',
      'emoji': '🟠',
      'color': const Color(0xFFFF7900)
    },
    {
      'id': 'mtn',
      'label': 'MTN MoMo',
      'emoji': '🟡',
      'color': const Color(0xFFFFCC00)
    },
    {'id': 'cash', 'label': 'Cash', 'emoji': '💵', 'color': Colors.green},
  ];

  String _selectedType = 'cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _soldeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _creerPortefeuille() async {
    final nom = _nomController.text.trim();
    final soldeStr = _soldeController.text.trim();

    if (nom.isEmpty) {
      _showError('Veuillez donner un nom à ce compte (ex: Wave Perso)');
      return;
    }

    if (soldeStr.isEmpty) {
      _showError('Veuillez indiquer le solde actuel');
      return;
    }

    final solde = double.tryParse(soldeStr) ?? 0;
    if (solde < 0) {
      _showError('Le solde ne peut pas être négatif');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      if (userId.isEmpty) throw Exception('Utilisateur non connecté');

      // Trouver les infos du type sélectionné
      final typeInfo = _types.firstWhere((t) => t['id'] == _selectedType);

      // ✅ Créer les paramètres avec la structure exacte de CreateWalletParams
      final params = CreateWalletParams(
        uid: userId,
        nom: nom,
        type: typeInfo['id'],
        emoji: typeInfo['emoji'],
        solde: solde,
        monnaie: ref.read(userMonnaieProvider),
        description: _descriptionController.text.trim(),
      );

      // ✅ Appeler le provider de création
      final result = await ref.read(createWalletProvider(params).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Portefeuille créé avec succès'),
            backgroundColor: TAPAColors.green,
          ),
        );
        context.pop(); // Retour à l'écran précédent
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur : ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: TAPAColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Nouveau compte'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SECTION : TYPE DE COMPTE
            const Text(
              'Type de compte',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final type = _types[i];
                  final isSelected = _selectedType == type['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? TAPAColors.navy : TAPAColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected ? TAPAColors.gold : TAPAColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: TAPAColors.navy.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(type['emoji'],
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 6),
                          Text(
                            type['label'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? TAPAColors.gold
                                  : TAPAColors.textSecond,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 2. SECTION : INFORMATIONS
            const Text(
              'Informations du compte',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy),
            ),
            const SizedBox(height: 12),

            // Champ Nom (dynamique selon le type)
            _buildTextField(
              controller: _nomController,
              label: _selectedType == 'bank'
                  ? 'Nom de la banque'
                  : 'Nom du compte',
              hint: _selectedType == 'bank'
                  ? 'Ex: NSIA Banque, SGCI...'
                  : 'Ex: Wave Perso, Orange Pro...',
              icon: Icons.account_balance_outlined,
            ),

            const SizedBox(height: 16),

            // Champ Solde Initial
            _buildTextField(
              controller: _soldeController,
              label: 'Solde actuel',
              hint: '0',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              suffix: monnaie,
            ),

            const SizedBox(height: 16),

            // Champ Description (optionnel)
            _buildTextField(
              controller: _descriptionController,
              label: 'Description (optionnel)',
              hint: 'Ex: Compte pour les dépenses quotidiennes...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // 3. BOUTON DE VALIDATION
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _creerPortefeuille,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAPAColors.gold,
                  foregroundColor: TAPAColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: TAPAColors.navy,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Créer le compte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget réutilisable pour les champs de texte
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? suffix,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: TAPAColors.textSecond),
        filled: true,
        fillColor: TAPAColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TAPAColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TAPAColors.navy, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
