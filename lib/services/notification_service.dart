// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' show TZDateTime, local;
import 'package:timezone/data/latest.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import '../core/utils/constants.dart';
import '../models/echeance_model.dart';
import '../core/utils/logger.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifs =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _notifs.initialize(settings);
      await _notifs
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      print('✅ NotificationService initialisé');
    } catch (e) {
      print('❌ Erreur init notifications: $e');
    }
  }

  static Future<void> programmerMotDuJour() async {
    try {
      await _notifs.show(
        1,
        'Mot du jour TAPA',
        'Ouvre TAPA Budget pour apprendre !',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'education_channel',
            'Education TAPA',
            channelDescription: 'Notifications educatives',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      print('Erreur notification: $e');
    }
  }

  static Future<void> alerteSoldeBas(String nom, double solde) async {
    try {
      await _notifs.show(
        2,
        'Portefeuille presque vide',
        '$nom : ${solde.round()} FCFA restants.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alerte_channel',
            'Alertes solde',
            channelDescription: 'Alertes portefeuille bas',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      print('Erreur notification: $e');
    }
  }

  static Future<void> felicitationsObjectif(String nom) async {
    try {
      await _notifs.show(
        3,
        'Objectif atteint !',
        'Bravo ! Tu as atteint "$nom" !',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'objectif_channel',
            'Objectifs',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      print('Erreur notification: $e');
    }
  }

  static const List<String> _messagesMatin = [
    'Bonjour ! As-tu enregistre tes depenses d hier soir ? 💰',
    'Bonne journee ! Ton TAPA Coach est disponible pour tes questions financieres. 🎯',
    'Bonjour ! Un budget bien suivi commence par une bonne habitude. Note tes depenses ! 📊',
    'Salut ! As-tu verifie ton budget ce mois-ci ? TAPA Coach peut t aider. 💪',
    'Bonjour ! Ton objectif d epargne t attend. 2 minutes pour mettre a jour ! 🐷',
    'Nouvelle journee ! Pense a noter tes revenus et depenses. 📝',
    'Bonjour ! Les petites depenses s accumulent. Note-les maintenant ! 💡',
    'Bonjour ! As-tu parle a ton TAPA Coach aujourd hui ? Il a des conseils pour toi. 🎯',
    'Bonne journee ! Verifie ton solde et note tes transactions. 💰',
    'Bonjour ! L intelligence financiere commence par suivre son argent. C est parti ! 🚀',
  ];

  static const List<String> _messagesSoir = [
    'Bonsoir ! As-tu enregistre toutes tes depenses du jour ? 📊',
    'Fin de journee ! Ton budget est-il a jour ? TAPA Coach peut t aider. 🎯',
    'Bonsoir ! Verifie ton budget et tes objectifs d epargne. 🐷',
    'Il est l heure du bilan financier de la journee ! 2 minutes suffisent. ⏰',
    'Bonsoir ! As-tu note tes depenses ? Chaque FCFA compte ! 💰',
    'La journee se termine. Mets ton budget a jour maintenant ! 📝',
    'Bonsoir ! Un budget suivi chaque jour = liberte financiere demain. 💪',
    'Bonsoir ! Pose une question a ton TAPA Coach sur l epargne ou l investissement. 🎯',
    'Fin de journee ! As-tu verifie tes echeances du mois ? ⏰',
    'Bonsoir ! La richesse se construit avec de petites habitudes quotidiennes. 🚀',
  ];

  static Future<void> programmerRappelsQuotidiens() async {
    try {
      await _notifs.cancel(10);
      await _notifs.cancel(11);

      final now = DateTime.now();
      final rand = now.millisecondsSinceEpoch % 7;

      var heureMatin = DateTime(now.year, now.month, now.day, 7, 0);
      if (heureMatin.isBefore(now)) {
        heureMatin = heureMatin.add(const Duration(days: 1));
      }

      var heureSoir = DateTime(now.year, now.month, now.day, 19, 0);
      if (heureSoir.isBefore(now)) {
        heureSoir = heureSoir.add(const Duration(days: 1));
      }

      await _notifs.zonedSchedule(
        10,
        'TAPA Budget',
        _messagesMatin[rand],
        _toTZDateTime(heureMatin),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'rappel_channel',
            'Rappels quotidiens',
            channelDescription: 'Rappels transactions',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      await _notifs.zonedSchedule(
        11,
        'TAPA Budget',
        _messagesSoir[rand],
        _toTZDateTime(heureSoir),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'rappel_channel',
            'Rappels quotidiens',
            channelDescription: 'Rappels transactions',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Silencieux
    }
  }

  static TZDateTime _toTZDateTime(DateTime dt) {
    return TZDateTime.from(dt, local);
  }

  static Future<void> annulerRappels() async {
    await _notifs.cancel(10);
    await _notifs.cancel(11);
  }

  static Future<void> programmerEcheance(EcheanceModel e) async {
    try {
      final rappel = DateTime.now().add(const Duration(days: 1));
      final idNotif = e.id.hashCode.abs() % 100000;

      await _notifs.zonedSchedule(
        idNotif,
        'Echeance : ${e.titre}',
        '${e.montant.round()} FCFA - ${e.descriptionRecurrence}',
        _toTZDateTime(rappel),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'echeance_channel',
            'Echeances et rappels',
            channelDescription: 'Rappels pour vos echeances',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('Erreur echeance: $e');
    }
  }

  static Future<void> annulerEcheance(String id) async {
    final idNotif = id.hashCode.abs() % 100000;
    await _notifs.cancel(idNotif);
  }

  // ============================================
  // RAPPEL ESSAI GRATUIT - CORRIGÉ
  // ============================================
  static Future<void> programmerRappelEssai(DateTime dateInscription) async {
    try {
      // ✅ RAPPEL 3 JOURS AVANT LA FIN (10 jours d'essai)
      final dateFinEssai = dateInscription.add(const Duration(days: 10));
      final dateRappel = dateFinEssai.subtract(const Duration(days: 3));
      final maintenant = DateTime.now();

      // ✅ NE PAS PROGRAMMER SI LA DATE DE RAPPEL EST DÉPASSÉE
      if (dateRappel.isBefore(maintenant)) {
        Logger.info('ℹ️ Rappel essai déjà passé, non programmé');
        return;
      }

      await _notifs.zonedSchedule(
        20,
        '⏰ TAPA Budget — Votre essai se termine bientôt',
        'Il vous reste 3 jours pour profiter de toutes les fonctionnalités.\n'
            'Passez à l\'accès à vie pour seulement 5 000 FCFA !',
        _toTZDateTime(dateRappel),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'essai_channel',
            'Rappel essai',
            channelDescription: 'Rappels fin d\'essai gratuit',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      Logger.info('✅ Rappel essai programmé pour le ${dateRappel.day}/${dateRappel.month}/${dateRappel.year}');
    } catch (e) {
      Logger.error('❌ Erreur programmation rappel essai: $e');
    }
  }

  // ============================================
  // NOTIFICATION DE FIN D'ESSAI (JOUR 11+)
  // ============================================
  static Future<void> programmerFinEssai(DateTime dateInscription) async {
    try {
      final dateFinEssai = dateInscription.add(const Duration(days: 10));
      final maintenant = DateTime.now();

      // NE PAS PROGRAMMER SI LA DATE EST DÉPASSÉE
      if (dateFinEssai.isBefore(maintenant)) {
        Logger.info('ℹ️ Fin d\'essai déjà passée');
        return;
      }

      await _notifs.zonedSchedule(
        21,
        '🔒 TAPA Budget — Votre essai gratuit est terminé',
        'Pour continuer à utiliser TAPA Budget,\n'
            'activez l\'accès à vie pour seulement 5 000 FCFA !',
        _toTZDateTime(dateFinEssai),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'essai_channel',
            'Fin essai',
            channelDescription: 'Notification de fin d\'essai',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      Logger.info('✅ Notification de fin d\'essai programmée pour le ${dateFinEssai.day}/${dateFinEssai.month}/${dateFinEssai.year}');
    } catch (e) {
      Logger.error('❌ Erreur programmation fin essai: $e');
    }
  }

  // ============================================
  // NOTIFICATION D'ACTIVATION RÉUSSIE
  // ============================================
  static Future<void> notifierActivationReussie() async {
    try {
      await _notifs.show(
        22,
        '🎉 Félicitations !',
        'Votre accès à vie est activé !\n'
            'Profitez de toutes les fonctionnalités de TAPA Budget.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'activation_channel',
            'Activation',
            channelDescription: 'Notifications d\'activation',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      Logger.error('❌ Erreur notification activation: $e');
    }
  }

  static Future<void> verifierAlertes() async {}
}