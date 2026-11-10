// lib/services/link_service.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart'; // ✅ AJOUTÉ pour TAPAColors

class LinkService {
  static Future<void> ouvrirWhatsApp({String message = ''}) async {
    try {
      String url = 'https://wa.me/2250160254102';
      if (message.isNotEmpty) {
        url =
            'https://wa.me/2250160254102?text=${Uri.encodeComponent(message)}';
      }

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        final webUrl = Uri.parse('https://wa.me/2250160254102');
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.platformDefault);
        } else {
          throw Exception('Impossible d\'ouvrir WhatsApp');
        }
      }
    } catch (e) {
      print('Erreur WhatsApp: $e');
      rethrow;
    }
  }

  static Future<void> ouvrirSiteWeb(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception("Impossible d'ouvrir le site web");
      }
    } catch (e) {
      print('Erreur ouverture site web: $e');
    }
  }

  static Future<void> ouvrirBoutique() async {
    try {
      final urls = [
        'https://tapa-budget.com/boutique',
        'https://tapa-budget.com',
        'https://tapa-budget.com/shop',
      ];

      bool opened = false;

      for (final url in urls) {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            opened = true;
            break;
          }
        } catch (e) {
          // Continuer avec l'URL suivante
        }
      }

      if (!opened) {
        throw Exception('Aucune URL accessible');
      }
    } catch (e) {
      print('Erreur boutique: $e');
      rethrow;
    }
  }

  static Future<void> ouvrirSite() async {
    try {
      final uri = Uri.parse('https://tapa-budget.com');
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Impossible d\'ouvrir le site');
      }
    } catch (e) {
      print('Erreur site: $e');
      rethrow;
    }
  }

  static Future<void> ouvrirBoutiqueAvecFallback(BuildContext context) async {
    try {
      await ouvrirBoutique();
    } catch (e) {
      if (context.mounted) {
        _showUrlDialog(context, 'https://tapa-budget.com/boutique');
      }
    }
  }

  static void _showUrlDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shopping_bag_outlined),
            SizedBox(width: 10),
            Text('Boutique TAPA'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Impossible d\'ouvrir la boutique automatiquement.\n'
              'Vous pouvez copier le lien ci-dessous et l\'ouvrir dans votre navigateur :',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TAPAColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TAPAColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Copier l'URL
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('📋 Lien copié !'),
                          backgroundColor: TAPAColors.gold,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, color: TAPAColors.gold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ouvrirSite();
              } catch (_) {}
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Ouvrir le site'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.navy,
              foregroundColor: TAPAColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
