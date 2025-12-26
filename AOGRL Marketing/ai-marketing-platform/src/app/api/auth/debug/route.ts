import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'
import { apiResponse, apiError } from '@/lib/api-utils'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { email, password } = body

    // Log for debugging
    console.log('🔍 Auth debug request:', { 
      email, 
      hasPassword: !!password,
      timestamp: new Date().toISOString()
    })

    if (!email || !password) {
      return apiError('Email and password are required', 400)
    }

    // Find the user in the database
    const user = await prisma.user.findUnique({
      where: {
        email: email
      }
    })

    console.log('👤 User lookup result:', { 
      found: !!user,
      email,
      hasPassword: user ? !!user.password : null
    })

    if (!user) {
      return apiResponse({
        success: false,
        message: 'User not found in database',
        email,
        userExists: false
      })
    }

    if (!user.isActive) {
      return apiResponse({
        success: false,
        message: 'User account is inactive',
        email,
        isActive: false
      })
    }

    // Check password
    let passwordValid = false
    if (user.password) {
      passwordValid = await bcrypt.compare(password, user.password)
      console.log('🔒 Password validation:', { 
        storedHash: user.password.substring(0, 10) + '...',
        passwordValid
      })
    } else {
      // Check against demo credentials
      const isDemoUser = 
        (email === 'admin@example.com' || email === 'viewer@example.com')
      const correctDemoPassword = password === 'TempPass123!'
      
      passwordValid = isDemoUser && correctDemoPassword
      console.log('🔓 Demo validation:', { 
        isDemoUser, 
        correctDemoPassword, 
        passwordValid 
      })
    }

    return apiResponse({
      success: true,
      message: 'Authentication check completed',
      email,
      userFound: true,
      isActive: user.isActive,
      passwordValid,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        hasPassword: !!user.password
      }
    })
  } catch (error: any) {
    console.error('Auth debug error:', error)
    return apiError(`Authentication debug failed: ${error.message}`, 500)
  }
}