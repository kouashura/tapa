// lib/scripts/export_data.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final exportData = <String, dynamic>{};

  final collections = [
    'categories',
    'users',
    'wallets',
    'transactions',
    'email_verifications'
  ];

  print('📥 Exportation en cours...\n');

  for (final collectionName in collections) {
    print('📁 Collection: $collectionName');

    try {
      final snapshot = await firestore.collection(collectionName).get();

      final documents = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      exportData[collectionName] = documents;
      print('   ✅ ${documents.length} documents exportés');

    } catch (e) {
      print('   ❌ Erreur: $e');
    }
  }

  // Sauvegarder en JSON
  final jsonData = jsonEncode(exportData);
  final file = File('firestore_export.json');
  await file.writeAsString(jsonData, mode: FileMode.write);

  print('\n✅ Export terminé !');
  print('📁 Fichier: ${file.path}');
  print('📊 Taille: ${file.statSync().size} bytes');
}