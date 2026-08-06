const admin = require('firebase-admin');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');

dotenv.config();

// ============================================
// CHARGEMENT DU SERVICE ACCOUNT
// ============================================

console.log('Chargement du fichier service-account.json...');

let serviceAccount;
try {
  const rawData = fs.readFileSync('./service-account.json', 'utf8');
  serviceAccount = JSON.parse(rawData);
  console.log('Service account charge avec succes');
  console.log('Projet:', serviceAccount.project_id);
} catch (error) {
  console.error('Erreur lors du chargement du service account:', error.message);
  console.log('Assurez-vous que le fichier service-account.json existe et est valide');
  process.exit(1);
}

// ============================================
// INITIALISATION FIREBASE
// ============================================

try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('Firebase Admin initialise');
} catch (error) {
  console.error('Erreur d\'initialisation Firebase:', error.message);
  process.exit(1);
}

const db = admin.firestore();

// ============================================
// TEST DE CONNEXION FIREBASE
// ============================================

async function testFirebaseConnection() {
  try {
    console.log('\nTest de connexion a Firebase...');
    const testSnapshot = await db.collection('utilisateurs').limit(1).get();
    console.log('Connexion Firebase OK (' + testSnapshot.size + ' document trouve)');
    return true;
  } catch (error) {
    console.error('Erreur de connexion Firebase:', error.message);
    return false;
  }
}

// ============================================
// CONFIGURATION MYSQL
// ============================================

const mysqlConfig = {
  host: process.env.MYSQL_HOST || 'localhost',
  port: parseInt(process.env.MYSQL_PORT) || 8889,
  user: process.env.MYSQL_USER || 'root',
  password: process.env.MYSQL_PASSWORD || 'root',
  database: process.env.MYSQL_DATABASE || 'tapa_budget',
};

console.log('\nConfiguration MySQL:');
console.log('Host:', mysqlConfig.host + ':' + mysqlConfig.port);
console.log('Database:', mysqlConfig.database);
console.log('User:', mysqlConfig.user);

// ============================================
// FONCTIONS UTILES
// ============================================

function formatDate(date) {
  if (!date) return null;
  if (date instanceof admin.firestore.Timestamp) {
    return date.toDate().toISOString().slice(0, 19).replace('T', ' ');
  }
  if (date instanceof Date) {
    return date.toISOString().slice(0, 19).replace('T', ' ');
  }
  if (typeof date === 'string') {
    try {
      const d = new Date(date);
      if (!isNaN(d.getTime())) {
        return d.toISOString().slice(0, 19).replace('T', ' ');
      }
    } catch (e) {}
  }
  return date || null;
}

function formatNumber(value) {
  if (value === undefined || value === null) return 0;
  return parseFloat(value) || 0;
}

function formatBoolean(value) {
  return value ? 1 : 0;
}

// ============================================
// MIGRATION
// ============================================

async function migrate() {
  let connection;
  
  try {
    console.log('\nDebut de la migration Firebase vers MySQL');
    console.log('============================================\n');
    
    // ============================================
    // 1. Test Firebase
    // ============================================
    const firebaseOk = await testFirebaseConnection();
    if (!firebaseOk) {
      console.log('Impossible de se connecter a Firebase.');
      return;
    }
    
    // ============================================
    // 2. Connexion à MySQL
    // ============================================
    console.log('\nConnexion a MySQL...');
    try {
      connection = await mysql.createConnection(mysqlConfig);
      console.log('Connecte a MySQL');
    } catch (error) {
      console.error('Erreur de connexion MySQL:', error.message);
      console.log('Verifiez que MAMP est demarre (port 8889)');
      return;
    }
    
    // ============================================
    // 3. Migration des Utilisateurs
    // ============================================
    console.log('\nMigration des utilisateurs...');
    const utilisateursSnapshot = await db.collection('utilisateurs').get();
    const utilisateurMap = new Map();
    
    if (utilisateursSnapshot.empty) {
      console.log('Aucun utilisateur trouve dans Firebase');
      console.log('La collection "utilisateurs" est vide');
    } else {
      console.log(' ' + utilisateursSnapshot.size + ' utilisateurs trouves');
      
      for (const doc of utilisateursSnapshot.docs) {
        const data = doc.data();
        const uuid = data.uuid || uuidv4();
        
        const query = `
          INSERT INTO utilisateurs (
            uuid, prenom, telephone, indicatif, code_pays, monnaie,
            pin_code, has_acces_vie, date_inscription,
            derniere_activite, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        
        const values = [
          uuid,
          data.prenom || data.nom || 'Utilisateur',
          data.telephone || data.phone || '',
          data.indicatif || '+225',
          data.code_pays || 'CI',
          data.monnaie || 'FCFA',
          data.pin_code || data.pinCode || '1234',
          formatBoolean(data.has_acces_vie || data.hasAccesVie || false),
          formatDate(data.date_inscription || data.createdAt || new Date()),
          formatDate(data.derniere_activite || data.updatedAt || new Date()),
          formatDate(data.created_at || data.createdAt || new Date()),
          formatDate(data.updated_at || data.updatedAt || new Date())
        ];
        
        try {
          const [result] = await connection.execute(query, values);
          utilisateurMap.set(doc.id, result.insertId);
          console.log('   ' + (data.prenom || data.nom || 'Utilisateur') + ' (ID MySQL: ' + 
result.insertId + ')');
        } catch (error) {
          console.error('   Erreur pour ' + (data.prenom || data.nom) + ':', error.message);
        }
      }
    }
    
    console.log('   ' + utilisateurMap.size + ' utilisateurs migres');
    
    // ============================================
    // 4. Migration des Portefeuilles
    // ============================================
    console.log('\nMigration des portefeuilles...');
    try {
      const portefeuillesSnapshot = await db.collection('portefeuilles').get();
      let portefeuilleCount = 0;
      
      for (const doc of portefeuillesSnapshot.docs) {
        const data = doc.data();
        const userId = utilisateurMap.get(data.utilisateur_id);
        
        if (!userId) {
          console.log('   Portefeuille ' + data.nom + ': utilisateur non trouve');
          continue;
        }
        
        const query = `
          INSERT INTO portefeuilles (
            uuid, utilisateur_id, nom, type, emoji, solde, seuil_alerte,
            updated_at, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        
        try {
          await connection.execute(query, [
            data.uuid || uuidv4(),
            userId,
            data.nom || 'Portefeuille',
            data.type || 'compte',
            data.emoji || '$',
            formatNumber(data.solde || 0),
            formatNumber(data.seuil_alerte || 5000),
            formatDate(data.updated_at || data.updatedAt || new Date()),
            formatDate(data.created_at || data.createdAt || new Date())
          ]);
          portefeuilleCount++;
          console.log('   Portefeuille ' + data.nom);
        } catch (error) {
          console.error('   Erreur pour ' + data.nom + ':', error.message);
        }
      }
      console.log('   ' + portefeuilleCount + ' portefeuilles migres');
    } catch (error) {
      console.log('   Collection portefeuilles non trouvee ou vide');
    }
    
    // ============================================
    // 5. Migration des Transactions
    // ============================================
    console.log('\nMigration des transactions...');
    try {
      const transactionsSnapshot = await db.collection('transactions').get();
      let transactionCount = 0;
      
      for (const doc of transactionsSnapshot.docs) {
        const data = doc.data();
        const userId = utilisateurMap.get(data.utilisateur_id);
        
        if (!userId) {
          console.log('   Transaction: utilisateur non trouve');
          continue;
        }
        
        const query = `
          INSERT INTO transactions (
            uuid, utilisateur_id, portefeuille_id, montant,
            type, categorie_id, categorie_label, categorie_emoji,
            note, date_transaction, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        
        try {
          await connection.execute(query, [
            data.uuid || uuidv4(),
            userId,
            1,
            formatNumber(data.montant || 0),
            data.type || 'depense',
            data.categorie_id || 'autre',
            data.categorie_label || 'Autre',
            data.categorie_emoji || '?',
            data.note || null,
            formatDate(data.date_transaction || data.transactionDate || new Date()),
            formatDate(data.created_at || data.createdAt || new Date())
          ]);
          transactionCount++;
        } catch (error) {
          console.error('   Erreur transaction:', error.message);
        }
      }
      console.log('   ' + transactionCount + ' transactions migrees');
    } catch (error) {
      console.log('   Collection transactions non trouvee ou vide');
    }
    
    // ============================================
    // 6. Résumé
    // ============================================
    console.log('\n============================================');
    console.log('Migration terminee avec succes !');
    console.log('Resume:');
    console.log('   - Utilisateurs: ' + utilisateurMap.size);
    console.log('\nVerifiez les donnees dans MySQL:');
    console.log('   SELECT * FROM utilisateurs;');
    
  } catch (error) {
    console.error('Erreur lors de la migration:', error);
    console.error(error.stack);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\nConnexion MySQL fermee');
    }
  }
}

// ============================================
// LANCEMENT
// ============================================

migrate();
