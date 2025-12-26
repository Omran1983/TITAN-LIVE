'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'react-hot-toast'
import {
  QueueListIcon,
  PlayIcon,
  PauseIcon,
  StopIcon,
  ClockIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  XCircleIcon,
  ArrowPathIcon,
  EyeIcon,
  TrashIcon,
  FunnelIcon,
  PlusIcon,
  CpuChipIcon,
  ChartBarIcon,
  ServerIcon,
  BoltIcon
} from '@heroicons/react/24/outline'
import { useQueueJobs, useQueueStats, useQueueMetrics, useQueueWorkers, useCreateJob } from '@/lib/hooks'
import { queueApi } from '@/lib/api'

interface QueueItem {
  id: string
  title: string
  type: 'campaign' | 'creative' | 'analytics' | 'export' | 'import'
  status: 'pending' | 'running' | 'completed' | 'failed' | 'paused'
  progress: number
  startTime?: string
  endTime?: string
  duration?: string
  client?: string
  priority: 'low' | 'medium' | 'high' | 'critical'
  details?: string
  logs?: string[]
}

const mockQueueItems: QueueItem[] = [
  {
    id: '1',
    title: 'Generate Campaign Creatives - TechFlow',
    type: 'creative',
    status: 'running',
    progress: 67,
    startTime: '2024-03-15T10:30:00Z',
    client: 'TechFlow Solutions',
    priority: 'high',
    details: 'Generating 12 banner variations for summer campaign',
    logs: ['Started creative generation process', 'Generated 8/12 banners', 'Processing remaining variants...']
  },
  {
    id: '2',
    title: 'Export Analytics Report - GreenLeaf',
    type: 'export',
    status: 'completed',
    progress: 100,
    startTime: '2024-03-15T09:15:00Z',
    endTime: '2024-03-15T09:18:00Z',
    duration: '3 minutes',
    client: 'GreenLeaf Organics',
    priority: 'medium',
    details: 'Monthly performance report exported to PDF',
    logs: ['Started report generation', 'Collected data from all campaigns', 'Generated charts and visualizations', 'Export completed successfully']
  },
  {
    id: '3',
    title: 'Campaign Performance Analysis',
    type: 'analytics',
    status: 'pending',
    progress: 0,
    client: 'Urban Fashion Co.',
    priority: 'critical',
    details: 'Deep analysis of Q1 campaign performance',
    logs: ['Queued for processing']
  },
  {
    id: '4',
    title: 'Bulk Product Import',
    type: 'import',
    status: 'failed',
    progress: 45,
    startTime: '2024-03-15T08:00:00Z',
    endTime: '2024-03-15T08:12:00Z',
    duration: '12 minutes',
    priority: 'medium',
    details: 'Import failed due to data validation errors',
    logs: ['Started import process', 'Processed 450/1000 products', 'Validation error: Invalid SKU format', 'Import process terminated']
  },
  {
    id: '5',
    title: 'A/B Test Campaign Launch',
    type: 'campaign',
    status: 'paused',
    progress: 25,
    startTime: '2024-03-15T07:45:00Z',
    client: 'TechFlow Solutions',
    priority: 'high',
    details: 'Campaign launch paused for review',
    logs: ['Campaign setup initiated', 'A/B variants created', 'Paused for manual review']
  }
]

export default function QueuePage() {
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [typeFilter, setTypeFilter] = useState<string>('all')
  const [selectedJobs, setSelectedJobs] = useState<string[]>([])
  const [showCreateJob, setShowCreateJob] = useState(false)
  const [activeTab, setActiveTab] = useState<'jobs' | 'stats' | 'workers'>('jobs')
  const [queueItems, setQueueItems] = useState<QueueItem[]>(mockQueueItems)
  const [selectedItem, setSelectedItem] = useState<QueueItem | null>(null)
  const queryClient = useQueryClient()

  // Fetch data using enhanced hooks
  const { data: jobsData } = useQueueJobs({
    status: statusFilter !== 'all' ? [statusFilter] : undefined,
    type: typeFilter !== 'all' ? [typeFilter] : undefined
  })
  
  const { data: statsData } = useQueueStats()
  const { data: metricsData } = useQueueMetrics('24h')
  const { data: workersData } = useQueueWorkers()
  const createJobMutation = useCreateJob()



  const jobs = jobsData?.jobs || []
  const stats = statsData?.stats || {}
  const metrics = metricsData?.metrics || {}
  const workers = workersData?.workers || {}

  // Filter queue items based on status and type
  const filteredItems = queueItems.filter(item => {
    const statusMatch = statusFilter === 'all' || item.status === statusFilter
    const typeMatch = typeFilter === 'all' || item.type === typeFilter
    return statusMatch && typeMatch
  })

  const activeJobs = filteredItems.filter(item => item.status === 'running').length
  const completedJobs = filteredItems.filter(item => item.status === 'completed').length
  const failedJobs = filteredItems.filter(item => item.status === 'failed').length

  // Job action mutations
  const pauseJobMutation = useMutation({
    mutationFn: (jobId: string) => queueApi.pauseJob(jobId).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('Job paused successfully')
    },
    onError: () => toast.error('Failed to pause job')
  })

  const resumeJobMutation = useMutation({
    mutationFn: (jobId: string) => queueApi.resumeJob(jobId).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('Job resumed successfully')
    },
    onError: () => toast.error('Failed to resume job')
  })

  const retryJobMutation = useMutation({
    mutationFn: (jobId: string) => queueApi.retryJob(jobId).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('Job retry initiated')
    },
    onError: () => toast.error('Failed to retry job')
  })

  const deleteJobMutation = useMutation({
    mutationFn: (jobId: string) => queueApi.deleteJob(jobId).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success('Job deleted successfully')
    },
    onError: () => toast.error('Failed to delete job')
  })

  // Bulk operations
  const bulkPauseMutation = useMutation({
    mutationFn: (jobIds: string[]) => queueApi.bulkPause(jobIds).then(res => res.data),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success(`Paused ${data.result.succeeded.length} jobs successfully`)
    }
  })

  const bulkRetryMutation = useMutation({
    mutationFn: (jobIds: string[]) => queueApi.bulkRetry(jobIds).then(res => res.data),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['queue'] })
      toast.success(`Retried ${data.result.succeeded.length} jobs successfully`)
    }
  })

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'running':
        return <ArrowPathIcon className="w-4 h-4 text-blue-500 animate-spin" />
      case 'completed':
        return <CheckCircleIcon className="w-4 h-4 text-green-500" />
      case 'failed':
        return <XCircleIcon className="w-4 h-4 text-red-500" />
      case 'paused':
        return <PauseIcon className="w-4 h-4 text-yellow-500" />
      case 'pending':
        return <ClockIcon className="w-4 h-4 text-gray-500" />
      default:
        return <ClockIcon className="w-4 h-4 text-gray-500" />
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'running':
        return 'bg-blue-100 text-blue-800'
      case 'completed':
        return 'status-active'
      case 'failed':
        return 'bg-red-100 text-red-800'
      case 'paused':
        return 'status-pending'
      case 'pending':
        return 'bg-gray-100 text-gray-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getPriorityBadge = (priority: string) => {
    switch (priority) {
      case 'critical':
        return 'bg-red-100 text-red-800 border border-red-200'
      case 'high':
        return 'bg-orange-100 text-orange-800 border border-orange-200'
      case 'medium':
        return 'bg-blue-100 text-blue-800 border border-blue-200'
      case 'low':
        return 'bg-gray-100 text-gray-800 border border-gray-200'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'campaign':
        return '🚀'
      case 'creative':
        return '🎨'
      case 'analytics':
        return '📊'
      case 'export':
        return '📤'
      case 'import':
        return '📥'
      default:
        return '⚙️'
    }
  }

  const handleAction = (itemId: string, action: 'pause' | 'resume' | 'stop' | 'retry' | 'delete') => {
    setQueueItems(items => 
      items.map(item => {
        if (item.id === itemId) {
          switch (action) {
            case 'pause':
              return { ...item, status: 'paused' as const }
            case 'resume':
              return { ...item, status: 'running' as const }
            case 'stop':
              return { ...item, status: 'failed' as const, progress: 0 }
            case 'retry':
              return { ...item, status: 'pending' as const, progress: 0 }
            default:
              return item
          }
        }
        return item
      }).filter(item => action !== 'delete' || item.id !== itemId)
    )
  }

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
                  <QueueListIcon className="w-8 h-8 text-white" />
                </div>
                <div>
                  <h1 className="text-display">Process Queue</h1>
                  <p className="text-body text-gray-600 mt-2">
                    Monitor background tasks and automated processes • {filteredItems.length} items
                  </p>
                </div>
              </div>
              
              <div className="flex items-center space-x-6 text-sm">
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <ArrowPathIcon className="w-4 h-4 text-blue-500 animate-spin" />
                  <span className="font-semibold">{activeJobs} Running</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <CheckCircleIcon className="w-4 h-4 text-green-500" />
                  <span className="font-semibold">{completedJobs} Completed</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <XCircleIcon className="w-4 h-4 text-red-500" />
                  <span className="font-semibold">{failedJobs} Failed</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="surface-elevated p-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex items-center space-x-4">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="form-input w-40"
            >
              <option value="all">All Status</option>
              <option value="running">Running</option>
              <option value="pending">Pending</option>
              <option value="completed">Completed</option>
              <option value="failed">Failed</option>
              <option value="paused">Paused</option>
            </select>
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="form-input w-40"
            >
              <option value="all">All Types</option>
              <option value="campaign">Campaigns</option>
              <option value="creative">Creative</option>
              <option value="analytics">Analytics</option>
              <option value="export">Exports</option>
              <option value="import">Imports</option>
            </select>
          </div>
          <button className="btn-secondary flex items-center space-x-2">
            <FunnelIcon className="w-4 h-4" />
            <span>Advanced Filters</span>
          </button>
        </div>
      </div>

      {/* Queue Items */}
      <div className="space-y-4">
        {filteredItems.map((item, index) => (
          <div
            key={item.id}
            className="surface-elevated-high hover-lift"
            style={{ animationDelay: `${index * 50}ms` }}
          >
            <div className="p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center space-x-4">
                  <div className="text-2xl">{getTypeIcon(item.type)}</div>
                  <div>
                    <h3 className="text-title font-bold text-gray-900">{item.title}</h3>
                    <div className="flex items-center space-x-3 mt-1">
                      {item.client && (
                        <span className="text-sm text-blue-600 font-medium">{item.client}</span>
                      )}
                      <span className={`status-badge ${getStatusBadge(item.status)} text-xs`}>
                        {item.status}
                      </span>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${getPriorityBadge(item.priority)}`}>
                        {item.priority}
                      </span>
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center space-x-2">
                  {getStatusIcon(item.status)}
                  <div className="flex space-x-1">
                    {item.status === 'running' && (
                      <button
                        onClick={() => handleAction(item.id, 'pause')}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="Pause"
                      >
                        <PauseIcon className="w-4 h-4 text-gray-600" />
                      </button>
                    )}
                    {item.status === 'paused' && (
                      <button
                        onClick={() => handleAction(item.id, 'resume')}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="Resume"
                      >
                        <PlayIcon className="w-4 h-4 text-gray-600" />
                      </button>
                    )}
                    {(item.status === 'running' || item.status === 'paused') && (
                      <button
                        onClick={() => handleAction(item.id, 'stop')}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="Stop"
                      >
                        <StopIcon className="w-4 h-4 text-gray-600" />
                      </button>
                    )}
                    {item.status === 'failed' && (
                      <button
                        onClick={() => handleAction(item.id, 'retry')}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="Retry"
                      >
                        <ArrowPathIcon className="w-4 h-4 text-gray-600" />
                      </button>
                    )}
                    <button
                      onClick={() => setSelectedItem(item)}
                      className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                      title="View Details"
                    >
                      <EyeIcon className="w-4 h-4 text-gray-600" />
                    </button>
                    <button
                      onClick={() => handleAction(item.id, 'delete')}
                      className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                      title="Delete"
                    >
                      <TrashIcon className="w-4 h-4 text-gray-600" />
                    </button>
                  </div>
                </div>
              </div>

              {/* Progress Bar */}
              {item.progress > 0 && (
                <div className="mb-4">
                  <div className="flex justify-between text-sm mb-2">
                    <span className="font-medium">Progress</span>
                    <span className="text-gray-600">{item.progress}%</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full transition-all duration-300 ${
                        item.status === 'completed' ? 'bg-gradient-to-r from-green-500 to-emerald-600' :
                        item.status === 'failed' ? 'bg-gradient-to-r from-red-500 to-pink-600' :
                        'bg-gradient-to-r from-blue-500 to-purple-600'
                      }`}
                      style={{ width: `${item.progress}%` }}
                    ></div>
                  </div>
                </div>
              )}

              {/* Details */}
              <p className="text-body text-sm mb-4">{item.details}</p>

              {/* Time Information */}
              <div className="flex items-center justify-between text-xs text-gray-500">
                <div className="flex items-center space-x-4">
                  {item.startTime && (
                    <span>Started: {new Date(item.startTime).toLocaleString()}</span>
                  )}
                  {item.endTime && (
                    <span>Ended: {new Date(item.endTime).toLocaleString()}</span>
                  )}
                  {item.duration && (
                    <span>Duration: {item.duration}</span>
                  )}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Details Modal */}
      {selectedItem && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="surface-premium max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h2 className="text-headline">{selectedItem.title}</h2>
                <button
                  onClick={() => setSelectedItem(null)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ×
                </button>
              </div>
            </div>
            <div className="p-6">
              <div className="space-y-4">
                <div>
                  <h3 className="font-semibold mb-2">Status</h3>
                  <span className={`status-badge ${getStatusBadge(selectedItem.status)}`}>
                    {selectedItem.status}
                  </span>
                </div>
                <div>
                  <h3 className="font-semibold mb-2">Progress</h3>
                  <div className="text-sm text-gray-600">{selectedItem.progress}%</div>
                </div>
                {selectedItem.logs && (
                  <div>
                    <h3 className="font-semibold mb-2">Logs</h3>
                    <div className="bg-gray-900 text-green-400 p-4 rounded-lg font-mono text-sm max-h-40 overflow-y-auto">
                      {selectedItem.logs.map((log, index) => (
                        <div key={index}>[{new Date().toLocaleTimeString()}] {log}</div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Empty State */}
      {filteredItems.length === 0 && (
        <div className="surface-elevated p-12 text-center">
          <QueueListIcon className="w-16 h-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-headline text-gray-600 mb-2">No queue items found</h3>
          <p className="text-body text-gray-500">
            Background processes will appear here when they are running.
          </p>
        </div>
      )}
    </div>
  )
}