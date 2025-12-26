'use client'

import { useState } from 'react'
import {
  DocumentTextIcon,
  MagnifyingGlassIcon,
  FunnelIcon,
  CalendarIcon,
  UserIcon,
  CogIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
  InformationCircleIcon,
  ShieldCheckIcon,
  EyeIcon
} from '@heroicons/react/24/outline'

interface AuditLog {
  id: string
  timestamp: string
  user: string
  action: string
  resource: string
  details: string
  ip: string
  status: 'success' | 'warning' | 'error' | 'info'
  category: 'auth' | 'campaign' | 'system' | 'user' | 'data'
}

const mockAuditLogs: AuditLog[] = [
  {
    id: '1',
    timestamp: '2024-03-15T14:30:25Z',
    user: 'john.doe@example.com',
    action: 'Campaign Created',
    resource: 'Summer Sale 2024',
    details: 'Created new campaign with budget $50,000',
    ip: '192.168.1.100',
    status: 'success',
    category: 'campaign'
  },
  {
    id: '2',
    timestamp: '2024-03-15T14:28:15Z',
    user: 'admin@example.com',
    action: 'User Login',
    resource: 'Authentication System',
    details: 'Successful login from admin dashboard',
    ip: '192.168.1.105',
    status: 'success',
    category: 'auth'
  },
  {
    id: '3',
    timestamp: '2024-03-15T14:25:42Z',
    user: 'system',
    action: 'Data Export',
    resource: 'Analytics Report',
    details: 'Monthly analytics report exported to PDF',
    ip: 'localhost',
    status: 'success',
    category: 'data'
  },
  {
    id: '4',
    timestamp: '2024-03-15T14:22:33Z',
    user: 'sarah.johnson@example.com',
    action: 'Budget Update',
    resource: 'TechFlow Campaign',
    details: 'Budget increased from $25,000 to $35,000',
    ip: '192.168.1.102',
    status: 'warning',
    category: 'campaign'
  },
  {
    id: '5',
    timestamp: '2024-03-15T14:20:18Z',
    user: 'system',
    action: 'Backup Failed',
    resource: 'Database Backup',
    details: 'Automated backup failed - disk space insufficient',
    ip: 'localhost',
    status: 'error',
    category: 'system'
  },
  {
    id: '6',
    timestamp: '2024-03-15T14:18:07Z',
    user: 'mike.chen@example.com',
    action: 'Client Added',
    resource: 'GreenLeaf Organics',
    details: 'New client onboarded with initial budget $150,000',
    ip: '192.168.1.103',
    status: 'success',
    category: 'user'
  },
  {
    id: '7',
    timestamp: '2024-03-15T14:15:52Z',
    user: 'system',
    action: 'Security Scan',
    resource: 'Platform Security',
    details: 'Weekly security scan completed - no threats detected',
    ip: 'localhost',
    status: 'info',
    category: 'system'
  }
]

export default function AuditPage() {
  const [logs, setLogs] = useState<AuditLog[]>(mockAuditLogs)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [categoryFilter, setCategoryFilter] = useState<string>('all')
  const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null)

  const filteredLogs = logs.filter(log => {
    const matchesSearch = log.action.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         log.user.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         log.resource.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = statusFilter === 'all' || log.status === statusFilter
    const matchesCategory = categoryFilter === 'all' || log.category === categoryFilter
    return matchesSearch && matchesStatus && matchesCategory
  })

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'success':
        return <CheckCircleIcon className="w-4 h-4 text-green-500" />
      case 'warning':
        return <ExclamationTriangleIcon className="w-4 h-4 text-yellow-500" />
      case 'error':
        return <ExclamationTriangleIcon className="w-4 h-4 text-red-500" />
      case 'info':
        return <InformationCircleIcon className="w-4 h-4 text-blue-500" />
      default:
        return <InformationCircleIcon className="w-4 h-4 text-gray-500" />
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'success':
        return 'status-active'
      case 'warning':
        return 'status-pending'
      case 'error':
        return 'bg-red-100 text-red-800'
      case 'info':
        return 'bg-blue-100 text-blue-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'auth':
        return '🔐'
      case 'campaign':
        return '🚀'
      case 'system':
        return '⚙️'
      case 'user':
        return '👤'
      case 'data':
        return '📊'
      default:
        return '📋'
    }
  }

  const summaryStats = {
    total: logs.length,
    success: logs.filter(l => l.status === 'success').length,
    warnings: logs.filter(l => l.status === 'warning').length,
    errors: logs.filter(l => l.status === 'error').length,
    info: logs.filter(l => l.status === 'info').length
  }

  return (
    <div className="animate-slide-up space-y-8">
      {/* Premium Header */}
      <div className="surface-premium p-8 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-gray-500/20 via-blue-500/20 to-purple-500/20 animate-gradient-flow"></div>
        <div className="relative z-10">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center space-x-4 mb-4">
                <div className="w-16 h-16 bg-gradient-to-br from-gray-600 to-blue-600 rounded-2xl flex items-center justify-center shadow-lg">
                  <DocumentTextIcon className="w-8 h-8 text-white" />
                </div>
                <div>
                  <h1 className="text-display">System Audit Logs</h1>
                  <p className="text-body text-gray-600 mt-2">
                    Track all system activities and user actions • {filteredLogs.length} entries
                  </p>
                </div>
              </div>
              
              <div className="flex items-center space-x-6 text-sm">
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <CheckCircleIcon className="w-4 h-4 text-green-500" />
                  <span className="font-semibold">{summaryStats.success} Success</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <ExclamationTriangleIcon className="w-4 h-4 text-yellow-500" />
                  <span className="font-semibold">{summaryStats.warnings} Warnings</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <ExclamationTriangleIcon className="w-4 h-4 text-red-500" />
                  <span className="font-semibold">{summaryStats.errors} Errors</span>
                </div>
              </div>
            </div>
            
            <div className="flex space-x-3">
              <button className="btn-secondary flex items-center space-x-2">
                <CalendarIcon className="w-5 h-5" />
                <span>Date Range</span>
              </button>
              <button className="btn-premium flex items-center space-x-2">
                <ShieldCheckIcon className="w-5 h-5" />
                <span>Security Report</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="surface-elevated p-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1 relative">
            <MagnifyingGlassIcon className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search logs by action, user, or resource..."
              className="form-input pl-12 w-full"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div className="flex items-center space-x-4">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="form-input w-40"
            >
              <option value="all">All Status</option>
              <option value="success">Success</option>
              <option value="warning">Warning</option>
              <option value="error">Error</option>
              <option value="info">Info</option>
            </select>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="form-input w-40"
            >
              <option value="all">All Categories</option>
              <option value="auth">Authentication</option>
              <option value="campaign">Campaigns</option>
              <option value="system">System</option>
              <option value="user">Users</option>
              <option value="data">Data</option>
            </select>
            <button className="btn-secondary flex items-center space-x-2">
              <FunnelIcon className="w-4 h-4" />
              <span>Advanced</span>
            </button>
          </div>
        </div>
      </div>

      {/* Audit Logs Table */}
      <div className="surface-elevated-high">
        <div className="p-6 border-b border-gray-100">
          <h2 className="text-headline">Activity Log</h2>
          <p className="text-body mt-1">Chronological list of all system activities</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Timestamp</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Resource</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredLogs.map((log, index) => (
                <tr 
                  key={log.id} 
                  className="hover:bg-gray-50 transition-colors"
                  style={{ animationDelay: `${index * 50}ms` }}
                >
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-2">
                      {getStatusIcon(log.status)}
                      <span className={`status-badge ${getStatusBadge(log.status)} text-xs`}>
                        {log.status}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {new Date(log.timestamp).toLocaleString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-2">
                      <UserIcon className="w-4 h-4 text-gray-400" />
                      <span className="text-sm text-gray-900">{log.user}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{log.action}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{log.resource}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-2">
                      <span className="text-lg">{getCategoryIcon(log.category)}</span>
                      <span className="text-sm text-gray-600 capitalize">{log.category}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <button
                      onClick={() => setSelectedLog(log)}
                      className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                      title="View Details"
                    >
                      <EyeIcon className="w-4 h-4 text-gray-600" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Log Details Modal */}
      {selectedLog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="surface-premium max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="text-2xl">{getCategoryIcon(selectedLog.category)}</div>
                  <h2 className="text-headline">{selectedLog.action}</h2>
                </div>
                <button
                  onClick={() => setSelectedLog(null)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ×
                </button>
              </div>
            </div>
            <div className="p-6 space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <h3 className="font-semibold text-sm text-gray-500 uppercase tracking-wider mb-2">Status</h3>
                  <div className="flex items-center space-x-2">
                    {getStatusIcon(selectedLog.status)}
                    <span className={`status-badge ${getStatusBadge(selectedLog.status)}`}>
                      {selectedLog.status}
                    </span>
                  </div>
                </div>
                <div>
                  <h3 className="font-semibold text-sm text-gray-500 uppercase tracking-wider mb-2">Category</h3>
                  <div className="flex items-center space-x-2">
                    <span className="text-lg">{getCategoryIcon(selectedLog.category)}</span>
                    <span className="text-sm text-gray-900 capitalize">{selectedLog.category}</span>
                  </div>
                </div>
                <div>
                  <h3 className="font-semibold text-sm text-gray-500 uppercase tracking-wider mb-2">User</h3>
                  <div className="flex items-center space-x-2">
                    <UserIcon className="w-4 h-4 text-gray-400" />
                    <span className="text-sm text-gray-900">{selectedLog.user}</span>
                  </div>
                </div>
                <div>
                  <h3 className="font-semibold text-sm text-gray-500 uppercase tracking-wider mb-2">IP Address</h3>
                  <span className="text-sm text-gray-900 font-mono">{selectedLog.ip}</span>
                </div>
                <div className="col-span-2">
                  <h3 className="font-semibold text-sm text-gray-500 uppercase tracking-wider mb-2">Timestamp</h3>
                  <span className="text-sm text-gray-900">{new Date(selectedLog.timestamp).toLocaleString()}</span>
                </div>
              </div>
              
              <div>
                <h3 className="font-semibold text-sm text-gray-500 uppercase tracking-wider mb-2">Resource</h3>
                <span className="text-sm text-gray-900">{selectedLog.resource}</span>
              </div>
              
              <div>
                <h3 className="font-semibold text-sm text-gray-500 uppercase tracking-wider mb-2">Details</h3>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-sm text-gray-900">{selectedLog.details}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Empty State */}
      {filteredLogs.length === 0 && (
        <div className="surface-elevated p-12 text-center">
          <DocumentTextIcon className="w-16 h-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-headline text-gray-600 mb-2">No audit logs found</h3>
          <p className="text-body text-gray-500">
            {searchTerm || statusFilter !== 'all' || categoryFilter !== 'all'
              ? 'Try adjusting your search criteria or filters.'
              : 'System activity logs will appear here as actions are performed.'}
          </p>
        </div>
      )}
    </div>
  )
}