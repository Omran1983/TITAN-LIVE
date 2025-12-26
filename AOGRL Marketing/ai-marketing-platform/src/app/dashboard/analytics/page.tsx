'use client'

import { useState } from 'react'
import {
  ChartBarIcon,
  ArrowTrendingUpIcon,
  ArrowTrendingDownIcon,
  EyeIcon,
  CursorArrowRaysIcon,
  BanknotesIcon,
  UserGroupIcon,
  CalendarIcon,
  FunnelIcon,
  DocumentArrowDownIcon,
  PresentationChartLineIcon,
  ChartPieIcon,
  SparklesIcon
} from '@heroicons/react/24/outline'

interface AnalyticsData {
  period: string
  revenue: number
  impressions: number
  clicks: number
  conversions: number
  ctr: number
  cpc: number
  roas: number
  reach: number
}

const mockAnalyticsData: AnalyticsData[] = [
  { period: 'Jan 2024', revenue: 145000, impressions: 2450000, clicks: 98000, conversions: 3920, ctr: 4.0, cpc: 1.48, roas: 4.2, reach: 156000 },
  { period: 'Feb 2024', revenue: 167000, impressions: 2780000, clicks: 111600, conversions: 4456, ctr: 4.0, cpc: 1.50, roas: 4.5, reach: 178000 },
  { period: 'Mar 2024', revenue: 198000, impressions: 3120000, clicks: 124800, conversions: 4992, ctr: 4.0, cpc: 1.58, roas: 4.8, reach: 195000 }
]

interface PredictiveInsight {
  title: string
  prediction: string
  confidence: number
  impact: 'positive' | 'negative' | 'neutral'
  timeframe: string
  recommendation: string
  metric: string
}

const predictiveInsights: PredictiveInsight[] = [
  {
    title: 'Revenue Growth Forecast',
    prediction: '+23% increase expected',
    confidence: 87,
    impact: 'positive',
    timeframe: 'Next 30 days',
    recommendation: 'Increase budget on high-performing campaigns',
    metric: 'Revenue'
  },
  {
    title: 'Seasonal Trend Alert',
    prediction: 'Summer surge anticipated',
    confidence: 94,
    impact: 'positive',
    timeframe: 'June - August',
    recommendation: 'Prepare seasonal campaign variations',
    metric: 'Impressions'
  },
  {
    title: 'Conversion Rate Optimization',
    prediction: '+1.2% CTR improvement possible',
    confidence: 76,
    impact: 'positive',
    timeframe: 'Next 14 days',
    recommendation: 'A/B test new ad creatives',
    metric: 'CTR'
  }
]

export default function AnalyticsPage() {
  const [selectedPeriod, setSelectedPeriod] = useState('last90days')
  const [selectedMetric, setSelectedMetric] = useState('revenue')

  const latestData = mockAnalyticsData[mockAnalyticsData.length - 1]
  const previousData = mockAnalyticsData[mockAnalyticsData.length - 2]

  const calculateChange = (current: number, previous: number) => {
    return ((current - previous) / previous * 100).toFixed(1)
  }

  const getChangeType = (current: number, previous: number): 'positive' | 'negative' => {
    return current >= previous ? 'positive' : 'negative'
  }

  const keyMetrics = [
    {
      title: 'Total Revenue',
      value: `$${latestData.revenue.toLocaleString()}`,
      change: calculateChange(latestData.revenue, previousData.revenue),
      changeType: getChangeType(latestData.revenue, previousData.revenue),
      icon: BanknotesIcon,
      gradient: 'from-green-500 to-emerald-600'
    },
    {
      title: 'Total Impressions',
      value: `${(latestData.impressions / 1000000).toFixed(1)}M`,
      change: calculateChange(latestData.impressions, previousData.impressions),
      changeType: getChangeType(latestData.impressions, previousData.impressions),
      icon: EyeIcon,
      gradient: 'from-blue-500 to-cyan-600'
    },
    {
      title: 'Click-Through Rate',
      value: `${latestData.ctr}%`,
      change: calculateChange(latestData.ctr, previousData.ctr),
      changeType: getChangeType(latestData.ctr, previousData.ctr),
      icon: CursorArrowRaysIcon,
      gradient: 'from-purple-500 to-pink-600'
    },
    {
      title: 'Total Reach',
      value: `${(latestData.reach / 1000).toFixed(0)}K`,
      change: calculateChange(latestData.reach, previousData.reach),
      changeType: getChangeType(latestData.reach, previousData.reach),
      icon: UserGroupIcon,
      gradient: 'from-orange-500 to-red-600'
    },
    {
      title: 'ROAS',
      value: `${latestData.roas}x`,
      change: calculateChange(latestData.roas, previousData.roas),
      changeType: getChangeType(latestData.roas, previousData.roas),
      icon: ArrowTrendingUpIcon,
      gradient: 'from-indigo-500 to-blue-600'
    },
    {
      title: 'Cost Per Click',
      value: `$${latestData.cpc}`,
      change: calculateChange(latestData.cpc, previousData.cpc),
      changeType: getChangeType(previousData.cpc, latestData.cpc), // Inverted for CPC (lower is better)
      icon: BanknotesIcon,
      gradient: 'from-yellow-500 to-orange-600'
    }
  ]

  return (
    <div className="animate-slide-up space-y-8">
      {/* Premium Header */}
      <div className="surface-premium p-8 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-500/20 via-purple-500/20 to-green-500/20 animate-gradient-flow"></div>
        <div className="relative z-10">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center space-x-4 mb-4">
                <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
                  <ChartBarIcon className="w-8 h-8 text-white" />
                </div>
                <div>
                  <h1 className="text-display">Predictive Analytics</h1>
                  <p className="text-body text-gray-600 mt-2">
                    AI-powered insights and future performance predictions
                  </p>
                </div>
              </div>
              
              <div className="flex items-center space-x-6 text-sm">
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <SparklesIcon className="w-4 h-4 text-purple-500" />
                  <span className="font-semibold">AI Predictions</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <PresentationChartLineIcon className="w-4 h-4 text-blue-500" />
                  <span className="font-semibold">Real-time Data</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <ArrowTrendingUpIcon className="w-4 h-4 text-green-500" />
                  <span className="font-semibold">Growth Tracking</span>
                </div>
              </div>
            </div>
            
            <div className="flex space-x-3">
              <button className="btn-secondary flex items-center space-x-2">
                <DocumentArrowDownIcon className="w-5 h-5" />
                <span>Export Report</span>
              </button>
              <button className="btn-premium flex items-center space-x-2">
                <SparklesIcon className="w-5 h-5" />
                <span>AI Insights</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="surface-elevated p-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex items-center space-x-4">
            <select
              value={selectedPeriod}
              onChange={(e) => setSelectedPeriod(e.target.value)}
              className="form-input w-48"
            >
              <option value="last7days">Last 7 days</option>
              <option value="last30days">Last 30 days</option>
              <option value="last90days">Last 90 days</option>
              <option value="last6months">Last 6 months</option>
              <option value="lastyear">Last year</option>
            </select>
            <select
              value={selectedMetric}
              onChange={(e) => setSelectedMetric(e.target.value)}
              className="form-input w-48"
            >
              <option value="revenue">Revenue</option>
              <option value="impressions">Impressions</option>
              <option value="clicks">Clicks</option>
              <option value="conversions">Conversions</option>
              <option value="ctr">Click-Through Rate</option>
              <option value="roas">Return on Ad Spend</option>
            </select>
          </div>
          <div className="flex space-x-2">
            <button className="btn-secondary flex items-center space-x-2">
              <FunnelIcon className="w-4 h-4" />
              <span>Advanced Filters</span>
            </button>
            <button className="btn-secondary flex items-center space-x-2">
              <CalendarIcon className="w-4 h-4" />
              <span>Custom Date Range</span>
            </button>
          </div>
        </div>
      </div>

      {/* Key Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {keyMetrics.map((metric, index) => (
          <div
            key={metric.title}
            className="metric-card hover-glow"
            style={{ animationDelay: `${index * 100}ms` }}
          >
            <div className="flex items-center justify-between mb-6">
              <div className={`p-4 rounded-2xl bg-gradient-to-br ${metric.gradient} shadow-lg`}>
                <metric.icon className="h-8 w-8 text-white" />
              </div>
              <div className={`flex items-center space-x-2 metric-change ${metric.changeType}`}>
                {metric.changeType === 'positive' ? (
                  <ArrowTrendingUpIcon className="h-4 w-4" />
                ) : (
                  <ArrowTrendingDownIcon className="h-4 w-4" />
                )}
                <span className="font-bold">{metric.change}%</span>
              </div>
            </div>
            <div>
              <div className="metric-value mb-2">{metric.value}</div>
              <div className="metric-label">{metric.title}</div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Chart Placeholder */}
        <div className="surface-elevated-high">
          <div className="p-6 border-b border-gray-100">
            <div className="flex items-center justify-between">
              <h2 className="text-headline">Performance Trends</h2>
              <div className="flex items-center space-x-2">
                <ChartPieIcon className="w-5 h-5 text-gray-400" />
                <span className="text-sm text-gray-500">Interactive Chart</span>
              </div>
            </div>
          </div>
          <div className="p-6">
            <div className="h-80 bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl flex items-center justify-center">
              <div className="text-center">
                <PresentationChartLineIcon className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                <p className="text-gray-500">Interactive charts would be rendered here</p>
                <p className="text-sm text-gray-400 mt-2">Revenue, impressions, and conversion trends</p>
              </div>
            </div>
          </div>
        </div>

        {/* AI Predictive Insights */}
        <div className="surface-elevated-high">
          <div className="p-6 border-b border-gray-100">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-pink-600 rounded-xl flex items-center justify-center animate-pulse-premium">
                <SparklesIcon className="w-5 h-5 text-white" />
              </div>
              <h2 className="text-headline">AI Predictions</h2>
            </div>
          </div>
          <div className="p-6 space-y-4">
            {predictiveInsights.map((insight, index) => (
              <div
                key={index}
                className="p-4 surface rounded-xl hover-lift"
                style={{ animationDelay: `${index * 150}ms` }}
              >
                <div className="flex items-start justify-between mb-3">
                  <h4 className="font-semibold text-sm text-gray-900">{insight.title}</h4>
                  <div className="flex items-center space-x-1 text-xs">
                    <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                    <span className="text-green-600 font-medium">{insight.confidence}% confidence</span>
                  </div>
                </div>
                
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-blue-600">{insight.prediction}</span>
                    <span className="text-xs text-gray-500">{insight.timeframe}</span>
                  </div>
                  
                  <p className="text-xs text-gray-600">{insight.recommendation}</p>
                  
                  <div className="flex items-center justify-between pt-2">
                    <span className="text-xs text-gray-500">Metric: {insight.metric}</span>
                    <button className="btn-primary text-xs py-1 px-3">
                      Apply Suggestion
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Campaign Performance Table */}
      <div className="surface-elevated-high">
        <div className="p-6 border-b border-gray-100">
          <h2 className="text-headline">Campaign Performance Breakdown</h2>
          <p className="text-body mt-1">Detailed analytics for all active campaigns</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Campaign</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Impressions</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Clicks</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">CTR</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Revenue</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ROAS</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              <tr className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div>
                    <div className="text-sm font-medium text-gray-900">Summer Sale 2024</div>
                    <div className="text-sm text-gray-500">TechFlow Solutions</div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">1.2M</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">48K</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">4.0%</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">$85,000</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">4.8x</td>
              </tr>
              <tr className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div>
                    <div className="text-sm font-medium text-gray-900">Organic Product Launch</div>
                    <div className="text-sm text-gray-500">GreenLeaf Organics</div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">950K</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">38K</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">4.0%</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">$67,000</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">4.2x</td>
              </tr>
              <tr className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div>
                    <div className="text-sm font-medium text-gray-900">Fashion Week Showcase</div>
                    <div className="text-sm text-gray-500">Urban Fashion Co.</div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">1.8M</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">72K</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">4.0%</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">$124,000</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">5.2x</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}