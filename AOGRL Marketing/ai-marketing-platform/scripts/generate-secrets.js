#!/usr/bin/env node

/**
 * Generate secrets for AI Marketing Platform deployment
 * 
 * This script generates secure random secrets needed for deployment:
 * - NEXTAUTH_SECRET (32-character hex string)
 * - Database password (16-character alphanumeric)
 */

const crypto = require('crypto');

function generateSecret(length = 32) {
  return crypto.randomBytes(length).toString('hex');
}

function generatePassword(length = 16) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let password = '';
  for (let i = 0; i < length; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

console.log('🔐 AI Marketing Platform - Secret Generator');
console.log('==========================================\n');

console.log('NEXTAUTH_SECRET (32-character hex string):');
console.log(generateSecret(32));
console.log();

console.log('Database Password (16-character alphanumeric):');
console.log(generatePassword(16));
console.log();

console.log('📝 Instructions:');
console.log('1. Copy these values to your .env.local file');
console.log('2. Replace the placeholder values in the DATABASE_URL');
console.log('3. Keep these secrets secure and never commit them to version control');
console.log('4. For production, use a password manager to store these values');