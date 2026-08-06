const admin = require('firebase-admin');

// 🔥 Initialiser Firebase Admin SDK
// Si tu as un fichier serviceAccountKey.json
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 📦 Définition des collections avec des données initiales
const collections = {
  // 1. Collection des utilisateurs (existe déjà)
  users: {
    '+2250711958528': {
      cleActive: null,
      codePays: "CI",
      createdAt: new Date(),
      dateInscription: "2026-06-21 14:26:00.000000",
      dernierActive: new Date().toISOString(),
      hasAccessVie: false,
      indicatif: "+225",
      monnaie: "FCFA",
      notificationsActivees: true,
      onboardingVu: true,
      pinCode: "$2b$10$wYicwx4ufRO6L2ARxV9ZK.57wDqYEo8oJE/5.1...",
      prenom: "Ibrahim"
    }
  },

  // 2. Transactions
  transactions: {
    'tx_001': {
      userId: '+2250711958528',
      type: 'depot',
      montant: 5000,
      monnaie: 'FCFA',
      status: 'completed',
      reference: 'REF_20260804_001',
      description: 'Dépot Mobile Money',
      createdAt: new Date(),
      updatedAt: new Date()
    }
  },

  // 3. Codes OTP
  otp_codes: {
    'otp_001': {
      userId: '+2250711958528',
      code: '5794',
      type: 'login',
      used: false,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000), // +5 min
      createdAt: new Date()
    }
  },

  // 4. Budgets
  budgets: {
    'budget_001': {
      userId: '+2250711958528',
      nom: 'Nourriture',
      montantTotal: 100000,
      depenseActuel: 45000,
      mois: '2026-08',
      createdAt: new Date(),
      updatedAt: new Date()
    }
  },

  // 5. Dépenses
  depenses: {
    'depense_001': {
      userId: '+2250711958528',
      budgetId: 'budget_001',
      categorie: 'Supermarket',
      montant: 2500,
      description: 'Course Auchan',
      date: new Date(),
      createdAt: new Date()
    }
  },

  // 6. Notifications
  notifications: {
    'notif_001': {
      userId: '+2250711958528',
      titre: 'Code de vérification',
      message: 'Votre code OTP est 5794',
      type: 'info',
      lu: false,
      createdAt: new Date()
    }
  },

  // 7. Paramètres
  settings: {
    'settings_001': {
      userId: '+2250711958528',
      langue: 'fr',
      theme: 'dark',
      notifications: {
        push: true,
        email: true,
        sms: true
      },
      pinActif: true,
      biometrieActif: false,
      createdAt: new Date(),
      updatedAt: new Date()
    }
  },

  // 8. Logs SMS
  sms_logs: {
    'sms_001': {
      userId: '+2250711958528',
      code: '5794',
      status: 'sent',
      provider: 'twilio',
      providerId: 'SMxxxxxxxxxxxxxxxx',
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 5 * 60 * 1000)
    }
  }
};

// 🚀 Fonction pour créer toutes les collections
async function initializeDatabase() {
  console.log('🚀 Initialisation de la base de données...');
  console.log('📦 Création des collections...\n');

  for (const [collectionName, documents] of Object.entries(collections)) {
    console.log(`📁 Création de la collection: ${collectionName}`);
    
    for (const [docId, data] of Object.entries(documents)) {
      try {
        await db.collection(collectionName).doc(docId).set(data);
        console.log(`  ✅ Document ${docId} créé avec succès`);
      } catch (error) {
        console.error(`  ❌ Erreur pour ${docId}:`, error.message);
      }
    }
    console.log(`✅ Collection ${collectionName} terminée\n`);
  }

  console.log('🎉 Toutes les collections ont été créées avec succès !');
}

// Exécuter l'initialisation
initializeDatabase().catch(console.error);
