import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError } from '@/lib/api-utils'

export async function GET(request: NextRequest) {
  try {
    // Simple database query to test connection
    const users = await prisma.user.findMany({
      take: 1,
      select: {
        id: true,
        email: true,
        name: true
      }
    })
    
    return apiResponse({
      message: 'Database connection successful',
      userSample: users,
      timestamp: new Date().toISOString()
    })
  } catch (error: any) {
    console.error('Database test error:', error)
    return apiError(`Database test failed: ${error.message}`, 500)
  }
}