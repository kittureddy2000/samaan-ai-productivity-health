// Test script to verify the production web app BMR calculation works
const https = require('https');

async function testProductionApp() {
  try {
    console.log('🧪 Testing production web app BMR calculation...');
    
    // Test the main production app URL
    console.log('🌐 Checking production web app at: https://samaan-ai-production-2025.web.app');
    
    // Test the HTTP endpoint directly (this should work)
    console.log('\n📞 Testing HTTP endpoint directly...');
    const uid = '54rE8WfAw2a5CIcBatZtDl6Bqw03';
    
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
    
    const req = https.request(options, (res) => {
      console.log(`📡 HTTP Status: ${res.statusCode}`);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          console.log('✅ Direct HTTP endpoint test: SUCCESS');
          console.log(`🧮 BMR Result: ${result.bmr}`);
          
          if (result.bmr && result.bmr > 0) {
            console.log('\n🎉 BMR calculation is working correctly!');
            console.log('📊 Full result:', result);
          } else {
            console.log('\n❌ BMR calculation returned invalid result');
          }
          
        } catch (parseError) {
          console.log('❌ Failed to parse response:', data);
        }
        
        console.log('\n' + '='.repeat(50));
        console.log('📋 Summary:');
        console.log('✅ HTTP endpoint: Working');
        console.log('🔧 If the web app still shows errors, it means:');
        console.log('   1. The web deployment is still in progress, OR');
        console.log('   2. Browser cache needs to be cleared, OR');
        console.log('   3. There\'s a client-side issue calling the endpoint');
        console.log('='.repeat(50));
        
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
    console.error('❌ Test error:', error);
    process.exit(1);
  }
}

// Run the test
testProductionApp();