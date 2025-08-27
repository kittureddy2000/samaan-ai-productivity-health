// Debug script to test calculateBMR function in production
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK for production
admin.initializeApp({
  projectId: 'samaan-ai-production-2025'
});

async function debugProductionBMR() {
  try {
    console.log('🔍 Debugging production BMR calculation...');
    
    // List all users in production
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .limit(5)
      .get();
    
    console.log(`📊 Found ${usersSnapshot.size} users in production`);
    
    if (usersSnapshot.empty) {
      console.log('❌ No users found in production database');
      return;
    }
    
    // Check each user's profile data
    for (const userDoc of usersSnapshot.docs) {
      const uid = userDoc.id;
      const userData = userDoc.data();
      
      console.log(`\n👤 User: ${uid}`);
      console.log('📋 Profile data:', {
        height: userData.height,
        weight: userData.weight,
        gender: userData.gender,
        dateOfBirth: userData.dateOfBirth?.toDate?.() || userData.dateOfBirth,
        email: userData.email
      });
      
      // Check required fields for BMR calculation
      const height = userData.height;
      const weightLbs = userData.weight;
      const gender = userData.gender;
      const dateOfBirth = userData.dateOfBirth;
      
      const missingFields = [];
      if (!height) missingFields.push('height');
      if (!weightLbs) missingFields.push('weight');
      if (!gender) missingFields.push('gender');
      if (!dateOfBirth) missingFields.push('dateOfBirth');
      
      if (missingFields.length > 0) {
        console.log(`❌ Missing required fields: ${missingFields.join(', ')}`);
      } else {
        console.log('✅ All required fields present');
        
        // Try to call the calculateBMR function
        try {
          console.log('🧮 Attempting BMR calculation...');
          
          // Calculate age for validation
          const dob = dateOfBirth.toDate ? dateOfBirth.toDate() : new Date(dateOfBirth);
          const today = new Date();
          let age = today.getFullYear() - dob.getFullYear();
          const monthDiff = today.getMonth() - dob.getMonth();
          if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
            age--;
          }
          
          console.log(`📊 Calculated age: ${age}`);
          
          // Manual BMR calculation
          const weightKg = weightLbs * 0.453592;
          let bmr;
          if (gender === 'male') {
            bmr = (10 * weightKg) + (6.25 * height) - (5 * age) + 5;
          } else {
            bmr = (10 * weightKg) + (6.25 * height) - (5 * age) - 161;
          }
          
          console.log(`🧮 Manual BMR calculation: ${bmr}`);
          
          // Check for invalid values
          if (isNaN(bmr) || bmr <= 0) {
            console.log('❌ Invalid BMR result from manual calculation');
          } else {
            console.log('✅ Manual BMR calculation successful');
          }
          
        } catch (calcError) {
          console.log('❌ Error in manual BMR calculation:', calcError.message);
        }
      }
      
      console.log('─'.repeat(50));
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit(0);
  }
}

// Run the debug script
debugProductionBMR();