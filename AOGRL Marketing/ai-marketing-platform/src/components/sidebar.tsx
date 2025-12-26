'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
// Removed useSession and signOut imports since we're removing authentication
import {
  HomeIcon,
  CubeIcon,
  PhotoIcon,
  MegaphoneIcon,
  QueueListIcon,
  ChartBarIcon,
  DocumentTextIcon,
  CogIcon,
  UserGroupIcon,
  UserIcon,
  PowerIcon,
  SparklesIcon,
  RocketLaunchIcon,
  LightBulbIcon,
  FireIcon,
  CpuChipIcon,
  CurrencyDollarIcon
} from '@heroicons/react/24/outline'
import { useState } from 'react'

const navigation = [
  { name: 'Command Center', href: '/dashboard', icon: HomeIcon, description: 'Overview & AI insights', premium: true },
  { name: 'Client Portfolio', href: '/dashboard/clients', icon: UserGroupIcon, description: 'Agency client management', premium: true },
  { name: 'Smart Products', href: '/dashboard/products', icon: CubeIcon, description: 'AI-optimized catalog', premium: true },
  { name: 'AI Creative Studio', href: '/dashboard/creative', icon: PhotoIcon, description: 'Generative content', premium: true },
  { name: 'Campaign Hub', href: '/dashboard/campaigns', icon: MegaphoneIcon, description: 'Automated campaigns', premium: true },
  { name: 'Budget Optimizer', href: '/dashboard/budget', icon: CurrencyDollarIcon, description: 'AI budget optimization', premium: true },
  { name: 'Data Intelligence', href: '/dashboard/scraper', icon: CpuChipIcon, description: 'Market intelligence & scraping', premium: true },
  { name: 'Process Queue', href: '/dashboard/queue', icon: QueueListIcon, description: 'Background tasks', premium: false },
  { name: 'Predictive Analytics', href: '/dashboard/analytics', icon: ChartBarIcon, description: 'Future insights', premium: true },
  { name: 'System Logs', href: '/dashboard/audit', icon: DocumentTextIcon, description: 'Activity tracking', premium: false },
]

const adminNavigation = [
  { name: 'Team Management', href: '/dashboard/admin', icon: UserGroupIcon, description: 'User administration', premium: true },
  { name: 'Platform Settings', href: '/dashboard/settings', icon: CogIcon, description: 'System configuration', premium: false },
]

function classNames(...classes: string[]) {
  return classes.filter(Boolean).join(' ')
}

export function Sidebar() {
  const pathname = usePathname()
  // Removed session data since we're removing authentication
  const [showUserMenu, setShowUserMenu] = useState(false)

  // Assume admin role for demo purposes since we're removing authentication
  const isAdmin = true

  // Removed signOut function since we're removing authentication
  const handleSignOut = () => {
    // For demo purposes, we'll just redirect to the signin page
    window.location.href = '/auth/signin'
  }

  return (
    <div className="hidden lg:flex lg:w-80 lg:flex-col lg:fixed lg:inset-y-0 z-50">
      <div className="flex-1 flex flex-col min-h-0 bg-gradient-to-b from-slate-900 via-purple-900 to-slate-900 border-r border-slate-800 overflow-hidden">
        {/* Premium Brand Section */}
        <div className="flex items-center flex-shrink-0 px-6 py-8 border-b border-slate-800/50 relative">
          <div className="absolute inset-0 bg-gradient-to-r from-blue-500/10 via-purple-500/10 to-pink-500/10"></div>
          <div className="relative z-10 flex items-center space-x-4 w-full">
            <div className="relative">
              <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-xl">
                <SparklesIcon className="w-7 h-7 text-white" />
              </div>
              <div className="absolute -top-1 -right-1 w-4 h-4 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full animate-pulse"></div>
            </div>
            <div className="flex-1">
              <h1 className="text-xl font-bold text-white">AI Marketing Hub</h1>
              <div className="flex items-center space-x-2 mt-1">
                <span className="text-xs text-blue-300 font-medium">ENTERPRISE PRO</span>
                <div className="flex items-center space-x-1">
                  <FireIcon className="w-3 h-3 text-orange-400" />
                  <span className="text-xs text-orange-300">LIVE</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Revolutionary Navigation */}
        <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto">
          <div className="mb-6">
            <div className="px-3 mb-3">
              <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider flex items-center space-x-2">
                <RocketLaunchIcon className="w-3 h-3" />
                <span>AI Platform</span>
              </h3>
            </div>
            {navigation.map((item) => {
              const isActive = pathname === item.href
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={classNames(
                    isActive
                      ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-xl'
                      : 'text-slate-300 hover:bg-slate-800/50 hover:text-white',
                    'nav-item group relative overflow-hidden'
                  )}
                >
                  <div className="flex items-center flex-1">
                    <div className={classNames(
                      isActive ? 'text-white' : 'text-slate-400 group-hover:text-blue-400',
                      'nav-icon transition-colors duration-200'
                    )}>
                      <item.icon className="w-5 h-5" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <span className="font-semibold text-sm">{item.name}</span>
                        {item.premium && (
                          <div className="w-2 h-2 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full animate-pulse"></div>
                        )}
                      </div>
                      <p className={classNames(
                        isActive ? 'text-blue-100' : 'text-slate-500 group-hover:text-slate-400',
                        'text-xs mt-0.5 transition-colors duration-200'
                      )}>
                        {item.description}
                      </p>
                    </div>
                  </div>
                  {isActive && (
                    <div className="absolute right-0 top-0 bottom-0 w-1 bg-gradient-to-b from-yellow-400 to-orange-500 rounded-l-full"></div>
                  )}
                </Link>
              )
            })}
          </div>
          
          {isAdmin && (
            <div>
              <div className="px-3 mb-3 mt-8">
                <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider flex items-center space-x-2">
                  <LightBulbIcon className="w-3 h-3" />
                  <span>Administration</span>
                </h3>
              </div>
              {adminNavigation.map((item) => {
                const isActive = pathname === item.href
                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    className={classNames(
                      isActive
                        ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-xl'
                        : 'text-slate-300 hover:bg-slate-800/50 hover:text-white',
                      'nav-item group relative overflow-hidden'
                    )}
                  >
                    <div className="flex items-center flex-1">
                      <div className={classNames(
                        isActive ? 'text-white' : 'text-slate-400 group-hover:text-blue-400',
                        'nav-icon transition-colors duration-200'
                      )}>
                        <item.icon className="w-5 h-5" />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center justify-between">
                          <span className="font-semibold text-sm">{item.name}</span>
                          {item.premium && (
                            <div className="w-2 h-2 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full animate-pulse"></div>
                          )}
                        </div>
                        <p className={classNames(
                          isActive ? 'text-blue-100' : 'text-slate-500 group-hover:text-slate-400',
                          'text-xs mt-0.5 transition-colors duration-200'
                        )}>
                          {item.description}
                        </p>
                      </div>
                    </div>
                    {isActive && (
                      <div className="absolute right-0 top-0 bottom-0 w-1 bg-gradient-to-b from-yellow-400 to-orange-500 rounded-l-full"></div>
                    )}
                  </Link>
                )
              })}
            </div>
          )}
        </nav>
        
        {/* Premium User Profile */}
        <div className="flex-shrink-0 border-t border-slate-800/50 p-4 relative">
          <div className="absolute inset-0 bg-gradient-to-r from-blue-500/5 via-purple-500/5 to-pink-500/5"></div>
          <div className="relative z-10">
            <button
              onClick={() => setShowUserMenu(!showUserMenu)}
              className="w-full flex items-center space-x-3 p-3 rounded-2xl hover:bg-slate-800/50 transition-all duration-200 group"
            >
              <div className="relative">
                <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
                  <UserIcon className="w-6 h-6 text-white" />
                </div>
                <div className="absolute -bottom-0.5 -right-0.5 w-4 h-4 bg-green-400 rounded-full border-2 border-slate-900 animate-pulse"></div>
              </div>
              <div className="flex-1 text-left">
                <p className="text-sm font-semibold text-white group-hover:text-blue-300 transition-colors">
                  Admin User
                </p>
                <p className="text-xs text-slate-400 truncate">
                  admin@example.com
                </p>
                <div className="flex items-center space-x-2 mt-1">
                  <span className="status-badge bg-gradient-to-r from-emerald-500 to-green-600 text-white text-xs px-2 py-0.5">
                    admin
                  </span>
                  <span className="text-xs text-slate-500">•</span>
                  <span className="text-xs text-slate-400 truncate">AOGRL Marketing</span>
                </div>
              </div>
            </button>
            
            {showUserMenu && (
              <div className="absolute bottom-full left-4 right-4 mb-2 bg-slate-800/95 backdrop-blur-xl rounded-2xl shadow-2xl border border-slate-700/50 py-2 animate-scale-in">
                <div className="px-4 py-3 border-b border-slate-700/50">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
                      <UserIcon className="w-5 h-5 text-white" />
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-white">Admin User</p>
                      <p className="text-xs text-slate-400">admin@example.com</p>
                    </div>
                  </div>
                </div>
                <button
                  onClick={handleSignOut}
                  className="w-full flex items-center space-x-3 px-4 py-3 text-sm text-slate-300 hover:bg-slate-700/50 hover:text-white transition-colors duration-200"
                >
                  <PowerIcon className="w-4 h-4" />
                  <span>Sign out</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}