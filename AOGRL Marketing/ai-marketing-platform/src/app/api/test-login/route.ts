import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'

export async function POST(request: Request) {
  try {
    const { email, password } = await request.json()
    
    console.log('Testing login with credentials:', { email })
    
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
      console.log('User not found:', email)
      return NextResponse.json({ error: 'User not found' }, { status: 401 })
    }

    if (!user.isActive) {
      console.log('User is inactive:', email)
      return NextResponse.json({ error: 'User is inactive' }, { status: 401 })
    }

    // Check if user has a password (for database users) or use demo credentials
    let validPassword = false
    if (user.password) {
      // User has a password in the database, validate it
      validPassword = await bcrypt.compare(password, user.password)
      console.log('Password validation result:', { 
        email: email,
        hasPassword: true,
        validPassword
      })
    } else {
      // For demo purposes, check against hardcoded values
      const validCredentials = 
        (email === 'admin@example.com' && password === 'TempPass123!') ||
        (email === 'viewer@example.com' && password === 'TempPass123!')
      
      validPassword = validCredentials
      console.log('Demo credentials validation:', { 
        email: email,
        isDemoUser: validCredentials,
        validPassword
      })
    }

    if (!validPassword) {
      console.log('Invalid credentials for:', email)
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 })
    }

    console.log('Authentication successful for:', {
      email: user.email,
      id: user.id,
      role: user.role
    })
    
    return NextResponse.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        tenantId: user.tenantId,
      }
    })
  } catch (error) {
    console.error('Login test error:', error)
    return NextResponse.json({ error: 'Login test failed', details: error.message }, { status: 500 })
  }
}