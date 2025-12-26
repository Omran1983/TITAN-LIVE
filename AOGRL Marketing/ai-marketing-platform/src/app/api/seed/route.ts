import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'
import { UserRole } from '@prisma/client'
import { apiResponse, apiError } from '@/lib/api-utils'

export async function POST(request: NextRequest) {
  try {
    console.log('🌱 Starting database seed...')
    
    // Create demo tenant
    const tenant = await prisma.tenant.upsert({
      where: { domain: 'demo.aimarketing.com' },
      update: {},
      create: {
        name: 'Demo Company',
        domain: 'demo.aimarketing.com'
      }
    })
    
    console.log('✅ Created demo tenant:', tenant.name)
    
    // Hash the default password
    const hashedPassword = await bcrypt.hash('TempPass123!', 12)
    
    // Create admin user
    const adminUser = await prisma.user.upsert({
      where: { email: 'admin@example.com' },
      update: {
        password: hashedPassword // Update password in case it was missing
      },
      create: {
        email: 'admin@example.com',
        name: 'Admin User',
        password: hashedPassword,
        role: UserRole.ADMIN,
        tenantId: tenant.id,
        isActive: true
      }
    })
    
    // Create viewer user
    const viewerUser = await prisma.user.upsert({
      where: { email: 'viewer@example.com' },
      update: {
        password: hashedPassword // Update password in case it was missing
      },
      create: {
        email: 'viewer@example.com',
        name: 'Viewer User',
        password: hashedPassword,
        role: UserRole.VIEWER,
        tenantId: tenant.id,
        isActive: true
      }
    })
    
    console.log('✅ Created/updated demo users')
    
    return apiResponse({
      message: 'Database seed completed successfully!',
      tenant: tenant.name,
      users: [
        { 
          email: adminUser.email, 
          role: adminUser.role,
          hasPassword: !!adminUser.password
        },
        { 
          email: viewerUser.email, 
          role: viewerUser.role,
          hasPassword: !!viewerUser.password
        }
      ]
    }, 201)
  } catch (error: any) {
    console.error('Database seed error:', error)
    return apiError(`Seeding failed: ${error.message}`, 500)
  }
}