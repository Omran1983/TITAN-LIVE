import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError } from '@/lib/api-utils'

export async function GET(request: NextRequest) {
  try {
    // Get all users
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        isActive: true,
        password: true,
        tenant: {
          select: {
            name: true
          }
        }
      }
    })
    
    return apiResponse({
      message: 'Users retrieved successfully',
      count: users.length,
      users: users.map(user => ({
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        isActive: user.isActive,
        hasPassword: !!user.password,
        tenant: user.tenant?.name
      }))
    })
  } catch (error: any) {
    console.error('Users API error:', error)
    return apiError(`Failed to retrieve users: ${error.message}`, 500)
  }
}