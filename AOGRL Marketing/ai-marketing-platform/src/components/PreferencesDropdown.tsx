'use client'

import { useState, useEffect } from 'react'
import { useI18n } from '@/lib/i18n'
import { useUserPreferences, useUpdateUserPreferences } from '@/lib/hooks'
import {
  SUPPORTED_CURRENCIES,
  SUPPORTED_TIMEZONES,
  CurrencyCode,
  TimezoneCode,
  getUserPreferences,
  setUserPreferences,
  UserPreferences
} from '@/lib/preferences'
import {
  GlobeAltIcon,
  BanknotesIcon,
  ClockIcon,
  CheckIcon,
  ChevronDownIcon
} from '@heroicons/react/24/outline'

interface PreferencesDropdownProps {
  onClose?: () => void
}

export function PreferencesDropdown({ onClose }: PreferencesDropdownProps) {
  const { language, setLanguage, t } = useI18n()
  const { data: userPreferences, isLoading } = useUserPreferences()
  const updatePreferencesMutation = useUpdateUserPreferences()
  const [preferences, setPreferencesState] = useState<UserPreferences>({
    currency: 'MUR',
    timezone: 'Africa/Mauritius',
    language: 'en'
  })
  const [isOpen, setIsOpen] = useState(false)

  useEffect(() => {
    if (userPreferences?.preferences) {
      setPreferencesState(userPreferences.preferences)
    } else {
      const current = getUserPreferences()
      setPreferencesState(current)
    }
  }, [userPreferences])

  const handlePreferenceChange = (key: keyof UserPreferences, value: any) => {
    const updated = { ...preferences, [key]: value }
    setPreferencesState(updated)
    setUserPreferences(updated)

    // Update language immediately
    if (key === 'language') {
      setLanguage(value)
    }

    // Update server preferences
    updatePreferencesMutation.mutate({ [key]: value })
    
    // Auto-close after a short delay
    setTimeout(() => {
      setIsOpen(false)
      onClose?.()
    }, 1000)
  }

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center space-x-2 p-2 hover:bg-gray-100 rounded-lg transition-colors"
        title={t('preferences.language')}
      >
        <GlobeAltIcon className="w-5 h-5 text-gray-600" />
        <span className="text-sm font-medium text-gray-700">
          {language.toUpperCase()} • {SUPPORTED_CURRENCIES[preferences.currency].symbol}
        </span>
        <ChevronDownIcon className="w-4 h-4 text-gray-400" />
      </button>

      {isOpen && (
        <>
          {/* Backdrop */}
          <div 
            className="fixed inset-0 z-40" 
            onClick={() => setIsOpen(false)}
          />
          
          {/* Dropdown */}
          <div className="absolute right-0 top-full mt-2 w-80 bg-white rounded-2xl shadow-2xl border border-gray-200 z-50 overflow-hidden animate-scale-in">
            <div className="p-6 border-b border-gray-100 bg-gradient-to-r from-blue-50 to-purple-50">
              <h3 className="text-lg font-bold text-gray-900 mb-1">
                {t('preferences.language')} & {t('preferences.currency')}
              </h3>
              <p className="text-sm text-gray-600">
                Customize your experience
              </p>
            </div>

            <div className="p-6 space-y-6">
              {/* Language Selection */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-3">
                  <GlobeAltIcon className="w-4 h-4 inline mr-2" />
                  {t('preferences.language')}
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {[
                    { code: 'en', name: 'English', flag: '🇺🇸' },
                    { code: 'fr', name: 'Français', flag: '🇫🇷' }
                  ].map((lang) => (
                    <button
                      key={lang.code}
                      onClick={() => handlePreferenceChange('language', lang.code)}
                      className={`flex items-center justify-between p-3 rounded-xl border-2 transition-all duration-200 ${
                        preferences.language === lang.code
                          ? 'border-blue-500 bg-blue-50 text-blue-700'
                          : 'border-gray-200 hover:border-gray-300 text-gray-700'
                      }`}
                    >
                      <div className="flex items-center space-x-2">
                        <span className="text-lg">{lang.flag}</span>
                        <span className="font-medium text-sm">{lang.name}</span>
                      </div>
                      {preferences.language === lang.code && (
                        <CheckIcon className="w-4 h-4 text-blue-600" />
                      )}
                    </button>
                  ))}
                </div>
              </div>

              {/* Currency Selection */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-3">
                  <BanknotesIcon className="w-4 h-4 inline mr-2" />
                  {t('preferences.currency')}
                </label>
                <div className="grid grid-cols-2 gap-2 max-h-48 overflow-y-auto">
                  {Object.entries(SUPPORTED_CURRENCIES).map(([code, info]) => (
                    <button
                      key={code}
                      onClick={() => handlePreferenceChange('currency', code)}
                      className={`flex items-center justify-between p-3 rounded-xl border-2 transition-all duration-200 ${
                        preferences.currency === code
                          ? 'border-blue-500 bg-blue-50 text-blue-700'
                          : 'border-gray-200 hover:border-gray-300 text-gray-700'
                      }`}
                    >
                      <div className="flex items-center space-x-2">
                        <span className="text-lg">{info.flag}</span>
                        <div className="text-left">
                          <div className="font-medium text-sm">{code}</div>
                          <div className="text-xs text-gray-500">{info.symbol}</div>
                        </div>
                      </div>
                      {preferences.currency === code && (
                        <CheckIcon className="w-4 h-4 text-blue-600" />
                      )}
                    </button>
                  ))}
                </div>
              </div>

              {/* Timezone Selection */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-3">
                  <ClockIcon className="w-4 h-4 inline mr-2" />
                  {t('preferences.timezone')}
                </label>
                <select
                  value={preferences.timezone}
                  onChange={(e) => handlePreferenceChange('timezone', e.target.value)}
                  className="w-full p-3 border-2 border-gray-200 rounded-xl focus:border-blue-500 focus:outline-none transition-colors"
                >
                  {Object.entries(SUPPORTED_TIMEZONES).map(([code, name]) => (
                    <option key={code} value={code}>
                      {name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="p-4 bg-gray-50 border-t border-gray-100">
              <div className="text-xs text-gray-500 text-center">
                {t('preferences.preferencesUpdated')}
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  )
}