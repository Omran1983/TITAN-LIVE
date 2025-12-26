import axios from 'axios'

const EXCHANGE_API_BASE = 'https://v6.exchangerate-api.com/v6'
const EXCHANGE_API_KEY = process.env.EXCHANGE_RATE_API_KEY

// Utility function to check if an object is empty
const isEmptyObject = (obj: any): boolean => {
  if (!obj || typeof obj !== 'object') return false
  return Object.keys(obj).length === 0
}

// Utility function to check if error message is meaningful
const isMeaningfulError = (message: string): boolean => {
  if (!message) return false
  const meaninglessMessages = ['{}', '""', '[object Object]', 'Network Error']
  return !meaninglessMessages.includes(message) && message.trim().length > 0
}

interface ExchangeRates {
  [currency: string]: number
}

interface CurrencyConversion {
  from: string
  to: string
  amount: number
  result: number
  rate: number
  timestamp: number
}

export class CurrencyService {
  private apiKey: string
  private baseURL: string
  private cache: Map<string, { data: any; timestamp: number }> = new Map()
  private cacheTimeout = 30 * 60 * 1000 // 30 minutes

  constructor() {
    this.apiKey = EXCHANGE_API_KEY || ''
    this.baseURL = EXCHANGE_API_BASE
  }

  private getCacheKey(endpoint: string, params?: any): string {
    return `${endpoint}_${JSON.stringify(params || {})}`
  }

  private isValidCache(cacheEntry: { data: any; timestamp: number }): boolean {
    return Date.now() - cacheEntry.timestamp < this.cacheTimeout
  }

  private async makeRequest(endpoint: string, params?: any) {
    const cacheKey = this.getCacheKey(endpoint, params)
    const cached = this.cache.get(cacheKey)

    if (cached && this.isValidCache(cached)) {
      return cached.data
    }

    try {
      const url = `${this.baseURL}/${this.apiKey}${endpoint}`
      const response = await axios.get(url, {
        params,
        timeout: 10000,
      })

      if (response.data.result === 'success') {
        this.cache.set(cacheKey, {
          data: response.data,
          timestamp: Date.now()
        })
        return response.data
      } else {
        throw new Error(response.data['error-type'] || 'Unknown API error')
      }
    } catch (error: any) {
      // More robust error logging to prevent "API Error: {}" messages
      let errorMessage = 'Unknown error'
      let errorData = null
      
      // Extract meaningful error information
      if (error.response?.data) {
        if (typeof error.response.data === 'string') {
          errorMessage = error.response.data
        } else if (typeof error.response.data === 'object' && !isEmptyObject(error.response.data)) {
          // Check if it's a structured error response
          if (error.response.data.error) {
            errorMessage = error.response.data.error
          } else if (error.response.data['error-type']) {
            errorMessage = error.response.data['error-type']
          } else {
            // Convert object to string but only if it contains meaningful data
            const dataStr = JSON.stringify(error.response.data)
            if (isMeaningfulError(dataStr)) {
              errorMessage = dataStr
            }
          }
          errorData = error.response.data
        }
      } else if (error.message) {
        errorMessage = error.message
      }
      
      // Only log meaningful errors
      if (isMeaningfulError(errorMessage) || errorData) {
        console.error('Exchange Rate API Error:', {
          message: errorMessage,
          status: error.response?.status,
          data: errorData
        })
      }
      
      throw new Error(`Currency API Error: ${errorMessage}`)
    }
  }

  // Get latest exchange rates for a base currency
  async getExchangeRates(baseCurrency = 'USD'): Promise<ExchangeRates> {
    const data = await this.makeRequest(`/latest/${baseCurrency}`)
    return data.conversion_rates
  }

  // Convert amount between currencies
  async convertCurrency(
    from: string,
    to: string,
    amount: number
  ): Promise<CurrencyConversion> {
    const data = await this.makeRequest(`/pair/${from}/${to}/${amount}`)
    
    return {
      from: data.base_code,
      to: data.target_code,
      amount: amount,
      result: data.conversion_result,
      rate: data.conversion_rate,
      timestamp: Date.now()
    }
  }

  // Get supported currencies
  async getSupportedCurrencies(): Promise<{ [code: string]: string }> {
    const data = await this.makeRequest('/codes')
    const currencies: { [code: string]: string } = {}
    
    data.supported_codes.forEach(([code, name]: [string, string]) => {
      currencies[code] = name
    })
    
    return currencies
  }

  // Get historical exchange rates (requires paid plan, fallback to current)
  async getHistoricalRates(
    baseCurrency: string,
    date: string // YYYY-MM-DD format
  ): Promise<ExchangeRates> {
    try {
      // Note: Historical data requires paid plan
      // Fallback to current rates for free tier
      console.warn('Historical rates require paid plan, using current rates')
      return await this.getExchangeRates(baseCurrency)
    } catch (error) {
      console.error('Historical rates not available:', error)
      return await this.getExchangeRates(baseCurrency)
    }
  }

  // Bulk currency conversion for multiple amounts
  async bulkConvert(
    conversions: Array<{ from: string; to: string; amount: number }>
  ): Promise<CurrencyConversion[]> {
    const results = await Promise.all(
      conversions.map(({ from, to, amount }) =>
        this.convertCurrency(from, to, amount)
      )
    )
    return results
  }

  // Get popular currencies for the platform
  getPopularCurrencies(): Array<{ code: string; name: string; symbol: string }> {
    return [
      { code: 'USD', name: 'US Dollar', symbol: '$' },
      { code: 'EUR', name: 'Euro', symbol: '€' },
      { code: 'GBP', name: 'British Pound', symbol: '£' },
      { code: 'MUR', name: 'Mauritian Rupee', symbol: '₨' },
      { code: 'JPY', name: 'Japanese Yen', symbol: '¥' },
      { code: 'CAD', name: 'Canadian Dollar', symbol: 'C$' },
      { code: 'AUD', name: 'Australian Dollar', symbol: 'A$' },
      { code: 'CHF', name: 'Swiss Franc', symbol: 'CHF' },
      { code: 'CNY', name: 'Chinese Yuan', symbol: '¥' },
      { code: 'INR', name: 'Indian Rupee', symbol: '₹' }
    ]
  }

  // Format currency value with proper symbol
  formatCurrency(amount: number, currency: string, locale = 'en-US'): string {
    try {
      return new Intl.NumberFormat(locale, {
        style: 'currency',
        currency: currency,
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      }).format(amount)
    } catch (error) {
      // Fallback formatting
      const symbols: { [key: string]: string } = {
        'USD': '$', 'EUR': '€', 'GBP': '£', 'MUR': '₨',
        'JPY': '¥', 'CAD': 'C$', 'AUD': 'A$', 'CHF': 'CHF',
        'CNY': '¥', 'INR': '₹'
      }
      
      const symbol = symbols[currency] || currency
      return `${symbol}${amount.toFixed(2)}`
    }
  }

  // Check if currency is supported
  async isCurrencySupported(currency: string): Promise<boolean> {
    try {
      const currencies = await this.getSupportedCurrencies()
      return currency in currencies
    } catch (error) {
      return false
    }
  }

  // Get currency info
  getCurrencyInfo(code: string) {
    const popular = this.getPopularCurrencies()
    return popular.find(currency => currency.code === code) || {
      code,
      name: code,
      symbol: code
    }
  }

  // Clear cache (useful for testing or forced refresh)
  clearCache(): void {
    this.cache.clear()
  }

  // Get cache statistics
  getCacheStats() {
    return {
      size: this.cache.size,
      timeout: this.cacheTimeout,
      entries: Array.from(this.cache.keys())
    }
  }
}

export const currencyService = new CurrencyService()