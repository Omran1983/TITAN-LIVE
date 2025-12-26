import axios from 'axios'

// Create axios instance with default config
export const api = axios.create({
  baseURL: '/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add request interceptor for authentication
api.interceptors.request.use(
  (config) => {
    // Add auth headers if needed
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

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

// Add response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    // Prevent logging of empty or meaningless errors
    try {
      const errorInfo: any = {
        message: error.message || 'Unknown error',
        status: error.response?.status || null,
        url: error.config?.url || null,
        method: error.config?.method || null
      }

      // Only include response data if it's meaningful
      if (error.response?.data && !isEmptyObject(error.response.data)) {
        errorInfo.response = error.response.data
      }

      // Log only meaningful errors
      if (isMeaningfulError(errorInfo.message) || errorInfo.status || 
          (errorInfo.response && !isEmptyObject(errorInfo.response))) {
        // Additional check to ensure we're not logging empty objects
        const hasMeaningfulResponse = errorInfo.response && 
          (typeof errorInfo.response === 'string' || !isEmptyObject(errorInfo.response))
        
        if (isMeaningfulError(errorInfo.message) || errorInfo.status || hasMeaningfulResponse) {
          console.error('API Error:', errorInfo)
        }
      }
    } catch (logError) {
      // Silent fail on logging errors to prevent infinite loops
      // Only log if it's a meaningful error
      if (logError instanceof Error && isMeaningfulError(logError.message)) {
        console.error('Error logging failed:', logError.message)
      }
    }
    
    return Promise.reject(error)
  }
)

// Campaign API
export const campaignApi = {
  getAll: () => api.get('/campaigns'),
  getById: (id: string) => api.get(`/campaigns/${id}`),
  create: (data: any) => api.post('/campaigns', data),
  update: (id: string, data: any) => api.put(`/campaigns/${id}`, data),
  delete: (id: string) => api.delete(`/campaigns/${id}`),
  start: (id: string) => api.post(`/campaigns/${id}/start`),
  pause: (id: string) => api.post(`/campaigns/${id}/pause`),
  stop: (id: string) => api.post(`/campaigns/${id}/stop`),
}

// Product API
export const productApi = {
  getAll: () => api.get('/products'),
  getById: (id: string) => api.get(`/products/${id}`),
  create: (data: any) => api.post('/products', data),
  update: (id: string, data: any) => api.put(`/products/${id}`, data),
  delete: (id: string) => api.delete(`/products/${id}`),
}

// Creative API
export const creativeApi = {
  getAll: () => api.get('/creatives'),
  getById: (id: string) => api.get(`/creatives/${id}`),
  create: (data: any) => api.post('/creatives', data),
  generate: (data: any) => api.post('/creative/generate', data),
  generateVariations: (data: any) => api.post('/creative/variations', data),
  getGenerationStatus: (id: string) => api.get(`/creative/status/${id}`),
  analyzeContent: (data: any) => api.post('/creative/analyze', data),
  delete: (id: string) => api.delete(`/creatives/${id}`),
}

// Analytics API
export const analyticsApi = {
  getDashboard: () => api.get('/analytics/dashboard'),
  getCampaign: (campaignId: string) => api.get(`/analytics/campaign/${campaignId}`),
  getOverview: (params?: any) => api.get('/analytics/overview', { params }),
  generateReport: (data: any) => api.post('/analytics/insights', data),
  getAnomalies: () => api.get('/analytics/insights'),
  getAttribution: (campaignId: string) => api.get(`/analytics/attribution/${campaignId}`),
  getMarketIntelligence: (industry?: string) => 
    api.get('/analytics/market-intelligence', { params: { industry } }),
}

// Queue API
export const queueApi = {
  getJobs: (params?: any) => api.get('/queue', { params }),
  getJob: (id: string) => api.get(`/queue/${id}`),
  getStats: () => api.get('/queue?action=stats'),
  getMetrics: (timeframe: string = '24h') => api.get(`/queue?action=metrics&timeframe=${timeframe}`),
  getWorkers: () => api.get('/queue?action=workers'),
  createJob: (data: any) => api.post('/queue', { action: 'create', ...data }),
  pauseJob: (id: string) => api.post(`/queue/${id}`, { action: 'pause' }),
  resumeJob: (id: string) => api.post(`/queue/${id}`, { action: 'resume' }),
  cancelJob: (id: string) => api.post(`/queue/${id}`, { action: 'cancel' }),
  retryJob: (id: string) => api.post(`/queue/${id}`, { action: 'retry' }),
  deleteJob: (id: string) => api.delete(`/queue/${id}`),
  bulkPause: (jobIds: string[]) => api.post('/queue', { action: 'bulk_pause', jobIds }),
  bulkRetry: (jobIds: string[]) => api.post('/queue', { action: 'bulk_retry', jobIds }),
  createTemplate: (data: any) => api.post('/queue', { action: 'create_template', ...data }),
}

// Audit API
export const auditApi = {
  getLogs: (params?: any) => api.get('/audit', { params }),
  getLog: (id: string) => api.get(`/audit/${id}`),
}

// Client API (for your marketing agency)
export const clientApi = {
  getAll: () => api.get('/clients'),
  getById: (id: string) => api.get(`/clients/${id}`),
  create: (data: any) => api.post('/clients', data),
  update: (id: string, data: any) => api.put(`/clients/${id}`, data),
  delete: (id: string) => api.delete(`/clients/${id}`),
}

// Scraper API (for market intelligence)
export const scraperApi = {
  getData: (params?: any) => api.get('/scraper', { params }),
  scrapeManual: (data: any) => api.post('/scraper', data),
  getJobs: () => api.get('/scraper/jobs'),
  createJob: (data: any) => api.post('/scraper/jobs', data),
  executeJob: (id: string) => api.get(`/scraper/jobs/${id}`),
  updateJob: (id: string, data: any) => api.put(`/scraper/jobs/${id}`, data),
  deleteJob: (id: string) => api.delete(`/scraper/jobs/${id}`),
  getAnalytics: () => api.get('/scraper/analytics'),
}

// Budget API (for optimization and monitoring)
export const budgetApi = {
  optimize: (data: any) => api.post('/budget/optimize', data),
  getAlerts: () => api.get('/budget/alerts'),
  getMonitoring: () => api.get('/budget/optimize'),
  getForecast: (campaignId: string, days?: number) => 
    api.get(`/budget/forecast/${campaignId}`, { params: { days } }),
}

// User API (for preferences and settings)
export const userApi = {
  getPreferences: () => api.get('/user/preferences'),
  updatePreferences: (data: any) => api.put('/user/preferences', data),
}

export default api