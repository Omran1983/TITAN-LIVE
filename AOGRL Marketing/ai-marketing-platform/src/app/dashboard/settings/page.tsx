'use client'

import { useState } from 'react'
import {
  CogIcon,
  BellIcon,
  ShieldCheckIcon,
  GlobeAltIcon,
  CircleStackIcon,
  KeyIcon,
  EnvelopeIcon,
  PaintBrushIcon,
  ChartBarIcon,
  CloudIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon
} from '@heroicons/react/24/outline'

interface SettingSection {
  id: string
  title: string
  description: string
  icon: React.ComponentType<{ className?: string }>
  settings: Setting[]
}

interface Setting {
  id: string
  title: string
  description: string
  type: 'toggle' | 'input' | 'select' | 'textarea'
  value: any
  options?: { label: string; value: string }[]
  required?: boolean
}

export default function SettingsPage() {
  const [activeSection, setActiveSection] = useState('general')
  const [settings, setSettings] = useState<Record<string, any>>({
    // General Settings
    'platform-name': 'AI Marketing Hub',
    'platform-description': 'Advanced AI-powered marketing automation platform',
    'default-language': 'en',
    'timezone': 'UTC',
    'maintenance-mode': false,

    // Notifications
    'email-notifications': true,
    'push-notifications': true,
    'system-alerts': true,
    'marketing-updates': false,
    
    // Security
    'two-factor-auth': true,
    'session-timeout': '30',
    'password-strength': 'strong',
    'api-rate-limiting': true,
    
    // AI Features
    'ai-insights': true,
    'auto-optimization': true,
    'predictive-analytics': true,
    'smart-recommendations': true,
    
    // Integration
    'api-access': true,
    'webhook-notifications': false,
    'third-party-integrations': true,
    
    // Performance
    'cache-enabled': true,
    'compression': true,
    'cdn-enabled': true,
    'auto-backup': true
  })

  const settingSections: SettingSection[] = [
    {
      id: 'general',
      title: 'General Settings',
      description: 'Basic platform configuration and preferences',
      icon: CogIcon,
      settings: [
        {
          id: 'platform-name',
          title: 'Platform Name',
          description: 'The name displayed across the application',
          type: 'input',
          value: settings['platform-name'],
          required: true
        },
        {
          id: 'platform-description',
          title: 'Platform Description',
          description: 'Brief description of your marketing platform',
          type: 'textarea',
          value: settings['platform-description']
        },
        {
          id: 'default-language',
          title: 'Default Language',
          description: 'Default language for new users',
          type: 'select',
          value: settings['default-language'],
          options: [
            { label: 'English', value: 'en' },
            { label: 'Spanish', value: 'es' },
            { label: 'French', value: 'fr' },
            { label: 'German', value: 'de' }
          ]
        },
        {
          id: 'timezone',
          title: 'Default Timezone',
          description: 'Default timezone for the platform',
          type: 'select',
          value: settings['timezone'],
          options: [
            { label: 'UTC', value: 'UTC' },
            { label: 'EST', value: 'EST' },
            { label: 'PST', value: 'PST' },
            { label: 'GMT', value: 'GMT' }
          ]
        },
        {
          id: 'maintenance-mode',
          title: 'Maintenance Mode',
          description: 'Enable maintenance mode to prevent user access',
          type: 'toggle',
          value: settings['maintenance-mode']
        }
      ]
    },
    {
      id: 'notifications',
      title: 'Notifications',
      description: 'Configure system and user notification preferences',
      icon: BellIcon,
      settings: [
        {
          id: 'email-notifications',
          title: 'Email Notifications',
          description: 'Send important updates via email',
          type: 'toggle',
          value: settings['email-notifications']
        },
        {
          id: 'push-notifications',
          title: 'Push Notifications',
          description: 'Enable browser push notifications',
          type: 'toggle',
          value: settings['push-notifications']
        },
        {
          id: 'system-alerts',
          title: 'System Alerts',
          description: 'Receive alerts for system events',
          type: 'toggle',
          value: settings['system-alerts']
        },
        {
          id: 'marketing-updates',
          title: 'Marketing Updates',
          description: 'Receive updates about new features and improvements',
          type: 'toggle',
          value: settings['marketing-updates']
        }
      ]
    },
    {
      id: 'security',
      title: 'Security & Privacy',
      description: 'Security settings and privacy controls',
      icon: ShieldCheckIcon,
      settings: [
        {
          id: 'two-factor-auth',
          title: 'Two-Factor Authentication',
          description: 'Require 2FA for all user accounts',
          type: 'toggle',
          value: settings['two-factor-auth']
        },
        {
          id: 'session-timeout',
          title: 'Session Timeout (minutes)',
          description: 'Automatically log out inactive users',
          type: 'select',
          value: settings['session-timeout'],
          options: [
            { label: '15 minutes', value: '15' },
            { label: '30 minutes', value: '30' },
            { label: '1 hour', value: '60' },
            { label: '2 hours', value: '120' }
          ]
        },
        {
          id: 'password-strength',
          title: 'Password Requirements',
          description: 'Minimum password strength requirements',
          type: 'select',
          value: settings['password-strength'],
          options: [
            { label: 'Basic', value: 'basic' },
            { label: 'Medium', value: 'medium' },
            { label: 'Strong', value: 'strong' }
          ]
        },
        {
          id: 'api-rate-limiting',
          title: 'API Rate Limiting',
          description: 'Enable rate limiting for API requests',
          type: 'toggle',
          value: settings['api-rate-limiting']
        }
      ]
    },
    {
      id: 'ai-features',
      title: 'AI Features',
      description: 'Configure artificial intelligence capabilities',
      icon: ChartBarIcon,
      settings: [
        {
          id: 'ai-insights',
          title: 'AI Insights',
          description: 'Enable AI-powered insights and recommendations',
          type: 'toggle',
          value: settings['ai-insights']
        },
        {
          id: 'auto-optimization',
          title: 'Auto Optimization',
          description: 'Allow AI to automatically optimize campaigns',
          type: 'toggle',
          value: settings['auto-optimization']
        },
        {
          id: 'predictive-analytics',
          title: 'Predictive Analytics',
          description: 'Enable future performance predictions',
          type: 'toggle',
          value: settings['predictive-analytics']
        },
        {
          id: 'smart-recommendations',
          title: 'Smart Recommendations',
          description: 'Show AI-generated recommendations',
          type: 'toggle',
          value: settings['smart-recommendations']
        }
      ]
    },
    {
      id: 'integration',
      title: 'Integration & API',
      description: 'External integrations and API configuration',
      icon: GlobeAltIcon,
      settings: [
        {
          id: 'api-access',
          title: 'API Access',
          description: 'Enable external API access',
          type: 'toggle',
          value: settings['api-access']
        },
        {
          id: 'webhook-notifications',
          title: 'Webhook Notifications',
          description: 'Send event notifications via webhooks',
          type: 'toggle',
          value: settings['webhook-notifications']
        },
        {
          id: 'third-party-integrations',
          title: 'Third-party Integrations',
          description: 'Allow connections to external services',
          type: 'toggle',
          value: settings['third-party-integrations']
        }
      ]
    },
    {
      id: 'performance',
      title: 'Performance',
      description: 'System performance and optimization settings',
      icon: CircleStackIcon,
      settings: [
        {
          id: 'cache-enabled',
          title: 'Caching',
          description: 'Enable application caching for better performance',
          type: 'toggle',
          value: settings['cache-enabled']
        },
        {
          id: 'compression',
          title: 'Data Compression',
          description: 'Compress data transfers to reduce bandwidth',
          type: 'toggle',
          value: settings['compression']
        },
        {
          id: 'cdn-enabled',
          title: 'CDN',
          description: 'Use Content Delivery Network for static assets',
          type: 'toggle',
          value: settings['cdn-enabled']
        },
        {
          id: 'auto-backup',
          title: 'Automatic Backups',
          description: 'Schedule automatic system backups',
          type: 'toggle',
          value: settings['auto-backup']
        }
      ]
    }
  ]

  const handleSettingChange = (settingId: string, value: any) => {
    setSettings(prev => ({
      ...prev,
      [settingId]: value
    }))
  }

  const activeSettingSection = settingSections.find(section => section.id === activeSection)

  const renderSettingField = (setting: Setting) => {
    switch (setting.type) {
      case 'toggle':
        return (
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              className="sr-only peer"
              checked={setting.value}
              onChange={(e) => handleSettingChange(setting.id, e.target.checked)}
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        )
      case 'input':
        return (
          <input
            type="text"
            className="form-input w-full"
            value={setting.value}
            onChange={(e) => handleSettingChange(setting.id, e.target.value)}
            required={setting.required}
          />
        )
      case 'textarea':
        return (
          <textarea
            className="form-input w-full h-24"
            value={setting.value}
            onChange={(e) => handleSettingChange(setting.id, e.target.value)}
          />
        )
      case 'select':
        return (
          <select
            className="form-input w-full"
            value={setting.value}
            onChange={(e) => handleSettingChange(setting.id, e.target.value)}
          >
            {setting.options?.map(option => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        )
      default:
        return null
    }
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
                  <CogIcon className="w-8 h-8 text-white" />
                </div>
                <div>
                  <h1 className="text-display">Platform Settings</h1>
                  <p className="text-body text-gray-600 mt-2">
                    Configure system preferences and platform behavior
                  </p>
                </div>
              </div>
              
              <div className="flex items-center space-x-6 text-sm">
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <CheckCircleIcon className="w-4 h-4 text-green-500" />
                  <span className="font-semibold">System Online</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <CloudIcon className="w-4 h-4 text-blue-500" />
                  <span className="font-semibold">Auto-sync Enabled</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <ShieldCheckIcon className="w-4 h-4 text-purple-500" />
                  <span className="font-semibold">Security Active</span>
                </div>
              </div>
            </div>
            
            <div className="flex space-x-3">
              <button className="btn-secondary">
                Reset to Defaults
              </button>
              <button className="btn-premium">
                Save All Changes
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        {/* Settings Navigation */}
        <div className="lg:col-span-1">
          <div className="surface-elevated">
            <div className="p-6 border-b border-gray-100">
              <h3 className="text-title font-bold">Settings Categories</h3>
            </div>
            <nav className="p-4 space-y-2">
              {settingSections.map((section) => {
                const isActive = activeSection === section.id
                return (
                  <button
                    key={section.id}
                    onClick={() => setActiveSection(section.id)}
                    className={`w-full flex items-center space-x-3 p-3 rounded-xl text-left transition-all duration-200 ${
                      isActive
                        ? 'bg-gradient-to-r from-blue-500 to-purple-600 text-white shadow-lg'
                        : 'hover:bg-gray-50 text-gray-700'
                    }`}
                  >
                    <section.icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-gray-400'}`} />
                    <div>
                      <div className="text-sm font-semibold">{section.title}</div>
                      <div className={`text-xs ${isActive ? 'text-blue-100' : 'text-gray-500'}`}>
                        {section.settings.length} settings
                      </div>
                    </div>
                  </button>
                )
              })}
            </nav>
          </div>
        </div>

        {/* Settings Content */}
        <div className="lg:col-span-3">
          {activeSettingSection && (
            <div className="surface-elevated-high">
              <div className="p-6 border-b border-gray-100">
                <div className="flex items-center space-x-3">
                  <activeSettingSection.icon className="w-8 h-8 text-blue-600" />
                  <div>
                    <h2 className="text-headline">{activeSettingSection.title}</h2>
                    <p className="text-body mt-1">{activeSettingSection.description}</p>
                  </div>
                </div>
              </div>
              
              <div className="p-6">
                <div className="space-y-8">
                  {activeSettingSection.settings.map((setting, index) => (
                    <div
                      key={setting.id}
                      className="flex items-start justify-between p-4 surface rounded-xl hover-lift"
                      style={{ animationDelay: `${index * 100}ms` }}
                    >
                      <div className="flex-1 mr-6">
                        <div className="flex items-center space-x-2 mb-2">
                          <h4 className="text-title font-semibold">{setting.title}</h4>
                          {setting.required && (
                            <span className="text-red-500 text-xs">*</span>
                          )}
                        </div>
                        <p className="text-body text-sm text-gray-600">{setting.description}</p>
                      </div>
                      <div className="flex-shrink-0">
                        {renderSettingField(setting)}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* System Status */}
      <div className="surface-elevated p-6">
        <div className="flex items-center space-x-3 mb-6">
          <div className="w-8 h-8 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl flex items-center justify-center">
            <CheckCircleIcon className="w-5 h-5 text-white" />
          </div>
          <h3 className="text-headline">System Status</h3>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="text-center p-4 surface rounded-xl">
            <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center mx-auto mb-3">
              <CircleStackIcon className="w-6 h-6 text-green-600" />
            </div>
            <div className="text-lg font-bold text-green-600">Operational</div>
            <div className="text-sm text-gray-600">Database</div>
          </div>
          <div className="text-center p-4 surface rounded-xl">
            <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center mx-auto mb-3">
              <CloudIcon className="w-6 h-6 text-blue-600" />
            </div>
            <div className="text-lg font-bold text-blue-600">Connected</div>
            <div className="text-sm text-gray-600">Cloud Services</div>
          </div>
          <div className="text-center p-4 surface rounded-xl">
            <div className="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center mx-auto mb-3">
              <ShieldCheckIcon className="w-6 h-6 text-purple-600" />
            </div>
            <div className="text-lg font-bold text-purple-600">Secure</div>
            <div className="text-sm text-gray-600">Security System</div>
          </div>
        </div>
      </div>
    </div>
  )
}