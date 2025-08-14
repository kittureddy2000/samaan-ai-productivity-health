/* eslint-disable no-console */
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc } = require('firebase/firestore');

(async () => {
  const testEnv = await initializeTestEnvironment({
    projectId: 'demo-project',
    firestore: { rules: require('fs').readFileSync('firestore.rules', 'utf8') },
  });

  const authedCtx = testEnv.authenticatedContext('user_1');
  const db = authedCtx.firestore();

  // users read/write own
  await assertSucceeds(setDoc(doc(db, 'users/user_1'), {
    uid: 'user_1', email: 'u@example.com', dateOfBirth: new Date(), height: 170, weight: 70, gender: 'male', createdAt: new Date(), updatedAt: new Date(),
  }));
  await assertFails(setDoc(doc(db, 'users/user_2'), { uid: 'user_2' }));

  // dailyEntries id pattern
  await assertSucceeds(setDoc(doc(db, 'dailyEntries/user_1_2025-08-01'), {
    uid: 'user_1', date: new Date(), createdAt: new Date(), updatedAt: new Date(),
  }));
  await assertFails(setDoc(doc(db, 'dailyEntries/other_2025-08-01'), {
    uid: 'user_1', date: new Date(), createdAt: new Date(), updatedAt: new Date(),
  }));

  console.log('All assertions passed');
  await testEnv.cleanup();
  process.exit(0);
})().catch(async (e) => {
  console.error(e);
  process.exit(1);
});


