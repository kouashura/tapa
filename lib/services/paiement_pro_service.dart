// lib/services/paiement_pro_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import '../core/utils/logger.dart';

class PaiementProService {
  // ⚠️ Votre ID Marchand PaiementPro
  final String merchantId = 'PP-F914';

  // ✅ URL officielle de l'API d'initialisation
  static const String _apiUrl =
      'https://www.paiementpro.net/webservice/onlinepayment/init/curl-init.php';

  /// Initialise un paiement et retourne l'URL de la page de paiement.
  Future<String?> initierPaiement({
    required int amount,
    required String description,
    required String referenceNumber,
    required String customerEmail,
    required String customerFirstName,
    required String customerLastname,
    required String customerPhoneNumber,
    String channel = 'WAVE',
    String countryCurrencyCode = '952',
    String? notificationURL,
    String? returnURL,
    String? returnContext,
  }) async {
    try {
      final body = {
        'merchantId': merchantId,
        'amount': amount,
        'description': description,
        'channel': channel,
        'countryCurrencyCode': countryCurrencyCode,
        'referenceNumber': referenceNumber,
        'customerEmail': customerEmail,
        'customerFirstName': customerFirstName,
        'customerLastname': customerLastname,
        'customerPhoneNumber': customerPhoneNumber,
      };

      if (notificationURL != null) body['notificationURL'] = notificationURL;
      if (returnURL != null) body['returnURL'] = returnURL;
      if (returnContext != null) body['returnContext'] = returnContext;

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['url'] != null) {
          return data['url'] as String;
        } else {
          Logger.error('❌ PaiementPro: ${data['message'] ?? 'Erreur inconnue'}');
          return null;
        }
      }
      return null;
    } catch (e) {
      Logger.error('❌ Erreur initialisation paiement: $e');
      return null;
    }
  }

  /// Initialise le paiement ET ouvre la page de paiement dans un Custom Tab.
  Future<bool> payerAvecPaiementPro({
    required int amount,
    required String description,
    required String referenceNumber,
    required String customerEmail,
    required String customerFirstName,
    required String customerLastname,
    required String customerPhoneNumber,
    String channel = 'WAVE',
    String countryCurrencyCode = '952',
    String? notificationURL,
    String? returnURL,
    String? returnContext,
  }) async {
    final url = await initierPaiement(
      amount: amount,
      description: description,
      referenceNumber: referenceNumber,
      customerEmail: customerEmail,
      customerFirstName: customerFirstName,
      customerLastname: customerLastname,
      customerPhoneNumber: customerPhoneNumber,
      channel: channel,
      countryCurrencyCode: countryCurrencyCode,
      notificationURL: notificationURL,
      returnURL: returnURL,
      returnContext: returnContext,
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
      Logger.error('❌ Erreur ouverture page de paiement: $e');
      return false;
    }
  }
}
