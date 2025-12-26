import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError } from '@/lib/api-utils'

export async function GET(request: NextRequest) {
  try {
    // Check if demo tenant exists
    const tenant = await prisma.tenant.findUnique({
      where: { domain: 'demo.aimarketing.com' }
    })
    
    // Check all users
    const users = await prisma.user.findMany({
      include: {
        tenant: true
      }
    })
    
    // Check specific demo users
    const adminUser = await prisma.user.findUnique({
      where: { email: 'admin@example.com' }
    })
    
    const viewerUser = await prisma.user.findUnique({
      where: { email: 'viewer@example.com' }
    })
    
    return apiResponse({
      tenant: tenant ? 'Exists' : 'Missing',
      totalUsers: users.length,
      adminUser: adminUser ? 'Exists' : 'Missing',
      viewerUser: viewerUser ? 'Exists' : 'Missing',
      users: users.map(user => ({
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        hasPassword: !!user.password,
        tenant: user.tenant?.name
      }))
    })
  } catch (error: any) {
    console.error('Debug users error:', error)
    return apiError(`Database error: ${error.message}`, 500)
  }
}