import axios, { AxiosInstance, AxiosError } from 'axios'
import { toast } from 'react-hot-toast'

// Create a more robust API service
class ApiService {
  private api: AxiosInstance
  private isDevelopment: boolean

  constructor() {
    this.isDevelopment = process.env.NODE_ENV === 'development'
    this.api = axios.create({
      baseURL: '/api',
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
      },
    })

    // Request interceptor
    this.api.interceptors.request.use(
      (config) => {
        // Add any auth headers if needed
        return config
      },
      (error) => {
        return Promise.reject(error)
      }
    )

    // Response interceptor with enhanced error handling
    this.api.interceptors.response.use(
      (response) => response,
      (error: AxiosError) => {
        // Enhanced error handling
        this.handleError(error)
        return Promise.reject(error)
      }
    )
  }

  private handleError(error: AxiosError) {
    // Prevent logging of empty or meaningless errors
    try {
      // Extract meaningful error information
      const errorMessage = error.message || 'Unknown error'
      const errorStatus = error.response?.status || null
      const errorData = error.response?.data
      const errorUrl = error.config?.url || null
      const errorMethod = error.config?.method || null

      // Check if we have any meaningful error information
      const hasMeaningfulMessage = this.isMeaningfulError(errorMessage)
      const hasErrorStatus = errorStatus !== null && errorStatus !== 0
      const hasErrorData = errorData && !this.isEmptyObject(errorData)
      const hasRequestInfo = errorUrl || errorMethod

      // Only show toast for significant errors that affect user experience
      if (hasErrorStatus && errorStatus !== 404) {
        const statusMessages: Record<number, string> = {
          400: 'Invalid request data',
          401: 'Authentication required',
          403: 'Access denied',
          404: 'Resource not found',
          500: 'Server error occurred',
          502: 'Server temporarily unavailable',
          503: 'Service temporarily unavailable',
        }

        const message = statusMessages[errorStatus] || `Error: ${errorMessage}`
        toast.error(message)
      }

      // Only log if we have meaningful information in development
      if (this.isDevelopment && (hasMeaningfulMessage || hasErrorStatus || hasErrorData || hasRequestInfo)) {
        const errorInfo: any = {
          message: hasMeaningfulMessage ? errorMessage : undefined,
          status: errorStatus || undefined,
          url: errorUrl || undefined,
          method: errorMethod || undefined
        }

        // Only include response data if it's meaningful
        if (hasErrorData) {
          errorInfo.response = errorData
        }

        // Only log if we have at least one meaningful piece of information
        const hasSomethingToLog = errorInfo.message || errorInfo.status || 
          (errorInfo.response && !this.isEmptyObject(errorInfo.response))
        
        if (hasSomethingToLog) {
          console.error('API Error:', errorInfo)
        }
      }
    } catch (logError) {
      // Silent fail on logging errors to prevent infinite loops
      if (this.isDevelopment && logError instanceof Error && 
          this.isMeaningfulError(logError.message) && 
          logError !== error) {
        console.error('Error logging failed:', logError.message)
      }
    }
  }

  private isEmptyObject(obj: any): boolean {
    // Handle null, undefined, or non-object values
    if (!obj || typeof obj !== 'object') {
      // For strings, check if they're empty or meaningless
      if (typeof obj === 'string') {
        const meaninglessMessages = ['{}', '""', '[object Object]', 'undefined', 'null', ''];
        return obj.trim() === '' || meaninglessMessages.includes(obj);
      }
      // For other non-object values, they're not "empty objects"
      return typeof obj !== 'object';
    }
    
    // Handle arrays
    if (Array.isArray(obj)) return obj.length === 0;
    
    // Handle plain objects
    return Object.keys(obj).length === 0;
  }

  private isMeaningfulError(message: string): boolean {
    if (!message) return false;
    const meaninglessMessages = ['{}', '""', '[object Object]', 'Network Error', 'Error', ''];
    return !meaninglessMessages.includes(message) && message.trim().length > 0;
  }

  // Generic request methods
  public async get<T>(url: string, params?: any): Promise<T> {
    try {
      const response = await this.api.get<T>(url, { params })
      return response.data
    } catch (error) {
      throw error
    }
  }

  public async post<T>(url: string, data?: any): Promise<T> {
    try {
      const response = await this.api.post<T>(url, data)
      return response.data
    } catch (error) {
      throw error
    }
  }

  public async put<T>(url: string, data?: any): Promise<T> {
    try {
      const response = await this.api.put<T>(url, data)
      return response.data
    } catch (error) {
      throw error
    }
  }

  public async delete<T>(url: string): Promise<T> {
    try {
      const response = await this.api.delete<T>(url)
      return response.data
    } catch (error) {
      throw error
    }
  }
}

// Export singleton instance
export const apiService = new ApiService()

// Export individual API service modules
export const campaignService = {
  getAll: () => apiService.get<any[]>('/campaigns'),
  getById: (id: string) => apiService.get<any>(`/campaigns/${id}`),
  create: (data: any) => apiService.post<any>('/campaigns', data),
  update: (id: string, data: any) => apiService.put<any>(`/campaigns/${id}`, data),
  delete: (id: string) => apiService.delete<any>(`/campaigns/${id}`),
  start: (id: string) => apiService.post<any>(`/campaigns/${id}/start`),
  pause: (id: string) => apiService.post<any>(`/campaigns/${id}/pause`),
  stop: (id: string) => apiService.post<any>(`/campaigns/${id}/stop`),
}

export const productService = {
  getAll: () => apiService.get<any[]>('/products'),
  getById: (id: string) => apiService.get<any>(`/products/${id}`),
  create: (data: any) => apiService.post<any>('/products', data),
  update: (id: string, data: any) => apiService.put<any>(`/products/${id}`, data),
  delete: (id: string) => apiService.delete<any>(`/products/${id}`),
}

export const creativeService = {
  getAll: () => apiService.get<any[]>('/creatives'),
  getById: (id: string) => apiService.get<any>(`/creatives/${id}`),
  create: (data: any) => apiService.post<any>('/creatives', data),
  generate: (data: any) => apiService.post<any>('/creative/generate', data),
  generateVariations: (data: any) => apiService.post<any>('/creative/variations', data),
  getGenerationStatus: (id: string) => apiService.get<any>(`/creative/status/${id}`),
  analyzeContent: (data: any) => apiService.post<any>('/creative/analyze', data),
  delete: (id: string) => apiService.delete<any>(`/creatives/${id}`),
}

export const analyticsService = {
  getDashboard: () => apiService.get<any>('/analytics/dashboard'),
  getCampaign: (campaignId: string) => apiService.get<any>(`/analytics/campaign/${campaignId}`),
  getOverview: (params?: any) => apiService.get<any>('/analytics/overview', params),
  generateReport: (data: any) => apiService.post<any>('/analytics/insights', data),
  getAnomalies: () => apiService.get<any[]>('/analytics/insights'),
  getAttribution: (campaignId: string) => apiService.get<any>(`/analytics/attribution/${campaignId}`),
  getMarketIntelligence: (industry?: string) => 
    apiService.get<any>('/analytics/market-intelligence', { industry }),
}

export const queueService = {
  getJobs: (params?: any) => apiService.get<any[]>('/queue', params),
  getJob: (id: string) => apiService.get<any>(`/queue/${id}`),
  getStats: () => apiService.get<any>('/queue?action=stats'),
  getMetrics: (timeframe: string = '24h') => apiService.get<any>(`/queue?action=metrics&timeframe=${timeframe}`),
  getWorkers: () => apiService.get<any[]>('/queue?action=workers'),
  createJob: (data: any) => apiService.post<any>('/queue', { action: 'create', ...data }),
  pauseJob: (id: string) => apiService.post<any>(`/queue/${id}`, { action: 'pause' }),
  resumeJob: (id: string) => apiService.post<any>(`/queue/${id}`, { action: 'resume' }),
  cancelJob: (id: string) => apiService.post<any>(`/queue/${id}`, { action: 'cancel' }),
  retryJob: (id: string) => apiService.post<any>(`/queue/${id}`, { action: 'retry' }),
  deleteJob: (id: string) => apiService.delete<any>(`/queue/${id}`),
  bulkPause: (jobIds: string[]) => apiService.post<any>('/queue', { action: 'bulk_pause', jobIds }),
  bulkRetry: (jobIds: string[]) => apiService.post<any>('/queue', { action: 'bulk_retry', jobIds }),
  createTemplate: (data: any) => apiService.post<any>('/queue', { action: 'create_template', ...data }),
}

export const auditService = {
  getLogs: (params?: any) => apiService.get<any[]>('/audit', params),
  getLog: (id: string) => apiService.get<any>(`/audit/${id}`),
}

export const clientService = {
  getAll: () => apiService.get<any[]>('/clients'),
  getById: (id: string) => apiService.get<any>(`/clients/${id}`),
  create: (data: any) => apiService.post<any>('/clients', data),
  update: (id: string, data: any) => apiService.put<any>(`/clients/${id}`, data),
  delete: (id: string) => apiService.delete<any>(`/clients/${id}`),
}

export const scraperService = {
  getData: (params?: any) => apiService.get<any>('/scraper', params),
  scrapeManual: (data: any) => apiService.post<any>('/scraper', data),
  getJobs: () => apiService.get<any[]>('/scraper/jobs'),
  createJob: (data: any) => apiService.post<any>('/scraper/jobs', data),
  executeJob: (id: string) => apiService.get<any>(`/scraper/jobs/${id}`),
  updateJob: (id: string, data: any) => apiService.put<any>(`/scraper/jobs/${id}`, data),
  deleteJob: (id: string) => apiService.delete<any>(`/scraper/jobs/${id}`),
  getAnalytics: () => apiService.get<any>('/scraper/analytics'),
}

export const budgetService = {
  optimize: (data: any) => apiService.post<any>('/budget/optimize', data),
  getAlerts: () => apiService.get<any[]>('/budget/alerts'),
  getMonitoring: () => apiService.get<any[]>('/budget/optimize'),
  getForecast: (campaignId: string, days?: number) => 
    apiService.get<any>(`/budget/forecast/${campaignId}`, { days }),
}

export const userService = {
  getPreferences: () => apiService.get<any>('/user/preferences'),
  updatePreferences: (data: any) => apiService.put<any>('/user/preferences', data),
}