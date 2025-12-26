import { PrismaClient, UserRole, CampaignStatus, CreativeType, CreativeStatus } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Starting seed...')
  
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
  
  // Create admin user
  const adminUser = await prisma.user.upsert({
    where: { email: 'admin@example.com' },
    update: {},
    create: {
      email: 'admin@example.com',
      name: 'Admin User',
      role: UserRole.ADMIN,
      tenantId: tenant.id,
      isActive: true
    }
  })
  
  // Create viewer user
  const viewerUser = await prisma.user.upsert({
    where: { email: 'viewer@example.com' },
    update: {},
    create: {
      email: 'viewer@example.com',
      name: 'Viewer User',
      role: UserRole.VIEWER,
      tenantId: tenant.id,
      isActive: true
    }
  })
  
  console.log('✅ Created demo users')
  
  // Create API key
  const apiKey = await prisma.apiKey.upsert({
    where: { key: 'ak_demo_12345678901234567890' },
    update: {},
    create: {
      name: 'Demo API Key',
      key: 'ak_demo_12345678901234567890',
      tenantId: tenant.id,
      isActive: true
    }
  })
  
  console.log('✅ Created API key')
  
  // Create sample products
  const products = [
    {
      name: 'Premium Wireless Headphones',
      description: 'High-quality wireless headphones with noise cancellation',
      price: 299.99,
      imageUrl: 'https://picsum.photos/400/400?random=1',
      category: 'Electronics'
    },
    {
      name: 'Smart Fitness Tracker',
      description: 'Advanced fitness tracking with heart rate monitoring',
      price: 199.99,
      imageUrl: 'https://picsum.photos/400/400?random=2',
      category: 'Fitness'
    },
    {
      name: 'Eco-Friendly Water Bottle',
      description: 'Sustainable water bottle made from recycled materials',
      price: 29.99,
      imageUrl: 'https://picsum.photos/400/400?random=3',
      category: 'Lifestyle'
    },
    {
      name: 'Professional Laptop Stand',
      description: 'Ergonomic laptop stand for better posture and productivity',
      price: 89.99,
      imageUrl: 'https://picsum.photos/400/400?random=4',
      category: 'Office'
    },
    {
      name: 'Organic Coffee Beans',
      description: 'Premium organic coffee beans from sustainable farms',
      price: 24.99,
      imageUrl: 'https://picsum.photos/400/400?random=5',
      category: 'Food & Beverage'
    }
  ]
  
  const createdProducts = []
  for (const productData of products) {
    const existingProduct = await prisma.product.findFirst({
      where: {
        name: productData.name,
        tenantId: tenant.id
      }
    })
    
    if (existingProduct) {
      createdProducts.push(existingProduct)
    } else {
      const product = await prisma.product.create({
        data: {
          ...productData,
          tenantId: tenant.id
        }
      })
      createdProducts.push(product)
    }
  }
  
  console.log('✅ Created sample products')
  
  // Create sample creatives
  const creatives = [
    {
      type: CreativeType.IMAGE,
      prompt: 'Create an engaging ad for premium wireless headphones',
      status: CreativeStatus.COMPLETED,
      content: JSON.stringify({
        imageUrl: 'https://picsum.photos/800/600?random=10',
        title: 'Experience Pure Sound',
        description: 'Discover the ultimate audio experience with our premium wireless headphones.',
        cta: 'Shop Now'
      })
    },
    {
      type: CreativeType.COPY,
      prompt: 'Write compelling copy for fitness tracker campaign',
      status: CreativeStatus.COMPLETED,
      content: JSON.stringify({
        title: 'Track Your Progress',
        description: 'Monitor your health and fitness goals with precision tracking technology.',
        cta: 'Get Yours Today'
      })
    }
  ]
  
  const createdCreatives = []
  for (const creativeData of creatives) {
    const creative = await prisma.creative.create({
      data: {
        ...creativeData,
        tenantId: tenant.id
      }
    })
    createdCreatives.push(creative)
  }
  
  console.log('✅ Created sample creatives')
  
  // Create sample campaigns
  const campaigns = [
    {
      name: 'Q1 Electronics Campaign',
      description: 'Promoting premium electronics for the first quarter',
      budget: 5000.00,
      audience: JSON.stringify({
        demographics: {
          ageRange: '25-45',
          interests: ['technology', 'music', 'gadgets']
        },
        targeting: {
          locations: ['US', 'CA', 'UK'],
          devices: ['mobile', 'desktop']
        }
      }),
      status: CampaignStatus.RUNNING,
      startDate: new Date('2024-01-01'),
      endDate: new Date('2024-03-31'),
      createdById: adminUser.id,
      tenantId: tenant.id,
      creativeId: createdCreatives[0].id
    },
    {
      name: 'Fitness New Year Campaign',
      description: 'Health and fitness products for New Year resolutions',
      budget: 3000.00,
      audience: JSON.stringify({
        demographics: {
          ageRange: '20-50',
          interests: ['fitness', 'health', 'wellness']
        },
        targeting: {
          locations: ['US', 'CA'],
          devices: ['mobile']
        }
      }),
      status: CampaignStatus.SCHEDULED,
      startDate: new Date('2024-01-15'),
      endDate: new Date('2024-02-29'),
      createdById: adminUser.id,
      tenantId: tenant.id,
      creativeId: createdCreatives[1].id
    },
    {
      name: 'Eco-Friendly Lifestyle',
      description: 'Sustainable products for environmentally conscious consumers',
      budget: 2000.00,
      audience: JSON.stringify({
        demographics: {
          ageRange: '25-55',
          interests: ['environment', 'sustainability', 'lifestyle']
        },
        targeting: {
          locations: ['US', 'CA', 'UK', 'AU'],
          devices: ['mobile', 'desktop']
        }
      }),
      status: CampaignStatus.DRAFT,
      createdById: adminUser.id,
      tenantId: tenant.id
    }
  ]
  
  const createdCampaigns = []
  for (const campaignData of campaigns) {
    const campaign = await prisma.campaign.create({
      data: campaignData
    })
    createdCampaigns.push(campaign)
  }
  
  console.log('✅ Created sample campaigns')
  
  // Link products to campaigns
  await prisma.campaignProduct.createMany({
    data: [
      { campaignId: createdCampaigns[0].id, productId: createdProducts[0].id }, // Headphones in Electronics
      { campaignId: createdCampaigns[0].id, productId: createdProducts[3].id }, // Laptop stand in Electronics
      { campaignId: createdCampaigns[1].id, productId: createdProducts[1].id }, // Fitness tracker in Fitness
      { campaignId: createdCampaigns[2].id, productId: createdProducts[2].id }, // Water bottle in Eco-Friendly
      { campaignId: createdCampaigns[2].id, productId: createdProducts[4].id }  // Coffee in Eco-Friendly
    ]
  })
  
  console.log('✅ Linked products to campaigns')
  
  // Create sample analytics data
  const analyticsData = []
  const startDate = new Date('2024-01-01')
  
  for (let i = 0; i < 30; i++) {
    const date = new Date(startDate)
    date.setDate(date.getDate() + i)
    
    for (const campaign of createdCampaigns.slice(0, 2)) { // Only for running/scheduled campaigns
      const baseImpressions = Math.floor(Math.random() * 5000) + 1000
      const clicks = Math.floor(baseImpressions * (Math.random() * 0.04 + 0.02)) // 2-6% CTR
      const conversions = Math.floor(clicks * (Math.random() * 0.08 + 0.03)) // 3-11% conversion rate
      const spend = Math.random() * 200 + 50 // $50-250 daily spend
      const revenue = conversions * (Math.random() * 80 + 40) // $40-120 per conversion
      
      analyticsData.push({
        campaignId: campaign.id,
        date,
        impressions: baseImpressions,
        clicks,
        conversions,
        spend: Math.round(spend * 100) / 100,
        revenue: Math.round(revenue * 100) / 100
      })
    }
  }
  
  await prisma.analytics.createMany({
    data: analyticsData
  })
  
  console.log('✅ Created sample analytics data')
  
  // Create audit log entries
  const auditLogs = [
    {
      userId: adminUser.id,
      tenantId: tenant.id,
      action: 'LOGIN' as const,
      resource: 'auth',
      details: JSON.stringify({ method: 'credentials' }),
      ipAddress: '192.168.1.1',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    },
    {
      userId: adminUser.id,
      tenantId: tenant.id,
      action: 'CREATE' as const,
      resource: 'product',
      resourceId: createdProducts[0].id,
      details: JSON.stringify({ name: createdProducts[0].name, price: createdProducts[0].price }),
      ipAddress: '192.168.1.1',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    },
    {
      userId: adminUser.id,
      tenantId: tenant.id,
      action: 'CREATE' as const,
      resource: 'campaign',
      resourceId: createdCampaigns[0].id,
      details: JSON.stringify({ name: createdCampaigns[0].name, budget: createdCampaigns[0].budget }),
      ipAddress: '192.168.1.1',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    },
    {
      userId: viewerUser.id,
      tenantId: tenant.id,
      action: 'VIEW' as const,
      resource: 'analytics',
      resourceId: createdCampaigns[0].id,
      details: JSON.stringify({ dateRange: '30 days' }),
      ipAddress: '192.168.1.2',
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    }
  ]
  
  await prisma.auditLog.createMany({
    data: auditLogs
  })
  
  console.log('✅ Created sample audit logs')
  
  console.log('🎉 Seed completed successfully!')
  console.log('')
  console.log('Demo Credentials:')
  console.log('Admin: admin@example.com / TempPass123!')
  console.log('Viewer: viewer@example.com / TempPass123!')
  console.log('')
  console.log('API Key: ak_demo_12345678901234567890')
  console.log('')
  console.log('Tenant: Demo Company (demo.aimarketing.com)')
  console.log(`- ${createdProducts.length} Products`)
  console.log(`- ${createdCreatives.length} Creatives`)
  console.log(`- ${createdCampaigns.length} Campaigns`)
  console.log(`- ${analyticsData.length} Analytics Records`)
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })