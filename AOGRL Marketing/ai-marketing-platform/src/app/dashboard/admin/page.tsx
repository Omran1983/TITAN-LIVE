'use client'

import { useState } from 'react'
import {
  UserGroupIcon,
  PlusIcon,
  MagnifyingGlassIcon,
  FunnelIcon,
  EllipsisVerticalIcon,
  UserIcon,
  EnvelopeIcon,
  CalendarIcon,
  CheckCircleIcon,
  XCircleIcon,
  ExclamationTriangleIcon,
  KeyIcon,
  ShieldCheckIcon,
  CogIcon
} from '@heroicons/react/24/outline'

interface User {
  id: string
  name: string
  email: string
  role: 'ADMIN' | 'USER' | 'VIEWER'
  status: 'active' | 'inactive' | 'pending'
  lastLogin: string
  createdAt: string
  tenant: string
  permissions: string[]
  avatar?: string
}

const mockUsers: User[] = [
  {
    id: '1',
    name: 'John Doe',
    email: 'john.doe@example.com',
    role: 'ADMIN',
    status: 'active',
    lastLogin: '2024-03-15T14:30:00Z',
    createdAt: '2024-01-15T09:00:00Z',
    tenant: 'Main Organization',
    permissions: ['all']
  },
  {
    id: '2',
    name: 'Sarah Johnson',
    email: 'sarah.johnson@example.com',
    role: 'USER',
    status: 'active',
    lastLogin: '2024-03-15T12:45:00Z',
    createdAt: '2024-02-01T10:30:00Z',
    tenant: 'Main Organization',
    permissions: ['campaigns.manage', 'analytics.view', 'clients.manage']
  },
  {
    id: '3',
    name: 'Mike Chen',
    email: 'mike.chen@example.com',
    role: 'USER',
    status: 'active',
    lastLogin: '2024-03-15T08:20:00Z',
    createdAt: '2024-02-10T14:15:00Z',
    tenant: 'Main Organization',
    permissions: ['campaigns.view', 'analytics.view', 'creative.manage']
  },
  {
    id: '4',
    name: 'Emma Davis',
    email: 'emma.davis@example.com',
    role: 'VIEWER',
    status: 'pending',
    lastLogin: '',
    createdAt: '2024-03-10T16:00:00Z',
    tenant: 'Main Organization',
    permissions: ['analytics.view', 'campaigns.view']
  },
  {
    id: '5',
    name: 'Alex Smith',
    email: 'alex.smith@example.com',
    role: 'USER',
    status: 'inactive',
    lastLogin: '2024-02-28T11:30:00Z',
    createdAt: '2024-01-20T13:45:00Z',
    tenant: 'Main Organization',
    permissions: ['campaigns.manage', 'analytics.view']
  }
]

export default function AdminPage() {
  const [users, setUsers] = useState<User[]>(mockUsers)
  const [searchTerm, setSearchTerm] = useState('')
  const [roleFilter, setRoleFilter] = useState<string>('all')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [selectedUser, setSelectedUser] = useState<User | null>(null)
  const [showAddUser, setShowAddUser] = useState(false)

  // Assume admin role for demo purposes since we're removing authentication
  const isAdmin = true

  const filteredUsers = users.filter(user => {
    const matchesSearch = user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.email.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesRole = roleFilter === 'all' || user.role === roleFilter
    const matchesStatus = statusFilter === 'all' || user.status === statusFilter
    return matchesSearch && matchesRole && matchesStatus
  })

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return 'status-active'
      case 'inactive':
        return 'status-inactive'
      case 'pending':
        return 'status-pending'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getRoleBadge = (role: string) => {
    switch (role) {
      case 'ADMIN':
        return 'bg-red-100 text-red-800 border border-red-200'
      case 'USER':
        return 'bg-blue-100 text-blue-800 border border-blue-200'
      case 'VIEWER':
        return 'bg-gray-100 text-gray-800 border border-gray-200'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active':
        return <CheckCircleIcon className="w-4 h-4 text-green-500" />
      case 'inactive':
        return <XCircleIcon className="w-4 h-4 text-red-500" />
      case 'pending':
        return <ExclamationTriangleIcon className="w-4 h-4 text-yellow-500" />
      default:
        return <ExclamationTriangleIcon className="w-4 h-4 text-gray-500" />
    }
  }

  const handleStatusChange = (userId: string, newStatus: string) => {
    setUsers(users.map(user => 
      user.id === userId ? { ...user, status: newStatus as any } : user
    ))
  }

  const summaryStats = {
    total: users.length,
    active: users.filter(u => u.status === 'active').length,
    inactive: users.filter(u => u.status === 'inactive').length,
    pending: users.filter(u => u.status === 'pending').length,
    admins: users.filter(u => u.role === 'ADMIN').length
  }

  return (
    <div className="animate-slide-up space-y-8">
      {/* Premium Header */}
      <div className="surface-premium p-8 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-red-500/20 via-purple-500/20 to-blue-500/20 animate-gradient-flow"></div>
        <div className="relative z-10">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center space-x-4 mb-4">
                <div className="w-16 h-16 bg-gradient-to-br from-red-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
                  <UserGroupIcon className="w-8 h-8 text-white" />
                </div>
                <div>
                  <h1 className="text-display">Team Management</h1>
                  <p className="text-body text-gray-600 mt-2">
                    Manage users, roles, and permissions • {filteredUsers.length} team members
                  </p>
                </div>
              </div>
              
              <div className="flex items-center space-x-6 text-sm">
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <CheckCircleIcon className="w-4 h-4 text-green-500" />
                  <span className="font-semibold">{summaryStats.active} Active</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <ExclamationTriangleIcon className="w-4 h-4 text-yellow-500" />
                  <span className="font-semibold">{summaryStats.pending} Pending</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <ShieldCheckIcon className="w-4 h-4 text-red-500" />
                  <span className="font-semibold">{summaryStats.admins} Admins</span>
                </div>
              </div>
            </div>
            
            <button 
              onClick={() => setShowAddUser(true)}
              className="btn-primary flex items-center space-x-2 px-6 py-3 shadow-lg hover:shadow-xl transition-all duration-300"
            >
              <PlusIcon className="w-5 h-5" />
              <span>Add Team Member</span>
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
              placeholder="Search users by name or email..."
              className="form-input pl-12 w-full"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div className="flex items-center space-x-4">
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="form-input w-40"
            >
              <option value="all">All Roles</option>
              <option value="ADMIN">Admin</option>
              <option value="USER">User</option>
              <option value="VIEWER">Viewer</option>
            </select>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="form-input w-40"
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="pending">Pending</option>
            </select>
            <button className="btn-secondary flex items-center space-x-2">
              <FunnelIcon className="w-4 h-4" />
              <span>Advanced</span>
            </button>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="surface-elevated-high">
        <div className="p-6 border-b border-gray-100">
          <h2 className="text-headline">Team Members</h2>
          <p className="text-body mt-1">Manage user accounts, roles, and access permissions</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Last Login</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredUsers.map((user, index) => (
                <tr 
                  key={user.id} 
                  className="hover:bg-gray-50 transition-colors"
                  style={{ animationDelay: `${index * 50}ms` }}
                >
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center text-white font-bold">
                        {user.name.charAt(0)}
                      </div>
                      <div>
                        <div className="text-sm font-medium text-gray-900">{user.name}</div>
                        <div className="text-sm text-gray-500">{user.email}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${getRoleBadge(user.role)}`}>
                      {user.role}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-2">
                      {getStatusIcon(user.status)}
                      <span className={`status-badge ${getStatusBadge(user.status)} text-xs`}>
                        {user.status}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {user.lastLogin ? new Date(user.lastLogin).toLocaleDateString() : 'Never'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {new Date(user.createdAt).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => setSelectedUser(user)}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="Edit User"
                      >
                        <CogIcon className="w-4 h-4 text-gray-600" />
                      </button>
                      <button
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="More Options"
                      >
                        <EllipsisVerticalIcon className="w-4 h-4 text-gray-600" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* User Details Modal */}
      {selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="surface-premium max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center text-white font-bold text-lg">
                    {selectedUser.name.charAt(0)}
                  </div>
                  <div>
                    <h2 className="text-headline">{selectedUser.name}</h2>
                    <p className="text-body text-gray-600">{selectedUser.email}</p>
                  </div>
                </div>
                <button
                  onClick={() => setSelectedUser(null)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ×
                </button>
              </div>
            </div>
            <div className="p-6 space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <h3 className="font-semibold text-sm text-gray-500 uppercase tracking-wider mb-2">Role</h3>
                  <select className="form-input w-full" defaultValue={selectedUser.role}>
                    <option value="ADMIN">Administrator</option>
                    <option value="USER">User</option>
                    <option value="VIEWER">Viewer</option>
                  </select>
                </div>
                <div>
                  <h3 className="font-semibold text-sm text-gray-500 uppercase tracking-wider mb-2">Status</h3>
                  <select 
                    className="form-input w-full" 
                    defaultValue={selectedUser.status}
                    onChange={(e) => handleStatusChange(selectedUser.id, e.target.value)}
                  >
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="pending">Pending</option>
                  </select>
                </div>
              </div>

              <div>
                <h3 className="font-semibold text-sm text-gray-500 uppercase tracking-wider mb-3">Permissions</h3>
                <div className="space-y-2">
                  {['campaigns.manage', 'analytics.view', 'clients.manage', 'creative.manage', 'settings.admin'].map(permission => (
                    <label key={permission} className="flex items-center space-x-3">
                      <input
                        type="checkbox"
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        defaultChecked={selectedUser.permissions.includes(permission) || selectedUser.permissions.includes('all')}
                        disabled={selectedUser.permissions.includes('all')}
                      />
                      <span className="text-sm text-gray-700 capitalize">{permission.replace('.', ' ')}</span>
                    </label>
                  ))}
                </div>
              </div>

              <div className="flex justify-end space-x-3 pt-6 border-t border-gray-200">
                <button
                  onClick={() => setSelectedUser(null)}
                  className="btn-secondary"
                >
                  Cancel
                </button>
                <button className="btn-primary">
                  Save Changes
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add User Modal */}
      {showAddUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="surface-premium max-w-lg w-full">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h2 className="text-headline">Add New User</h2>
                <button
                  onClick={() => setShowAddUser(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ×
                </button>
              </div>
            </div>
            <div className="p-6">
              <p className="text-body mb-6">User creation form would be implemented here...</p>
              <button
                onClick={() => setShowAddUser(false)}
                className="btn-secondary w-full"
              >
                Close for now
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Empty State */}
      {filteredUsers.length === 0 && (
        <div className="surface-elevated p-12 text-center">
          <UserGroupIcon className="w-16 h-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-headline text-gray-600 mb-2">No users found</h3>
          <p className="text-body text-gray-500 mb-6">
            {searchTerm || roleFilter !== 'all' || statusFilter !== 'all'
              ? 'Try adjusting your search criteria or filters.'
              : 'Start by adding team members to manage your marketing platform.'}
          </p>
          <button
            onClick={() => setShowAddUser(true)}
            className="btn-primary"
          >
            <PlusIcon className="w-5 h-5 mr-2" />
            Add First User
          </button>
        </div>
      )}
    </div>
  )
}