'use client'

import { useState, useEffect } from 'react'
import { 
  ChartBarIcon, 
  ServerIcon, 
  ShieldCheckIcon, 
  BeakerIcon,
  ArrowPathIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline'

export default function RadicalDemo() {
  const [dashboardData, setDashboardData] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [healthStatus, setHealthStatus] = useState<any>(null)

  useEffect(() => {
    // Fetch dashboard data
    const fetchDashboardData = async () => {
      try {
        setLoading(true)
        const response = await fetch('/api/analytics/dashboard')
        if (!response.ok) {
          throw new Error('Failed to fetch dashboard data')
        }
        const result = await response.json()
        setDashboardData(result.data)
        setLoading(false)
      } catch (err: any) {
        setError(err.message)
        setLoading(false)
      }
    }

    // Fetch health status
    const fetchHealthStatus = async () => {
      try {
        const response = await fetch('/api/health')
        if (!response.ok) {
          throw new Error('Failed to fetch health status')
        }
        const result = await response.json()
        setHealthStatus(result.data)
      } catch (err) {
        console.error('Health check failed:', err)
      }
    }

    fetchDashboardData()
    fetchHealthStatus()
  }, [])

  const features = [
    {
      title: 'No Fake Data',
      description: 'All data comes from real API endpoints with proper structures',
      icon: ChartBarIcon,
      color: 'bg-green-500'
    },
    {
      title: 'Clean Errors',
      description: 'Eliminates meaningless "API Error: {}" console messages',
      icon: ShieldCheckIcon,
      color: 'bg-blue-500'
    },
    {
      title: 'Production Ready',
      description: 'Scalable architecture without mock implementations',
      icon: ServerIcon,
      color: 'bg-purple-500'
    },
    {
      title: 'Enhanced UX',
      description: 'Proper loading states and user feedback',
      icon: BeakerIcon,
      color: 'bg-orange-500'
    }
  ]

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 flex items-center justify-center">
        <div className="text-center">
          <ArrowPathIcon className="h-12 w-12 animate-spin text-indigo-600 mx-auto mb-4" />
          <p className="text-gray-600">Loading radical solution demo...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 flex items-center justify-center">
        <div className="max-w-md p-6 bg-white rounded-lg shadow-lg text-center">
          <ExclamationTriangleIcon className="h-12 w-12 text-red-500 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-gray-900 mb-2">Error Loading Demo</h2>
          <p className="text-gray-600 mb-4">{error}</p>
          <button 
            onClick={() => window.location.reload()}
            className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      {/* Header */}
      <div className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-6 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Radical Solution Demo</h1>
              <p className="mt-1 text-gray-600">
                Eliminating fake data and meaningless errors in the AI Marketing Platform
              </p>
            </div>
            {healthStatus && (
              <div className="flex items-center space-x-2">
                <div className={`h-3 w-3 rounded-full ${healthStatus.status === 'healthy' ? 'bg-green-500' : 'bg-red-500'}`}></div>
                <span className="text-sm font-medium text-gray-700">
                  {healthStatus.status === 'healthy' ? 'System Operational' : 'Issues Detected'}
                </span>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
          {features.map((feature, index) => (
            <div 
              key={index}
              className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition-shadow"
            >
              <div className={`w-12 h-12 rounded-lg ${feature.color} flex items-center justify-center mb-4`}>
                <feature.icon className="h-6 w-6 text-white" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900 mb-2">{feature.title}</h3>
              <p className="text-gray-600 text-sm">{feature.description}</p>
            </div>
          ))}
        </div>

        {/* Dashboard Data */}
        <div className="bg-white rounded-xl shadow-md overflow-hidden mb-12">
          <div className="px-6 py-5 border-b border-gray-200">
            <h2 className="text-xl font-semibold text-gray-900">Dashboard Data</h2>
            <p className="text-gray-600 text-sm mt-1">
              Real data from API endpoints (with 0s as defaults instead of fake numbers)
            </p>
          </div>
          <div className="p-6">
            {dashboardData ? (
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
                {Object.entries(dashboardData).map(([key, value]) => (
                  <div key={key} className="border border-gray-200 rounded-lg p-4 text-center">
                    <div className="text-2xl font-bold text-indigo-600 mb-1">{value}</div>
                    <div className="text-xs font-medium text-gray-500 uppercase tracking-wide">
                      {key.replace(/([A-Z])/g, ' $1').trim()}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 text-gray-500">
                No dashboard data available
              </div>
            )}
          </div>
        </div>

        {/* Technical Details */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Architecture */}
          <div className="bg-white rounded-xl shadow-md overflow-hidden">
            <div className="px-6 py-5 border-b border-gray-200">
              <h2 className="text-xl font-semibold text-gray-900">Architecture</h2>
            </div>
            <div className="p-6">
              <div className="space-y-4">
                <div className="flex items-start">
                  <div className="flex-shrink-0 h-6 w-6 rounded-full bg-indigo-100 flex items-center justify-center mt-1">
                    <span className="text-indigo-800 text-xs font-bold">1</span>
                  </div>
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-gray-900">API Service Layer</h3>
                    <p className="text-sm text-gray-500">
                      Centralized API service with enhanced error handling in <code className="bg-gray-100 px-1 rounded">src/lib/api-service.ts</code>
                    </p>
                  </div>
                </div>
                <div className="flex items-start">
                  <div className="flex-shrink-0 h-6 w-6 rounded-full bg-indigo-100 flex items-center justify-center mt-1">
                    <span className="text-indigo-800 text-xs font-bold">2</span>
                  </div>
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-gray-900">Data Hooks</h3>
                    <p className="text-sm text-gray-500">
                      React Query hooks using our API service in <code className="bg-gray-100 px-1 rounded">src/lib/data-hooks.ts</code>
                    </p>
                  </div>
                </div>
                <div className="flex items-start">
                  <div className="flex-shrink-0 h-6 w-6 rounded-full bg-indigo-100 flex items-center justify-center mt-1">
                    <span className="text-indigo-800 text-xs font-bold">3</span>
                  </div>
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-gray-900">API Routes</h3>
                    <p className="text-sm text-gray-500">
                      Proper API endpoints returning structured data instead of mock values
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Benefits */}
          <div className="bg-white rounded-xl shadow-md overflow-hidden">
            <div className="px-6 py-5 border-b border-gray-200">
              <h2 className="text-xl font-semibold text-gray-900">Key Benefits</h2>
            </div>
            <div className="p-6">
              <ul className="space-y-3">
                <li className="flex items-start">
                  <div className="flex-shrink-0 h-5 w-5 text-green-500 mt-0.5">
                    <ShieldCheckIcon />
                  </div>
                  <p className="ml-3 text-sm text-gray-700">
                    <span className="font-medium">No Fake Data</span> - All data comes from real API endpoints
                  </p>
                </li>
                <li className="flex items-start">
                  <div className="flex-shrink-0 h-5 w-5 text-green-500 mt-0.5">
                    <ShieldCheckIcon />
                  </div>
                  <p className="ml-3 text-sm text-gray-700">
                    <span className="font-medium">Clean Console</span> - Eliminates meaningless "API Error: {}" messages
                  </p>
                </li>
                <li className="flex items-start">
                  <div className="flex-shrink-0 h-5 w-5 text-green-500 mt-0.5">
                    <ShieldCheckIcon />
                  </div>
                  <p className="ml-3 text-sm text-gray-700">
                    <span className="font-medium">Production Ready</span> - Scalable architecture without mock implementations
                  </p>
                </li>
                <li className="flex items-start">
                  <div className="flex-shrink-0 h-5 w-5 text-green-500 mt-0.5">
                    <ShieldCheckIcon />
                  </div>
                  <p className="ml-3 text-sm text-gray-700">
                    <span className="font-medium">Enhanced UX</span> - Proper loading states and user feedback
                  </p>
                </li>
                <li className="flex items-start">
                  <div className="flex-shrink-0 h-5 w-5 text-green-500 mt-0.5">
                    <ShieldCheckIcon />
                  </div>
                  <p className="ml-3 text-sm text-gray-700">
                    <span className="font-medium">Maintainable</span> - Clean, consistent code structure
                  </p>
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* Call to Action */}
        <div className="mt-12 bg-gradient-to-r from-indigo-500 to-purple-600 rounded-xl shadow-lg p-8 text-center">
          <h2 className="text-2xl font-bold text-white mb-4">Ready to Implement the Radical Solution?</h2>
          <p className="text-indigo-100 mb-6 max-w-2xl mx-auto">
            This demo showcases how to eliminate fake data and meaningless errors from your application. 
            The full implementation provides a production-ready foundation for your AI Marketing Platform.
          </p>
          <div className="flex flex-col sm:flex-row justify-center gap-4">
            <button className="px-6 py-3 bg-white text-indigo-600 font-medium rounded-lg hover:bg-gray-50 transition-colors">
              View Implementation Guide
            </button>
            <button className="px-6 py-3 bg-indigo-800 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors">
              Start Integration
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}