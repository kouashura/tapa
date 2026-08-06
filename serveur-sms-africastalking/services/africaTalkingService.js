const axios = require('axios');

class AfricaTalkingService {
  constructor() {
    this.username = 'kouassi';
    this.apiKey = 'atsk_f9cd1a92a604b136a2cfcb68908fb7c5a0325004ea80e23dc97d759e4a7188207c86c568';
    this.baseUrl = 'https://api.africastalking.com';

    console.log('=================================');
    console.log('🚀 AFRICA\'S TALKING - PRODUCTION');
    console.log('=================================');
    console.log('👤 Username:', this.username);
    console.log('🔑 Clé API: ✅ Chargée');
    console.log('🌐 Base URL:', this.baseUrl);
    console.log('=================================');
  }

  async sendSMS(to, message) {
    try {
      const cleanNumber = to.replace(/\s/g, '').replace(/^\+/, '');

      console.log(`📤 Envoi SMS à ${cleanNumber}...`);

      const response = await axios.post(
        `${this.baseUrl}/version1/messaging`,
        new URLSearchParams({
          username: this.username,
          to: cleanNumber,
          message: message,
        }),
        {
          headers: {
            'apiKey': this.apiKey,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
        }
      );

      // 🔍 Log de la réponse brute (déjà du JSON, pas du XML)
      console.log('=================================');
      console.log('📦 RÉPONSE BRUTE:');
      console.log('Type:', typeof response.data);
      console.log('Contenu:', JSON.stringify(response.data, null, 2));
      console.log('=================================');

      // ✅ La réponse est du JSON natif, pas besoin de xml2js
      const smsData = response.data?.SMSMessageData;
      let recipients = smsData?.Recipients;

      if (!Array.isArray(recipients)) {
        recipients = recipients ? [recipients] : [];
      }

      const recipient = recipients[0];

      console.log('=================================');
      console.log('📊 DONNÉES EXTRAITES:');
      console.log('- smsData:', smsData);
      console.log('- recipient:', recipient);
      console.log('=================================');

      const status = recipient?.status || 'Unknown';
      const messageId = recipient?.messageId || 'N/A';
      const cost = recipient?.cost || 'N/A';
      const number = recipient?.number || cleanNumber;
      const statusCode = recipient?.statusCode;

      console.log('=================================');
      console.log('✅ SMS envoyé avec succès !');
      console.log(`📊 Statut: ${status}`);
      console.log(`🆔 MessageID: ${messageId}`);
      console.log(`💰 Coût: ${cost}`);
      console.log(`📱 Numéro: ${number}`);
      console.log(`📝 Message complet: ${smsData?.Message || 'N/A'}`);
      console.log('=================================');

      // statusCode 101 ou 102 = succès chez Africa's Talking
      const isSuccess = statusCode === 101 || statusCode === 102 || status === 'Success';

      return {
        success: isSuccess,
        messageId: messageId,
        status: status,
        cost: cost,
        number: number,
        data: response.data,
      };

    } catch (error) {
      console.error('=================================');
      console.error('❌ Erreur lors de l\'envoi:');
      console.error(`📝 Message: ${error.message}`);

      if (error.response) {
        console.error('📊 Réponse API (erreur):');
        console.error(JSON.stringify(error.response.data, null, 2));
        console.error(`🔢 Status code: ${error.response.status}`);
      }
      console.error('=================================');

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