const { PrismaClient } = require('@prisma/client')
const bcrypt = require('bcryptjs')

const prisma = new PrismaClient()

async function updateDemoUsers() {
  try {
    console.log('Updating demo users with hashed passwords...')
    
    // Hash the demo passwords
    const adminPassword = await bcrypt.hash('TempPass123!', 12)
    const viewerPassword = await bcrypt.hash('TempPass123!', 12)
    
    // Update admin user
    const adminUser = await prisma.user.update({
      where: { email: 'admin@example.com' },
      data: { password: adminPassword }
    })
    
    console.log('✅ Updated admin user:', adminUser.email)
    
    // Update viewer user
    const viewerUser = await prisma.user.update({
      where: { email: 'viewer@example.com' },
      data: { password: viewerPassword }
    })
    
    console.log('✅ Updated viewer user:', viewerUser.email)
    
    console.log('🎉 Demo users updated successfully!')
    console.log('')
    console.log('Demo Credentials:')
    console.log('Admin: admin@example.com / TempPass123!')
    console.log('Viewer: viewer@example.com / TempPass123!')
    
  } catch (error) {
    console.error('Error updating demo users:', error)
  } finally {
    await prisma.$disconnect()
  }
}

updateDemoUsers()