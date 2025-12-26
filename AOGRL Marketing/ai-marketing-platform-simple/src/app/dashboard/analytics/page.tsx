'use client'

import { useState } from 'react'
import { 
  ChartBarIcon, 
  CursorArrowRaysIcon, 
  BanknotesIcon, 
  UserGroupIcon,
  EyeIcon,
  ArrowTrendingUpIcon
} from '@heroicons/react/24/outline'

export default function AnalyticsPage() {
  // Mock analytics data
  const analyticsData = {
    totalRevenue: 847650.25,
    totalCampaigns: 12,
    totalImpressions: 2847320,
    clickRate: 4.7,
    conversions: 8947,
    totalSpend: 156890.50,
    products: 89,
    creatives: 234,
    activeUsers: 15847,
    globalReach: 47
  }

  const metrics = [
    {
      name: 'Total Revenue',
      value: `$${analyticsData.totalRevenue.toLocaleString()}`,
      change: '+34.2%',
      changeType: 'positive',
      icon: BanknotesIcon,
    },
    {
      name: 'Campaigns',
      value: analyticsData.totalCampaigns.toString(),
      change: '+28.1%',
      changeType: 'positive',
      icon: ChartBarIcon,
    },
    {
      name: 'Impressions',
      value: `${(analyticsData.totalImpressions / 1000000).toFixed(1)}M`,
      change: '+45.6%',
      changeType: 'positive',
      icon: EyeIcon,
    },
    {
      name: 'Click Rate',
      value: `${analyticsData.clickRate}%`,
      change: '+8.9%',
      changeType: 'positive',
      icon: CursorArrowRaysIcon,
    },
  ]

  return (
    <div className="py-6">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
        <h1 className="text-2xl font-semibold text-gray-900">Analytics Dashboard</h1>
        <p className="mt-1 text-sm text-gray-500">Track your marketing performance and insights</p>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 md:px-8 mt-6">
        {/* Metrics Grid */}
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4 mb-8">
          {metrics.map((item) => (
            <div key={item.name} className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <item.icon className="h-6 w-6 text-gray-400" aria-hidden="true" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">{item.name}</dt>
                      <dd className="flex items-baseline">
                        <div className="text-2xl font-semibold text-gray-900">{item.value}</div>
                        <div className="ml-2 flex items-baseline text-sm font-semibold">
                          {item.changeType === 'positive' ? (
                            <span className="text-green-600">
                              <ArrowTrendingUpIcon className="h-4 w-4" aria-hidden="true" />
                              {item.change}
                            </span>
                          ) : (
                            <span className="text-red-600">
                              <ArrowTrendingUpIcon className="h-4 w-4 rotate-180" aria-hidden="true" />
                              {item.change}
                            </span>
                          )}
                        </div>
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Charts Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* Revenue Chart */}
          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Revenue Trend</h3>
            </div>
            <div className="p-6">
              <div className="h-64 flex items-center justify-center bg-gray-50 rounded">
                <div className="text-center">
                  <ChartBarIcon className="mx-auto h-12 w-12 text-gray-400" />
                  <p className="mt-2 text-sm text-gray-500">Revenue chart visualization</p>
                </div>
              </div>
            </div>
          </div>

          {/* Campaign Performance */}
          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Campaign Performance</h3>
            </div>
            <div className="p-6">
              <div className="h-64 flex items-center justify-center bg-gray-50 rounded">
                <div className="text-center">
                  <CursorArrowRaysIcon className="mx-auto h-12 w-12 text-gray-400" />
                  <p className="mt-2 text-sm text-gray-500">Campaign performance chart</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Additional Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0 bg-blue-100 rounded-md p-3">
                  <UserGroupIcon className="h-6 w-6 text-blue-600" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Active Users</dt>
                    <dd className="text-lg font-medium text-gray-900">{analyticsData.activeUsers.toLocaleString()}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0 bg-green-100 rounded-md p-3">
                  <BanknotesIcon className="h-6 w-6 text-green-600" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Total Spend</dt>
                    <dd className="text-lg font-medium text-gray-900">${analyticsData.totalSpend.toLocaleString()}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0 bg-purple-100 rounded-md p-3">
                  <ChartBarIcon className="h-6 w-6 text-purple-600" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Conversions</dt>
                    <dd className="text-lg font-medium text-gray-900">{analyticsData.conversions.toLocaleString()}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}