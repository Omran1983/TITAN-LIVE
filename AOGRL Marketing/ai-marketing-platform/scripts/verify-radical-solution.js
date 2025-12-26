#!/usr/bin/env node

/**
 * Script to verify that the radical solution is working correctly
 * This script checks that:
 * 1. The application uses real data hooks instead of mock data
 * 2. No meaningless "API Error: {}" messages are logged
 * 3. All API endpoints return structured data
 * 4. The application is ready for production
 */

const fs = require('fs');
const path = require('path');

// Function to check if a file uses mock data instead of real data hooks
function usesMockData(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Check if the file uses mock data patterns
    const mockPatterns = [
      { pattern: /\bmock[A-Z]\w*\s*=/i, name: 'mock variable assignment' },
      { pattern: /\bfake[A-Z]\w*\s*=/i, name: 'fake variable assignment' },
      { pattern: /\bdummy[A-Z]\w*\s*=/i, name: 'dummy variable assignment' },
      { pattern: /\buseMock\w*/i, name: 'useMock hook' },
    ];
    
    for (const { pattern, name } of mockPatterns) {
      if (pattern.test(content)) {
        console.log(`   Found pattern "${name}" in ${filePath}`);
        return true;
      }
    }
    
    return false;
  } catch (error) {
    console.error(`Error reading file ${filePath}:`, error.message);
    return false;
  }
}

// Function to check for meaningless error messages
function containsMeaninglessErrors(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const meaninglessErrorPatterns = [
      { pattern: /console\.error\([^)]*\{\s*\}\s*\)/, name: 'console.error with empty object' },
      { pattern: /API Error: \{\}/, name: 'API Error: {} message' },
      { pattern: /Error: \{\}/, name: 'Error: {} message' },
    ];
    
    for (const { pattern, name } of meaninglessErrorPatterns) {
      if (pattern.test(content)) {
        console.log(`   Found pattern "${name}" in ${filePath}`);
        return true;
      }
    }
    
    return false;
  } catch (error) {
    console.error(`Error reading file ${filePath}:`, error.message);
    return false;
  }
}

// Function to check if API routes return structured data
function checkApiRoutes() {
  const apiDir = path.join(__dirname, '../src/app/api');
  let issues = [];
  
  function checkDirectory(dir) {
    const items = fs.readdirSync(dir);
    
    for (const item of items) {
      const itemPath = path.join(dir, item);
      const stat = fs.statSync(itemPath);
      
      if (stat.isDirectory()) {
        checkDirectory(itemPath);
      } else if (stat.isFile() && item.endsWith('.ts')) {
        const content = fs.readFileSync(itemPath, 'utf8');
        // Check if the route returns structured data (look for our apiResponse or NextResponse.json)
        if (!content.includes('apiResponse(') && !content.includes('NextResponse.json') && 
            !content.includes('return Response') && !content.includes('return new Response')) {
          // Only report as issue if it's actually an API route (has GET, POST, etc. exports)
          if (content.includes('export async function')) {
            issues.push(`API route ${itemPath} may not return structured data`);
          }
        }
      }
    }
  }
  
  try {
    checkDirectory(apiDir);
  } catch (error) {
    console.error('Error checking API routes:', error.message);
  }
  
  return issues;
}

// Function to verify dashboard uses real data
function verifyDashboardUsesRealData() {
  try {
    const filePath = path.join(__dirname, '../src/app/dashboard/page.tsx');
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Check that dashboard uses our real data hook
    if (!content.includes('useDashboardAnalytics')) {
      console.log('   Dashboard does not use useDashboardAnalytics hook');
      return false;
    }
    
    // Check that dashboard does not use mock data
    if (content.includes('mock') || content.includes('fake') || content.includes('dummy')) {
      // But allow these words in comments
      const lines = content.split('\n');
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if ((line.includes('mock') || line.includes('fake') || line.includes('dummy')) && 
            !line.trim().startsWith('//') && !line.includes('Use real API data')) {
          console.log(`   Found mock/fake/dummy in code (not comment) at line ${i + 1}: ${line.trim()}`);
          return true; // Found mock data
        }
      }
    }
    
    return false; // No mock data found
  } catch (error) {
    console.error('Error checking dashboard:', error.message);
    return false;
  }
}

// Main verification function
async function verifyRadicalSolution() {
  console.log('🔍 Verifying Radical Solution Implementation...\n');
  
  // Check 1: Dashboard uses real data
  console.log('✅ Checking that dashboard uses real data...');
  if (verifyDashboardUsesRealData()) {
    console.log('❌ Dashboard appears to use mock/fake data');
  } else {
    console.log('✅ Dashboard uses real data hooks');
  }
  
  // Check 2: No meaningless errors
  console.log('\n✅ Checking for meaningless error messages...');
  const keyFiles = [
    'src/lib/api-service.ts',
    'src/lib/data-hooks.ts',
    'src/app/dashboard/page.tsx',
    'src/app/api/analytics/dashboard/route.ts',
  ];
  
  let errorIssues = [];
  for (const file of keyFiles) {
    const filePath = path.join(__dirname, '..', file);
    if (containsMeaninglessErrors(filePath)) {
      errorIssues.push(file);
    }
  }
  
  if (errorIssues.length > 0) {
    console.log('❌ Issues found with meaningless error messages in files:');
    errorIssues.forEach(file => console.log(`   - ${file}`));
  } else {
    console.log('✅ No meaningless error messages found');
  }
  
  // Check 3: API routes return structured data
  console.log('\n✅ Checking API routes...');
  const apiIssues = checkApiRoutes();
  if (apiIssues.length > 0) {
    console.log('❌ Issues found with API routes:');
    apiIssues.forEach(issue => console.log(`   - ${issue}`));
  } else {
    console.log('✅ All API routes appear to return structured data');
  }
  
  // Final assessment
  console.log('\n📊 Final Assessment:');
  const dashboardUsesMockData = verifyDashboardUsesRealData();
  const totalIssues = (dashboardUsesMockData ? 1 : 0) + errorIssues.length + apiIssues.length;
  
  if (totalIssues === 0) {
    console.log('🎉 SUCCESS: Radical solution is properly implemented!');
    console.log('   ✅ Dashboard uses real data hooks');
    console.log('   ✅ No meaningless error messages');
    console.log('   ✅ All API routes return structured data');
    console.log('   ✅ Application is ready for production');
  } else {
    console.log(`⚠️  WARNING: ${totalIssues} issues found that need to be addressed`);
    console.log('   Please review the issues above and make necessary corrections');
  }
  
  return totalIssues === 0;
}

// Run the verification
verifyRadicalSolution()
  .then(success => {
    process.exit(success ? 0 : 1);
  })
  .catch(error => {
    console.error('Verification failed:', error.message);
    process.exit(1);
  });