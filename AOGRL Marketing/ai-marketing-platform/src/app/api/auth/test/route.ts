import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'

export async function POST(request: Request) {
  try {
    const body = await request.json()
    const { email, password } = body

    if (!email || !password) {
      return NextResponse.json({ 
        error: 'Email and password are required' 
      }, { status: 400 })
    }

    // Find user
    const user = await prisma.user.findUnique({
      where: { email }
    })

    if (!user) {
      return NextResponse.json({ 
        error: 'User not found',
        emailProvided: email
      }, { status: 404 })
    }

    // Check password
    let passwordValid = false
    if (user.password) {
      passwordValid = await bcrypt.compare(password, user.password)
    } else {
      // Demo credentials check
      const isDemoUser = 
        (email === 'admin@example.com' && password === 'TempPass123!') ||
        (email === 'viewer@example.com' && password === 'TempPass123!')
      passwordValid = isDemoUser
    }

    return NextResponse.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        hasPassword: !!user.password,
        passwordValid
      },
      authResult: passwordValid ? 'Authenticated' : 'Invalid credentials'
    })

  } catch (error) {
    console.error('Auth test error:', error)
    return NextResponse.json({ 
      error: 'Internal server error',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}