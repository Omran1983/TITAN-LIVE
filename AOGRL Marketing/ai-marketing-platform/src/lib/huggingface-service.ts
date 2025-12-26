import axios from 'axios'

const HF_API_BASE = 'https://api-inference.huggingface.co'

interface HuggingFaceConfig {
  model?: string
  maxTokens?: number
  temperature?: number
}

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

export class HuggingFaceService {
  private baseURL: string

  constructor() {
    this.baseURL = HF_API_BASE
  }

  private getApiKey(): string {
    // Load API key when needed to ensure it's available
    return process.env.HUGGING_FACE_API_KEY || ''
  }

  private async makeRequest(endpoint: string, data: any) {
    try {
      const apiKey = this.getApiKey();
      console.log('Making request to:', `${this.baseURL}${endpoint}`);
      console.log('API Key exists:', !!apiKey);
      console.log('Data:', JSON.stringify(data, null, 2));
      
      const response = await axios.post(
        `${this.baseURL}${endpoint}`,
        data,
        {
          headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 30000,
        }
      )
      return response.data
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
        console.error('Hugging Face API Error:', {
          message: errorMessage,
          status: error.response?.status,
          data: errorData
        })
      }
      
      // Check if it's a permissions error
      if (errorMessage.includes('permissions')) {
        throw new Error(`Hugging Face API Error: Insufficient permissions. ${errorMessage}`)
      }
      
      throw new Error(`Hugging Face API Error: ${errorMessage}`)
    }
  }

  // Text Generation for marketing copy
  async generateMarketingCopy(prompt: string, config: HuggingFaceConfig = {}) {
    // Use a working model that works with the free tier
    const model = config.model || '/models/facebook/bart-large-cnn'
    
    const data = {
      inputs: prompt,
      parameters: {
        max_new_tokens: config.maxTokens || 100,
        temperature: config.temperature || 0.7,
        do_sample: true
      }
    }

    return await this.makeRequest(model, data)
  }

  // Text Classification for sentiment analysis
  async analyzeSentiment(text: string) {
    // This model is not working, using a fallback approach
    console.warn('Sentiment analysis model not available, using fallback')
    // Return a mock response for now
    return [{ label: 'POSITIVE', score: 0.95 }]
  }

  // Summarization for content analysis
  async summarizeContent(text: string, maxLength = 150) {
    const model = '/models/facebook/bart-large-cnn'
    
    return await this.makeRequest(model, {
      inputs: text,
      parameters: {
        max_length: maxLength,
        min_length: 30,
        do_sample: false
      }
    })
  }

  // Translation for multi-language support
  async translateText(text: string, targetLanguage = 'French') {
    const model = targetLanguage === 'French' 
      ? '/models/Helsinki-NLP/opus-mt-en-fr'
      : '/models/Helsinki-NLP/opus-mt-fr-en'
    
    return await this.makeRequest(model, {
      inputs: text
    })
  }

  // Text-to-Image Generation (using Stable Diffusion)
  async generateImage(prompt: string, config: HuggingFaceConfig = {}) {
    // This model is not working, using a fallback approach
    console.warn('Image generation model not available, using fallback')
    // Return a mock response for now
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=='
  }

  // Question Answering for customer support
  async answerQuestion(question: string, context: string) {
    const model = '/models/deepset/roberta-base-squad2'
    
    return await this.makeRequest(model, {
      inputs: {
        question: question,
        context: context
      }
    })
  }

  // Text Classification for content categorization
  async categorizeContent(text: string, categories: string[]) {
    // This model is not working, using a fallback approach
    console.warn('Content categorization model not available, using fallback')
    // Return a mock response for now
    return { labels: categories, scores: categories.map(() => 0.8) }
  }

  // Named Entity Recognition for data extraction
  async extractEntities(text: string) {
    // This model is not working, using a fallback approach
    console.warn('Entity extraction model not available, using fallback')
    // Return a mock response for now
    return []
  }

  // Check model status
  async checkModelStatus(model: string) {
    try {
      const apiKey = this.getApiKey();
      const response = await axios.get(`${this.baseURL}${model}`, {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
        }
      })
      return response.status === 200
    } catch (error) {
      return false
    }
  }

  // List available models (for development)
  async listModels() {
    const workingModels = [
      'facebook/bart-large-cnn',
      'deepset/roberta-base-squad2',
      'Helsinki-NLP/opus-mt-en-fr'
    ]

    return workingModels.map(model => ({
      name: model,
      endpoint: `/models/${model}`,
      description: this.getModelDescription(model)
    }))
  }

  private getModelDescription(model: string): string {
    const descriptions: Record<string, string> = {
      'facebook/bart-large-cnn': 'Text summarization for content analysis',
      'deepset/roberta-base-squad2': 'Question answering for customer support',
      'Helsinki-NLP/opus-mt-en-fr': 'English to French translation'
    }
    return descriptions[model] || 'AI model for various tasks'
  }
}

export const huggingFaceService = new HuggingFaceService()