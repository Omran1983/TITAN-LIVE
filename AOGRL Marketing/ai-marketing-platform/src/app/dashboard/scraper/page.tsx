'use client'

import { useState } from 'react'
import { toast } from 'react-hot-toast'
import {
  CpuChipIcon,
  MagnifyingGlassIcon,
  GlobeAltIcon,
  ChartBarIcon,
  PlayIcon,
  SparklesIcon,
  BoltIcon,
  FireIcon
} from '@heroicons/react/24/outline'

// Mock data for demonstration
const mockScraperData = [
  {
    id: '1',
    type: 'COMPETITOR_PRICING',
    url: 'https://competitor-example.com',
    title: 'Competitor Product Pricing Analysis',
    scrapedAt: new Date().toISOString(),
    content: {
      products: [
        { name: 'Premium Widget', price: 299, currency: 'USD' },
        { name: 'Standard Widget', price: 199, currency: 'USD' },
        { name: 'Basic Widget', price: 99, currency: 'USD' }
      ],
      averagePrice: 199,
      totalProducts: 3
    },
    metadata: {
      averagePrice: 199,
      productsFound: 3
    }
  },
  {
    id: '2',
    type: 'SOCIAL_MEDIA_METRICS',
    url: 'https://instagram.com/competitor',
    title: 'Competitor Social Media Analysis',
    scrapedAt: new Date().toISOString(),
    content: {
      platform: 'instagram',
      followers: 125000,
      following: 1200,
      posts: 450,
      engagementRate: 3.5,
      topHashtags: ['marketing', 'business', 'innovation', 'growth']
    },
    metadata: {
      platform: 'instagram',
      followers: 125000,
      engagementRate: 3.5
    }
  },
  {
    id: '3',
    type: 'MARKET_TRENDS',
    url: 'https://trends.google.com/marketing',
    title: 'Marketing Industry Trends',
    scrapedAt: new Date().toISOString(),
    content: {
      industry: 'Marketing',
      trends: [
        { keyword: 'AI marketing', searchVolume: 50000, trend: 'up', change: 25 },
        { keyword: 'social commerce', searchVolume: 30000, trend: 'up', change: 18 },
        { keyword: 'email marketing', searchVolume: 80000, trend: 'stable', change: 2 }
      ],
      sentiment: { overall: 0.3, positive: 65, negative: 20, neutral: 15 }
    },
    metadata: {
      trendsCount: 3,
      overallSentiment: 0.3
    }
  }
]

const SCRAPER_TYPES = [
  { value: 'COMPETITOR_PRICING', label: 'Competitor Pricing', icon: '💰', description: 'Track competitor product prices and positioning' },
  { value: 'COMPETITOR_PRODUCTS', label: 'Competitor Products', icon: '🛍️', description: 'Monitor competitor product catalogs and features' },
  { value: 'SOCIAL_MEDIA_METRICS', label: 'Social Media Metrics', icon: '📱', description: 'Analyze competitor social media performance' },
  { value: 'MARKET_TRENDS', label: 'Market Trends', icon: '📈', description: 'Track industry trends and keyword popularity' },
  { value: 'NEWS_SENTIMENT', label: 'News Sentiment', icon: '📰', description: 'Monitor brand mentions and sentiment analysis' },
  { value: 'INDUSTRY_REPORTS', label: 'Industry Reports', icon: '📊', description: 'Scrape industry reports and market research' }
]

export default function ScraperDemoPage() {
  const [selectedType, setSelectedType] = useState('')
  const [targetUrl, setTargetUrl] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [results, setResults] = useState<any[]>(mockScraperData)
  const [selectedResult, setSelectedResult] = useState<any>(null)

  const handleManualScrape = async () => {
    if (!selectedType || !targetUrl) {
      toast.error('Please select a scraper type and enter a URL')
      return
    }

    setIsLoading(true)
    
    // Simulate scraping delay
    setTimeout(() => {
      const newResult = {
        id: Date.now().toString(),
        type: selectedType,
        url: targetUrl,
        title: `Scraped data from ${new URL(targetUrl).hostname}`,
        scrapedAt: new Date().toISOString(),
        content: { demo: true, message: 'This is demo data. In production, this would contain real scraped data.' },
        metadata: { scrapeType: selectedType, demo: true }
      }
      
      setResults([newResult, ...results])
      setIsLoading(false)
      toast.success('Scraping completed successfully!')
      
      // Clear form
      setSelectedType('')
      setTargetUrl('')
    }, 2000)
  }

  const getTypeIcon = (type: string) => {
    const typeInfo = SCRAPER_TYPES.find(t => t.value === type)
    return typeInfo?.icon || '🔍'
  }

  const getTypeLabel = (type: string) => {
    const typeInfo = SCRAPER_TYPES.find(t => t.value === type)
    return typeInfo?.label || type
  }

  return (
    <div className="animate-slide-up space-y-8">
      {/* Premium Header */}
      <div className="surface-premium p-8 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-purple-500/20 via-blue-500/20 to-green-500/20 animate-gradient-flow"></div>
        <div className="relative z-10">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center space-x-4 mb-4">
                <div className="w-16 h-16 bg-gradient-to-br from-purple-600 to-blue-600 rounded-2xl flex items-center justify-center shadow-lg">
                  <CpuChipIcon className="w-8 h-8 text-white" />
                </div>
                <div>
                  <h1 className="text-display">Data Intelligence Center</h1>
                  <p className="text-body text-gray-600 mt-2">
                    Advanced market intelligence and competitive analysis • Real-time data scraping
                  </p>
                </div>
              </div>
              
              <div className="flex items-center space-x-6 text-sm">
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <SparklesIcon className="w-4 h-4 text-purple-500" />
                  <span className="font-semibold">AI-Powered Analysis</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <ChartBarIcon className="w-4 h-4 text-blue-500" />
                  <span className="font-semibold">{results.length} Data Points</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <BoltIcon className="w-4 h-4 text-yellow-500" />
                  <span className="font-semibold">Real-time Intelligence</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Scraper Types Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {SCRAPER_TYPES.map((type, index) => (
          <div
            key={type.value}
            className="surface-elevated-high hover-lift p-6 cursor-pointer"
            style={{ animationDelay: `${index * 100}ms` }}
            onClick={() => setSelectedType(type.value)}
          >
            <div className="flex items-start space-x-4">
              <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-blue-600 rounded-xl flex items-center justify-center text-xl shadow-lg">
                {type.icon}
              </div>
              <div className="flex-1">
                <h3 className="text-title font-bold text-gray-900 mb-2">{type.label}</h3>
                <p className="text-sm text-gray-600">{type.description}</p>
                {selectedType === type.value && (
                  <div className="mt-3 px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-xs font-medium inline-block">
                    Selected
                  </div>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Manual Scraper */}
      <div className="surface-elevated-high p-8">
        <div className="flex items-center space-x-3 mb-6">
          <PlayIcon className="w-6 h-6 text-blue-600" />
          <h2 className="text-headline">Manual Scraper</h2>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Scraper Type</label>
            <select
              value={selectedType}
              onChange={(e) => setSelectedType(e.target.value)}
              className="form-input w-full"
            >
              <option value="">Select scraper type...</option>
              {SCRAPER_TYPES.map(type => (
                <option key={type.value} value={type.value}>
                  {type.icon} {type.label}
                </option>
              ))}
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Target URL</label>
            <input
              type="url"
              value={targetUrl}
              onChange={(e) => setTargetUrl(e.target.value)}
              placeholder="https://example.com"
              className="form-input w-full"
            />
          </div>
          
          <div className="flex items-end">
            <button
              onClick={handleManualScrape}
              disabled={isLoading || !selectedType || !targetUrl}
              className="btn-primary w-full flex items-center justify-center space-x-2"
            >
              {isLoading ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  <span>Scraping...</span>
                </>
              ) : (
                <>
                  <PlayIcon className="w-4 h-4" />
                  <span>Start Scraping</span>
                </>
              )}
            </button>
          </div>
        </div>
        
        {selectedType && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="flex items-center space-x-2 mb-2">
              <span className="text-lg">{getTypeIcon(selectedType)}</span>
              <span className="font-semibold text-blue-800">{getTypeLabel(selectedType)}</span>
            </div>
            <p className="text-sm text-blue-700">
              {SCRAPER_TYPES.find(t => t.value === selectedType)?.description}
            </p>
          </div>
        )}
      </div>

      {/* Results */}
      <div className="surface-elevated-high">
        <div className="p-6 border-b border-gray-100">
          <div className="flex items-center justify-between">
            <h2 className="text-headline">Intelligence Data</h2>
            <div className="flex items-center space-x-2 text-sm text-gray-500">
              <FireIcon className="w-4 h-4 text-orange-500" />
              <span>Live Data</span>
            </div>
          </div>
        </div>
        
        <div className="divide-y divide-gray-100">
          {results.map((result, index) => (
            <div
              key={result.id}
              className="p-6 hover:bg-gray-50 transition-colors cursor-pointer"
              onClick={() => setSelectedResult(result)}
              style={{ animationDelay: `${index * 50}ms` }}
            >
              <div className="flex items-start justify-between">
                <div className="flex items-start space-x-3">
                  <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center text-sm">
                    {getTypeIcon(result.type)}
                  </div>
                  <div>
                    <h3 className="font-semibold text-gray-900">{result.title}</h3>
                    <p className="text-sm text-gray-600 mt-1">{result.url}</p>
                    <div className="flex items-center space-x-4 mt-2 text-xs text-gray-500">
                      <span>Type: {getTypeLabel(result.type)}</span>
                      <span>Scraped: {new Date(result.scrapedAt).toLocaleString()}</span>
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-medium text-blue-600">View Details</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Result Detail Modal */}
      {selectedResult && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="surface-premium max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-blue-600 rounded-xl flex items-center justify-center text-lg">
                    {getTypeIcon(selectedResult.type)}
                  </div>
                  <div>
                    <h2 className="text-headline">{selectedResult.title}</h2>
                    <p className="text-sm text-gray-600">{selectedResult.url}</p>
                  </div>
                </div>
                <button
                  onClick={() => setSelectedResult(null)}
                  className="text-gray-400 hover:text-gray-600 text-2xl"
                >
                  ×
                </button>
              </div>
            </div>
            <div className="p-6">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div>
                  <h3 className="font-semibold text-gray-800 mb-3">Raw Data</h3>
                  <pre className="bg-gray-50 p-4 rounded-lg text-sm overflow-auto max-h-80">
                    {JSON.stringify(selectedResult.content, null, 2)}
                  </pre>
                </div>
                <div>
                  <h3 className="font-semibold text-gray-800 mb-3">Metadata</h3>
                  <pre className="bg-gray-50 p-4 rounded-lg text-sm overflow-auto max-h-80">
                    {JSON.stringify(selectedResult.metadata, null, 2)}
                  </pre>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}