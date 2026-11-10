// lib/presentation/screens/investir/assurance_success_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class AssuranceSuccessScreen extends StatelessWidget {
  final String produitNom;
  final int montantPaye;
  final String reference;

  const AssuranceSuccessScreen({
    super.key,
    required this.produitNom,
    required this.montantPaye,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF27AE60),
                  size: 70,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Merci !',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre assurance $produitNom est en cours',
                style: const TextStyle(
                  fontSize: 15,
                  color: TAPAColors.textSecond,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: TAPAColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TAPAColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ligne('Produit', produitNom),
                    const SizedBox(height: 8),
                    _ligne('Montant',
                        '${montantPaye.toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA'),
                    const SizedBox(height: 8),
                    _ligne('Reference', reference),
                    const SizedBox(height: 8),
                    _ligne('Statut', 'En cours de traitement'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TAPAColors.navy,
                    foregroundColor: TAPAColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retour a l accueil',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Un conseiller vous contactera sous 24h',
                style: TextStyle(
                  fontSize: 12,
                  color: TAPAColors.textSecond.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ligne(String label, String valeur) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: TAPAColors.textSecond,
          ),
        ),
        Flexible(
          child: Text(
            valeur,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
