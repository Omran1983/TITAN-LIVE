import dayjs from 'dayjs'
import utc from 'dayjs/plugin/utc'
import timezone from 'dayjs/plugin/timezone'
import relativeTime from 'dayjs/plugin/relativeTime'
import localizedFormat from 'dayjs/plugin/localizedFormat'

dayjs.extend(utc)
dayjs.extend(timezone)
dayjs.extend(relativeTime)
dayjs.extend(localizedFormat)

// Supported currencies with their symbols and names
export const SUPPORTED_CURRENCIES = {
  MUR: { symbol: 'Rs', name: 'Mauritian Rupee', flag: '🇲🇺' },
  USD: { symbol: '$', name: 'US Dollar', flag: '🇺🇸' },
  EUR: { symbol: '€', name: 'Euro', flag: '🇪🇺' },
  GBP: { symbol: '£', name: 'British Pound', flag: '🇬🇧' },
  ZAR: { symbol: 'R', name: 'South African Rand', flag: '🇿🇦' },
  AUD: { symbol: 'A$', name: 'Australian Dollar', flag: '🇦🇺' },
  CAD: { symbol: 'C$', name: 'Canadian Dollar', flag: '🇨🇦' },
  JPY: { symbol: '¥', name: 'Japanese Yen', flag: '🇯🇵' },
  INR: { symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳' },
} as const

export type CurrencyCode = keyof typeof SUPPORTED_CURRENCIES

// Common timezones grouped by region
export const SUPPORTED_TIMEZONES = {
  'Africa/Mauritius': 'Mauritius (GMT+4)',
  'UTC': 'UTC (GMT+0)',
  'Europe/London': 'London (GMT+0/+1)',
  'Europe/Paris': 'Paris (GMT+1/+2)',
  'Europe/Berlin': 'Berlin (GMT+1/+2)',
  'America/New_York': 'New York (GMT-5/-4)',
  'America/Los_Angeles': 'Los Angeles (GMT-8/-7)',
  'America/Chicago': 'Chicago (GMT-6/-5)',
  'Asia/Tokyo': 'Tokyo (GMT+9)',
  'Asia/Singapore': 'Singapore (GMT+8)',
  'Asia/Dubai': 'Dubai (GMT+4)',
  'Australia/Sydney': 'Sydney (GMT+10/+11)',
  'Africa/Johannesburg': 'Johannesburg (GMT+2)',
  'Asia/Kolkata': 'Mumbai (GMT+5:30)',
} as const

export type TimezoneCode = keyof typeof SUPPORTED_TIMEZONES

// Exchange rates (in production, this would come from an API)
const MOCK_EXCHANGE_RATES: Record<CurrencyCode, number> = {
  MUR: 1, // Base currency (Mauritian Rupee)
  USD: 0.022, // 1 MUR = 0.022 USD
  EUR: 0.020, // 1 MUR = 0.020 EUR
  GBP: 0.017, // 1 MUR = 0.017 GBP
  ZAR: 0.40, // 1 MUR = 0.40 ZAR
  AUD: 0.034, // 1 MUR = 0.034 AUD
  CAD: 0.030, // 1 MUR = 0.030 CAD
  JPY: 3.30, // 1 MUR = 3.30 JPY
  INR: 1.85, // 1 MUR = 1.85 INR
}

// Currency conversion functions
export function convertCurrency(
  amount: number,
  fromCurrency: CurrencyCode,
  toCurrency: CurrencyCode
): number {
  if (fromCurrency === toCurrency) return amount

  // Convert to MUR first, then to target currency
  const amountInMUR = fromCurrency === 'MUR' ? amount : amount / MOCK_EXCHANGE_RATES[fromCurrency]
  const convertedAmount = toCurrency === 'MUR' ? amountInMUR : amountInMUR * MOCK_EXCHANGE_RATES[toCurrency]

  return Math.round(convertedAmount * 100) / 100 // Round to 2 decimal places
}

export function formatCurrency(
  amount: number,
  currency: CurrencyCode,
  locale: string = 'en-US'
): string {
  const currencyInfo = SUPPORTED_CURRENCIES[currency]
  
  // Special formatting for different currencies
  switch (currency) {
    case 'MUR':
      return `Rs ${amount.toLocaleString(locale, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
    case 'JPY':
      return `¥${amount.toLocaleString(locale, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`
    default:
      return new Intl.NumberFormat(locale, {
        style: 'currency',
        currency: currency,
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(amount)
  }
}

export function formatCurrencyCompact(
  amount: number,
  currency: CurrencyCode,
  locale: string = 'en-US'
): string {
  const currencyInfo = SUPPORTED_CURRENCIES[currency]
  const symbol = currencyInfo.symbol

  if (amount >= 1000000) {
    return `${symbol}${(amount / 1000000).toFixed(1)}M`
  } else if (amount >= 1000) {
    return `${symbol}${(amount / 1000).toFixed(1)}K`
  } else {
    return `${symbol}${amount.toFixed(0)}`
  }
}

// Timezone functions
export function formatDateTime(
  date: string | Date,
  timezone: TimezoneCode,
  locale: string = 'en-US'
): string {
  return dayjs(date).tz(timezone).format('MMMM D, YYYY [at] h:mm A')
}

export function formatDate(
  date: string | Date,
  timezone: TimezoneCode,
  locale: string = 'en-US'
): string {
  return dayjs(date).tz(timezone).format('MMMM D, YYYY')
}

export function formatTime(
  date: string | Date,
  timezone: TimezoneCode,
  locale: string = 'en-US'
): string {
  return dayjs(date).tz(timezone).format('h:mm A')
}

export function getRelativeTime(
  date: string | Date,
  timezone: TimezoneCode,
  locale: string = 'en-US'
): string {
  return dayjs(date).tz(timezone).fromNow()
}

export function getCurrentTime(timezone: TimezoneCode): string {
  return dayjs().tz(timezone).format('h:mm A')
}

export function detectUserTimezone(): TimezoneCode {
  const detectedTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone
  
  // Check if detected timezone is in our supported list
  if (detectedTimezone in SUPPORTED_TIMEZONES) {
    return detectedTimezone as TimezoneCode
  }
  
  // Fallback to UTC if not supported
  return 'UTC'
}

export function detectUserCurrency(): CurrencyCode {
  // Try to detect from locale
  try {
    const locale = navigator.language || 'en-US'
    const region = locale.split('-')[1]?.toUpperCase()
    
    // Map common regions to currencies
    const regionToCurrency: Record<string, CurrencyCode> = {
      'MU': 'MUR', // Mauritius
      'US': 'USD', // United States
      'GB': 'GBP', // United Kingdom
      'FR': 'EUR', // France
      'DE': 'EUR', // Germany
      'IT': 'EUR', // Italy
      'ES': 'EUR', // Spain
      'ZA': 'ZAR', // South Africa
      'AU': 'AUD', // Australia
      'CA': 'CAD', // Canada
      'JP': 'JPY', // Japan
      'IN': 'INR', // India
    }
    
    return regionToCurrency[region] || 'USD'
  } catch {
    return 'USD'
  }
}

// User preferences helper functions
export interface UserPreferences {
  currency: CurrencyCode
  timezone: TimezoneCode
  language: 'en' | 'fr'
}

export function getUserPreferences(): UserPreferences {
  if (typeof window === 'undefined') {
    return {
      currency: 'MUR',
      timezone: 'Africa/Mauritius',
      language: 'en'
    }
  }

  const stored = localStorage.getItem('userPreferences')
  if (stored) {
    try {
      return JSON.parse(stored)
    } catch {
      // Fall through to defaults
    }
  }

  return {
    currency: detectUserCurrency(),
    timezone: detectUserTimezone(),
    language: 'en'
  }
}

export function setUserPreferences(preferences: Partial<UserPreferences>): void {
  if (typeof window === 'undefined') return

  const current = getUserPreferences()
  const updated = { ...current, ...preferences }
  localStorage.setItem('userPreferences', JSON.stringify(updated))
  
  // Trigger a custom event for components to listen to
  window.dispatchEvent(new CustomEvent('preferencesChanged', { detail: updated }))
}