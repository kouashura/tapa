// lib/presentation/screens/admin/admin_withdraw_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/theme/app_theme.dart';

class AdminWithdrawScreen extends StatefulWidget {
  const AdminWithdrawScreen({super.key});

  @override
  State<AdminWithdrawScreen> createState() => _AdminWithdrawScreenState();
}

class _AdminWithdrawScreenState extends State<AdminWithdrawScreen> {
  // ⚠️ Ce token doit correspondre à celui du serveur
  static const String _adminToken = 'TAPA_ADMIN_SECRET_2026';
  static const String _serverUrl =
      'https://tapa-budget-server.onrender.com/api';

  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/admin/withdraws'),
        headers: {'x-admin-token': _adminToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _requests = List<Map<String, dynamic>>.from(data['requests']);
        });
      } else {
        setState(
            () => _error = 'Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => _error = 'Erreur réseau: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _valider(String requestId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/admin/withdraw/$requestId/complete'),
        headers: {
          'Content-Type': 'application/json',
          'x-admin-token': _adminToken,
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'success'
                ? '✅ Retrait validé'
                : '❌ Retrait marqué comme échoué'),
            backgroundColor: status == 'success' ? Colors.green : Colors.red,
          ),
        );
        _loadRequests(); // Recharger la liste
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: ${response.body}'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur réseau: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Admin - Demandes de retrait'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                )
              : _requests.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune demande en attente',
                        style: TextStyle(
                            fontSize: 16, color: TAPAColors.textSecond),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (ctx, i) {
                        final r = _requests[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.payments,
                                        color: TAPAColors.gold),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${r['amount']} FCFA',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: TAPAColors.navy,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Opérateur : ${r['operator']}'),
                                Text('Numéro : ${r['phone']}'),
                                Text('Date : ${r['requestedAt'] ?? 'N/A'}'),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _valider(r['id'], 'success'),
                                        icon: const Icon(Icons.check,
                                            color: Colors.white),
                                        label: const Text('Valider'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _valider(r['id'], 'failed'),
                                        icon: const Icon(Icons.close,
                                            color: Colors.white),
                                        label: const Text('Échec'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
