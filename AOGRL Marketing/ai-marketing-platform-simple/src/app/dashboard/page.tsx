'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { 
  CubeIcon, 
  PhotoIcon, 
  MegaphoneIcon, 
  ChartBarIcon,
  ArrowUpIcon,
  BanknotesIcon,
  GlobeAltIcon,
  UserGroupIcon
} from '@heroicons/react/24/outline'

export default function Dashboard() {
  const router = useRouter()
  const [currentTime, setCurrentTime] = useState<string | null>(null)
  
  useEffect(() => {
    // Set initial time
    setCurrentTime(new Date().toLocaleTimeString())
    
    const timer = setInterval(() => {
      setCurrentTime(new Date().toLocaleTimeString())
    }, 1000)
    
    return () => clearInterval(timer)
  }, [])

  // Mock dashboard data
  const dashboardData = {
    revenue: 847650.25,
    campaigns: 12,
    impressions: 2847320,
    clickRate: 4.7,
    conversions: 8947,
    totalSpend: 156890.50,
    products: 89,
    creatives: 234,
    activeUsers: 15847,
    globalReach: 47,
    aiInsights: 1247
  }

  const metrics = [
    {
      title: 'Total Revenue',
      value: `$${dashboardData.revenue.toLocaleString()}`,
      change: '+34.2%',
      changeType: 'positive',
      icon: BanknotesIcon,
      description: 'Revenue generated this quarter from all campaigns'
    },
    {
      title: 'Active Campaigns',
      value: dashboardData.campaigns.toString(),
      change: '+28.1%',
      changeType: 'positive',
      icon: MegaphoneIcon,
      description: 'High-performance campaigns delivering results'
    },
    {
      title: 'Total Impressions',
      value: `${(dashboardData.impressions / 1000000).toFixed(1)}M`,
      change: '+45.6%',
      changeType: 'positive',
      icon: ChartBarIcon,
      description: 'Brand visibility across all marketing channels'
    },
    {
      title: 'Global Reach',
      value: `${dashboardData.globalReach} Countries`,
      change: '+12.3%',
      changeType: 'positive',
      icon: GlobeAltIcon,
      description: 'International markets reached by your campaigns'
    }
  ]

  const quickActions = [
    {
      title: '🚀 AI Campaign Builder',
      description: 'Create high-converting campaigns with AI assistance',
      href: '/dashboard/campaigns',
      icon: MegaphoneIcon
    },
    {
      title: '🎨 Smart Creative Studio',
      description: 'Generate stunning visuals with AI-powered tools',
      href: '/dashboard/creative',
      icon: PhotoIcon
    },
    {
      title: '📊 Predictive Analytics',
      description: 'Get AI insights for future campaign performance',
      href: '/dashboard/analytics',
      icon: ChartBarIcon
    },
    {
      title: '📦 Product Management',
      description: 'Manage your product catalog and inventory',
      href: '/dashboard/products',
      icon: CubeIcon
    }
  ]

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 py-6 sm:px-6 lg:px-8 flex justify-between items-center">
          <h1 className="text-3xl font-bold text-gray-900">AI Marketing Platform</h1>
          <div className="flex items-center space-x-4">
            {currentTime && (
              <span className="text-sm text-gray-500">{currentTime}</span>
            )}
            <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center text-white font-bold">
              U
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-6 sm:px-6 lg:px-8">
        {/* Welcome Section */}
        <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg shadow-lg p-6 mb-8 text-white">
          <h2 className="text-2xl font-bold mb-2">Welcome to Your AI Marketing Hub ✨</h2>
          <p className="text-blue-100">Your AI-powered marketing empire is thriving</p>
        </div>

        {/* Metrics Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {metrics.map((metric) => (
            <div key={metric.title} className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center">
                  <metric.icon className="h-8 w-8 text-blue-500" />
                  <div className="ml-4">
                    <p className="text-sm font-medium text-gray-500">{metric.title}</p>
                    <p className="text-2xl font-bold text-gray-900">{metric.value}</p>
                  </div>
                </div>
                <div className={`flex items-center ${metric.changeType === 'positive' ? 'text-green-500' : 'text-red-500'}`}>
                  <ArrowUpIcon className="h-4 w-4" />
                  <span className="ml-1 text-sm font-medium">{metric.change}</span>
                </div>
              </div>
              <p className="mt-4 text-sm text-gray-500">{metric.description}</p>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Quick Actions */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg shadow">
              <div className="px-6 py-4 border-b border-gray-200">
                <h2 className="text-lg font-medium text-gray-900">Quick Actions</h2>
                <p className="text-sm text-gray-500">Get started with these AI-powered tools</p>
              </div>
              <div className="p-6">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {quickActions.map((action) => (
                    <button
                      key={action.title}
                      onClick={() => router.push(action.href)}
                      className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors text-left"
                    >
                      <div className="flex items-center">
                        <action.icon className="h-6 w-6 text-blue-500" />
                        <div className="ml-3">
                          <h3 className="text-sm font-medium text-gray-900">{action.title}</h3>
                          <p className="text-xs text-gray-500 mt-1">{action.description}</p>
                        </div>
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Recent Activity */}
          <div>
            <div className="bg-white rounded-lg shadow">
              <div className="px-6 py-4 border-b border-gray-200">
                <h2 className="text-lg font-medium text-gray-900">Recent Activity</h2>
                <p className="text-sm text-gray-500">Latest updates from your campaigns</p>
              </div>
              <div className="p-6">
                <div className="space-y-4">
                  <div className="flex items-start">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                        <ChartBarIcon className="h-4 w-4 text-green-500" />
                      </div>
                    </div>
                    <div className="ml-3">
                      <p className="text-sm font-medium text-gray-900">Campaign Performance Boost</p>
                      <p className="text-xs text-gray-500">Your "Summer Sale" campaign can increase ROI by 23%</p>
                      <p className="text-xs text-gray-400 mt-1">2 minutes ago</p>
                    </div>
                  </div>
                  <div className="flex items-start">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                        <PhotoIcon className="h-4 w-4 text-blue-500" />
                      </div>
                    </div>
                    <div className="ml-3">
                      <p className="text-sm font-medium text-gray-900">New Creative Generated</p>
                      <p className="text-xs text-gray-500">AI created 3 new ad variations for your product</p>
                      <p className="text-xs text-gray-400 mt-1">15 minutes ago</p>
                    </div>
                  </div>
                  <div className="flex items-start">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                        <UserGroupIcon className="h-4 w-4 text-purple-500" />
                      </div>
                    </div>
                    <div className="ml-3">
                      <p className="text-sm font-medium text-gray-900">Audience Insights</p>
                      <p className="text-xs text-gray-500">New demographic data available for analysis</p>
                      <p className="text-xs text-gray-400 mt-1">1 hour ago</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}