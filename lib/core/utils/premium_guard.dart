// lib/core/utils/premium_guard.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../services/db_service_mysql.dart';

class PremiumGuard {
  static bool isPremium() {
    final db = DBService();
    return db.aAccesAVie || !db.essaiGratuitExpire;
  }

  static void verifier(BuildContext context, {
    required VoidCallback onAcces,
  }) {
    if (isPremium()) {
      onAcces();
    } else {
      _afficherModal(context);
    }
  }

  static void _afficherModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: TAPAColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: TAPAColors.goldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: TAPAColors.gold,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fonctionnalité Premium',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette fonctionnalité est réservée aux\n'
                  'membres premium TAPA Invest.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TAPAColors.textSecond,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TAPAColors.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text(
                    'Accès à vie',
                    style: TextStyle(
                      color: TAPAColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '5 000 FCFA',
                    style: TextStyle(
                      color: TAPAColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Paiement unique — toutes les fonctionnalités',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _avantage('📊 Budget et analyse financière'),
            _avantage('💰 Épargne et objectifs'),
            _avantage('📋 Historique complet'),
            _avantage('🔔 Échéances et rappels'),
            _avantage('📈 Investissement et assurance'),
            _avantage('📄 Rapports PDF'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/activation');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAPAColors.gold,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  'Obtenir l\'accès premium',
                  style: TextStyle(
                    color: TAPAColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Plus tard',
                style: TextStyle(
                  color: TAPAColors.textSecond,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  static Widget _avantage(String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            texte,
            style: const TextStyle(
              fontSize: 13,
              color: TAPAColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}