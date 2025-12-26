import { BaseScraper, ScrapedData, ScraperConfig } from './base-scraper'

export interface MarketTrend {
  keyword: string
  searchVolume: number
  trend: 'up' | 'down' | 'stable'
  change: number // percentage change
  relatedKeywords: string[]
}

export interface NewsItem {
  title: string
  summary: string
  sentiment: 'positive' | 'negative' | 'neutral'
  source: string
  url: string
  publishedAt: string
  relevanceScore: number
}

export interface MarketIntelligence {
  industry: string
  trends: MarketTrend[]
  news: NewsItem[]
  insights: {
    growingTopics: string[]
    decliningTopics: string[]
    emergingOpportunities: string[]
    threats: string[]
  }
  sentiment: {
    overall: number // -1 to 1
    positive: number
    negative: number
    neutral: number
  }
}

export class MarketIntelligenceScraper extends BaseScraper {
  constructor(config: ScraperConfig = {}) {
    super({
      delay: 2000,
      retries: 3,
      ...config
    })
  }

  async scrape(url: string): Promise<ScrapedData> {
    const $ = await this.fetchPage(url)
    
    const marketData = await this.extractMarketData($, url)
    const hash = this.generateHash(marketData)

    return {
      url,
      title: this.extractText($, 'title'),
      content: marketData,
      metadata: {
        scrapeType: 'market_intelligence',
        industry: marketData.industry,
        trendsCount: marketData.trends.length,
        newsCount: marketData.news.length,
        overallSentiment: marketData.sentiment.overall
      },
      hash,
      scrapedAt: new Date()
    }
  }

  private async extractMarketData($: any, url: string): Promise<MarketIntelligence> {
    const sourceType = this.detectSourceType(url)
    
    let marketData: MarketIntelligence = {
      industry: 'General',
      trends: [],
      news: [],
      insights: {
        growingTopics: [],
        decliningTopics: [],
        emergingOpportunities: [],
        threats: []
      },
      sentiment: {
        overall: 0,
        positive: 0,
        negative: 0,
        neutral: 0
      }
    }

    switch (sourceType) {
      case 'google_trends':
        marketData.trends = this.extractGoogleTrends($)
        break
      case 'news_site':
        marketData.news = this.extractNews($, url)
        break
      case 'industry_report':
        marketData = this.extractIndustryReport($, url)
        break
      default:
        marketData = this.extractGenericMarketData($, url)
    }

    // Calculate sentiment analysis
    marketData.sentiment = this.calculateSentiment(marketData.news)
    
    // Generate insights
    marketData.insights = this.generateInsights(marketData.trends, marketData.news)

    return marketData
  }

  private detectSourceType(url: string): string {
    if (url.includes('trends.google.com')) return 'google_trends'
    if (url.includes('news.') || url.includes('reuters.') || url.includes('bloomberg.')) return 'news_site'
    if (url.includes('report') || url.includes('research') || url.includes('market')) return 'industry_report'
    return 'generic'
  }

  private extractGoogleTrends($: any): MarketTrend[] {
    const trends: MarketTrend[] = []
    
    // Google Trends specific selectors
    $('.trends-table-row, .trend-item').each((_, element) => {
      const $trend = $(element)
      const keyword = this.extractText($trend, '.trend-term, .keyword')
      const volumeText = this.extractText($trend, '.search-volume, .volume')
      const changeText = this.extractText($trend, '.change, .trend-change')
      
      if (keyword) {
        const searchVolume = this.parseSearchVolume(volumeText)
        const change = this.parsePercentage(changeText)
        const trend = change > 5 ? 'up' : change < -5 ? 'down' : 'stable'
        
        trends.push({
          keyword,
          searchVolume,
          trend,
          change,
          relatedKeywords: [] // Would need additional API calls
        })
      }
    })
    
    return trends
  }

  private extractNews($: any, baseUrl: string): NewsItem[] {
    const news: NewsItem[] = []
    
    // Generic news selectors
    $('article, .news-item, .story, .post').each((_, element) => {
      const $article = $(element)
      
      const title = this.extractText($article, 'h1, h2, h3, .title, .headline')
      const summary = this.extractText($article, '.summary, .excerpt, .description, p').substring(0, 300)
      const source = this.extractText($article, '.source, .author, .byline')
      const linkUrl = this.extractAttribute($article, 'a', 'href')
      const publishedText = this.extractText($article, '.date, .published, time')
      
      if (title && summary) {
        news.push({
          title,
          summary,
          sentiment: this.analyzeSentiment(title + ' ' + summary),
          source: source || new URL(baseUrl).hostname,
          url: linkUrl ? new URL(linkUrl, baseUrl).href : baseUrl,
          publishedAt: this.parseDate(publishedText),
          relevanceScore: this.calculateRelevance(title, summary)
        })
      }
    })
    
    return news.slice(0, 20) // Limit to 20 articles
  }

  private extractIndustryReport($: any, url: string): MarketIntelligence {
    const industry = this.extractText($, 'h1, .industry, .market-name') || 'General'
    
    // Extract key insights from report structure
    const insights = {
      growingTopics: this.extractMultiple($, '.growth, .opportunity, .trend-up'),
      decliningTopics: this.extractMultiple($, '.decline, .threat, .trend-down'),
      emergingOpportunities: this.extractMultiple($, '.emerging, .opportunity, .new-trend'),
      threats: this.extractMultiple($, '.risk, .threat, .challenge')
    }

    return {
      industry,
      trends: [],
      news: this.extractNews($, url),
      insights,
      sentiment: { overall: 0, positive: 0, negative: 0, neutral: 0 }
    }
  }

  private extractGenericMarketData($: any, url: string): MarketIntelligence {
    return {
      industry: this.extractText($, 'h1, title').split(' ')[0] || 'General',
      trends: [],
      news: this.extractNews($, url),
      insights: {
        growingTopics: this.extractMultiple($, 'h2, h3').slice(0, 5),
        decliningTopics: [],
        emergingOpportunities: [],
        threats: []
      },
      sentiment: { overall: 0, positive: 0, negative: 0, neutral: 0 }
    }
  }

  private parseSearchVolume(text: string): number {
    const cleanText = text.replace(/[^\d.KMB]/gi, '').toLowerCase()
    const number = parseFloat(cleanText)
    
    if (cleanText.includes('k')) return Math.floor(number * 1000)
    if (cleanText.includes('m')) return Math.floor(number * 1000000)
    if (cleanText.includes('b')) return Math.floor(number * 1000000000)
    
    return Math.floor(number) || 0
  }

  private parsePercentage(text: string): number {
    const match = text.match(/([+-]?\d+(?:\.\d+)?)%/)
    return match ? parseFloat(match[1]) : 0
  }

  private parseDate(dateText: string): string {
    try {
      // Try to parse various date formats
      const date = new Date(dateText)
      return date.toISOString()
    } catch {
      return new Date().toISOString()
    }
  }

  private analyzeSentiment(text: string): 'positive' | 'negative' | 'neutral' {
    const positiveWords = ['growth', 'increase', 'opportunity', 'success', 'improve', 'rising', 'gain', 'profit', 'boost']
    const negativeWords = ['decline', 'decrease', 'threat', 'loss', 'fall', 'drop', 'crisis', 'risk', 'concern']
    
    const lowercaseText = text.toLowerCase()
    const positiveCount = positiveWords.filter(word => lowercaseText.includes(word)).length
    const negativeCount = negativeWords.filter(word => lowercaseText.includes(word)).length
    
    if (positiveCount > negativeCount) return 'positive'
    if (negativeCount > positiveCount) return 'negative'
    return 'neutral'
  }

  private calculateRelevance(title: string, summary: string): number {
    // Simple relevance scoring based on content quality
    const text = (title + ' ' + summary).toLowerCase()
    const marketingKeywords = ['marketing', 'advertising', 'campaign', 'brand', 'customer', 'digital', 'social media']
    
    const relevanceScore = marketingKeywords.filter(keyword => text.includes(keyword)).length
    return Math.min(relevanceScore / marketingKeywords.length, 1) * 100
  }

  private calculateSentiment(news: NewsItem[]): { overall: number; positive: number; negative: number; neutral: number } {
    if (news.length === 0) {
      return { overall: 0, positive: 0, negative: 0, neutral: 0 }
    }

    const positive = news.filter(item => item.sentiment === 'positive').length
    const negative = news.filter(item => item.sentiment === 'negative').length
    const neutral = news.filter(item => item.sentiment === 'neutral').length
    
    const overall = (positive - negative) / news.length
    
    return {
      overall,
      positive: (positive / news.length) * 100,
      negative: (negative / news.length) * 100,
      neutral: (neutral / news.length) * 100
    }
  }

  private generateInsights(trends: MarketTrend[], news: NewsItem[]): MarketIntelligence['insights'] {
    const growingTopics = trends
      .filter(trend => trend.trend === 'up')
      .map(trend => trend.keyword)
      .slice(0, 5)

    const decliningTopics = trends
      .filter(trend => trend.trend === 'down')
      .map(trend => trend.keyword)
      .slice(0, 5)

    const emergingOpportunities = news
      .filter(item => item.sentiment === 'positive' && item.relevanceScore > 50)
      .map(item => item.title.split(' ').slice(0, 3).join(' '))
      .slice(0, 5)

    const threats = news
      .filter(item => item.sentiment === 'negative' && item.relevanceScore > 50)
      .map(item => item.title.split(' ').slice(0, 3).join(' '))
      .slice(0, 5)

    return {
      growingTopics,
      decliningTopics,
      emergingOpportunities,
      threats
    }
  }
}