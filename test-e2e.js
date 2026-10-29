/**
 * OmniStore End-to-End Stack Verification Script
 * Validates Frontend, Backend API, MongoDB Persistence, and Nginx Reverse Proxy
 */

const FRONTEND_URL = process.env.FRONTEND_URL || 'http://127.0.0.1:3000';
const BACKEND_URL = process.env.BACKEND_URL || 'http://127.0.0.1:5000';

async function runVerification() {
  console.log('\n======================================================');
  console.log('   OmniStore MERN Stack Automated Verification Suite  ');
  console.log('======================================================\n');

  let passed = 0;
  let total = 4;

  // 1. Direct Backend & DB Health
  try {
    process.stdout.write('[1/4] Checking Backend API & MongoDB Health... ');
    const res = await fetch(`${BACKEND_URL}/health`);
    const data = await res.json();
    if (res.status === 200 && data.status === 'UP' && data.mongodb === 'connected') {
      console.log('PASSED (Status: UP, Mongo: Connected)');
      passed++;
    } else {
      console.log(`FAILED (${JSON.stringify(data)})`);
    }
  } catch (err) {
    console.log(`FAILED (${err.message})`);
  }

  // 2. Frontend SPA Web Server
  try {
    process.stdout.write('[2/4] Checking Frontend SPA & Nginx Server... ');
    const res = await fetch(`${FRONTEND_URL}/`);
    const html = await res.text();
    if (res.status === 200 && html.includes('<div id="root">') && html.includes('OmniStore')) {
      console.log('PASSED (Nginx serving React SPA on port 3000)');
      passed++;
    } else {
      console.log(`FAILED (Unexpected response on port 3000)`);
    }
  } catch (err) {
    console.log(`FAILED (${err.message})`);
  }

  // 3. Nginx Reverse Proxy to Product Catalog
  try {
    process.stdout.write('[3/4] Checking Reverse Proxy to Catalog API... ');
    const res = await fetch(`${FRONTEND_URL}/api/products`);
    const products = await res.json();
    if (res.status === 200 && Array.isArray(products) && products.length >= 6) {
      console.log(`PASSED (Retrieved ${products.length} products via Nginx proxy)`);
      passed++;
    } else {
      console.log(`FAILED (Expected at least 6 products)`);
    }
  } catch (err) {
    console.log(`FAILED (${err.message})`);
  }

  // 4. End-to-End Order Creation & MongoDB Write
  try {
    process.stdout.write('[4/4] Testing Order Transaction & DB Persistence... ');
    const orderPayload = {
      customer: {
        name: 'Submission Reviewer',
        email: 'reviewer@eval.edu',
        address: 'Faculty of Computer Science'
      },
      items: [
        { name: 'Aura Sound Pro ANC Headphones', price: 249.99, quantity: 1 }
      ],
      totalAmount: 249.99
    };

    const res = await fetch(`${FRONTEND_URL}/api/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(orderPayload)
    });

    const orderResult = await res.json();
    if (res.status === 201 && orderResult.orderId && orderResult.status === 'Confirmed') {
      console.log(`PASSED (Order ID: ${orderResult.orderId}, Status: Confirmed)`);
      passed++;
    } else {
      console.log(`FAILED (${JSON.stringify(orderResult)})`);
    }
  } catch (err) {
    console.log(`FAILED (${err.message})`);
  }

  console.log('\n======================================================');
  if (passed === total) {
    console.log(`   RESULT: ALL ${passed}/${total} CHECKS PASSED (100% HEALTHY)`);
    console.log('   The MERN Stack is fully verified and ready to submit!');
  } else {
    console.log(`   RESULT: ${passed}/${total} checks passed. Please review errors above.`);
    process.exit(1);
  }
  console.log('======================================================\n');
}

runVerification();
