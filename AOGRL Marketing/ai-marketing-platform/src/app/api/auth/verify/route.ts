import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'
import { apiResponse, apiError } from '@/lib/api-utils'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { email, password } = body

    if (!email || !password) {
      return apiError('Email and password are required', 400)
    }

    // Find user
    const user = await prisma.user.findUnique({
      where: { email }
    })

    if (!user) {
      return apiResponse({
        success: false,
        message: 'User not found'
      })
    }

    if (!user.isActive) {
      return apiResponse({
        success: false,
        message: 'User is inactive'
      })
    }

    // Verify password
    let isValid = false
    if (user.password) {
      isValid = await bcrypt.compare(password, user.password)
    } else {
      // Demo credentials check
      isValid = (email === 'admin@example.com' || email === 'viewer@example.com') 
        && password === 'TempPass123!'
    }

    return apiResponse({
      success: true,
      message: 'Authentication verification completed',
      email,
      isValid,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role
      }
    })
  } catch (error: any) {
    console.error('Auth verification error:', error)
    return apiError(`Verification failed: ${error.message}`, 500)
  }
}