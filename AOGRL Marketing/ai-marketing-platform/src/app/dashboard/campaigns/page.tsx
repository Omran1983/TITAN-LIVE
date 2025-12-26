'use client'

import { useState, useEffect } from 'react'
import { 
  PlusIcon, 
  PlayIcon, 
  PauseIcon, 
  StopIcon,
  EyeIcon,
  PencilIcon,
  ChartBarIcon,
  CalendarIcon,
  CurrencyDollarIcon,
  UsersIcon
} from '@heroicons/react/24/outline'

interface Campaign {
  id: string
  name: string
  description?: string
  status: 'draft' | 'active' | 'paused' | 'completed'
  budget: number
  spent: number
  impressions: number
  clicks: number
  startDate: string
  endDate: string
  createdAt: string
}

export default function Campaigns() {
  const [campaigns, setCampaigns] = useState<Campaign[]>([])
  const [loading, setLoading] = useState(true)
  const [showCreateForm, setShowCreateForm] = useState(false)

  useEffect(() => {
    // Simulate API call
    const fetchCampaigns = async () => {
      try {
        await new Promise(resolve => setTimeout(resolve, 800))
        
        // Mock data
        setCampaigns([
          {
            id: '1',
            name: 'Summer Sale 2024',
            description: 'Promote summer collection with 30% discount',
            status: 'active',
            budget: 5000,
            spent: 1200,
            impressions: 45320,
            clicks: 1247,
            startDate: '2024-06-01',
            endDate: '2024-08-31',
            createdAt: '2024-05-25'
          },
          {
            id: '2',
            name: 'Back to School',
            description: 'Target students and parents for school supplies',
            status: 'draft',
            budget: 3000,
            spent: 0,
            impressions: 0,
            clicks: 0,
            startDate: '2024-08-01',
            endDate: '2024-09-15',
            createdAt: '2024-07-20'
          },
          {
            id: '3',
            name: 'Holiday Promotion',
            description: 'End of year holiday sales campaign',
            status: 'paused',
            budget: 8000,
            spent: 2400,
            impressions: 78500,
            clicks: 2156,
            startDate: '2024-11-01',
            endDate: '2024-12-31',
            createdAt: '2024-10-15'
          }
        ])
      } catch (error) {
        console.error('Failed to fetch campaigns:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchCampaigns()
  }, [])

  const getStatusBadge = (status: Campaign['status']) => {
    const styles = {
      draft: 'status-badge bg-gray-100 text-gray-700',
      active: 'status-badge status-active',
      paused: 'status-badge status-pending',
      completed: 'status-badge bg-purple-100 text-purple-700'
    }
    
    const labels = {
      draft: 'Draft',
      active: 'Active',
      paused: 'Paused',
      completed: 'Completed'
    }

    return (
      <span className={styles[status]}>
        {labels[status]}
      </span>
    )
  }

  const getStatusIcon = (status: Campaign['status']) => {
    switch (status) {
      case 'active':
        return <PlayIcon className="h-4 w-4 text-green-600" />
      case 'paused':
        return <PauseIcon className="h-4 w-4 text-yellow-600" />
      case 'completed':
        return <StopIcon className="h-4 w-4 text-purple-600" />
      default:
        return <EyeIcon className="h-4 w-4 text-gray-600" />
    }
  }

  if (loading) {
    return (
      <div className="animate-fade-in space-y-6">
        <div className="flex justify-between items-start">
          <div>
            <div className="h-8 bg-gray-200 rounded w-48 mb-2 skeleton"></div>
            <div className="h-4 bg-gray-200 rounded w-96 skeleton"></div>
          </div>
          <div className="h-10 bg-gray-200 rounded w-32 skeleton"></div>
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="surface-elevated p-6">
              <div className="h-6 bg-gray-200 rounded mb-4 skeleton"></div>
              <div className="h-4 bg-gray-200 rounded mb-2 skeleton"></div>
              <div className="h-16 bg-gray-200 rounded skeleton"></div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="animate-slide-up space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-display">Campaign Management</h1>
          <p className="text-body mt-2">
            Create and manage your marketing campaigns
          </p>
        </div>
        <div className="mt-4 sm:mt-0">
          <button
            onClick={() => setShowCreateForm(true)}
            className="btn btn-primary"
          >
            <PlusIcon className="h-4 w-4 mr-2" />
            Create Campaign
          </button>
        </div>
      </div>

      {/* Campaign Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="metric-card">
          <div className="flex items-center justify-between">
            <div className="p-3 bg-blue-600 rounded-lg">
              <ChartBarIcon className="h-6 w-6 text-white" />
            </div>
          </div>
          <div className="mt-4">
            <div className="metric-value">{campaigns.length}</div>
            <div className="metric-label">Total Campaigns</div>
          </div>
        </div>
        
        <div className="metric-card">
          <div className="flex items-center justify-between">
            <div className="p-3 bg-green-600 rounded-lg">
              <PlayIcon className="h-6 w-6 text-white" />
            </div>
          </div>
          <div className="mt-4">
            <div className="metric-value">{campaigns.filter(c => c.status === 'active').length}</div>
            <div className="metric-label">Active Campaigns</div>
          </div>
        </div>
        
        <div className="metric-card">
          <div className="flex items-center justify-between">
            <div className="p-3 bg-purple-600 rounded-lg">
              <CurrencyDollarIcon className="h-6 w-6 text-white" />
            </div>
          </div>
          <div className="mt-4">
            <div className="metric-value">
              ${campaigns.reduce((sum, c) => sum + c.spent, 0).toLocaleString()}
            </div>
            <div className="metric-label">Total Spent</div>
          </div>
        </div>
        
        <div className="metric-card">
          <div className="flex items-center justify-between">
            <div className="p-3 bg-orange-600 rounded-lg">
              <UsersIcon className="h-6 w-6 text-white" />
            </div>
          </div>
          <div className="mt-4">
            <div className="metric-value">
              {campaigns.reduce((sum, c) => sum + c.impressions, 0).toLocaleString()}
            </div>
            <div className="metric-label">Total Impressions</div>
          </div>
        </div>
      </div>

      {/* Campaigns Grid */}
      {campaigns.length === 0 ? (
        <div className="surface-elevated text-center py-12">
          <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <ChartBarIcon className="h-8 w-8 text-gray-400" />
          </div>
          <h3 className="text-title mb-2">No campaigns yet</h3>
          <p className="text-body mb-4">
            Get started by creating your first marketing campaign
          </p>
          <button
            onClick={() => setShowCreateForm(true)}
            className="btn btn-primary"
          >
            Create Your First Campaign
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
          {campaigns.map((campaign, index) => (
            <div 
              key={campaign.id} 
              className="surface-elevated-high hover-lift"
              style={{ animationDelay: `${index * 100}ms` }}
            >
              <div className="p-6">
                {/* Header */}
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center space-x-2">
                    {getStatusIcon(campaign.status)}
                    <h3 className="text-title font-semibold line-clamp-1">
                      {campaign.name}
                    </h3>
                  </div>
                  {getStatusBadge(campaign.status)}
                </div>

                {/* Description */}
                {campaign.description && (
                  <p className="text-body line-clamp-2 mb-4">{campaign.description}</p>
                )}

                {/* Metrics */}
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div>
                    <div className="text-sm font-medium text-gray-900">
                      ${campaign.spent.toLocaleString()}
                    </div>
                    <div className="text-xs text-gray-500">
                      of ${campaign.budget.toLocaleString()} budget
                    </div>
                  </div>
                  <div>
                    <div className="text-sm font-medium text-gray-900">
                      {campaign.clicks.toLocaleString()}
                    </div>
                    <div className="text-xs text-gray-500">clicks</div>
                  </div>
                  <div>
                    <div className="text-sm font-medium text-gray-900">
                      {campaign.impressions.toLocaleString()}
                    </div>
                    <div className="text-xs text-gray-500">impressions</div>
                  </div>
                  <div>
                    <div className="text-sm font-medium text-gray-900">
                      {campaign.clicks > 0 ? ((campaign.clicks / campaign.impressions) * 100).toFixed(1) : '0.0'}%
                    </div>
                    <div className="text-xs text-gray-500">CTR</div>
                  </div>
                </div>

                {/* Progress Bar */}
                <div className="mb-4">
                  <div className="flex justify-between text-xs text-gray-500 mb-1">
                    <span>Budget Used</span>
                    <span>{((campaign.spent / campaign.budget) * 100).toFixed(0)}%</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div 
                      className="bg-blue-600 h-2 rounded-full" 
                      style={{ width: `${Math.min((campaign.spent / campaign.budget) * 100, 100)}%` }}
                    ></div>
                  </div>
                </div>

                {/* Dates */}
                <div className="flex items-center space-x-4 text-xs text-gray-500 mb-4">
                  <div className="flex items-center space-x-1">
                    <CalendarIcon className="h-3 w-3" />
                    <span>{new Date(campaign.startDate).toLocaleDateString()}</span>
                  </div>
                  <span>-</span>
                  <span>{new Date(campaign.endDate).toLocaleDateString()}</span>
                </div>

                {/* Actions */}
                <div className="flex items-center justify-between pt-4 border-t border-gray-100">
                  <div className="flex space-x-1">
                    <button className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors">
                      <EyeIcon className="h-4 w-4" />
                    </button>
                    <button className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-50 rounded-lg transition-colors">
                      <PencilIcon className="h-4 w-4" />
                    </button>
                  </div>
                  
                  <div className="flex space-x-2">
                    {campaign.status === 'active' && (
                      <button className="btn btn-ghost text-xs py-1 px-3">
                        <PauseIcon className="h-3 w-3 mr-1" />
                        Pause
                      </button>
                    )}
                    {campaign.status === 'paused' && (
                      <button className="btn btn-ghost text-xs py-1 px-3">
                        <PlayIcon className="h-3 w-3 mr-1" />
                        Resume
                      </button>
                    )}
                    {campaign.status === 'draft' && (
                      <button className="btn btn-primary text-xs py-1 px-3">
                        <PlayIcon className="h-3 w-3 mr-1" />
                        Launch
                      </button>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}