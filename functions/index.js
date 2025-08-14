const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({
  origin: [
    'https://samaan-ai-production-2025.web.app',
    'https://samaan-ai-production-2025.firebaseapp.com',
    'https://samaan-ai-staging-2025.web.app',
    'https://samaan-ai-staging-2025.firebaseapp.com',
    'http://localhost:3000',
    'http://localhost:5000'
  ]
});

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Calculate BMR using the Mifflin-St Jeor Equation
 * For men: BMR = 10 × weight + 6.25 × height - 5 × age + 5
 * For women: BMR = 10 × weight + 6.25 × height - 5 × age - 161
 */
exports.calculateBMR = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to calculate BMR.',
    );
  }

  const uid = data.uid || context.auth.uid;

  try {
    // Get user profile from Firestore
    const userDoc = await admin.firestore()
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
          'not-found',
          'User profile not found.',
      );
    }

    const userData = userDoc.data();
    const height = userData.height; // in cm
    const weightLbs = userData.weight; // stored in lbs in Firestore
    const weightKg = weightLbs * 0.453592; // Convert lbs to kg for BMR calculation
    const gender = userData.gender;
    const dateOfBirth = userData.dateOfBirth && userData.dateOfBirth.toDate ? 
      userData.dateOfBirth.toDate() : new Date(userData.dateOfBirth);

    // Validate required fields
    if (!height || !weightLbs || !gender || !dateOfBirth) {
      throw new functions.https.HttpsError(
          'invalid-argument',
          'Missing required profile data: height, weight, gender, or dateOfBirth',
      );
    }

    // Validate numeric values
    if (isNaN(height) || isNaN(weightLbs) || height <= 0 || weightLbs <= 0) {
      throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid height or weight values',
      );
    }

    // Calculate age
    const today = new Date();
    let age = today.getFullYear() - dateOfBirth.getFullYear();
    const monthDiff = today.getMonth() - dateOfBirth.getMonth();
    if (monthDiff < 0 ||
        (monthDiff === 0 && today.getDate() < dateOfBirth.getDate())) {
      age--;
    }

    // Validate age
    if (isNaN(age) || age <= 0 || age > 120) {
      throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid age calculated from date of birth',
      );
    }

    // Calculate BMR using Mifflin-St Jeor equation
    // For men: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age + 5
    // For women: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age - 161
    let bmr;
    if (gender === 'male') {
      bmr = (10 * weightKg) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * height) - (5 * age) - 161;
    }

    // Validate BMR result
    if (isNaN(bmr) || bmr <= 0) {
      throw new functions.https.HttpsError(
          'internal',
          'Invalid BMR calculation result',
      );
    }

    const result = {
      bmr: Math.round(bmr * 100) / 100, // Round to 2 decimal places
      weightLbs: weightLbs, // Original weight in lbs
      weightKg: Math.round(weightKg * 100) / 100, // Weight in kg used for calculation
      height: height,
      age: age,
      gender: gender,
    };

    // Validate all return values
    Object.keys(result).forEach(key => {
      if (typeof result[key] === 'number' && isNaN(result[key])) {
        throw new functions.https.HttpsError(
            'internal',
            `Invalid ${key} value in BMR calculation`,
        );
      }
    });

    return result;
  } catch (error) {
    console.error('Error calculating BMR:', error);
    if (error.code) {
      throw error; // Re-throw HttpsError
    }
    throw new functions.https.HttpsError(
        'internal',
        'Failed to calculate BMR: ' + error.message,
    );
  }
});

/**
 * Helper function to calculate BMR (for internal use)
 */
async function calculateBMRInternal(uid) {
  // Get user profile from Firestore
  const userDoc = await admin.firestore()
      .collection('users')
      .doc(uid)
      .get();

  if (!userDoc.exists) {
    throw new Error('User profile not found');
  }

  const userData = userDoc.data();
  const height = userData.height; // in cm
  const weightLbs = userData.weight; // stored in lbs in Firestore
  const weightKg = weightLbs * 0.453592; // Convert lbs to kg for BMR calculation
  const gender = userData.gender;
  const dateOfBirth = userData.dateOfBirth && userData.dateOfBirth.toDate ? 
    userData.dateOfBirth.toDate() : new Date(userData.dateOfBirth);

  // Validate required fields
  if (!height || !weightLbs || !gender || !dateOfBirth) {
    throw new Error('Missing required profile data');
  }

  // Validate numeric values
  if (isNaN(height) || isNaN(weightLbs) || height <= 0 || weightLbs <= 0) {
    throw new Error('Invalid height or weight values');
  }

  // Calculate age
  const today = new Date();
  let age = today.getFullYear() - dateOfBirth.getFullYear();
  const monthDiff = today.getMonth() - dateOfBirth.getMonth();
  if (monthDiff < 0 ||
      (monthDiff === 0 && today.getDate() < dateOfBirth.getDate())) {
    age--;
  }

  // Validate age
  if (isNaN(age) || age <= 0 || age > 120) {
    throw new Error('Invalid age calculated');
  }

  // Calculate BMR using Mifflin-St Jeor equation
  let bmr;
  if (gender === 'male') {
    bmr = (10 * weightKg) + (6.25 * height) - (5 * age) + 5;
  } else {
    bmr = (10 * weightKg) + (6.25 * height) - (5 * age) - 161;
  }

  // Validate BMR result
  if (isNaN(bmr) || bmr <= 0) {
    throw new Error('Invalid BMR calculation result');
  }

  return {
    bmr: Math.round(bmr * 100) / 100,
    weightLbs: weightLbs,
    weightKg: Math.round(weightKg * 100) / 100,
    height: height,
    age: age,
    gender: gender,
  };
}

/**
 * Generate calorie report for a specific period
 * Calculates net calorie deficit for each day in the period
 */
exports.generateCalorieReport = functions.https.onCall(
    async (data, context) => {
      // Check if user is authenticated
      if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated to generate report.',
        );
      }

      const uid = data.uid || context.auth.uid;
      const period = data.period || 'weekly';

      try {
        // Calculate date range based on period
        const endDate = new Date();
        const startDate = new Date();

        switch (period) {
          case 'weekly':
            // Weekly period: Wednesday to Tuesday
            const currentDay = endDate.getDay(); // 0=Sunday, 1=Monday, 2=Tuesday, 3=Wednesday, etc.
            
            // Set end date to next Tuesday (or today if today is Tuesday)
            const daysUntilNextTuesday = currentDay === 2 ? 0 : (2 + 7 - currentDay) % 7;
            endDate.setDate(endDate.getDate() + daysUntilNextTuesday);
            endDate.setHours(23, 59, 59, 999); // End of Tuesday
            
            // Set start date to Wednesday (7 days before Tuesday)
            startDate.setDate(endDate.getDate() - 6); // 7 days back from end
            startDate.setHours(0, 0, 0, 0); // Start of Wednesday
            break;
          case 'monthly':
            startDate.setMonth(endDate.getMonth() - 1);
            break;
          case 'yearly':
            startDate.setFullYear(endDate.getFullYear() - 1);
            break;
          default:
            // Default to Wednesday-Tuesday weekly
            const defaultCurrentDay = endDate.getDay();
            const defaultDaysUntilNextTuesday = defaultCurrentDay === 2 ? 0 : (2 + 7 - defaultCurrentDay) % 7;
            endDate.setDate(endDate.getDate() + defaultDaysUntilNextTuesday);
            endDate.setHours(23, 59, 59, 999);
            startDate.setDate(endDate.getDate() - 6);
            startDate.setHours(0, 0, 0, 0);
        }

        // Get BMR for the user using internal function
        const bmrResult = await calculateBMRInternal(uid);
        const userBMR = bmrResult.bmr;

        // Validate BMR
        if (isNaN(userBMR) || userBMR <= 0) {
          throw new Error('Invalid BMR calculation');
        }

        // Get user's weight loss goal for accurate deficit calculation
        let userGoal = null;
        try {
          const goalDoc = await admin.firestore()
              .collection('weightLossGoals')
              .doc(uid)
              .get();

          if (goalDoc.exists) {
            const goalData = goalDoc.data();
            if (goalData && goalData.isActive) {
              userGoal = goalData;
              console.log(`User has active weight loss goal: ${goalData.weightLossPerWeek} lbs/week`);
            }
          }
        } catch (goalError) {
          console.error('Error fetching weight loss goal:', goalError);
          // Continue without goal
        }

        // Get daily entries for the period (simplified for testing)
        const dailyEntriesSnapshot = await admin.firestore()
            .collection('dailyEntries')
            .where('uid', '==', uid)
            .get();

        const reportData = [];
        const dailyEntries = {};

        // Process daily entries
        dailyEntriesSnapshot.forEach((doc) => {
          const data = doc.data();
          const dateKey = data.date.toDate().toISOString().split('T')[0];
          dailyEntries[dateKey] = data;
        });

        // Generate report data for each day in the period
        let totalCaloriesConsumed = 0;
        let totalCaloriesBurned = 0;
        let totalNetDeficit = 0;
        let totalGlasses = 0;
        let daysWithData = 0;
        
        // Calculate total days in period
        const totalDaysInPeriod = Math.max(1, Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24)) + 1);

        const currentDate = new Date(startDate);
        while (currentDate <= endDate) {
          const dateKey = currentDate.toISOString().split('T')[0];
          const dayEntry = dailyEntries[dateKey];

          let caloriesConsumed = 0;
          let caloriesBurned = 0;
          let weight = null;
          let glasses = null;
          let hasData = false; // Track if this day has any meaningful data

          if (dayEntry) {
            // Calculate total calories consumed
            if (dayEntry.foodEntries && Array.isArray(dayEntry.foodEntries)) {
              caloriesConsumed = dayEntry.foodEntries.reduce((total, entry) => {
                const calories = entry.calories || 0;
                return total + (isNaN(calories) ? 0 : calories);
              }, 0);
              // Only count as having data if there are actual food entries with calories > 0
              if (dayEntry.foodEntries.length > 0 && caloriesConsumed > 0) {
                hasData = true;
              }
            }

            // Calculate total calories burned
            if (dayEntry.exerciseEntries &&
            Array.isArray(dayEntry.exerciseEntries)) {
              caloriesBurned = dayEntry.exerciseEntries.reduce(
                  (total, entry) => {
                    const burned = entry.caloriesBurned || 0;
                    return total + (isNaN(burned) ? 0 : burned);
                  }, 0);
              // Only count as having data if there are actual exercise entries with calories > 0
              if (dayEntry.exerciseEntries.length > 0 && caloriesBurned > 0) {
                hasData = true;
              }
            }

            weight = dayEntry.weight;
            // Weight entry alone also counts as data
            if (weight !== null && !isNaN(weight) && weight > 0) {
              hasData = true;
            }
            
            glasses = dayEntry.glasses;
            // Glasses entry alone also counts as data
            if (glasses !== null && !isNaN(glasses) && glasses > 0) {
              hasData = true;
            }
          }

          // Only include this day in the report if it has actual data
          if (hasData) {
            // Validate numbers
            caloriesConsumed = isNaN(caloriesConsumed) ? 0 : caloriesConsumed;
            caloriesBurned = isNaN(caloriesBurned) ? 0 : caloriesBurned;

            // Calculate net calorie deficit with weight loss goal context
            // For weight loss: negative deficit = good (eating less than target)
            // For maintenance: deficit near 0 = good
            let netCalorieDeficit;
            let targetDailyCalories;

            if (userGoal && userGoal.weightLossPerWeek) {
              // With weight loss goal: Target + exercise - consumed
              const dailyCalorieDeficit = (userGoal.weightLossPerWeek * 3500) / 7;
              targetDailyCalories = userBMR - dailyCalorieDeficit;
              netCalorieDeficit = (targetDailyCalories + caloriesBurned) - caloriesConsumed;
            } else {
              // Without goal: maintenance mode (BMR + exercise)
              targetDailyCalories = userBMR + caloriesBurned;
              netCalorieDeficit = targetDailyCalories - caloriesConsumed;
            }

            // Validate the calculated values
            if (isNaN(netCalorieDeficit)) {
              console.error('NaN detected in netCalorieDeficit calculation:', {
                userBMR, caloriesConsumed, caloriesBurned,
              });
            } else {
              const dailyData = {
                date: currentDate.toISOString().split('T')[0],
                bmr: Math.round(userBMR * 100) / 100,
                caloriesConsumed: Math.round(caloriesConsumed * 100) / 100,
                caloriesBurned: Math.round(caloriesBurned * 100) / 100,
                netCalorieDeficit: Math.round(netCalorieDeficit * 100) / 100,
                weight: weight && !isNaN(weight) && weight > 0 ? 
                  Math.round(weight * 100) / 100 : null,
                glasses: glasses && !isNaN(glasses) && glasses > 0 ? 
                  Math.round(glasses * 100) / 100 : null,
              };
              
              // Validate all numeric fields before adding
              let validData = true;
              Object.keys(dailyData).forEach(key => {
                if (key !== 'weight' && key !== 'glasses' && typeof dailyData[key] === 'number' && isNaN(dailyData[key])) {
                  console.error(`NaN detected in dailyData.${key}:`, dailyData[key]);
                  validData = false;
                }
              });
              
              if (validData) {
                reportData.push(dailyData);
              }

              totalCaloriesConsumed += caloriesConsumed;
              totalCaloriesBurned += caloriesBurned;
              totalNetDeficit += netCalorieDeficit;
              totalGlasses += glasses || 0;
              daysWithData++;
            }
          }

          // Move to next day
          currentDate.setDate(currentDate.getDate() + 1);
        }

        // Validate totals
        totalCaloriesConsumed = isNaN(totalCaloriesConsumed) ? 
          0 : Math.round(totalCaloriesConsumed * 100) / 100;
        totalCaloriesBurned = isNaN(totalCaloriesBurned) ? 
          0 : Math.round(totalCaloriesBurned * 100) / 100;
        totalNetDeficit = isNaN(totalNetDeficit) ? 
          0 : Math.round(totalNetDeficit * 100) / 100;
        totalGlasses = isNaN(totalGlasses) ? 
          0 : Math.round(totalGlasses * 100) / 100;

        const result = {
          period: String(period),
          startDate: String(startDate.toISOString().split('T')[0]),
          endDate: String(endDate.toISOString().split('T')[0]),
          data: reportData.map(item => ({
            date: String(item.date),
            bmr: Number(item.bmr),
            caloriesConsumed: Number(item.caloriesConsumed),
            caloriesBurned: Number(item.caloriesBurned),
            netCalorieDeficit: Number(item.netCalorieDeficit),
            weight: item.weight !== null ? Number(item.weight) : null,
            glasses: item.glasses !== null ? Number(item.glasses) : null,
          })),
          averageBMR: Number(userBMR),
          totalCaloriesConsumed: Number(totalCaloriesConsumed),
          totalCaloriesBurned: Number(totalCaloriesBurned),
          totalNetDeficit: Number(totalNetDeficit),
          totalGlasses: Number(totalGlasses),
          averageGlasses: daysWithData > 0 ? Number(totalGlasses / daysWithData) : 0,
          daysWithData: Number(daysWithData),
          totalDays: Number(totalDaysInPeriod),
        };

        // Final validation of result
        Object.keys(result).forEach(key => {
          if (typeof result[key] === 'number' && (isNaN(result[key]) || !isFinite(result[key]))) {
            console.error(`Invalid number detected in result.${key}:`, result[key]);
            throw new Error(`Invalid ${key} value in report`);
          }
        });
        
        // Ensure totalDays is reasonable
        if (result.totalDays <= 0 || result.totalDays > 366) {
          console.error(`Invalid totalDays calculated: ${result.totalDays}`);
          throw new Error('Invalid total days calculation');
        }

        return result;
      } catch (error) {
        console.error('Error generating calorie report:', error);
        throw new functions.https.HttpsError(
            'internal',
            'Failed to generate calorie report: ' + error.message,
        );
      }
    });

/**
 * HTTP endpoint for calculateBMR with CORS support
 * This handles direct HTTP calls that bypass the Firebase SDK
 */
exports.calculateBMRHttp = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({error: 'Method not allowed'});
      }

      const data = req.body;
      const uid = data.uid;

      if (!uid) {
        return res.status(400).json({error: 'User ID is required'});
      }

      const result = await calculateBMRInternal(uid);
      return res.status(200).json(result);
    } catch (error) {
      console.error('Error in calculateBMRHttp:', error);
      return res.status(500).json({error: 'Failed to calculate BMR: ' + error.message});
    }
  });
});

/**
 * HTTP endpoint for generateCalorieReport with CORS support  
 */
exports.generateCalorieReportHttp = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({error: 'Method not allowed'});
      }

      const data = req.body;
      const uid = data.uid;
      const period = data.period || 'weekly';

      if (!uid) {
        return res.status(400).json({error: 'User ID is required'});
      }

      // Calculate date range based on period
      const endDate = new Date();
      const startDate = new Date();

      switch (period) {
        case 'weekly':
          const currentDay = endDate.getDay();
          const daysUntilNextTuesday = currentDay === 2 ? 0 : (2 + 7 - currentDay) % 7;
          endDate.setDate(endDate.getDate() + daysUntilNextTuesday);
          endDate.setHours(23, 59, 59, 999);
          startDate.setDate(endDate.getDate() - 6);
          startDate.setHours(0, 0, 0, 0);
          break;
        case 'monthly':
          startDate.setMonth(endDate.getMonth() - 1);
          break;
        case 'yearly':
          startDate.setFullYear(endDate.getFullYear() - 1);
          break;
        default:
          const defaultCurrentDay = endDate.getDay();
          const defaultDaysUntilNextTuesday = defaultCurrentDay === 2 ? 0 : (2 + 7 - defaultCurrentDay) % 7;
          endDate.setDate(endDate.getDate() + defaultDaysUntilNextTuesday);
          endDate.setHours(23, 59, 59, 999);
          startDate.setDate(endDate.getDate() - 6);
          startDate.setHours(0, 0, 0, 0);
      }

      // Get BMR for the user using internal function
      const bmrResult = await calculateBMRInternal(uid);
      const userBMR = bmrResult.bmr;

      // Validate BMR
      if (isNaN(userBMR) || userBMR <= 0) {
        return res.status(500).json({error: 'Invalid BMR calculation'});
      }

      // Get user's weight loss goal for accurate deficit calculation
      let userGoal = null;
      try {
        const goalDoc = await admin.firestore()
            .collection('weightLossGoals')
            .doc(uid)
            .get();

        if (goalDoc.exists) {
          const goalData = goalDoc.data();
          if (goalData && goalData.isActive) {
            userGoal = goalData;
          }
        }
      } catch (goalError) {
        console.error('Error fetching weight loss goal:', goalError);
      }

      // Get daily entries for the period (simplified for testing)
      const dailyEntriesSnapshot = await admin.firestore()
          .collection('dailyEntries')
          .where('uid', '==', uid)
          .get();

      const reportData = [];
      const dailyEntries = {};

      // Process daily entries
      dailyEntriesSnapshot.forEach((doc) => {
        const data = doc.data();
        const dateKey = data.date.toDate().toISOString().split('T')[0];
        dailyEntries[dateKey] = data;
      });

      // Generate report data for each day in the period
      let totalCaloriesConsumed = 0;
      let totalCaloriesBurned = 0;
      let totalNetDeficit = 0;
      let totalGlasses = 0;
      let daysWithData = 0;
      
      // Calculate total days in period
      const totalDaysInPeriod = Math.max(1, Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24)) + 1);

      const currentDate = new Date(startDate);
      while (currentDate <= endDate) {
        const dateKey = currentDate.toISOString().split('T')[0];
        const dayEntry = dailyEntries[dateKey];

        let caloriesConsumed = 0;
        let caloriesBurned = 0;
        let weight = null;
        let glasses = null;
        let hasData = false;

        if (dayEntry) {
          // Calculate total calories consumed
          if (dayEntry.foodEntries && Array.isArray(dayEntry.foodEntries)) {
            caloriesConsumed = dayEntry.foodEntries.reduce((total, entry) => {
              const calories = entry.calories || 0;
              return total + (isNaN(calories) ? 0 : calories);
            }, 0);
            if (dayEntry.foodEntries.length > 0 && caloriesConsumed > 0) {
              hasData = true;
            }
          }

          // Calculate total calories burned
          if (dayEntry.exerciseEntries && Array.isArray(dayEntry.exerciseEntries)) {
            caloriesBurned = dayEntry.exerciseEntries.reduce((total, entry) => {
              const burned = entry.caloriesBurned || 0;
              return total + (isNaN(burned) ? 0 : burned);
            }, 0);
            if (dayEntry.exerciseEntries.length > 0 && caloriesBurned > 0) {
              hasData = true;
            }
          }

          weight = dayEntry.weight;
          if (weight !== null && !isNaN(weight) && weight > 0) {
            hasData = true;
          }
          
          glasses = dayEntry.glasses;
          if (glasses !== null && !isNaN(glasses) && glasses > 0) {
            hasData = true;
          }
        }

        // Only include this day in the report if it has actual data
        if (hasData) {
          // Validate numbers
          caloriesConsumed = isNaN(caloriesConsumed) ? 0 : caloriesConsumed;
          caloriesBurned = isNaN(caloriesBurned) ? 0 : caloriesBurned;

          // Calculate net calorie deficit with weight loss goal context
          let netCalorieDeficit;
          let targetDailyCalories;

          if (userGoal && userGoal.weightLossPerWeek) {
            // With weight loss goal: Target + exercise - consumed
            const dailyCalorieDeficit = (userGoal.weightLossPerWeek * 3500) / 7;
            targetDailyCalories = userBMR - dailyCalorieDeficit;
            netCalorieDeficit = (targetDailyCalories + caloriesBurned) - caloriesConsumed;
          } else {
            // Without goal: maintenance mode (BMR + exercise)
            targetDailyCalories = userBMR + caloriesBurned;
            netCalorieDeficit = targetDailyCalories - caloriesConsumed;
          }

          // Validate the calculated values
          if (!isNaN(netCalorieDeficit)) {
            const dailyData = {
              date: currentDate.toISOString().split('T')[0],
              bmr: Math.round(userBMR * 100) / 100,
              caloriesConsumed: Math.round(caloriesConsumed * 100) / 100,
              caloriesBurned: Math.round(caloriesBurned * 100) / 100,
              netCalorieDeficit: Math.round(netCalorieDeficit * 100) / 100,
              weight: weight && !isNaN(weight) && weight > 0 ? 
                Math.round(weight * 100) / 100 : null,
              glasses: glasses && !isNaN(glasses) && glasses > 0 ? 
                Math.round(glasses * 100) / 100 : null,
            };
            
            reportData.push(dailyData);
            totalCaloriesConsumed += caloriesConsumed;
            totalCaloriesBurned += caloriesBurned;
            totalNetDeficit += netCalorieDeficit;
            totalGlasses += glasses || 0;
            daysWithData++;
          }
        }

        // Move to next day
        currentDate.setDate(currentDate.getDate() + 1);
      }

      // Validate totals
      totalCaloriesConsumed = isNaN(totalCaloriesConsumed) ? 
        0 : Math.round(totalCaloriesConsumed * 100) / 100;
      totalCaloriesBurned = isNaN(totalCaloriesBurned) ? 
        0 : Math.round(totalCaloriesBurned * 100) / 100;
      totalNetDeficit = isNaN(totalNetDeficit) ? 
        0 : Math.round(totalNetDeficit * 100) / 100;
      totalGlasses = isNaN(totalGlasses) ? 
        0 : Math.round(totalGlasses * 100) / 100;

      const result = {
        period: String(period),
        startDate: String(startDate.toISOString().split('T')[0]),
        endDate: String(endDate.toISOString().split('T')[0]),
        data: reportData.map(item => ({
          date: String(item.date),
          bmr: Number(item.bmr),
          caloriesConsumed: Number(item.caloriesConsumed),
          caloriesBurned: Number(item.caloriesBurned),
          netCalorieDeficit: Number(item.netCalorieDeficit),
          weight: item.weight !== null ? Number(item.weight) : null,
          glasses: item.glasses !== null ? Number(item.glasses) : null,
        })),
        averageBMR: Number(userBMR),
        totalCaloriesConsumed: Number(totalCaloriesConsumed),
        totalCaloriesBurned: Number(totalCaloriesBurned),
        totalNetDeficit: Number(totalNetDeficit),
        totalGlasses: Number(totalGlasses),
        averageGlasses: daysWithData > 0 ? Number(totalGlasses / daysWithData) : 0,
        daysWithData: Number(daysWithData),
        totalDays: Number(totalDaysInPeriod),
      };

      // Final validation of result
      Object.keys(result).forEach(key => {
        if (typeof result[key] === 'number' && (isNaN(result[key]) || !isFinite(result[key]))) {
          console.error(`Invalid number detected in result.${key}:`, result[key]);
          result[key] = 0; // Set to 0 instead of throwing error
        }
      });

      return res.status(200).json(result);
    } catch (error) {
      console.error('Error in generateCalorieReportHttp:', error);
      return res.status(500).json({error: 'Failed to generate calorie report: ' + error.message});
    }
  });
});

/**
 * Trigger function to update user statistics
 * when daily entry is created/updated
 */
exports.updateUserStats = functions.firestore
    .document('dailyEntries/{entryId}')
    .onWrite(async (change, context) => {
      try {
        const entryData = change.after.exists ? change.after.data() : null;
        const uid = entryData && entryData.uid;

        if (!uid) return;

        // Calculate latest BMR and update user stats using internal function
        const bmrResult = await calculateBMRInternal(uid);

        // Validate BMR before saving
        if (isNaN(bmrResult.bmr) || bmrResult.bmr <= 0) {
          console.error('Invalid BMR calculated for user stats update:', uid);
          return;
        }

        // Update user document with latest BMR calculation timestamp
        await admin.firestore()
            .collection('users')
            .doc(uid)
            .update({
              lastBMRCalculation: new Date(),
              lastCalculatedBMR: bmrResult.bmr,
            });

        console.log(`Updated stats for user ${uid}, BMR: ${bmrResult.bmr}`);
      } catch (error) {
        console.error('Error updating user stats:', error);
      }
    });
