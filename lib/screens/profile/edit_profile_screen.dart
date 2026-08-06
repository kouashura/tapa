// lib/screens/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../data/models/models.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/logger.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _prenomCtrl;
  late String _monnaie;
  late String _codePays;
  late String _indicatif;
  late String _telephone;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _prenomCtrl = TextEditingController(text: user?.prenom ?? '');
    _monnaie = user?.monnaie ?? 'FCFA';
    _codePays = user?.codePays ?? 'CI';
    _indicatif = user?.indicatif ?? '+225';
    _telephone = user?.telephone ?? '';
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur non trouvé'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    final newPrenom = _prenomCtrl.text.trim();
    if (newPrenom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le prénom ne peut pas être vide'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedUser = user.copyWith(
        prenom: newPrenom,
        monnaie: _monnaie,
        codePays: _codePays,
        indicatif: _indicatif,
      );

      await ref.read(authStateProvider.notifier).updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil mis à jour !'),
            backgroundColor: TAPAColors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: TAPAColors.red,
          ),
        );
      }
      Logger.error('❌ Erreur mise à jour profil: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isSmall = MediaQuery.of(context).size.width < 360;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final paddingSize = isSmall ? 12.0 : (isTablet ? 24.0 : 16.0);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: TAPAColors.gold,
              ),
            )
                : const Text(
              'Sauver',
              style: TextStyle(
                color: TAPAColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(paddingSize),
        children: [
          // Prénom
          const Text(
            'Mon prénom',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TAPAColors.textSecond,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _prenomCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'ex : Kouassi',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 20),

          // Monnaie
          const Text(
            'Ma monnaie',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TAPAColors.textSecond,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: AppConstants.monnaies.length,
            itemBuilder: (ctx, i) {
              final m = AppConstants.monnaies[i];
              final sel = _monnaie == m['symbole'];
              return GestureDetector(
                onTap: () => setState(() => _monnaie = m['symbole']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: sel ? TAPAColors.navy : TAPAColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? TAPAColors.gold : TAPAColors.border,
                      width: sel ? 2 : 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        m['symbole']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: sel ? TAPAColors.gold : TAPAColors.navy,
                        ),
                      ),
                      Text(
                        m['nom']!,
                        style: TextStyle(
                          fontSize: 10,
                          color: sel ? Colors.white60 : TAPAColors.textSecond,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Pays
          DropdownButtonFormField<String>(
            value: _codePays,
            decoration: const InputDecoration(
              labelText: 'Mon pays',
            ),
            items: AppConstants.pays.map((p) =>
                DropdownMenuItem<String>(
                  value: p['code'] as String,
                  child: Text('${p['flag']} ${p['nom']}'),
                ),
            ).toList(),
            onChanged: (v) {
              if (v == null) return;
              final p = AppConstants.pays.firstWhere((p) => p['code'] == v);
              setState(() {
                _codePays = v;
                _indicatif = p['indicatif']!;
                _monnaie = p['monnaie']!;
              });
            },
          ),
          const SizedBox(height: 16),

          // Téléphone (lecture seule)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TAPAColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_outlined, color: TAPAColors.textHint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Téléphone',
                        style: TextStyle(
                          fontSize: 11,
                          color: TAPAColors.textSecond,
                        ),
                      ),
                      Text(
                        _telephone,
                        style: const TextStyle(
                          fontSize: 14,
                          color: TAPAColors.navy,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Bouton Enregistrer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: TAPAColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TAPAColors.gold,
                ),
              )
                  : const Text(
                'Enregistrer les modifications',
                style: TextStyle(color: TAPAColors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}