import { NextRequest } from 'next/server'
import { apiResponse, apiError } from '@/lib/api-utils'

export async function GET(request: NextRequest) {
  try {
    // Check environment variables
    const nextAuthUrl = process.env.NEXTAUTH_URL
    const databaseUrl = process.env.DATABASE_URL ? 'Set (hidden for security)' : 'Not set'
    const nextAuthSecret = process.env.NEXTAUTH_SECRET ? 'Set (hidden for security)' : 'Not set'
    
    // Check if we're in production
    const isProduction = process.env.NODE_ENV === 'production'
    const vercelUrl = process.env.VERCEL_URL
    
    return apiResponse({
      environment: process.env.NODE_ENV,
      isProduction,
      vercelUrl,
      nextAuthUrl,
      databaseUrl,
      nextAuthSecret,
      timestamp: new Date().toISOString()
    })
  } catch (error: any) {
    console.error('Debug config error:', error)
    return apiError(`Config check failed: ${error.message}`, 500)
  }
}