import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

// Initialiser Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

// Africa's Talking - import dynamique
let africastalking: any;
try {
  africastalking = require('africastalking');
} catch (e) {
  console.warn('⚠️ Africastalking non installé, mode simulation');
}

// ============================================
// GÉNÉRATION OTP
// ============================================

export const generateOTP = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 30,
    memory: '128MB',
  })
  .https.onCall(async (data: { phoneNumber: string }, context) => {
    try {
      if (!context.auth?.uid) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Vous devez être connecté'
        );
      }

      const uid = context.auth.uid;
      const { phoneNumber } = data;

      if (!phoneNumber || phoneNumber.length < 8) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Numéro de téléphone invalide'
        );
      }

      // Nettoyer le numéro
      let cleanPhone = phoneNumber
        .replace(/[\s\-+]/g, '')
        .replace(/^0/, '225')
        .replace(/^\+/, '');

      if (!cleanPhone.startsWith('225')) {
        cleanPhone = `225${cleanPhone}`;
      }
      const fullNumber = `+${cleanPhone}`;

      console.log(`📱 Génération OTP pour ${fullNumber} (uid: ${uid})`);

      // Anti-spam : max 3 requêtes en 5 minutes
      const recentOTPs = await admin
        .firestore()
        .collection('otp_requests')
        .where('uid', '==', uid)
        .where('createdAt', '>=', new Date(Date.now() - 5 * 60 * 1000))
        .get();

      if (recentOTPs.size >= 3) {
        throw new functions.https.HttpsError(
          'resource-exhausted',
          'Trop de tentatives (max 3 en 5 minutes)'
        );
      }

      // Générer le code OTP (6 chiffres)
      const otpCode = crypto
        .randomInt(100000, 999999)
        .toString()
        .padStart(6, '0');

      const verificationId = crypto.randomBytes(16).toString('hex');

      // Envoyer le SMS
      let smsSent = false;
      let smsError: string | null = null;

      if (africastalking) {
        try {
          const username = functions.config().at?.username || 'sandbox';
          const apiKey = functions.config().at?.api_key || '';

          if (!apiKey) {
            console.warn('⚠️ API Key Africa\'s Talking non configurée');
            throw new Error('API Key manquante');
          }

          const at = africastalking({
            username: username,
            apiKey: apiKey,
          });

          const sms = at.SMS;
          const result = await sms.send({
            to: [fullNumber],
            message: `Votre code de vérification TAPA Budget est: ${otpCode}\nValable 10 minutes.`,
            from: functions.config().at?.short_code || 'TAPABGT',
          });
          console.log('📨 SMS envoyé:', JSON.stringify(result));
          smsSent = true;
        } catch (error: any) {
          console.error('❌ Erreur envoi SMS:', error);
          smsError = error.message || 'Erreur inconnue';
        }
      } else {
        console.log('⚠️ Africastalking non configuré, mode simulation');
        smsSent = false;
        smsError = 'Mode simulation - SMS non envoyé';
        // En développement, on log le code pour les tests
        console.log(`💡 CODE DE TEST (simulation): ${otpCode}`);
      }

      // Stocker l'OTP dans Firestore
      const otpRef = admin
        .firestore()
        .collection('otp_codes')
        .doc(verificationId);

      await otpRef.set({
        uid,
        phoneNumber: fullNumber,
        cleanPhone,
        code: otpCode,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
        verified: false,
        attempts: 0,
        maxAttempts: 3,
        smsSent,
        smsError,
      });

      // Log de la requête
      await admin
        .firestore()
        .collection('otp_requests')
        .add({
          uid,
          phoneNumber: fullNumber,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          verificationId,
        });

      console.log(`✅ OTP généré pour ${uid}`);

      return {
        success: true,
        message: smsSent ? 'Code envoyé par SMS' : 'Code généré (mode simulation)',
        verificationId: verificationId,
      };

    } catch (error: any) {
      console.error('❌ Erreur generateOTP:', error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Erreur lors de la génération'
      );
    }
  });

// ============================================
// VÉRIFICATION OTP
// ============================================

export const verifyOTP = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 30,
    memory: '128MB',
  })
  .https.onCall(async (data: { verificationId: string; code: string }, context) => {
    try {
      if (!context.auth?.uid) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Vous devez être connecté'
        );
      }

      const uid = context.auth.uid;
      const { verificationId, code } = data;

      if (!verificationId || !code) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'ID de vérification et code requis'
        );
      }

      console.log(`🔍 Vérification OTP pour ${uid}, ID: ${verificationId}`);

      const otpDoc = await admin
        .firestore()
        .collection('otp_codes')
        .doc(verificationId)
        .get();

      if (!otpDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Code de vérification invalide ou expiré'
        );
      }

      const otpData = otpDoc.data();
      if (!otpData) {
        throw new functions.https.HttpsError(
          'not-found',
          'Données de vérification introuvables'
        );
      }

      if (otpData.uid !== uid) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Ce code ne vous appartient pas'
        );
      }

      const expiresAt = otpData.expiresAt.toDate();
      if (new Date() > expiresAt) {
        await otpDoc.ref.update({ status: 'expired' });
        throw new functions.https.HttpsError(
          'deadline-exceeded',
          'Code expiré (10 minutes)'
        );
      }

      if (otpData.verified === true) {
        throw new functions.https.HttpsError(
          'already-exists',
          'Ce code a déjà été utilisé'
        );
      }

      const attempts = (otpData.attempts || 0) + 1;
      if (attempts > otpData.maxAttempts) {
        await otpDoc.ref.update({ status: 'blocked', attempts });
        throw new functions.https.HttpsError(
          'resource-exhausted',
          'Trop de tentatives (max 3)'
        );
      }

      const isValid = otpData.code === code;

      await otpDoc.ref.update({
        attempts,
        verified: isValid,
        status: isValid ? 'verified' : 'failed',
        verifiedAt: isValid ? admin.firestore.FieldValue.serverTimestamp() : null,
      });

      if (!isValid) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Code incorrect'
        );
      }

      // Mettre à jour le profil utilisateur
      await admin
        .firestore()
        .collection('users')
        .doc(uid)
        .update({
          phoneNumber: otpData.phoneNumber,
          phoneVerified: true,
          phoneVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(`✅ OTP vérifié pour ${uid}`);

      return {
        success: true,
        message: 'Téléphone vérifié avec succès',
        userId: uid,
        phoneNumber: otpData.phoneNumber,
      };

    } catch (error: any) {
      console.error('❌ Erreur verifyOTP:', error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Erreur lors de la vérification'
      );
    }
  });

// ============================================
// NETTOYAGE AUTO DES OTP EXPIRÉS
// ============================================

export const cleanupExpiredOTPs = functions
  .region('europe-west1')
  .pubsub
  .schedule('0 * * * *')
  .timeZone('Africa/Abidjan')
  .onRun(async () => {
    try {
      console.log('🧹 Nettoyage des OTP expirés...');

      const expired = await admin
        .firestore()
        .collection('otp_codes')
        .where('expiresAt', '<', new Date())
        .where('verified', '==', false)
        .limit(500)
        .get();

      const batch = admin.firestore().batch();
      expired.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`🧹 ${expired.size} OTP expirés supprimés`);

    } catch (error) {
      console.error('❌ Erreur cleanup:', error);
    }
  });