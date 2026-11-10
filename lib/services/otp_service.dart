import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class OTPService {
  static const String _username = 'sandbox';
  static const String _apiKey =
      'atsk_34c5c02504d1c3c5797634f6154f15f6214a236dc15839ce07c6109d1b122bbbbdbf4dc3';
  static const String _apiUrl =
      'https://api.sandbox.africastalking.com/version1/messaging';

  static String _otpEnCours = '';
  static String _telephoneEnCours = '';

  static String _genererCode() {
    final random = Random.secure();
    return (1000 + random.nextInt(9000)).toString();
  }

  static Future<bool> envoyerOTP(String telephone) async {
    final code = _genererCode();
    _otpEnCours = code;
    _telephoneEnCours = telephone;

    // Formatter le numero
    String tel =
        telephone.replaceAll(' ', '').replaceAll('-', '').replaceAll('+', '');
    if (tel.startsWith('0') && tel.length == 10) {
      tel = '225${tel.substring(1)}';
    } else if (!tel.startsWith('225')) {
      tel = '225$tel';
    }
    tel = '+$tel';

    print('ENVOI SMS A: $tel');

    try {
      final response = await http.post(Uri.parse(_apiUrl), headers: {
        'apiKey': _apiKey,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      }, body: {
        'username': _username,
        'to': tel,
        'message': 'Votre code TAPA Invest : $code. '
            'Valable 10 minutes.',
      });

      print('AT STATUS: ${response.statusCode}');
      print('AT BODY: ${response.body}');

      final data = jsonDecode(response.body);
      final recipients = data['SMSMessageData']?['Recipients'];
      if (recipients != null && (recipients as List).isNotEmpty) {
        final status = recipients[0]['status'] as String? ?? '';
        if (status == 'Success') return true;
      }
      return false;
    } catch (e) {
      print('AT ERROR: $e');
      return false;
    }
  }

  static bool verifierOTP(String code) {
    return code == _otpEnCours && _otpEnCours.isNotEmpty;
  }

  static void reinitialiser() {
    _otpEnCours = '';
    _telephoneEnCours = '';
  }

  static String get telephoneVerifie => _telephoneEnCours;
}
