#!/usr/bin/env node

/**
 * Setup script for AI Marketing Platform
 * 
 * This script helps with the initial setup of the AI Marketing Platform:
 * - Checks for required environment variables
 * - Validates database connection
 * - Runs Prisma setup
 * - Seeds the database
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function runCommand(command, description) {
  console.log(`\n🔧 ${description}`);
  console.log(`   $ ${command}\n`);
  
  try {
    const output = execSync(command, { encoding: 'utf-8', stdio: 'inherit' });
    return output;
  } catch (error) {
    console.error(`❌ Command failed: ${command}`);
    console.error(error.message);
    process.exit(1);
  }
}

function checkFileExists(filePath) {
  return fs.existsSync(filePath);
}

function checkEnvironment() {
  console.log('🔍 Checking environment...\n');
  
  // Check if .env.local exists
  if (!checkFileExists('.env.local')) {
    console.log('⚠️  .env.local file not found');
    console.log('   Please create .env.local by copying .env and updating with your values');
    console.log('   $ cp .env .env.local');
    console.log('   Then edit .env.local with your actual configuration\n');
    return false;
  }
  
  // Check required environment variables
  const requiredVars = ['DATABASE_URL', 'NEXTAUTH_SECRET', 'UPSTASH_REDIS_URL'];
  const missingVars = [];
  
  // Load environment variables from .env.local
  const envContent = fs.readFileSync('.env.local', 'utf-8');
  const envVars = {};
  
  envContent.split('\n').forEach(line => {
    if (line && !line.startsWith('#')) {
      const [key, value] = line.split('=');
      if (key && value) {
        envVars[key.trim()] = value.trim().replace(/"/g, '');
      }
    }
  });
  
  requiredVars.forEach(varName => {
    if (!envVars[varName] || envVars[varName] === `your-${varName.toLowerCase().replace(/_/g, '-')}`) {
      missingVars.push(varName);
    }
  });
  
  if (missingVars.length > 0) {
    console.log(`⚠️  Missing required environment variables:`);
    missingVars.forEach(varName => {
      console.log(`   - ${varName}`);
    });
    console.log('\n   Please update your .env.local file with actual values\n');
    return false;
  }
  
  console.log('✅ Environment check passed\n');
  return true;
}

function main() {
  console.log('🚀 AI Marketing Platform - Setup Script');
  console.log('=======================================\n');
  
  // Check environment
  if (!checkEnvironment()) {
    console.log('💡 Tip: Run "npm run generate:secrets" to generate secure secrets');
    process.exit(1);
  }
  
  // Install dependencies
  runCommand('npm install', 'Installing dependencies');
  
  // Generate Prisma client
  runCommand('npm run generate', 'Generating Prisma client');
  
  // Push database schema
  runCommand('npm run db:push', 'Pushing database schema');
  
  // Seed database
  runCommand('npm run db:seed', 'Seeding database with demo data');
  
  console.log('\n🎉 Setup completed successfully!');
  console.log('\n📝 Next steps:');
  console.log('   1. Start the development server: npm run dev');
  console.log('   2. Visit http://localhost:3000 in your browser');
  console.log('   3. Sign in with demo credentials:');
  console.log('      - Admin: admin@example.com / TempPass123!');
  console.log('      - Viewer: viewer@example.com / TempPass123!');
  console.log('\nFor production deployment, see DEPLOYMENT_GUIDE.md');
}

main();