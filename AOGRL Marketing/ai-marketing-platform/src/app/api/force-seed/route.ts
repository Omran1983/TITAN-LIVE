import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'

export async function POST() {
  try {
    // Check if users already exist
    const existingUsers = await prisma.user.findMany()
    
    if (existingUsers.length > 0) {
      return NextResponse.json({
        message: 'Users already exist in database',
        userCount: existingUsers.length
      })
    }

    // Create demo users with hashed passwords
    const adminPassword = await bcrypt.hash('TempPass123!', 12)
    const viewerPassword = await bcrypt.hash('TempPass123!', 12)

    const tenant = await prisma.tenant.create({
      data: {
        name: 'Default Tenant',
        slug: 'default',
        timezone: 'UTC',
        locale: 'en-US',
        isActive: true,
      }
    })

    const users = await prisma.user.createMany({
      data: [
        {
          email: 'admin@example.com',
          name: 'Admin User',
          password: adminPassword,
          role: 'ADMIN',
          tenantId: tenant.id,
          isActive: true,
        },
        {
          email: 'viewer@example.com',
          name: 'Viewer User',
          password: viewerPassword,
          role: 'VIEWER',
          tenantId: tenant.id,
          isActive: true,
        }
      ]
    })

    return NextResponse.json({
      message: 'Demo users created successfully',
      usersCreated: users.count,
      tenant: {
        id: tenant.id,
        name: tenant.name
      }
    })
  } catch (error) {
    console.error('Force seed error:', error)
    return NextResponse.json({
      error: 'Failed to seed database',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}