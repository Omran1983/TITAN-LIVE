import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError } from '@/lib/api-utils'

export async function GET(request: NextRequest) {
  try {
    // Test database connection
    const userCount = await prisma.user.count()
    const tenantCount = await prisma.tenant.count()
    
    return apiResponse({
      status: 'ok',
      database: 'connected',
      userCount,
      tenantCount,
      timestamp: new Date().toISOString()
    })
  } catch (error: any) {
    console.error('Database health check error:', error)
    return apiError(`Database connection failed: ${error.message}`, 500)
  }
}