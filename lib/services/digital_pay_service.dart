// lib/services/digital_pay_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import '../core/utils/logger.dart';

class DigitalPayService {
  // ⚠️ Remplacer par l'URL de TON backend (pas DigitalPaye directement)
  static const String _backendUrl = 'https://tapa-budget-server.onrender.com/api';

  /// Initie un paiement et retourne l'URL de checkout DigitalPaye.
  Future<String?> initierPaiement({
    required String userId,
    required int amount,
    required String operator, // 'WAVE', 'ORANGE', 'MTN', 'MOOV'
    required String phone,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/paiement/init'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
          'operator': operator,
          'phone': phone,
          'description': description ?? 'Rechargement TAPA Budget',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['checkoutUrl'] != null) {
          Logger.success('✅ DigitalPaye URL obtenue: ${data['checkoutUrl']}');
          return data['checkoutUrl'] as String;
        } else {
          Logger.error('❌ DigitalPaye API Error: ${data['error'] ?? data.toString()}');
          return null;
        }
      } else {
        Logger.error('❌ DigitalPaye HTTP Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      Logger.error('❌ Erreur init paiement: $e');
      return null;
    }
  }

  /// Initie le paiement ET ouvre la page de checkout dans un Custom Tab.
  Future<bool> payerAvecDigitalPay({
    required String userId,
    required int amount,
    required String operator,
    required String phone,
    String? description,
  }) async {
    final url = await initierPaiement(
      userId: userId,
      amount: amount,
      operator: operator,
      phone: phone,
      description: description,
    );

    if (url == null) {
      Logger.error('❌ Impossible d\'obtenir l\'URL de paiement');
      return false;
    }

    try {
      await launchUrl(
        Uri.parse(url),
        customTabsOptions: const CustomTabsOptions(
          urlBarHidingEnabled: true,
          showTitle: true,
        ),
      );
      Logger.success('✅ Page de paiement ouverte: $url');
      return true;
    } catch (e) {
      Logger.error('❌ Erreur launchUrl: $e');
      throw Exception('Erreur ouverture navigateur: $e');
    }
  }
}
