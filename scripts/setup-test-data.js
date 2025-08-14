const admin = require('firebase-admin');

// Initialize Firebase Admin SDK for emulator
admin.initializeApp({
  projectId: 'fitness-tracker-p2025',
});

// Connect to Firestore emulator
const db = admin.firestore();
db.settings({
  host: 'localhost:8080',
  ssl: false,
});

async function createTestData() {
  console.log('🎯 Setting up test data for local development...');
  
  try {
    // Create multiple test user profiles
    const users = [
      {
        uid: 'test-user-1',
        height: 175, // cm
        weight: 154, // lbs (70 kg)
        gender: 'male',
        dateOfBirth: admin.firestore.Timestamp.fromDate(new Date('1990-01-01')),
        name: 'John Doe',
        email: 'john@test.com',
      },
      {
        uid: 'test-user-2',
        height: 165, // cm
        weight: 130, // lbs (59 kg)
        gender: 'female',
        dateOfBirth: admin.firestore.Timestamp.fromDate(new Date('1995-06-15')),
        name: 'Jane Smith',
        email: 'jane@test.com',
      }
    ];
    
    // Create user profiles
    for (const user of users) {
      const userProfile = {
        ...user,
        createdAt: admin.firestore.Timestamp.fromDate(new Date()),
        updatedAt: admin.firestore.Timestamp.fromDate(new Date()),
      };
      
      await db.collection('users').doc(user.uid).set(userProfile);
      console.log(`✅ Created user: ${user.name}`);
      
      // Create daily entries for the past week
      const today = new Date();
      for (let i = 0; i < 7; i++) {
        const date = new Date(today);
        date.setDate(today.getDate() - i);
        
        const dailyEntry = {
          id: `${user.uid}_${date.toISOString().split('T')[0]}`,
          uid: user.uid,
          date: admin.firestore.Timestamp.fromDate(date),
          weight: user.weight - (i * 0.2), // Gradual weight loss
          glasses: 6 + Math.floor(Math.random() * 4), // 6-10 glasses
          foodEntries: [
            { name: 'Breakfast', calories: 350 + Math.floor(Math.random() * 100), time: '08:00' },
            { name: 'Lunch', calories: 500 + Math.floor(Math.random() * 150), time: '12:00' },
            { name: 'Dinner', calories: 400 + Math.floor(Math.random() * 200), time: '18:00' },
            { name: 'Snack', calories: 100 + Math.floor(Math.random() * 100), time: '15:00' }
          ],
          exerciseEntries: [
            { 
              name: i % 2 === 0 ? 'Running' : 'Cycling', 
              caloriesBurned: 200 + Math.floor(Math.random() * 200), 
              duration: 30 + Math.floor(Math.random() * 30), 
              time: '07:00' 
            }
          ],
          createdAt: admin.firestore.Timestamp.fromDate(new Date()),
          updatedAt: admin.firestore.Timestamp.fromDate(new Date()),
        };
        
        await db.collection('dailyEntries').doc(dailyEntry.id).set(dailyEntry);
      }
      
      // Create weight loss goal
      const weightLossGoal = {
        uid: user.uid,
        currentWeight: user.weight,
        targetWeight: user.weight - 10,
        weightLossPerWeek: 1.0,
        isActive: true,
        startDate: admin.firestore.Timestamp.fromDate(new Date()),
        createdAt: admin.firestore.Timestamp.fromDate(new Date()),
        updatedAt: admin.firestore.Timestamp.fromDate(new Date()),
      };
      
      await db.collection('weightLossGoals').doc(user.uid).set(weightLossGoal);
      console.log(`✅ Created weight loss goal for: ${user.name}`);
    }
    
    console.log('🎉 Test data setup complete!');
    console.log('👤 Test Users:');
    console.log('   • john@test.com (password: test123)');
    console.log('   • jane@test.com (password: test123)');
    console.log('📊 Dashboard will show sample data for the past week');
    
  } catch (error) {
    console.error('❌ Error setting up test data:', error);
  }
}

createTestData().then(() => {
  console.log('Exiting...');
  process.exit(0);
});