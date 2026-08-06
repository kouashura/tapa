const express = require('express');
const router = express.Router();
const smsController = require('../controllers/smsController');

// Envoyer un OTP
router.post('/send-otp', smsController.sendOTP);

// Vérifier un OTP
router.post('/verify-otp', smsController.verifyOTP);

// Vérifier le statut
router.get('/status/:phone', smsController.getStatus);

module.exports = router;
