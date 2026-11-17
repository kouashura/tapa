import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import '../core/utils/logger.dart';

class DigitalPayService {
  static const String _backendUrl = 'https://tapa-budget-server.onrender.com/api';

  Future<String?> initierPaiement({
    required String userId,
    required int amount,
    required String operator,
    required String phone,
    required String sourceWalletId,
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
          'sourceWalletId': sourceWalletId,
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

  Future<bool> payerAvecDigitalPay({
    required String userId,
    required int amount,
    required String operator,
    required String phone,
    required String sourceWalletId,
    String? description,
  }) async {
    final url = await initierPaiement(
      userId: userId,
      amount: amount,
      operator: operator,
      phone: phone,
      sourceWalletId: sourceWalletId,
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

  Future<bool> retirerAvecDigitalPay({
    required String userId,
    required int amount,
    required String operator,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
          'operator': operator,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          Logger.success('✅ Retrait initié: ${data['requestId']}');
          return true;
        } else {
          Logger.error('❌ Erreur retrait: ${data['error']}');
          return false;
        }
      } else {
        Logger.error('❌ Erreur HTTP retrait ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      Logger.error('❌ Erreur retrait: $e');
      return false;
    }
  }
}
