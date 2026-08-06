const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Connexion MySQL
const db = mysql.createConnection({
    host: 'localhost',
    port: 8889,
    user: 'root',
    password: 'root',
    database: 'tapa_budget'
});

db.connect((err) => {
    if (err) {
        console.error('Erreur de connexion à MySQL:', err);
        return;
    }
    console.log('✅ Connecté à MySQL');
});

// ============================================
// ROUTES API
// ============================================

// GET: Récupérer tous les utilisateurs
app.get('/api/utilisateurs', (req, res) => {
    db.query('SELECT * FROM utilisateurs', (err, results) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json(results);
    });
});

// POST: Créer un utilisateur
app.post('/api/utilisateurs', (req, res) => {
    const { 
        prenom, 
        telephone, 
        indicatif, 
        codePays, 
        monnaie, 
        pinCode, 
        hasAccesVie,
        dateInscription 
    } = req.body;

    console.log('📝 Création utilisateur:', { prenom, telephone });

    if (!prenom || !telephone) {
        return res.status(400).json({ error: 'Le prénom et le téléphone sont requis' });
    }

    // Générer un UUID automatiquement
    const uuid = require('crypto').randomUUID ? require('crypto').randomUUID() : 
        'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });

    const query = `
        INSERT INTO utilisateurs 
        (uuid, prenom, telephone, indicatif, code_pays, monnaie, pin_code, has_acces_vie, date_inscription) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const values = [
        uuid,
        prenom,
        telephone,
        indicatif || '+225',
        codePays || 'CI',
        monnaie || 'FCFA',
        pinCode || '1234',
        hasAccesVie || 0,
        dateInscription || new Date()
    ];

    db.query(query, values, (err, result) => {
        if (err) {
            console.error('❌ Erreur insertion:', err);
            return res.status(500).json({ error: err.message });
        }
        console.log('✅ Utilisateur créé ID:', result.insertId);
        res.status(201).json({ 
            id: result.insertId, 
            message: 'Utilisateur créé avec succès' 
        });
    });
});

// GET: Récupérer un utilisateur par ID
app.get('/api/utilisateurs/:id', (req, res) => {
    const { id } = req.params;
    db.query(
        'SELECT * FROM utilisateurs WHERE id = ?',
        [id],
        (err, results) => {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            if (results.length === 0) {
                res.status(404).json({ error: 'Utilisateur non trouvé' });
                return;
            }
            res.json(results[0]);
        }
    );
});

// GET: Récupérer les portefeuilles d'un utilisateur
app.get('/api/utilisateurs/:id/portefeuilles', (req, res) => {
    const { id } = req.params;
    db.query(
        'SELECT * FROM portefeuilles WHERE utilisateur_id = ?',
        [id],
        (err, results) => {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            res.json(results);
        }
    );
});

// POST: Créer un portefeuille
app.post('/api/portefeuilles', (req, res) => {
    const { uuid, utilisateur_id, nom, type, emoji, solde, seuilAlerte } = req.body;

    const query = `
        INSERT INTO portefeuilles 
        (uuid, utilisateur_id, nom, type, emoji, solde, seuil_alerte) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
    `;

    db.query(
        query,
        [uuid, utilisateur_id, nom, type || 'compte', emoji || '💰', solde || 0, seuilAlerte || 5000],
        (err, result) => {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            res.status(201).json({ 
                id: result.insertId, 
                message: 'Portefeuille créé avec succès' 
            });
        }
    );
});

// GET: Récupérer les transactions d'un utilisateur
app.get('/api/utilisateurs/:id/transactions', (req, res) => {
    const { id } = req.params;
    db.query(
        'SELECT * FROM transactions WHERE utilisateur_id = ? ORDER BY date_transaction DESC',
        [id],
        (err, results) => {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            res.json(results);
        }
    );
});

// POST: Créer une transaction
app.post('/api/transactions', (req, res) => {
    const {
        uuid, utilisateur_id, portefeuille_id, montant,
        type, categorie_id, categorie_label, categorie_emoji,
        note, date_transaction
    } = req.body;

    const query = `
        INSERT INTO transactions 
        (uuid, utilisateur_id, portefeuille_id, montant, type, 
         categorie_id, categorie_label, categorie_emoji, note, date_transaction)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    db.query(
        query,
        [uuid, utilisateur_id, portefeuille_id, montant, type,
         categorie_id, categorie_label, categorie_emoji, note, date_transaction],
        (err, result) => {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            res.status(201).json({ 
                id: result.insertId, 
                message: 'Transaction créée avec succès' 
            });
        }
    );
});

// GET: Statistiques (total revenus, dépenses, solde)
app.get('/api/utilisateurs/:id/statistiques', (req, res) => {
    const { id } = req.params;

    const query = `
        SELECT 
            COALESCE(SUM(CASE WHEN type = 'revenu' THEN montant ELSE 0 END), 0) as total_revenus,
            COALESCE(SUM(CASE WHEN type = 'depense' THEN montant ELSE 0 END), 0) as total_depenses,
            COALESCE(SUM(CASE WHEN type = 'revenu' THEN montant ELSE 0 END), 0) - 
            COALESCE(SUM(CASE WHEN type = 'depense' THEN montant ELSE 0 END), 0) as solde
        FROM transactions 
        WHERE utilisateur_id = ?
    `;

    db.query(query, [id], (err, results) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json(results[0]);
    });
});

// GET: Récupérer les catégories d'un utilisateur
app.get('/api/utilisateurs/:id/categories', (req, res) => {
    const { id } = req.params;
    db.query(
        'SELECT * FROM categories WHERE utilisateur_id = ?',
        [id],
        (err, results) => {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            res.json(results);
        }
    );
});

// GET: Récupérer les budgets d'un utilisateur
app.get('/api/utilisateurs/:id/budgets', (req, res) => {
    const { id } = req.params;
    db.query(
        'SELECT * FROM budgets WHERE utilisateur_id = ?',
        [id],
        (err, results) => {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            res.json(results);
        }
    );
});

// POST: Login
app.post('/api/auth/login', (req, res) => {
    const { telephone, pin_code } = req.body;

    db.query(
        'SELECT * FROM utilisateurs WHERE telephone = ? AND pin_code = ?',
        [telephone, pin_code],
        (err, results) => {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            if (results.length === 0) {
                res.status(401).json({ error: 'Identifiants incorrects' });
                return;
            }
            res.json({ 
                success: true, 
                user: results[0],
                message: 'Connexion réussie'
            });
        }
    );
});

// ============================================
// DÉMARRAGE DU SERVEUR
// ============================================

app.listen(port, '0.0.0.0', () => {
    console.log(`🚀 API démarrée sur http://0.0.0.0:${port}`);
});