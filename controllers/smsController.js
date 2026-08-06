const africaTalkingService = require('../services/africaTalkingService');
const otpGenerator = require('../utils/otpGenerator');

// Stockage temporaire (en production, utiliser Redis)
const otpStorage = new Map();

// Nettoyer les OTP expirés (5 minutes)
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of otpStorage.entries()) {
    if (now > value.expiresAt) {
      otpStorage.delete(key);
    }
  }
}, 5 * 60 * 1000);

// Envoyer un OTP
const sendOTP = async (req, res) => {
  try {
    const { phoneNumber, userId } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'Le numéro de téléphone est requis',
      });
    }

    const cleanPhone = phoneNumber.replace(/\s/g, '').replace(/^\+/, '');

    // Générer un OTP
    const otp = otpGenerator.generateOTP();
    const key = `otp:${cleanPhone}:${userId || 'anonymous'}`;

    // Vérifier si un OTP existe déjà
    if (otpStorage.has(key)) {
      const existing = otpStorage.get(key);
      if (Date.now() < existing.expiresAt) {
        return res.status(429).json({
          success: false,
          message: 'Un code a déjà été envoyé, veuillez attendre',
          expiresIn: Math.floor((existing.expiresAt - Date.now()) / 1000),
        });
      }
    }

    // Envoyer le SMS via Africa's Talking
    const result = await africaTalkingService.sendOTP(cleanPhone, otp);

    if (!result.success) {
      return res.status(500).json({
        success: false,
        message: result.message || 'Erreur lors de l\'envoi du SMS',
      });
    }

    // Stocker l'OTP
    otpStorage.set(key, {
      otp,
      expiresAt: Date.now() + 5 * 60 * 1000, // 5 minutes
      attempts: 0,
      maxAttempts: 3,
    });

    return res.json({
      success: true,
      message: 'Code OTP envoyé avec succès',
      messageId: result.messageId,
      expiresIn: 300, // secondes
    });

  } catch (error) {
    console.error('❌ Erreur sendOTP:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'envoi du code',
    });
  }
};

// Vérifier un OTP
const verifyOTP = async (req, res) => {
  try {
    const { phoneNumber, otp, userId } = req.body;

    if (!phoneNumber || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Le numéro de téléphone et le code sont requis',
      });
    }

    const cleanPhone = phoneNumber.replace(/\s/g, '').replace(/^\+/, '');
    const key = `otp:${cleanPhone}:${userId || 'anonymous'}`;

    const record = otpStorage.get(key);

    if (!record) {
      return res.status(400).json({
        success: false,
        message: 'Aucun code OTP trouvé ou code expiré',
      });
    }

    // Vérifier l'expiration
    if (Date.now() > record.expiresAt) {
      otpStorage.delete(key);
      return res.status(400).json({
        success: false,
        message: 'Le code OTP a expiré',
      });
    }

    // Vérifier les tentatives
    if (record.attempts >= record.maxAttempts) {
      otpStorage.delete(key);
      return res.status(400).json({
        success: false,
        message: 'Trop de tentatives, veuillez demander un nouveau code',
      });
    }

    // Vérifier le code
    if (record.otp !== otp) {
      record.attempts++;
      return res.status(400).json({
        success: false,
        message: `Code invalide, il vous reste ${record.maxAttempts - record.attempts} tentatives`,
      });
    }

    // Code valide
    otpStorage.delete(key);

    return res.json({
      success: true,
      message: 'Code OTP vérifié avec succès',
      verified: true,
    });

  } catch (error) {
    console.error('❌ Erreur verifyOTP:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification du code',
    });
  }
};

// Obtenir le statut
const getStatus = async (req, res) => {
  try {
    const { phone } = req.params;
    const cleanPhone = phone.replace(/\s/g, '').replace(/^\+/, '');
    const key = `otp:${cleanPhone}:anonymous`;

    const record = otpStorage.get(key);

    if (!record) {
      return res.json({
        success: true,
        hasOTP: false,
        message: 'Aucun code OTP actif',
      });
    }

    return res.json({
      success: true,
      hasOTP: true,
      expiresIn: Math.floor((record.expiresAt - Date.now()) / 1000),
      attemptsRemaining: record.maxAttempts - record.attempts,
    });

  } catch (error) {
    console.error('❌ Erreur getStatus:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du statut',
    });
  }
};

module.exports = {
  sendOTP,
  verifyOTP,
  getStatus,
};
