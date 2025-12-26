import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'

export async function GET() {
  try {
    console.log('Checking users in database...')
    
    // Check if demo users exist
    const adminUser = await prisma.user.findUnique({
      where: {
        email: 'admin@example.com'
      }
    })

    const viewerUser = await prisma.user.findUnique({
      where: {
        email: 'viewer@example.com'
      }
    })

    console.log('Admin user:', adminUser)
    console.log('Viewer user:', viewerUser)

    // If users don't exist, create them
    if (!adminUser) {
      console.log('Creating admin user...')
      const hashedPassword = await bcrypt.hash('TempPass123!', 12)
      await prisma.user.create({
        data: {
          email: 'admin@example.com',
          name: 'Admin User',
          password: hashedPassword,
          role: 'ADMIN',
          isActive: true,
          tenant: {
            connect: {
              id: 'default'
            }
          }
        }
      })
      console.log('Admin user created')
    }

    if (!viewerUser) {
      console.log('Creating viewer user...')
      const hashedPassword = await bcrypt.hash('TempPass123!', 12)
      await prisma.user.create({
        data: {
          email: 'viewer@example.com',
          name: 'Viewer User',
          password: hashedPassword,
          role: 'VIEWER',
          isActive: true,
          tenant: {
            connect: {
              id: 'default'
            }
          }
        }
      })
      console.log('Viewer user created')
    }

    return NextResponse.json({
      success: true,
      message: 'Users checked and created if needed'
    })
  } catch (error) {
    console.error('Check users error:', error)
    return NextResponse.json({ error: 'Failed to check users', details: error.message }, { status: 500 })
  }
}