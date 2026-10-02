import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WaveService {
  // Remplacer par tes vraies cles quand tu auras ton compte Wave Business
  static const String _apiKey = 'WAVE_API_KEY_ICI';
  static const String _currency = 'XOF'; // FCFA
  static const int _montantLicence = 5000;

  static Future<Map<String, dynamic>?> creerLienPaiement({
    required String nomClient,
    required String telephone,
    required String userId,
  }) async {
    try {
      final response = await Uri.parse(
        'https://api.wave.com/v1/checkout/sessions').toString();

      // Corps de la requete Wave Checkout
      final body = {
        'amount': _montantLicence.toString(),
        'currency': _currency,
        'error_url': 'https://tapaconseil.com/paiement-echoue',
        'succèss_url': 'https://tapaconseil.com/paiement-reussi',
        'client_reference': userId,
        'payment_method': 'wave_money',
        'name': 'Licence TAPA Invest - Accès a vie',
        'merchant_data': {
          'client_nom': nomClient,
          'client_téléphone': telephone,
          'produit': 'TAPA Invest Licence',
        }
      };

      // TODO: Activer quand tu auras ton API Key Wave
      // final resp = await http.post(
      //   Uri.parse('https://api.wave.com/v1/checkout/sessions'),
      //   headers: {
      //     'Authorization': 'Bearer $_apiKey',
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode(body),
      // );
      // final data = jsonDecode(resp.body);
      // return data;

      return {'status': 'demo', 'wave_launch_url': 'https://wave.com'};
    } catch (e) {
      return null;
    }
  }

  static Future<bool> ouvrirWave(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  // Verification du paiement via webhook
  // Wave envoie une notification a ton serveur quand le paiement est confirme
  static bool verifierSignatureWebhook(
      String payload, String signature) {
    // TODO: Implementer verification HMAC avec ta cle secrete Wave
    return true;
  }

  // Generer une cle TAPA automatiquement apres paiement confirme
  static String genererCleTAPA() {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    String cle = 'TB-2026-';
    for (int i = 0; i < 8; i++) {
      cle += chars[int.parse(random[i % random.length]) % chars.length];
    }
    return cle;
  }
}
