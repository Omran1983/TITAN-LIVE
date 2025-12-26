#!/usr/bin/env node

/**
 * Health check script for AI Marketing Platform
 * 
 * This script verifies that all required services are working:
 * - Database connection
 * - Redis connection
 * - Environment variables
 */

const { PrismaClient } = require('@prisma/client');
const fs = require('fs');

// Load environment variables
require('dotenv').config();

async function checkDatabase() {
  console.log('🔍 Checking database connection...');
  
  if (!process.env.DATABASE_URL) {
    console.log('❌ DATABASE_URL not set in environment variables');
    return false;
  }
  
  try {
    const prisma = new PrismaClient();
    await prisma.$connect();
    
    // Run a simple query
    await prisma.$queryRaw`SELECT 1`;
    
    // Get counts
    const [userCount, productCount, campaignCount] = await Promise.all([
      prisma.user.count(),
      prisma.product.count(),
      prisma.campaign.count()
    ]);
    
    console.log('✅ Database connection successful');
    console.log(`   Users: ${userCount}`);
    console.log(`   Products: ${productCount}`);
    console.log(`   Campaigns: ${campaignCount}`);
    
    await prisma.$disconnect();
    return true;
  } catch (error) {
    console.log('❌ Database connection failed');
    console.log(`   Error: ${error.message}`);
    return false;
  }
}

function checkEnvironment() {
  console.log('\n🔍 Checking environment variables...');
  
  const requiredVars = [
    'DATABASE_URL',
    'NEXTAUTH_SECRET',
    'NEXTAUTH_URL',
    'UPSTASH_REDIS_URL'
  ];
  
  const missingVars = [];
  
  requiredVars.forEach(varName => {
    if (!process.env[varName]) {
      missingVars.push(varName);
    }
  });
  
  if (missingVars.length > 0) {
    console.log('❌ Missing required environment variables:');
    missingVars.forEach(varName => {
      console.log(`   - ${varName}`);
    });
    return false;
  }
  
  console.log('✅ All required environment variables are set');
  return true;
}

function checkFiles() {
  console.log('\n🔍 Checking required files...');
  
  const requiredFiles = [
    '.env.local',
    'prisma/schema.prisma'
  ];
  
  const missingFiles = [];
  
  requiredFiles.forEach(fileName => {
    if (!fs.existsSync(fileName)) {
      missingFiles.push(fileName);
    }
  });
  
  if (missingFiles.length > 0) {
    console.log('❌ Missing required files:');
    missingFiles.forEach(fileName => {
      console.log(`   - ${fileName}`);
    });
    return false;
  }
  
  console.log('✅ All required files are present');
  return true;
}

async function main() {
  console.log('🏥 AI Marketing Platform - Health Check');
  console.log('=====================================\n');
  
  const checks = [
    checkFiles(),
    checkEnvironment(),
    await checkDatabase()
  ];
  
  const allPassed = checks.every(check => check === true);
  
  console.log('\n📋 Summary:');
  if (allPassed) {
    console.log('✅ All health checks passed!');
    console.log('\n🚀 You\'re ready to start the development server:');
    console.log('   $ npm run dev');
  } else {
    console.log('❌ Some health checks failed.');
    console.log('\n💡 Please fix the issues above and run this check again.');
    console.log('   $ node scripts/health-check.js');
  }
  
  process.exit(allPassed ? 0 : 1);
}

main();