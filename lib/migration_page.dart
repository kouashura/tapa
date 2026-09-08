// lib/screens/migration/migration_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import '../../firebase_options.dart';
import '../../core/utils/logger.dart';

class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  String _status = 'Prêt pour la migration...';
  bool _isMigrating = false;
  int _progress = 0;
  int _total = 0;

  Future<void> _migrate() async {
    setState(() {
      _isMigrating = true;
      _status = 'Début de la migration...';
      _progress = 0;
      _total = 0;
    });

    try {
      // Lire le fichier JSON depuis assets
      final String jsonString = await rootBundle.loadString('assets/data/utilisateurs.json');
      final List<dynamic> users = jsonDecode(jsonString);

      _total = users.length;
      setState(() => _status = 'Migration de $_total utilisateurs...');

      int count = 0;
      for (final user in users) {
        try {
          final telephone = user['telephone']?.toString() ?? '';
          if (telephone.isEmpty) {
            Logger.warning('⚠️ Utilisateur sans téléphone: ${user['prenom']}');
            continue;
          }

          final cleanTelephone = telephone.replaceAll(' ', '').trim();

          // ✅ Utiliser l'UID ou générer un ID si absent
          final String docId = user['uid']?.toString() ?? cleanTelephone;

          await FirebaseFirestore.instance.collection('users').doc(docId).set({
            'uid': user['uid'] ?? '',
            'prenom': user['prenom'] ?? '',
            'phoneNumber': cleanTelephone,  // ✅ CORRIGÉ: phoneNumber au lieu de telephone
            'indicatif': user['indicatif'] ?? '+225',
            'codePays': user['code_pays'] ?? 'CI',
            'monnaie': user['monnaie'] ?? 'FCFA',
            'pinCode': user['pin_code'] ?? '1234',
            'hasAccessVie': user['has_acces_vie'] == 1,
            'cleActivee': user['cle_activee'],
            'dateInscription': user['date_inscription'] ?? DateTime.now().toIso8601String(),  // ✅ FALLBACK
            'derniereActivite': user['derniere_activite'] ?? DateTime.now().toIso8601String(),
            'onboardingVu': user['onboarding_vu'] == 1,
            'notificationsActivees': user['notifications_activees'] == 1,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          count++;
          setState(() {
            _progress = count;
            _status = 'Importé ${user['prenom']} ($count/$_total)';
          });

          Logger.success('✅ ${user['prenom']} - $cleanTelephone');

        } catch (e) {
          Logger.error('❌ Erreur pour ${user['prenom']}: $e');
        }
      }

      setState(() {
        _status = '✅ Migration terminée ! $count utilisateurs importés sur $_total.';
        _isMigrating = false;
      });

    } catch (e) {
      setState(() {
        _status = '❌ Erreur: $e. Vérifiez que le fichier assets/data/utilisateurs.json existe.';
        _isMigrating = false;
      });
      Logger.error('❌ Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migration Firebase'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload, size: 64, color: Color(0xFF1A237E)),
            const SizedBox(height: 20),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (_total > 0) ...[
              LinearProgressIndicator(
                value: _progress / _total,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
              ),
              const SizedBox(height: 10),
              Text(
                '$_progress / $_total',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isMigrating ? null : _migrate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isMigrating ? 'Migration en cours...' : 'Lancer la migration',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            if (_isMigrating)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
              ),
          ],
        ),
      ),
    );
  }
}