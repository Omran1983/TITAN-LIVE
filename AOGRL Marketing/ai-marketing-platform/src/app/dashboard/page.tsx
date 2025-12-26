'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  Legend, 
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts'
import { 
  Users, 
  TrendingUp, 
  DollarSign, 
  Eye, 
  MessageSquare, 
  ThumbsUp,
  Calendar,
  Target,
  BarChart3,
  PieChart as PieChartIcon
} from 'lucide-react'
import { useToast } from '@/hooks/use-toast'
import { useDashboardData } from '@/hooks/use-dashboard-data'

export default function DashboardPage() {
  const router = useRouter()
  const { toast } = useToast()
  const { data: dashboardData, isLoading, error } = useDashboardData()
  
  const [showCreateCampaign, setShowCreateCampaign] = useState(false)
  const [currentTime, setCurrentTime] = useState(new Date())

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000)
    return () => clearInterval(timer)
  }, [])

  const premiumMetrics = [
    {
      title: 'Total Revenue',
      value: `$${dashboardData?.revenue?.toLocaleString() || '0'}`,
      change: '+34.2%',
      changeType: 'positive' as const,
      icon: DollarSign,
      gradient: 'bg-gradient-to-br from-green-500 to-emerald-600',
      description: 'Revenue generated this quarter from all campaigns',
      trend: [20, 35, 25, 40, 30, 45, 35, 50]
    },
    {
      title: 'AI Insights Generated',
      value: dashboardData?.aiInsights?.toLocaleString() || '0',
      change: '+67.8%',
      changeType: 'positive' as const,
      icon: MessageSquare,
      gradient: 'bg-gradient-to-br from-purple-500 to-pink-600',
      description: 'Actionable insights powered by advanced AI algorithms',
      trend: [15, 25, 35, 20, 40, 30, 45, 55]
    },
    {
      title: 'Global Reach',
      value: `${dashboardData?.globalReach || '0'} Countries`,
      change: '+12.3%',
      changeType: 'positive' as const,
      icon: Target,
      gradient: 'bg-gradient-to-br from-blue-500 to-cyan-600',
      description: 'International markets reached by your campaigns',
      trend: [25, 30, 20, 35, 25, 40, 30, 45]
    },
    {
      title: 'Active Campaigns',
      value: dashboardData?.campaigns?.toString() || '0',
      change: '+28.1%',
      changeType: 'positive' as const,
      icon: BarChart3,
      gradient: 'bg-gradient-to-br from-orange-500 to-red-600',
      description: 'High-performance campaigns delivering results',
      trend: [30, 20, 35, 25, 40, 30, 35, 45]
    },
    {
      title: 'Total Impressions',
      value: `${(dashboardData?.impressions! / 1000000).toFixed(1)}M`,
      change: '+45.6%',
      changeType: 'positive' as const,
      icon: Eye,
      gradient: 'bg-gradient-to-br from-indigo-500 to-purple-600',
      description: 'Brand visibility across all marketing channels',
      trend: [20, 40, 30, 45, 35, 50, 40, 55]
    },
    {
      title: 'Conversion Rate',
      value: `${dashboardData?.clickRate || '0'}%`,
      change: '+8.9%',
      changeType: 'positive' as const,
      icon: ThumbsUp,
      gradient: 'bg-gradient-to-br from-yellow-500 to-orange-600',
      description: 'Optimized conversion rates through AI targeting',
      trend: [25, 30, 35, 25, 40, 35, 45, 40]
    }
  ]

  const quickActions = [
    {
      title: '🚀 AI Campaign Builder',
      description: 'Create high-converting campaigns with AI assistance',
      href: '/dashboard/campaigns',
      icon: BarChart3,
      gradient: 'from-blue-500 to-purple-600',
      premium: true,
      onClick: () => setShowCreateCampaign(true)
    },
    {
      title: '🎨 Smart Creative Studio',
      description: 'Generate stunning visuals with AI-powered tools',
      href: '/dashboard/creative',
      icon: MessageSquare,
      gradient: 'from-purple-500 to-pink-600',
      premium: true
    },
    {
      title: '📊 Predictive Analytics',
      description: 'Get AI insights for future campaign performance',
      href: '/dashboard/analytics',
      icon: TrendingUp,
      gradient: 'from-green-500 to-emerald-600',
      premium: true
    },
    {
      title: '🧠 AI Product Optimizer',
      description: 'Optimize product listings with machine learning',
      href: '/dashboard/products',
      icon: Users,
      gradient: 'from-orange-500 to-red-600',
      premium: true
    }
  ]

  const aiInsights = [
    {
      type: 'optimization',
      title: 'Campaign Performance Boost',
      message: 'Your "Summer Sale" campaign can increase ROI by 23% with audience targeting adjustments.',
      confidence: 94,
      action: 'Apply AI Recommendations'
    },
    {
      type: 'prediction',
      title: 'Trending Product Alert',
      message: 'Wireless earbuds are trending up 67% - perfect time to launch a promotional campaign.',
      confidence: 87,
      action: 'Create Campaign'
    },
    {
      type: 'alert',
      title: 'Budget Optimization',
      message: 'Reallocate $2,400 from Campaign A to Campaign B for 18% better performance.',
      confidence: 91,
      action: 'Optimize Budget'
    }
  ]

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-indigo-600"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-red-600 mb-4">Error Loading Dashboard</h2>
          <p className="text-gray-600 mb-4">{error.message}</p>
          <Button onClick={() => router.refresh()}>Retry</Button>
        </div>
      </div>
    )
  }

  return (
    <div className="animate-slide-up space-y-8">
      {/* Premium Hero Section */}
      <div className="surface-premium p-8 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-500/20 via-purple-500/20 to-pink-500/20 animate-gradient-flow"></div>
        <div className="relative z-10">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center space-x-4 mb-4">
                <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
                  <MessageSquare className="w-8 h-8 text-white" />
                </div>
                <div>
                  <h1 className="text-display">
                    Welcome back, User ✨
                  </h1>
                  <p className="text-body text-gray-600 mt-2">
                    Your AI-powered marketing empire is thriving • {currentTime.toLocaleTimeString()}
                  </p>
                </div>
              </div>
              
              <div className="flex items-center space-x-6 text-sm">
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <TrendingUp className="w-4 h-4 text-orange-500" />
                  <span className="font-semibold">Performance: Excellent</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <DollarSign className="w-4 h-4 text-yellow-500" />
                  <span className="font-semibold">ROI: +{((dashboardData?.revenue! / dashboardData?.totalSpend! - 1) * 100).toFixed(0)}%</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <Users className="w-4 h-4 text-blue-500" />
                  <span className="font-semibold">{dashboardData?.activeUsers?.toLocaleString()} Active Users</span>
                </div>
              </div>
            </div>
            
            <div className="text-right">
              <div className="text-3xl font-bold text-gradient-premium mb-2">
                ${((dashboardData?.revenue! / dashboardData?.totalSpend! - 1) * 100).toFixed(1)}% ROI
              </div>
              <p className="text-caption">This Quarter's Return</p>
            </div>
          </div>
        </div>
      </div>

      {/* Revolutionary Metrics Grid */}
      <div className="grid-premium">
        {premiumMetrics.map((metric, index) => (
          <div key={metric.title} style={{ animationDelay: `${index * 150}ms` }} className="animate-scale-in">
            <Card className="metric-card hover-glow group">
              <div className="flex items-center justify-between mb-6">
                <div className={`p-4 rounded-2xl ${metric.gradient} shadow-lg group-hover:scale-110 transition-transform duration-300`}>
                  <metric.icon className="h-8 w-8 text-white" />
                </div>
                <div className={`flex items-center space-x-2 metric-change ${metric.changeType} animate-pulse-premium`}>
                  {metric.changeType === 'positive' ? (
                    <TrendingUp className="h-4 w-4" />
                  ) : (
                    <TrendingUp className="h-4 w-4 transform rotate-180" />
                  )}
                  <span className="font-bold">{metric.change}</span>
                </div>
              </div>
              <div>
                <div className="metric-value mb-2">{metric.value}</div>
                <div className="metric-label mb-3">{metric.title}</div>
                <p className="text-caption">{metric.description}</p>
                {metric.trend && (
                  <div className="mt-4 flex items-center space-x-1">
                    {metric.trend.map((point, i) => (
                      <div
                        key={i}
                        className="w-2 h-8 bg-gradient-to-t from-blue-200 to-blue-500 rounded-full opacity-60"
                        style={{ height: `${point}px` }}
                      />
                    ))}
                  </div>
                )}
              </div>
            </Card>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* AI-Powered Quick Actions */}
        <div className="lg:col-span-2">
          <div className="surface-elevated-high">
            <div className="p-6 border-b border-gray-100">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-pink-600 rounded-xl flex items-center justify-center">
                  <BarChart3 className="w-6 h-6 text-white" />
                </div>
                <div>
                  <h2 className="text-headline">AI-Powered Actions</h2>
                  <p className="text-body">Supercharge your marketing with intelligent automation</p>
                </div>
              </div>
            </div>
            <div className="p-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                {quickActions.map((action, index) => (
                  <button
                    key={action.title}
                    onClick={action.onClick || (() => window.location.href = action.href)}
                    className="group relative p-6 surface-elevated rounded-2xl hover-lift overflow-hidden w-full text-left"
                    style={{ animationDelay: `${index * 100}ms` }}
                  >
                    <div className={`absolute inset-0 bg-gradient-to-br ${action.gradient} opacity-0 group-hover:opacity-10 transition-opacity duration-300`}></div>
                    <div className="relative z-10">
                      <div className={`w-12 h-12 bg-gradient-to-br ${action.gradient} rounded-xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform duration-300 shadow-lg`}>
                        <action.icon className="h-6 w-6 text-white" />
                      </div>
                      <h3 className="text-title font-bold mb-2 group-hover:text-transparent group-hover:bg-clip-text group-hover:bg-gradient-to-r group-hover:from-blue-600 group-hover:to-purple-600 transition-all duration-300">
                        {action.title}
                      </h3>
                      <p className="text-body text-sm">{action.description}</p>
                      {action.premium && (
                        <div className="mt-3">
                          <span className="status-badge bg-gradient-to-r from-yellow-400 to-orange-500 text-white text-xs">
                            ✨ AI POWERED
                          </span>
                        </div>
                      )}
                    </div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* AI Insights Panel */}
        <div>
          <div className="surface-elevated-high">
            <div className="p-6 border-b border-gray-100">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl flex items-center justify-center animate-pulse-premium">
                  <MessageSquare className="w-6 h-6 text-white" />
                </div>
                <div>
                  <h2 className="text-headline">AI Insights</h2>
                  <p className="text-body">Smart recommendations</p>
                </div>
              </div>
            </div>
            <div className="p-6 space-y-4">
              {aiInsights.map((insight, index) => (
                <div 
                  key={index} 
                  className="p-4 surface rounded-xl hover-lift group"
                  style={{ animationDelay: `${index * 200}ms` }}
                >
                  <div className="flex items-start justify-between mb-3">
                    <h4 className="font-semibold text-sm text-gray-900 group-hover:text-blue-600 transition-colors">
                      {insight.title}
                    </h4>
                    <div className="flex items-center space-x-1 text-xs">
                      <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                      <span className="text-green-600 font-medium">{insight.confidence}%</span>
                    </div>
                  </div>
                  <p className="text-xs text-gray-600 mb-3 leading-relaxed">
                    {insight.message}
                  </p>
                  <button className="btn-premium text-xs py-2 px-4 w-full">
                    {insight.action}
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Revolutionary Performance Dashboard */}
      <div className="surface-premium p-8">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h2 className="text-headline text-gradient-premium">Performance Command Center</h2>
            <p className="text-body mt-2">Real-time analytics and predictive intelligence</p>
          </div>
          <Button className="btn-premium">
            <Calendar className="w-5 h-5 mr-2" />
            Advanced Analytics
          </Button>
        </div>
        
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
          <div className="text-center group">
            <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300 shadow-lg">
              <DollarSign className="w-8 h-8 text-white" />
            </div>
            <div className="text-2xl font-bold text-gradient-premium">${dashboardData?.revenue?.toLocaleString()}</div>
            <div className="text-sm text-gray-600 mt-1">Total Revenue</div>
          </div>
          
          <div className="text-center group">
            <div className="w-16 h-16 bg-gradient-to-br from-green-500 to-emerald-600 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300 shadow-lg">
              <Users className="w-8 h-8 text-white" />
            </div>
            <div className="text-2xl font-bold text-gradient-premium">{dashboardData?.conversions?.toLocaleString()}</div>
            <div className="text-sm text-gray-600 mt-1">Conversions</div>
          </div>
          
          <div className="text-center group">
            <div className="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300 shadow-lg">
              <Target className="w-8 h-8 text-white" />
            </div>
            <div className="text-2xl font-bold text-gradient-premium">{dashboardData?.globalReach}</div>
            <div className="text-sm text-gray-600 mt-1">Countries Reached</div>
          </div>
          
          <div className="text-center group">
            <div className="w-16 h-16 bg-gradient-to-br from-orange-500 to-red-600 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300 shadow-lg">
              <MessageSquare className="w-8 h-8 text-white" />
            </div>
            <div className="text-2xl font-bold text-gradient-premium">{dashboardData?.aiInsights?.toLocaleString()}</div>
            <div className="text-sm text-gray-600 mt-1">AI Insights</div>
          </div>
        </div>
      </div>

      {/* Create Campaign Modal */}
      <CreateCampaignModal 
        isOpen={showCreateCampaign} 
        onClose={() => setShowCreateCampaign(false)} 
      />
    </div>
  )
}
