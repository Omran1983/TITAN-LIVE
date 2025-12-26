'use client'

import { useState, useEffect } from 'react'
import {
  PlusIcon,
  MagnifyingGlassIcon,
  FunnelIcon,
  EllipsisVerticalIcon,
  UserGroupIcon,
  BanknotesIcon,
  ChartBarIcon,
  CalendarIcon,
  PhoneIcon,
  EnvelopeIcon,
  GlobeAltIcon,
  BuildingOfficeIcon,
  TrophyIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
  ClockIcon,
  SparklesIcon
} from '@heroicons/react/24/outline'

interface Client {
  id: string
  name: string
  company: string
  email: string
  phone: string
  website?: string
  industry: string
  status: 'active' | 'inactive' | 'pending' | 'paused'
  totalBudget: number
  spentBudget: number
  activeCampaigns: number
  totalCampaigns: number
  joinDate: string
  lastActivity: string
  roi: number
  priority: 'low' | 'medium' | 'high' | 'critical'
  avatar?: string
  contactPerson?: string
  location?: string
}

const mockClients: Client[] = [
  {
    id: '1',
    name: 'TechFlow Solutions',
    company: 'TechFlow Inc.',
    email: 'contact@techflow.com',
    phone: '+1 (555) 123-4567',
    website: 'https://techflow.com',
    industry: 'Technology',
    status: 'active',
    totalBudget: 250000,
    spentBudget: 187500,
    activeCampaigns: 3,
    totalCampaigns: 12,
    joinDate: '2024-01-15',
    lastActivity: '2024-03-15',
    roi: 245.8,
    priority: 'high',
    contactPerson: 'Sarah Johnson',
    location: 'San Francisco, CA'
  },
  {
    id: '2',
    name: 'GreenLeaf Organics',
    company: 'GreenLeaf Ltd.',
    email: 'marketing@greenleaf.com',
    phone: '+1 (555) 987-6543',
    website: 'https://greenleaf.com',
    industry: 'Food & Beverage',
    status: 'active',
    totalBudget: 150000,
    spentBudget: 98000,
    activeCampaigns: 2,
    totalCampaigns: 8,
    joinDate: '2024-02-20',
    lastActivity: '2024-03-14',
    roi: 198.4,
    priority: 'medium',
    contactPerson: 'Mike Chen',
    location: 'Austin, TX'
  },
  {
    id: '3',
    name: 'Urban Fashion Co.',
    company: 'Urban Fashion',
    email: 'hello@urbanfashion.com',
    phone: '+1 (555) 456-7890',
    website: 'https://urbanfashion.com',
    industry: 'Fashion & Retail',
    status: 'pending',
    totalBudget: 300000,
    spentBudget: 0,
    activeCampaigns: 0,
    totalCampaigns: 0,
    joinDate: '2024-03-10',
    lastActivity: '2024-03-10',
    roi: 0,
    priority: 'critical',
    contactPerson: 'Emma Davis',
    location: 'New York, NY'
  }
]

export default function ClientsPage() {
  const [clients, setClients] = useState<Client[]>(mockClients)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [showAddClient, setShowAddClient] = useState(false)
  const [loading, setLoading] = useState(false)

  const filteredClients = clients.filter(client => {
    const matchesSearch = client.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         client.company.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         client.email.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = statusFilter === 'all' || client.status === statusFilter
    return matchesSearch && matchesStatus
  })

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return 'status-active'
      case 'inactive':
        return 'status-inactive'
      case 'pending':
        return 'status-pending'
      case 'paused':
        return 'bg-yellow-100 text-yellow-800'
      default:
        return 'status-inactive'
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

  const calculateBudgetPercentage = (spent: number, total: number) => {
    return total > 0 ? Math.round((spent / total) * 100) : 0
  }

  return (
    <div className="animate-slide-up space-y-8">
      {/* Premium Header */}
      <div className="surface-premium p-8 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-500/20 via-purple-500/20 to-pink-500/20 animate-gradient-flow"></div>
        <div className="relative z-10">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center space-x-4 mb-4">
                <div className="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center shadow-lg">
                  <UserGroupIcon className="w-8 h-8 text-white" />
                </div>
                <div>
                  <h1 className="text-display">Client Portfolio</h1>
                  <p className="text-body text-gray-600 mt-2">
                    Manage your marketing clients and campaigns • {filteredClients.length} total clients
                  </p>
                </div>
              </div>
              
              <div className="flex items-center space-x-6 text-sm">
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <CheckCircleIcon className="w-4 h-4 text-green-500" />
                  <span className="font-semibold">{clients.filter(c => c.status === 'active').length} Active</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <BanknotesIcon className="w-4 h-4 text-blue-500" />
                  <span className="font-semibold">${clients.reduce((sum, c) => sum + c.totalBudget, 0).toLocaleString()} Total Budget</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <TrophyIcon className="w-4 h-4 text-yellow-500" />
                  <span className="font-semibold">{Math.round(clients.reduce((sum, c) => sum + c.roi, 0) / clients.length)}% Avg ROI</span>
                </div>
              </div>
            </div>
            
            <button
              onClick={() => setShowAddClient(true)}
              className="btn-premium flex items-center space-x-2"
            >
              <PlusIcon className="w-5 h-5" />
              <span>Add New Client</span>
            </button>
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
              placeholder="Search clients by name, company, or email..."
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
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="pending">Pending</option>
              <option value="paused">Paused</option>
            </select>
            <button className="btn-secondary flex items-center space-x-2">
              <FunnelIcon className="w-4 h-4" />
              <span>Filters</span>
            </button>
          </div>
        </div>
      </div>

      {/* Client Cards Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
        {filteredClients.map((client, index) => (
          <div
            key={client.id}
            className="surface-elevated-high hover-lift group"
            style={{ animationDelay: `${index * 100}ms` }}
          >
            {/* Client Header */}
            <div className="p-6 border-b border-gray-100">
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center space-x-3">
                  <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center text-white font-bold text-lg shadow-lg">
                    {client.name.charAt(0)}
                  </div>
                  <div>
                    <h3 className="text-title font-bold text-gray-900 group-hover:text-blue-600 transition-colors">
                      {client.name}
                    </h3>
                    <p className="text-sm text-gray-600">{client.company}</p>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <span className={`status-badge ${getStatusBadge(client.status)} text-xs`}>
                    {client.status}
                  </span>
                  <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                    <EllipsisVerticalIcon className="w-4 h-4 text-gray-400" />
                  </button>
                </div>
              </div>

              {/* Priority and Industry */}
              <div className="flex items-center justify-between">
                <span className={`px-3 py-1 rounded-full text-xs font-medium ${getPriorityBadge(client.priority)}`}>
                  {client.priority} priority
                </span>
                <span className="text-xs text-gray-500 px-2 py-1 bg-gray-50 rounded-full">
                  {client.industry}
                </span>
              </div>
            </div>

            {/* Client Stats */}
            <div className="p-6 space-y-4">
              {/* Budget Progress */}
              <div>
                <div className="flex justify-between text-sm mb-2">
                  <span className="font-medium">Budget Usage</span>
                  <span className="text-gray-600">
                    ${client.spentBudget.toLocaleString()} / ${client.totalBudget.toLocaleString()}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className="bg-gradient-to-r from-blue-500 to-purple-600 h-2 rounded-full transition-all duration-300"
                    style={{ width: `${calculateBudgetPercentage(client.spentBudget, client.totalBudget)}%` }}
                  ></div>
                </div>
                <div className="text-xs text-gray-500 mt-1">
                  {calculateBudgetPercentage(client.spentBudget, client.totalBudget)}% utilized
                </div>
              </div>

              {/* Key Metrics */}
              <div className="grid grid-cols-2 gap-4">
                <div className="text-center p-3 bg-blue-50 rounded-xl">
                  <div className="text-lg font-bold text-blue-600">{client.activeCampaigns}</div>
                  <div className="text-xs text-blue-500">Active Campaigns</div>
                </div>
                <div className="text-center p-3 bg-green-50 rounded-xl">
                  <div className="text-lg font-bold text-green-600">{client.roi}%</div>
                  <div className="text-xs text-green-500">ROI</div>
                </div>
              </div>

              {/* Contact Information */}
              <div className="space-y-2 pt-4 border-t border-gray-100">
                <div className="flex items-center space-x-2 text-sm text-gray-600">
                  <EnvelopeIcon className="w-4 h-4" />
                  <span className="truncate">{client.email}</span>
                </div>
                <div className="flex items-center space-x-2 text-sm text-gray-600">
                  <PhoneIcon className="w-4 h-4" />
                  <span>{client.phone}</span>
                </div>
                {client.contactPerson && (
                  <div className="flex items-center space-x-2 text-sm text-gray-600">
                    <UserGroupIcon className="w-4 h-4" />
                    <span>{client.contactPerson}</span>
                  </div>
                )}
                {client.location && (
                  <div className="flex items-center space-x-2 text-sm text-gray-600">
                    <BuildingOfficeIcon className="w-4 h-4" />
                    <span>{client.location}</span>
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              <div className="flex space-x-2 pt-4">
                <button className="flex-1 btn-primary text-sm py-2">
                  View Details
                </button>
                <button className="flex-1 btn-secondary text-sm py-2">
                  Manage Campaigns
                </button>
              </div>
            </div>

            {/* Last Activity */}
            <div className="px-6 py-3 bg-gray-50 border-t border-gray-100">
              <div className="flex items-center justify-between text-xs text-gray-500">
                <div className="flex items-center space-x-1">
                  <ClockIcon className="w-3 h-3" />
                  <span>Last activity: {new Date(client.lastActivity).toLocaleDateString()}</span>
                </div>
                <div className="flex items-center space-x-1">
                  <CalendarIcon className="w-3 h-3" />
                  <span>Joined: {new Date(client.joinDate).toLocaleDateString()}</span>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Add Client Modal/Form */}
      {showAddClient && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="surface-premium max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-pink-600 rounded-xl flex items-center justify-center">
                    <PlusIcon className="w-6 h-6 text-white" />
                  </div>
                  <h2 className="text-headline">Add New Client</h2>
                </div>
                <button
                  onClick={() => setShowAddClient(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ×
                </button>
              </div>
            </div>
            <div className="p-6">
              <p className="text-body mb-6">Client form would be implemented here with all necessary fields...</p>
              <button
                onClick={() => setShowAddClient(false)}
                className="btn-secondary w-full"
              >
                Close for now
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Empty State */}
      {filteredClients.length === 0 && (
        <div className="surface-elevated p-12 text-center">
          <UserGroupIcon className="w-16 h-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-headline text-gray-600 mb-2">No clients found</h3>
          <p className="text-body text-gray-500 mb-6">
            {searchTerm || statusFilter !== 'all' 
              ? 'Try adjusting your search criteria or filters.'
              : 'Get started by adding your first client to manage their campaigns.'}
          </p>
          <button
            onClick={() => setShowAddClient(true)}
            className="btn-primary"
          >
            <PlusIcon className="w-5 h-5 mr-2" />
            Add Your First Client
          </button>
        </div>
      )}
    </div>
  )
}