const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const mysql = require('mysql2/promise');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');

console.log('Chargement du service account...');

let firebaseApp;
try {
  const serviceAccount = JSON.parse(fs.readFileSync('./service-account.json', 'utf8'));
  console.log('Service account charge pour le projet:', serviceAccount.project_id);

  if (!getApps().length) {
    firebaseApp = initializeApp({
      credential: cert(serviceAccount)
    });
    console.log('Firebase Admin initialise avec succes');
  } else {
    firebaseApp = getApps()[0];
    console.log('Firebase Admin deja initialise, on continue');
  }
} catch (error) {
  console.error('Erreur:', error.message);
  console.error('Details:', error);
  process.exit(1);
}

const db = getFirestore(firebaseApp);

async function testFirebase() {
  try {
    console.log('\nTest de connexion a Firebase...');
    const snapshot = await db.collection('utilisateurs').limit(1).get();
    console.log('Connexion reussie, ' + snapshot.size + ' document(s) trouve(s)');
    return true;
  } catch (e) {
    console.error('Erreur de connexion Firebase:', e.message);
    return false;
  }
}

const mysqlConfig = {
  host: 'localhost',
  port: 8889,
  user: 'root',
  password: 'root',
  database: 'tapa_budget'
};

async function migrate() {
  console.log('\n=== DEBUT DE LA MIGRATION ===\n');
  
  const ok = await testFirebase();
  if (!ok) {
    console.log('Arret de la migration');
    return;
  }
  
  let conn;
  try {
    conn = await mysql.createConnection(mysqlConfig);
    console.log('Connecte a MySQL avec succes');
  } catch (e) {
    console.error('Erreur de connexion MySQL:', e.message);
    return;
  }
  
  try {
    console.log('\n--- Migration des utilisateurs ---');
    const users = await db.collection('utilisateurs').get();
    console.log(users.size + ' utilisateur(s) trouve(s)');
    
    let count = 0;
    for (const doc of users.docs) {
      const data = doc.data();
      const sql = 'INSERT INTO utilisateurs (uuid, prenom, telephone, monnaie, pin_code, created_at) VALUES (?, ?, ?, ?, ?, ?)';
      const values = [
        data.uuid || uuidv4(),
        data.prenom || data.nom || 'Inconnu',
        data.telephone || data.phone || '',
        data.monnaie || 'FCFA',
        data.pin_code || data.pinCode || '1234',
        new Date()
      ];
      
      try {
        await conn.execute(sql, values);
        count++;
        console.log('  -> ' + (data.prenom || data.nom || 'Utilisateur') + ' migre avec succes');
      } catch (e) {
        console.log('  -> Erreur pour ' + (data.prenom || 'Utilisateur') + ': ' + e.message);
      }
    }
    console.log('\n' + count + ' utilisateur(s) migre(s) avec succes');
    
  } catch (e) {
    console.error('Erreur pendant la migration:', e.message);
  } finally {
    await conn.end();
    console.log('\n=== MIGRATION TERMINEE ===');
  }
}

migrate();