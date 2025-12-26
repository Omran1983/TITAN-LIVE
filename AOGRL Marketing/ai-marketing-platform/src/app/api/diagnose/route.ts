import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    // Check environment variables
    const envCheck = {
      hasDatabaseUrl: !!process.env.DATABASE_URL,
      hasNextAuthSecret: !!process.env.NEXTAUTH_SECRET,
      hasNextAuthUrl: !!process.env.NEXTAUTH_URL,
      vercelUrl: process.env.VERCEL_URL || null,
      nodeEnv: process.env.NODE_ENV || null,
      nextAuthUrl: process.env.NEXTAUTH_URL || null,
    }

    // Check database connectivity
    let dbStatus = 'unknown'
    let userCount = 0
    let users: any[] = []
    
    try {
      // Test database connection
      await prisma.$queryRaw`SELECT 1`
      dbStatus = 'connected'
      
      // Check if users exist
      users = await prisma.user.findMany({
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          isActive: true,
          createdAt: true,
        }
      })
      userCount = users.length
    } catch (dbError) {
      dbStatus = `error: ${dbError instanceof Error ? dbError.message : 'Unknown database error'}`
    }

    // Check if demo users exist
    let demoUsersExist = false
    try {
      const demoUsers = await prisma.user.findMany({
        where: {
          email: {
            in: ['admin@example.com', 'viewer@example.com']
          }
        }
      })
      demoUsersExist = demoUsers.length > 0
    } catch (error) {
      // Ignore error for demo users check
    }

    return NextResponse.json({
      status: 'success',
      timestamp: new Date().toISOString(),
      environment: envCheck,
      database: {
        status: dbStatus,
        userCount,
        demoUsersExist,
        users: users.map(user => ({
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          isActive: user.isActive,
          createdAt: user.createdAt,
        }))
      }
    })
  } catch (error) {
    return NextResponse.json({
      status: 'error',
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    }, { status: 500 })
  }
}