import 'dart:convert';
import 'package:http/http.dart' as http;

class MySqlApiService {
  static const String baseUrl = 'http://10.230.149.118:3000/api';

  // ============================================
  // UTILISATEURS
  // ============================================

  Future<List<dynamic>> getUtilisateurs() async {
    final response = await http.get(Uri.parse('$baseUrl/utilisateurs'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getUtilisateur(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/utilisateurs/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createUtilisateur(Map<String, dynamic> data) async {
    print('📡 Création utilisateur...');
    print('📡 URL: $baseUrl/utilisateurs');
    print('📡 Data: $data');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/utilisateurs'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      print('📡 Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Exception: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getPortefeuilles(int utilisateurId) async {
    final response = await http.get(
        Uri.parse('$baseUrl/utilisateurs/$utilisateurId/portefeuilles')
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  // Ajoutez ces méthodes à votre MySqlApiService

  Future<Map<String, dynamic>> updateUtilisateur(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/utilisateurs/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updatePortefeuille(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/portefeuilles/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updatePortefeuilleSolde(int id, double variation) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/portefeuilles/$id/solde'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'variation': variation}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<void> deletePortefeuille(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/portefeuilles/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }
  Future<Map<String, dynamic>> createPortefeuille(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/portefeuilles'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  // ============================================
  // TRANSACTIONS
  // ============================================

  Future<List<dynamic>> getTransactions(int utilisateurId) async {
    final response = await http.get(
        Uri.parse('$baseUrl/utilisateurs/$utilisateurId/transactions')
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  // ============================================
  // STATISTIQUES
  // ============================================

  Future<Map<String, dynamic>> getStatistiques(int utilisateurId) async {
    final response = await http.get(
        Uri.parse('$baseUrl/utilisateurs/$utilisateurId/statistiques')
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  // ============================================
  // CATEGORIES
  // ============================================

  Future<List<dynamic>> getCategories(int utilisateurId) async {
    final response = await http.get(
        Uri.parse('$baseUrl/utilisateurs/$utilisateurId/categories')
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  // ============================================
  // BUDGETS
  // ============================================

  Future<List<dynamic>> getBudgets(int utilisateurId) async {
    final response = await http.get(
        Uri.parse('$baseUrl/utilisateurs/$utilisateurId/budgets')
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  // ============================================
  // AUTHENTIFICATION
  // ============================================

  Future<Map<String, dynamic>> login(String telephone, String pinCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'telephone': telephone, 'pin_code': pinCode}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Identifiants incorrects');
    }
  }
}