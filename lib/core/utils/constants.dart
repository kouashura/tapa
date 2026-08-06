// lib/core/utils/constants.dart

class AppConstants {
  static const List<Map<String, String>> pays = [
    {'code': 'CI', 'nom': 'Côte d\'Ivoire', 'indicatif': '+225', 'flag': '🇨🇮', 'monnaie': 'FCFA'},
    {'code': 'SN', 'nom': 'Sénégal', 'indicatif': '+221', 'flag': '🇸🇳', 'monnaie': 'FCFA'},
    {'code': 'BF', 'nom': 'Burkina Faso', 'indicatif': '+226', 'flag': '🇧🇫', 'monnaie': 'FCFA'},
    {'code': 'ML', 'nom': 'Mali', 'indicatif': '+223', 'flag': '🇲🇱', 'monnaie': 'FCFA'},
    {'code': 'BJ', 'nom': 'Bénin', 'indicatif': '+229', 'flag': '🇧🇯', 'monnaie': 'FCFA'},
    {'code': 'TG', 'nom': 'Togo', 'indicatif': '+228', 'flag': '🇹🇬', 'monnaie': 'FCFA'},
    {'code': 'NG', 'nom': 'Nigeria', 'indicatif': '+234', 'flag': '🇳🇬', 'monnaie': 'NGN'},
    {'code': 'GH', 'nom': 'Ghana', 'indicatif': '+233', 'flag': '🇬🇭', 'monnaie': 'GHS'},
    {'code': 'FR', 'nom': 'France', 'indicatif': '+33', 'flag': '🇫🇷', 'monnaie': 'EUR'},
    {'code': 'US', 'nom': 'États-Unis', 'indicatif': '+1', 'flag': '🇺🇸', 'monnaie': 'USD'},
  ];

  static const List<Map<String, String>> monnaies = [
    {'symbole': 'FCFA', 'nom': 'Franc CFA'},
    {'symbole': 'NGN', 'nom': 'Naira'},
    {'symbole': 'GHS', 'nom': 'Cedi'},
    {'symbole': 'EUR', 'nom': 'Euro'},
    {'symbole': 'USD', 'nom': 'Dollar'},
    {'symbole': 'GBP', 'nom': 'Livre Sterling'},
  ];

  static const List<Map<String, dynamic>> categoriesDepense = [
    {'id': 'nourriture', 'label': 'Nourriture', 'emoji': '🍽️'},
    {'id': 'transport', 'label': 'Transport', 'emoji': '🚗'},
    {'id': 'logement', 'label': 'Logement', 'emoji': '🏠'},
    {'id': 'sante', 'label': 'Santé', 'emoji': '🏥'},
    {'id': 'education', 'label': 'Éducation', 'emoji': '📚'},
    {'id': 'loisirs', 'label': 'Loisirs', 'emoji': '🎮'},
    {'id': 'tontine', 'label': 'Tontine', 'emoji': '🤝'},
    {'id': 'factures', 'label': 'Factures', 'emoji': '📄'},
    {'id': 'autre', 'label': 'Autre', 'emoji': '📌'},
  ];

  static const List<Map<String, dynamic>> categoriesRevenu = [
    {'id': 'salaire', 'label': 'Salaire', 'emoji': '💰'},
    {'id': 'business', 'label': 'Business', 'emoji': '📈'},
    {'id': 'tontine', 'label': 'Tontine', 'emoji': '🤝'},
    {'id': 'investissement', 'label': 'Investissement', 'emoji': '📊'},
    {'id': 'autre', 'label': 'Autre', 'emoji': '📌'},
  ];
}
