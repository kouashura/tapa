const path = require('path');
const fs = require('fs');

// Lire le fichier .env manuellement
function loadEnv() {
  const envPath = path.join(__dirname, '.env');
  const envContent = fs.readFileSync(envPath, 'utf8');
  
  const lines = envContent.split('\n');
  for (const line of lines) {
    const trimmedLine = line.trim();
    if (!trimmedLine || trimmedLine.startsWith('#')) continue;
    
    const [key, ...valueParts] = trimmedLine.split('=');
    const value = valueParts.join('=').trim();
    
    if (key && value) {
      process.env[key.trim()] = value;
      console.log(`📌 Chargé: ${key.trim()}`);
    }
  }
}

loadEnv();

console.log('🔑 AT_API_KEY après chargement:', process.env.AT_API_KEY ? '✅ OUI' : '❌ NON');
