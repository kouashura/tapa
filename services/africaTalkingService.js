const axios = require('axios');

class AfricaTalkingService {
  constructor() {
    // 🔑 Clé en dur pour production
    this.username = 'kouassi';
    this.apiKey = 'atsk_f9cd1a92a604b136a2cfcb68908fb7c5a0325004ea80e23dc97d759e4a7188207c86c568';
    this.baseUrl = 'https://api.africastalking.com';
    
    console.log('=================================');
    console.log('🚀 AFRICA\'S TALKING - PRODUCTION');
    console.log('=================================');
    console.log('👤 Username:', this.username);
    console.log('🔑 Clé API:', this.apiKey ? '✅ Chargée' : '❌ Manquante');
    console.log('🌐 Base URL:', this.baseUrl);
    console.log('💰 Solde: 43.9792 XOF');
    console.log('=================================');
  }

  async sendSMS(to, message) {
    try {
      const cleanNumber = to.replace(/\s/g, '').replace(/^\+/, '');
      
      console.log(`📤 Envoi SMS à ${cleanNumber}...`);
      console.log(`📝 Message: ${message.substring(0, 50)}...`);
      
      const response = await axios.post(
        `${this.baseUrl}/version1/messaging`,
        new URLSearchParams({
          username: this.username,
          to: cleanNumber,
          message: message,
          from: 'TAPA',
        }),
        {
          headers: {
            'apiKey': this.apiKey,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        }
      );

      const recipient = response.data?.SMSMessageData?.Recipients?.[0];
      
      console.log('✅ SMS envoyé avec succès !');
      console.log(`📊 Statut: ${recipient?.status}`);
      console.log(`🆔 MessageID: ${recipient?.messageId}`);
      console.log(`💰 Coût: ${recipient?.cost}`);
      console.log(`📱 Numéro: ${recipient?.number}`);

      return {
        success: true,
        messageId: recipient?.messageId,
        status: recipient?.status,
        data: response.data,
      };

    } catch (error) {
      console.error('❌ Erreur lors de l\'envoi:');
      console.error(`📝 Message: ${error.message}`);
      
      if (error.response) {
        console.error('📊 Réponse API (erreur):');
        console.error(JSON.stringify(error.response.data, null, 2));
        console.error(`🔢 Status code: ${error.response.status}`);
      }
      
      return {
        success: false,
        message: error.response?.data?.message || error.message,
        error: error.response?.data,
      };
    }
  }

  async sendOTP(to, otp) {
    const message = `TAPA Budget\n\nVotre code de vérification est : ${otp}\n\nValable 5 minutes.\nNe partagez pas ce code.`;
    return this.sendSMS(to, message);
  }
}

module.exports = new AfricaTalkingService();
