import axios from 'axios'
import * as cheerio from 'cheerio'
import { createHash } from 'crypto'

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

// Common user agents for scraping
const USER_AGENTS = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
]

export interface ScrapedData {
  url: string
  title?: string
  content: any
  metadata?: any
  hash: string
  scrapedAt: Date
}

export interface ScraperConfig {
  userAgent?: string
  delay?: number
  retries?: number
  timeout?: number
  headers?: Record<string, string>
  selectors?: Record<string, string>
  filters?: string[]
}

export abstract class BaseScraper {
  protected config: ScraperConfig
  protected userAgent: string

  constructor(config: ScraperConfig = {}) {
    this.config = {
      delay: 1000,
      retries: 3,
      timeout: 30000,
      headers: {},
      ...config
    }
    this.userAgent = USER_AGENTS[Math.floor(Math.random() * USER_AGENTS.length)]
  }

  protected async fetchPage(url: string): Promise<cheerio.CheerioAPI> {
    const headers = {
      'User-Agent': this.config.userAgent || this.userAgent,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      ...this.config.headers
    }

    let attempt = 0
    while (attempt < (this.config.retries || 3)) {
      try {
        // Add delay between requests
        if (attempt > 0 && this.config.delay) {
          await this.sleep(this.config.delay * attempt)
        }

        const response = await axios.get(url, {
          headers,
          timeout: this.config.timeout,
          validateStatus: (status) => status < 500 // Don't throw on 4xx errors
        })

        if (response.status >= 400) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`)
        }

        return cheerio.load(response.data)
      } catch (error: any) {
        attempt++
        
        // More robust error logging to prevent "API Error: {}" messages
        let errorMessage = 'Unknown error'
        
        // Extract meaningful error information
        if (error.response?.data) {
          if (typeof error.response.data === 'string') {
            errorMessage = error.response.data
          } else if (typeof error.response.data === 'object' && !isEmptyObject(error.response.data)) {
            // Check if it's a structured error response
            if (error.response.data.error) {
              errorMessage = error.response.data.error
            } else {
              // Convert object to string but only if it contains meaningful data
              const dataStr = JSON.stringify(error.response.data)
              if (isMeaningfulError(dataStr)) {
                errorMessage = dataStr
              }
            }
          }
        } else if (error.message) {
          errorMessage = error.message
        }
        
        // Only log meaningful errors
        if (isMeaningfulError(errorMessage)) {
          console.error(`Scraping attempt ${attempt} failed for ${url}:`, errorMessage)
        }
        
        if (attempt >= (this.config.retries || 3)) {
          throw new Error(`Failed to fetch ${url} after ${attempt} attempts: ${errorMessage}`)
        }
      }
    }

    throw new Error('Unexpected error in fetchPage')
  }

  protected generateHash(content: any): string {
    const contentString = typeof content === 'string' 
      ? content 
      : JSON.stringify(content)
    return createHash('sha256').update(contentString).digest('hex')
  }

  protected sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  protected extractText($: cheerio.CheerioAPI, selector: string): string {
    return $(selector).text().trim()
  }

  protected extractAttribute($: cheerio.CheerioAPI, selector: string, attribute: string): string {
    return $(selector).attr(attribute) || ''
  }

  protected extractMultiple($: cheerio.CheerioAPI, selector: string): string[] {
    const results: string[] = []
    $(selector).each((_, element) => {
      const text = $(element).text().trim()
      if (text) results.push(text)
    })
    return results
  }

  protected extractPrice(text: string): number | null {
    // Extract price from text (supports multiple currencies)
    const priceRegex = /[\$€£¥₹₨]\s*?(\d+(?:,\d{3})*(?:\.\d{2})?)|(\d+(?:,\d{3})*(?:\.\d{2})?)\s*?[\$€£¥₹₨]/gi
    const match = text.match(priceRegex)
    if (match) {
      const numberStr = match[0].replace(/[^\d.]/g, '')
      return parseFloat(numberStr)
    }
    return null
  }

  // Abstract method to be implemented by specific scrapers
  abstract scrape(url: string): Promise<ScrapedData>
}