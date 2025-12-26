import { BaseScraper, ScrapedData, ScraperConfig } from './base-scraper'

export interface CompetitorProduct {
  name: string
  price: number | null
  currency: string
  description: string
  category: string
  inStock: boolean
  rating: number | null
  reviews: number
  imageUrl: string
  url: string
}

export interface CompetitorPricingData {
  products: CompetitorProduct[]
  averagePrice: number | null
  priceRange: { min: number | null; max: number | null }
  currency: string
  totalProducts: number
}

export class CompetitorScraper extends BaseScraper {
  constructor(config: ScraperConfig = {}) {
    super({
      delay: 2000, // Be respectful to competitor sites
      retries: 2,
      ...config
    })
  }

  async scrape(url: string): Promise<ScrapedData> {
    const $ = await this.fetchPage(url)
    
    const competitorData = await this.extractCompetitorData($, url)
    const hash = this.generateHash(competitorData)

    return {
      url,
      title: this.extractText($, 'title'),
      content: competitorData,
      metadata: {
        scrapeType: 'competitor_analysis',
        productsFound: competitorData.products.length,
        averagePrice: competitorData.averagePrice
      },
      hash,
      scrapedAt: new Date()
    }
  }

  private async extractCompetitorData($: any, baseUrl: string): Promise<CompetitorPricingData> {
    const products: CompetitorProduct[] = []
    
    // Generic selectors - can be customized per site
    const productSelectors = this.config.selectors || {
      product: '.product, .item, [data-product]',
      name: '.product-title, .item-title, h3, h4',
      price: '.price, .cost, .amount, [data-price]',
      description: '.description, .summary, .excerpt',
      category: '.category, .type, .tag',
      stock: '.stock, .availability',
      rating: '.rating, .stars, [data-rating]',
      reviews: '.reviews, .review-count',
      image: 'img, [data-image]',
      link: 'a'
    }

    $(productSelectors.product).each((_, element) => {
      try {
        const $product = $(element)
        
        const name = this.extractText($product, productSelectors.name)
        if (!name) return // Skip if no name found
        
        const priceText = this.extractText($product, productSelectors.price)
        const price = this.extractPrice(priceText)
        
        const description = this.extractText($product, productSelectors.description)
        const category = this.extractText($product, productSelectors.category)
        const stockText = this.extractText($product, productSelectors.stock).toLowerCase()
        const inStock = !stockText.includes('out') && !stockText.includes('unavailable')
        
        const ratingText = this.extractText($product, productSelectors.rating)
        const rating = parseFloat(ratingText) || null
        
        const reviewsText = this.extractText($product, productSelectors.reviews)
        const reviews = parseInt(reviewsText.replace(/[^\d]/g, '')) || 0
        
        const imageUrl = this.extractAttribute($product, productSelectors.image, 'src')
        const linkUrl = this.extractAttribute($product, productSelectors.link, 'href')
        
        // Determine currency from price text
        let currency = 'USD'
        if (priceText.includes('€')) currency = 'EUR'
        else if (priceText.includes('£')) currency = 'GBP'
        else if (priceText.includes('₹')) currency = 'INR'
        else if (priceText.includes('₨')) currency = 'MUR'
        
        const product: CompetitorProduct = {
          name,
          price,
          currency,
          description,
          category,
          inStock,
          rating,
          reviews,
          imageUrl: imageUrl ? new URL(imageUrl, baseUrl).href : '',
          url: linkUrl ? new URL(linkUrl, baseUrl).href : baseUrl
        }
        
        products.push(product)
      } catch (error) {
        console.warn('Error extracting product data:', error)
      }
    })

    // Calculate pricing analytics
    const prices = products.map(p => p.price).filter(p => p !== null) as number[]
    const averagePrice = prices.length > 0 ? prices.reduce((a, b) => a + b, 0) / prices.length : null
    const priceRange = prices.length > 0 
      ? { min: Math.min(...prices), max: Math.max(...prices) }
      : { min: null, max: null }

    return {
      products,
      averagePrice,
      priceRange,
      currency: products[0]?.currency || 'USD',
      totalProducts: products.length
    }
  }

  // Method to scrape specific competitor sites with custom selectors
  async scrapeEcommerceSite(url: string, customSelectors: Record<string, string>): Promise<ScrapedData> {
    this.config.selectors = customSelectors
    return this.scrape(url)
  }
}