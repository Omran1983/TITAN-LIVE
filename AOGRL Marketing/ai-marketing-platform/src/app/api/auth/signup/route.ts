import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { apiResponse, apiError } from '@/lib/api-utils'
import bcrypt from 'bcryptjs'
import { UserRole } from '@prisma/client'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { email, password, name } = body

    // Validate input
    if (!email || !password || !name) {
      return apiError('Email, password, and name are required', 400)
    }

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email }
    })

    if (existingUser) {
      return apiError('User with this email already exists', 409)
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12)

    // Get demo tenant (in a real app, you'd have a more sophisticated tenant creation process)
    const tenant = await prisma.tenant.findFirst({
      where: { domain: 'demo.aimarketing.com' }
    })

    if (!tenant) {
      return apiError('Demo tenant not found', 500)
    }

    // Create user with Viewer role by default
    const user = await prisma.user.create({
      data: {
        email,
        name,
        role: UserRole.VIEWER,
        tenantId: tenant.id,
        isActive: true
      }
    })

    return apiResponse({
      message: 'User created successfully',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role
      }
    }, 201)
  } catch (error: any) {
    console.error('Signup error:', error)
    return apiError('Failed to create user', 500)
  }
}