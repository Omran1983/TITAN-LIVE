'use client'

import { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'react-hot-toast'
import {
  CurrencyDollarIcon,
  ChartBarIcon,
  ArrowTrendingUpIcon,
  ArrowTrendingDownIcon,
  ExclamationTriangleIcon,
  LightBulbIcon,
  CpuChipIcon,
  RocketLaunchIcon,
  BoltIcon,
  ShieldCheckIcon,
  AdjustmentsHorizontalIcon,
  CalendarIcon,
  BanknotesIcon,
  ArrowUpIcon,
  ArrowDownIcon,
  EyeIcon
} from '@heroicons/react/24/outline'
import { api } from '@/lib/api'

interface BudgetOptimizationRequest {
  campaignIds?: string[]
  totalBudget: number
  currency: string
  timeframe: 'daily' | 'weekly' | 'monthly'
  objectives: {
    primary: 'conversions' | 'reach' | 'engagement' | 'revenue'
    secondary?: string
  }
  constraints?: {
    minBudgetPerCampaign?: number
    maxBudgetPerCampaign?: number
  }
}

export default function BudgetOptimizationPage() {
  const [optimizationRequest, setOptimizationRequest] = useState<BudgetOptimizationRequest>({
    totalBudget: 10000,
    currency: 'USD',
    timeframe: 'monthly',
    objectives: {
      primary: 'conversions'
    }
  })
  const [showAdvanced, setShowAdvanced] = useState(false)
  const [selectedCampaigns, setSelectedCampaigns] = useState<string[]>([])
  const queryClient = useQueryClient()

  // Fetch campaigns for selection
  const { data: campaignsData } = useQuery({
    queryKey: ['campaigns'],
    queryFn: () => api.get('/campaigns').then(res => res.data)
  })

  // Fetch budget alerts
  const { data: alertsData } = useQuery({
    queryKey: ['budget-alerts'],
    queryFn: () => api.get('/budget/alerts').then(res => res.data),
    refetchInterval: 30000 // Refresh every 30 seconds
  })

  // Optimization mutation
  const optimizeMutation = useMutation({
    mutationFn: (data: BudgetOptimizationRequest) => 
      api.post('/budget/optimize', data).then(res => res.data),
    onSuccess: (data) => {
      toast.success('🎯 Budget optimization completed!')
      queryClient.invalidateQueries({ queryKey: ['budget-optimization'] })
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.error || 'Optimization failed')
    }
  })

  const handleOptimize = () => {
    const request = {
      ...optimizationRequest,
      campaignIds: selectedCampaigns.length > 0 ? selectedCampaigns : undefined
    }
    optimizeMutation.mutate(request)
  }

  const campaigns = campaignsData?.campaigns || []
  const alerts = alertsData?.alerts || []
  const alertsSummary = alertsData?.summary || {}
  const optimization = optimizeMutation.data?.optimization

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
            AI Budget Optimization
          </h1>
          <p className="text-gray-600 mt-2">
            Maximize your marketing ROI with AI-powered budget allocation
          </p>
        </div>
        <div className="flex items-center space-x-4">
          <div className="text-right">
            <div className="text-sm text-gray-500">Total Managed Budget</div>
            <div className="text-2xl font-bold text-green-600">
              ${alertsSummary.totalBudget?.toLocaleString() || '0'}
            </div>
          </div>
          <div className="w-16 h-16 bg-gradient-to-br from-green-500 to-emerald-600 rounded-2xl flex items-center justify-center">
            <CurrencyDollarIcon className="w-8 h-8 text-white" />
          </div>
        </div>
      </div>

      {/* Budget Alerts Dashboard */}
      {alerts.length > 0 && (
        <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold flex items-center">
              <ExclamationTriangleIcon className="w-6 h-6 text-yellow-500 mr-2" />
              Active Budget Alerts
            </h2>
            <span className="bg-red-100 text-red-800 px-3 py-1 rounded-full text-sm font-semibold">
              {alerts.length} alerts
            </span>
          </div>
          
          <div className="grid gap-4">
            {alerts.map((alert: any, index: number) => (
              <div 
                key={index}
                className={`p-4 rounded-xl border-l-4 ${
                  alert.severity === 'high' ? 'border-red-500 bg-red-50' :
                  alert.severity === 'medium' ? 'border-yellow-500 bg-yellow-50' :
                  'border-blue-500 bg-blue-50'
                }`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-1">
                      <span className={`text-sm font-semibold px-2 py-1 rounded-full ${
                        alert.type === 'overspend' ? 'bg-red-100 text-red-800' :
                        alert.type === 'underspend' ? 'bg-yellow-100 text-yellow-800' :
                        alert.type === 'performance_drop' ? 'bg-orange-100 text-orange-800' :
                        'bg-green-100 text-green-800'
                      }`}>
                        {alert.type.replace('_', ' ').toUpperCase()}
                      </span>
                      <span className="font-medium text-gray-900">
                        {alert.campaignName}
                      </span>
                    </div>
                    <p className="text-gray-700 mb-2">{alert.message}</p>
                    <p className="text-sm text-gray-600">
                      <strong>Recommended:</strong> {alert.recommendedAction}
                    </p>
                  </div>
                  <div className={`w-3 h-3 rounded-full ${
                    alert.severity === 'high' ? 'bg-red-400 animate-pulse' :
                    alert.severity === 'medium' ? 'bg-yellow-400' : 'bg-blue-400'
                  }`}></div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Budget Optimization Form */}
      <div className="grid lg:grid-cols-2 gap-8">
        <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-6">
          <div className="flex items-center mb-6">
            <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center mr-4">
              <AdjustmentsHorizontalIcon className="w-6 h-6 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-semibold">Optimization Settings</h2>
              <p className="text-gray-600">Configure your budget optimization parameters</p>
            </div>
          </div>

          <div className="space-y-6">
            {/* Total Budget */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Total Budget to Optimize
              </label>
              <div className="relative">
                <CurrencyDollarIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="number"
                  value={optimizationRequest.totalBudget}
                  onChange={(e) => setOptimizationRequest(prev => ({
                    ...prev,
                    totalBudget: parseFloat(e.target.value) || 0
                  }))}
                  className="form-input pl-10 w-full"
                  placeholder="10000"
                />
              </div>
            </div>

            {/* Currency & Timeframe */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Currency
                </label>
                <select
                  value={optimizationRequest.currency}
                  onChange={(e) => setOptimizationRequest(prev => ({
                    ...prev,
                    currency: e.target.value
                  }))}
                  className="form-select w-full"
                >
                  <option value="USD">USD ($)</option>
                  <option value="EUR">EUR (€)</option>
                  <option value="GBP">GBP (£)</option>
                  <option value="MUR">MUR (Rs)</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Timeframe
                </label>
                <select
                  value={optimizationRequest.timeframe}
                  onChange={(e) => setOptimizationRequest(prev => ({
                    ...prev,
                    timeframe: e.target.value as any
                  }))}
                  className="form-select w-full"
                >
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="monthly">Monthly</option>
                </select>
              </div>
            </div>

            {/* Primary Objective */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Primary Objective
              </label>
              <div className="grid grid-cols-2 gap-3">
                {[
                  { value: 'conversions', label: 'Conversions', icon: '🎯' },
                  { value: 'revenue', label: 'Revenue', icon: '💰' },
                  { value: 'reach', label: 'Reach', icon: '📢' },
                  { value: 'engagement', label: 'Engagement', icon: '❤️' }
                ].map((objective) => (
                  <label
                    key={objective.value}
                    className={`relative flex items-center p-3 rounded-xl border cursor-pointer transition-all ${
                      optimizationRequest.objectives.primary === objective.value
                        ? 'border-blue-500 bg-blue-50 ring-2 ring-blue-200'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <input
                      type="radio"
                      name="objective"
                      value={objective.value}
                      checked={optimizationRequest.objectives.primary === objective.value}
                      onChange={(e) => setOptimizationRequest(prev => ({
                        ...prev,
                        objectives: { ...prev.objectives, primary: e.target.value as any }
                      }))}
                      className="sr-only"
                    />
                    <span className="text-2xl mr-3">{objective.icon}</span>
                    <span className="font-medium">{objective.label}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* Campaign Selection */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Campaigns to Include
              </label>
              <div className="max-h-40 overflow-y-auto border border-gray-200 rounded-lg p-3 space-y-2">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={selectedCampaigns.length === 0}
                    onChange={() => setSelectedCampaigns([])}
                    className="form-checkbox"
                  />
                  <span className="ml-2 text-sm font-medium text-blue-600">
                    All Campaigns
                  </span>
                </label>
                {campaigns.map((campaign: any) => (
                  <label key={campaign.id} className="flex items-center">
                    <input
                      type="checkbox"
                      checked={selectedCampaigns.includes(campaign.id)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedCampaigns(prev => [...prev, campaign.id])
                        } else {
                          setSelectedCampaigns(prev => prev.filter(id => id !== campaign.id))
                        }
                      }}
                      className="form-checkbox"
                    />
                    <span className="ml-2 text-sm">{campaign.name}</span>
                    <span className="ml-auto text-xs text-gray-500">
                      ${campaign.budget?.toLocaleString()}
                    </span>
                  </label>
                ))}
              </div>
            </div>

            {/* Advanced Settings */}
            <div>
              <button
                onClick={() => setShowAdvanced(!showAdvanced)}
                className="text-blue-600 hover:text-blue-800 text-sm font-medium flex items-center"
              >
                <AdjustmentsHorizontalIcon className="w-4 h-4 mr-1" />
                Advanced Settings
              </button>
              
              {showAdvanced && (
                <div className="mt-4 space-y-4 p-4 bg-gray-50 rounded-lg">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Min Budget Per Campaign
                      </label>
                      <input
                        type="number"
                        placeholder="500"
                        onChange={(e) => setOptimizationRequest(prev => ({
                          ...prev,
                          constraints: {
                            ...prev.constraints,
                            minBudgetPerCampaign: parseFloat(e.target.value) || undefined
                          }
                        }))}
                        className="form-input text-sm"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Max Budget Per Campaign
                      </label>
                      <input
                        type="number"
                        placeholder="5000"
                        onChange={(e) => setOptimizationRequest(prev => ({
                          ...prev,
                          constraints: {
                            ...prev.constraints,
                            maxBudgetPerCampaign: parseFloat(e.target.value) || undefined
                          }
                        }))}
                        className="form-input text-sm"
                      />
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Optimize Button */}
            <button
              onClick={handleOptimize}
              disabled={optimizeMutation.isPending || optimizationRequest.totalBudget <= 0}
              className="w-full bg-gradient-to-r from-blue-600 to-purple-600 text-white font-semibold py-3 px-6 rounded-xl hover:from-blue-700 hover:to-purple-700 transition-all duration-200 disabled:opacity-50 flex items-center justify-center"
            >
              {optimizeMutation.isPending ? (
                <>
                  <CpuChipIcon className="w-5 h-5 mr-2 animate-spin" />
                  Optimizing...
                </>
              ) : (
                <>
                  <RocketLaunchIcon className="w-5 h-5 mr-2" />
                  Optimize Budget
                </>
              )}
            </button>
          </div>
        </div>

        {/* Results Panel */}
        <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-6">
          <div className="flex items-center mb-6">
            <div className="w-12 h-12 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl flex items-center justify-center mr-4">
              <ChartBarIcon className="w-6 h-6 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-semibold">Optimization Results</h2>
              <p className="text-gray-600">AI-powered recommendations and insights</p>
            </div>
          </div>

          {optimization ? (
            <div className="space-y-6">
              {/* Overview Cards */}
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-gradient-to-br from-blue-50 to-indigo-50 p-4 rounded-xl border border-blue-100">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-sm text-blue-600 font-semibold">Budget Utilization</div>
                      <div className="text-2xl font-bold text-blue-900">
                        {optimization.budgetUtilization}%
                      </div>
                    </div>
                    <BanknotesIcon className="w-8 h-8 text-blue-500" />
                  </div>
                </div>

                <div className="bg-gradient-to-br from-green-50 to-emerald-50 p-4 rounded-xl border border-green-100">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-sm text-green-600 font-semibold">Expected ROAS</div>
                      <div className="text-2xl font-bold text-green-900">
                        {optimization.expectedPerformanceImprovement.roas.toFixed(2)}x
                      </div>
                    </div>
                    <ArrowTrendingUpIcon className="w-8 h-8 text-green-500" />
                  </div>
                </div>
              </div>

              {/* Risk Analysis */}
              <div className={`p-4 rounded-xl border-l-4 ${
                optimization.riskAnalysis.overallRisk === 'high' ? 'border-red-500 bg-red-50' :
                optimization.riskAnalysis.overallRisk === 'medium' ? 'border-yellow-500 bg-yellow-50' :
                'border-green-500 bg-green-50'
              }`}>
                <div className="flex items-center mb-2">
                  <ShieldCheckIcon className={`w-5 h-5 mr-2 ${
                    optimization.riskAnalysis.overallRisk === 'high' ? 'text-red-500' :
                    optimization.riskAnalysis.overallRisk === 'medium' ? 'text-yellow-500' :
                    'text-green-500'
                  }`} />
                  <span className="font-semibold">
                    Risk Level: {optimization.riskAnalysis.overallRisk.toUpperCase()}
                  </span>
                </div>
                <div className="text-sm space-y-1">
                  {optimization.riskAnalysis.recommendations.map((rec: string, i: number) => (
                    <div key={i}>• {rec}</div>
                  ))}
                </div>
              </div>

              {/* Campaign Recommendations */}
              <div>
                <h3 className="font-semibold mb-4 flex items-center">
                  <LightBulbIcon className="w-5 h-5 mr-2 text-yellow-500" />
                  Campaign Recommendations
                </h3>
                <div className="space-y-3 max-h-96 overflow-y-auto">
                  {optimization.recommendations.map((rec: any) => (
                    <div key={rec.campaignId} className="border border-gray-200 rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <span className="font-medium">{rec.campaignName}</span>
                        <div className="flex items-center space-x-2">
                          {rec.budgetChangePercent > 0 ? (
                            <ArrowUpIcon className="w-4 h-4 text-green-500" />
                          ) : rec.budgetChangePercent < 0 ? (
                            <ArrowDownIcon className="w-4 h-4 text-red-500" />
                          ) : null}
                          <span className={`text-sm font-semibold ${
                            rec.budgetChangePercent > 0 ? 'text-green-600' : 
                            rec.budgetChangePercent < 0 ? 'text-red-600' : 'text-gray-600'
                          }`}>
                            {rec.budgetChangePercent > 0 ? '+' : ''}{rec.budgetChangePercent.toFixed(1)}%
                          </span>
                        </div>
                      </div>
                      
                      <div className="grid grid-cols-2 gap-4 mb-3">
                        <div>
                          <div className="text-xs text-gray-500">Current</div>
                          <div className="font-semibold">${rec.currentBudget.toLocaleString()}</div>
                        </div>
                        <div>
                          <div className="text-xs text-gray-500">Recommended</div>
                          <div className="font-semibold text-blue-600">${rec.recommendedBudget.toLocaleString()}</div>
                        </div>
                      </div>

                      <div className="text-sm space-y-1">
                        {rec.reasoning.map((reason: string, i: number) => (
                          <div key={i} className="text-gray-600">• {reason}</div>
                        ))}
                      </div>

                      <div className="mt-3 pt-3 border-t border-gray-100">
                        <div className="grid grid-cols-3 gap-2 text-xs">
                          <div>
                            <div className="text-gray-500">Expected Revenue</div>
                            <div className="font-semibold text-green-600">
                              ${rec.predictedMetrics.expectedRevenue.toLocaleString()}
                            </div>
                          </div>
                          <div>
                            <div className="text-gray-500">Expected ROAS</div>
                            <div className="font-semibold">
                              {rec.predictedMetrics.expectedROAS.toFixed(2)}x
                            </div>
                          </div>
                          <div>
                            <div className="text-gray-500">Confidence</div>
                            <div className="font-semibold">{rec.confidence.toFixed(0)}%</div>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-12">
              <CpuChipIcon className="w-16 h-16 text-gray-300 mx-auto mb-4" />
              <p className="text-gray-500">
                Run budget optimization to see AI-powered recommendations
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}