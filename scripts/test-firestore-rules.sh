#!/usr/bin/env bash
set -euo pipefail

if ! command -v firebase >/dev/null 2>&1; then
  echo "❌ Firebase CLI not found. Install with: npm i -g firebase-tools" >&2
  exit 1
fi

echo "🔧 Starting emulators (Firestore + Auth) in background..."
firebase emulators:start --only firestore,auth --project demo-project --import=.testdata --export-on-exit --silent &
EMU_PID=$!
trap 'kill $EMU_PID || true' EXIT

sleep 3

echo "✅ Running security rules unit tests (Node harness)..."
node scripts/tests/firestore-rules.spec.js

echo "✅ All Firestore rules tests passed"

