// Test script to call the calculateBMR HTTP endpoint
const https = require('https');

async function testCalculateBMRHttp() {
  try {
    console.log('🧪 Testing calculateBMR HTTP endpoint...');
    
    const uid = '54rE8WfAw2a5CIcBatZtDl6Bqw03'; // The user we found
    
    const postData = JSON.stringify({ uid: uid });
    
    const options = {
      hostname: 'us-central1-samaan-ai-production-2025.cloudfunctions.net',
      port: 443,
      path: '/calculateBMRHttp',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };
    
    console.log('📞 Calling HTTP endpoint...');
    console.log('🌐 URL: https://us-central1-samaan-ai-production-2025.cloudfunctions.net/calculateBMRHttp');
    console.log('📦 Payload:', postData);
    
    const req = https.request(options, (res) => {
      console.log(`📡 HTTP Status: ${res.statusCode}`);
      console.log('📋 Headers:', res.headers);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log('📄 Raw response:', data);
        
        try {
          const result = JSON.parse(data);
          console.log('✅ HTTP call successful!');
          console.log('📊 Parsed result:', result);
        } catch (parseError) {
          console.log('❌ Failed to parse HTTP response as JSON');
          console.log('📄 Response content:', data);
        }
        process.exit(0);
      });
    });
    
    req.on('error', (error) => {
      console.log('❌ HTTP request error:', error.message);
      process.exit(1);
    });
    
    req.write(postData);
    req.end();
    
  } catch (error) {
    console.error('❌ General error:', error);
    process.exit(1);
  }
}

// Run the test
testCalculateBMRHttp();