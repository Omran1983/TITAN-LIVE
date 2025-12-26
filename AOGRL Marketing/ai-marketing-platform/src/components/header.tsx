'use client'

// Removed useSession import since we're removing authentication
import { 
  MagnifyingGlassIcon, 
  BellIcon, 
  Cog6ToothIcon,
  SparklesIcon,
  RocketLaunchIcon,
  FireIcon
} from '@heroicons/react/24/outline'
import { useState } from 'react'
import { PreferencesDropdown } from './PreferencesDropdown'

export function Header() {
  // Removed session data since we're removing authentication
  const [searchQuery, setSearchQuery] = useState('')
  const [notifications] = useState([
    { id: 1, type: 'success', message: 'Campaign "Summer Sale" exceeded targets by 23%', time: '2m ago' },
    { id: 2, type: 'info', message: 'New AI insights available for product optimization', time: '5m ago' },
    { id: 3, type: 'warning', message: 'Budget alert: Campaign A approaching 80% spend', time: '10m ago' }
  ])
  const [showNotifications, setShowNotifications] = useState(false)

  return (
    <div className="bg-white/80 backdrop-blur-xl border-b border-gray-200/50 sticky top-0 z-40 shadow-sm">
      <div className="px-6 py-4">
        <div className="flex items-center justify-between">
          {/* Premium Search */}
          <div className="flex-1 max-w-2xl">
            <div className="relative group">
              <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <MagnifyingGlassIcon className="h-5 w-5 text-gray-400 group-focus-within:text-blue-500 transition-colors" />
              </div>
              <input
                type="search"
                placeholder="Search campaigns, products, analytics, AI insights..."
                className="form-input pl-12 pr-4 w-full bg-gray-50/50 border-gray-200/50 focus:bg-white focus:border-blue-300 focus:ring-4 focus:ring-blue-100 transition-all duration-300"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
              {searchQuery && (
                <div className="absolute top-full left-0 right-0 mt-2 bg-white rounded-2xl shadow-xl border border-gray-100 p-4 animate-scale-in">
                  <div className="text-sm text-gray-500 mb-2">Quick suggestions:</div>
                  <div className="space-y-2">
                    <div className="flex items-center space-x-2 p-2 hover:bg-gray-50 rounded-lg cursor-pointer">
                      <SparklesIcon className="w-4 h-4 text-purple-500" />
                      <span className="text-sm">AI Campaign Optimization</span>
                    </div>
                    <div className="flex items-center space-x-2 p-2 hover:bg-gray-50 rounded-lg cursor-pointer">
                      <RocketLaunchIcon className="w-4 h-4 text-blue-500" />
                      <span className="text-sm">Product Performance Analytics</span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
          
          {/* Premium Actions */}
          <div className="flex items-center space-x-4">
            {/* AI Status Indicator */}
            <div className="hidden md:flex items-center space-x-3 px-4 py-2 bg-gradient-to-r from-green-50 to-emerald-50 rounded-full border border-green-200/50">
              <div className="flex items-center space-x-2">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                <span className="text-xs font-semibold text-green-700">AI Systems Online</span>
              </div>
              <FireIcon className="w-4 h-4 text-orange-500" />
            </div>

            {/* Notifications */}
            <div className="relative">
              <button 
                className="relative p-3 text-gray-400 hover:text-gray-500 hover:bg-gray-100/50 rounded-xl transition-all duration-200 hover-glow"
                onClick={() => setShowNotifications(!showNotifications)}
              >
                <BellIcon className="h-6 w-6" />
                {notifications.length > 0 && (
                  <span className="absolute -top-1 -right-1 block h-5 w-5 rounded-full bg-gradient-to-br from-red-500 to-pink-600 text-xs text-white font-bold flex items-center justify-center animate-pulse">
                    {notifications.length}
                  </span>
                )}
              </button>
              
              {showNotifications && (
                <div className="absolute right-0 mt-2 w-80 bg-white rounded-2xl shadow-2xl border border-gray-100 animate-scale-in z-50">
                  <div className="p-4 border-b border-gray-100">
                    <div className="flex items-center justify-between">
                      <h3 className="font-semibold text-gray-900">Notifications</h3>
                      <span className="text-xs text-gray-500">{notifications.length} new</span>
                    </div>
                  </div>
                  <div className="max-h-96 overflow-y-auto">
                    {notifications.map((notification) => (
                      <div key={notification.id} className="p-4 border-b border-gray-50 hover:bg-gray-50/50 transition-colors">
                        <div className="flex items-start space-x-3">
                          <div className={`w-2 h-2 rounded-full mt-2 ${
                            notification.type === 'success' ? 'bg-green-400' : 
                            notification.type === 'warning' ? 'bg-yellow-400' : 'bg-blue-400'
                          }`}></div>
                          <div className="flex-1">
                            <p className="text-sm text-gray-900">{notification.message}</p>
                            <p className="text-xs text-gray-500 mt-1">{notification.time}</p>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                  <div className="p-4 bg-gray-50/50">
                    <button className="w-full text-center text-sm text-blue-600 hover:text-blue-800 font-medium">
                      View all notifications
                    </button>
                  </div>
                </div>
              )}
            </div>
            
            {/* Global Preferences */}
            <PreferencesDropdown />
            
            {/* Settings */}
            <button className="p-3 text-gray-400 hover:text-gray-500 hover:bg-gray-100/50 rounded-xl transition-all duration-200">
              <Cog6ToothIcon className="h-6 w-6" />
            </button>
            
            {/* Premium User Profile */}
            <div className="flex items-center space-x-3 pl-4 border-l border-gray-200/50">
              <div className="text-right hidden sm:block">
                <p className="text-sm font-semibold text-gray-900">
                  Admin User
                </p>
                <div className="flex items-center space-x-2">
                  <p className="text-xs text-gray-500">
                    AOGRL Marketing
                  </p>
                  <span className="status-badge bg-gradient-to-r from-blue-500 to-purple-600 text-white text-xs">
                    PRO
                  </span>
                </div>
              </div>
              <div className="relative">
                <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg hover:shadow-xl transition-shadow duration-300">
                  <span className="text-sm font-bold text-white">
                    A
                  </span>
                </div>
                <div className="absolute -bottom-0.5 -right-0.5 w-4 h-4 bg-green-400 rounded-full border-2 border-white animate-pulse"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}