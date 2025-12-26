import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    console.log('Testing user database connection...')
    
    // Test database connection by fetching users
    const users = await prisma.user.findMany({
      take: 10,
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        isActive: true,
        createdAt: true,
      }
    })

    console.log('User database connection successful, found users:', users.length)
    
    return NextResponse.json({
      success: true,
      message: 'User database connection successful',
      usersCount: users.length,
      users: users
    })
  } catch (error) {
    console.error('User database connection error:', error)
    return NextResponse.json({ 
      success: false, 
      error: 'User database connection failed',
      details: error.message 
    }, { status: 500 })
  }
}