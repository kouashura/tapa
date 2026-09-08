import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// ============================================
// ACTIVATION DE LICENCE
// ============================================

export const activateLicense = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB',
  })
  .https.onCall(async (data: { licenseKey: string; userEmail?: string }, context) => {
    try {
      if (!context.auth?.uid) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Vous devez être connecté'
        );
      }

      const uid = context.auth.uid;
      const { licenseKey, userEmail } = data;

      if (!licenseKey || licenseKey.length < 10) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Clé de licence invalide'
        );
      }

      console.log(`🔑 Activation licence pour ${uid}: ${licenseKey}`);

      const licenseDoc = await admin
        .firestore()
        .collection('licenses')
        .doc(licenseKey)
        .get();

      let licenseData: any = null;
      let isRoot = false;

      const rootKeys = [
        'TAPA-ROOT-2026-SUPER-ADMIN',
        'TAPA-ROOT-2026-DEVELOPPER',
        'TAPA-ROOT-2026-TESTER',
      ];

      if (rootKeys.includes(licenseKey)) {
        isRoot = true;
        console.log(`👑 Licence root détectée: ${licenseKey}`);
      } else if (licenseDoc.exists) {
        licenseData = licenseDoc.data();

        if (licenseData?.used === true) {
          throw new functions.https.HttpsError(
            'already-exists',
            'Cette licence a déjà été activée'
          );
        }

        if (licenseData?.expiresAt) {
          const expiresAt = licenseData.expiresAt.toDate();
          if (new Date() > expiresAt) {
            throw new functions.https.HttpsError(
              'deadline-exceeded',
              'Cette licence a expiré'
            );
          }
        }
      } else {
        throw new functions.https.HttpsError(
          'not-found',
          'Clé de licence invalide'
        );
      }

      let expiresAt: Date | null = null;
      let licenseType: 'premium' | 'root' = 'premium';

      if (isRoot) {
        licenseType = 'root';
        expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
      } else if (licenseData) {
        expiresAt = licenseData.expiresAt?.toDate() || new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
        licenseType = licenseData.type || 'premium';
      }

      if (!isRoot && licenseDoc.exists) {
        await licenseDoc.ref.update({
          used: true,
          usedBy: uid,
          userEmail: userEmail || null,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      const userRef = admin.firestore().collection('users').doc(uid);
      await userRef.update({
        hasAccesVie: true,
        licenseKey: licenseKey,
        licenseType: licenseType,
        licenseActivatedAt: admin.firestore.FieldValue.serverTimestamp(),
        licenseExpiresAt: expiresAt,
        isRootUser: isRoot,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await admin
        .firestore()
        .collection('license_activations')
        .add({
          uid,
          licenseKey,
          type: licenseType,
          isRoot,
          userEmail: userEmail || null,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt,
        });

      console.log(`✅ Licence activée pour ${uid}: ${licenseType}`);

      return {
        success: true,
        message: isRoot ? 'Accès root activé' : 'Accès premium activé',
        licenseType,
        expiresAt: expiresAt?.toISOString(),
      };

    } catch (error: any) {
      console.error('❌ Erreur activateLicense:', error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Erreur lors de l\'activation'
      );
    }
  });

// ============================================
// VÉRIFICATION DE LICENCE
// ============================================

export const checkLicense = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 30,
    memory: '128MB',
  })
  .https.onCall(async (data: { userId?: string }, context) => {
    try {
      const uid = context.auth?.uid || data.userId;
      if (!uid) {
        return {
          hasAccess: false,
          licenseType: 'none',
          trialDaysRemaining: 0,
        };
      }

      console.log(`🔍 Vérification licence pour ${uid}`);

      const userDoc = await admin
        .firestore()
        .collection('users')
        .doc(uid)
        .get();

      if (!userDoc.exists) {
        return {
          hasAccess: false,
          licenseType: 'none',
          trialDaysRemaining: 0,
        };
      }

      const userData = userDoc.data()!;

      const hasAccesVie = userData.hasAccesVie === true;
      const licenseType = userData.licenseType || 'premium';
      const isRoot = userData.isRootUser === true;
      const expiresAt = userData.licenseExpiresAt?.toDate() || null;

      let isExpired = false;
      if (expiresAt && new Date() > expiresAt) {
        isExpired = true;
        if (hasAccesVie) {
          await admin
            .firestore()
            .collection('users')
            .doc(uid)
            .update({
              hasAccesVie: false,
              licenseExpired: true,
              licenseExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
      }

      const trialStart = userData.dateInscription
        ? new Date(userData.dateInscription)
        : null;

      let trialDaysRemaining = 0;
      if (trialStart) {
        const trialDays = 10;
        const daysUsed = Math.floor((Date.now() - trialStart.getTime()) / (1000 * 60 * 60 * 24));
        trialDaysRemaining = Math.max(0, trialDays - daysUsed);
      }

      let daysRemaining = 0;
      if (expiresAt && !isExpired) {
        daysRemaining = Math.max(0, Math.floor((expiresAt.getTime() - Date.now()) / (1000 * 60 * 60 * 24)));
      }

      const hasAccess = hasAccesVie && !isExpired;

      return {
        hasAccess,
        licenseType: hasAccess ? licenseType : 'none',
        expiresAt: expiresAt?.toISOString(),
        daysRemaining,
        trialDaysRemaining,
        isRoot: isRoot && hasAccess,
      };

    } catch (error) {
      console.error('❌ Erreur checkLicense:', error);
      return {
        hasAccess: false,
        licenseType: 'none',
        trialDaysRemaining: 0,
      };
    }
  });