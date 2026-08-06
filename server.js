// ============================================
// 1. CHARGEMENT DES VARIABLES D'ENVIRONNEMENT
// ============================================
require('./config');

// ============================================
// 2. IMPORTS
// ============================================
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const smsRoutes = require('./routes/sms');

// ============================================
// 3. CONFIGURATION DE L'APP
// ============================================
const app = express();
const PORT = process.env.PORT || 3000;

// Logs de vérification
console.log('=================================');
console.log('🚀 DÉMARRAGE DU SERVEUR');
console.log('=================================');
console.log('📌 PORT:', PORT);
console.log('📌 AT_USERNAME:', process.env.AT_USERNAME || 'Non défini');
console.log('📌 AT_API_KEY:', process.env.AT_API_KEY ? '✅ OUI' : '❌ NON');
console.log('📌 AT_BASE_URL:', process.env.AT_BASE_URL || 'Non défini');
console.log('=================================');

// ============================================
// 4. MIDDLEWARE
// ============================================
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate Limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000,
  max: parseInt(process.env.RATE_LIMIT_MAX) || 5,
  message: 'Trop de requêtes, veuillez réessayer dans une minute.',
});

// ============================================
// 5. ROUTES
// ============================================
app.use('/api/sms', limiter, smsRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('❌ Erreur:', err);
  res.status(500).json({
    success: false,
    message: err.message || 'Erreur interne du serveur',
  });
});

// ============================================
// 6. DÉMARRAGE
// ============================================
app.listen(PORT, () => {
  console.log(`✅ Serveur SMS Africa's Talking démarré sur le port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`📱 API SMS: http://localhost:${PORT}/api/sms/send-otp`);
  console.log('=================================');
});
