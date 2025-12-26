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

    // Log the auth attempt for debugging
    console.log('🔍 Debug auth attempt:', { email, hasPassword: !!password })

    // Find the user in the database
    const user = await prisma.user.findUnique({
      where: {
        email: email
      },
      include: {
        tenant: true
      }
    })

    if (!user) {
      return apiResponse({
        success: false,
        message: 'User not found',
        email,
        userExists: false
      })
    }

    if (!user.isActive) {
      return apiResponse({
        success: false,
        message: 'User is inactive',
        email,
        userExists: true,
        isActive: false
      })
    }

    // Check password
    let validPassword = false
    if (user.password) {
      // User has a password in the database, validate it
      validPassword = await bcrypt.compare(password, user.password)
      console.log('🔒 Database password validation:', { 
        hasPassword: !!user.password,
        validPassword 
      })
    } else {
      // For demo purposes, check against hardcoded values
      const validCredentials = 
        (email === 'admin@example.com' && password === 'TempPass123!') ||
        (email === 'viewer@example.com' && password === 'TempPass123!')
      
      validPassword = validCredentials
      console.log('🔓 Demo credentials validation:', { validPassword })
    }

    return apiResponse({
      success: true,
      message: 'Auth check completed',
      email,
      userExists: true,
      isActive: user.isActive,
      hasPassword: !!user.password,
      validPassword,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    })
  } catch (error: any) {
    console.error('Debug auth error:', error)
    return apiError(`Auth check failed: ${error.message}`, 500)
  }
}