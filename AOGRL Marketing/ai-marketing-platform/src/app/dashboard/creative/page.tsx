'use client'

import { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'react-hot-toast'
import {
  PhotoIcon,
  VideoCameraIcon,
  SpeakerWaveIcon,
  DocumentTextIcon,
  PlusIcon,
  SparklesIcon,
  RocketLaunchIcon,
  EyeIcon,
  HeartIcon,
  ShareIcon,
  ArrowDownTrayIcon,
  AdjustmentsHorizontalIcon,
  SwatchIcon,
  PaintBrushIcon,
  BeakerIcon,
  ChartBarIcon,
  LightBulbIcon,
  CpuChipIcon,
  BoltIcon,
  CheckCircleIcon,
  ClockIcon,
  ExclamationCircleIcon,
  XCircleIcon
} from '@heroicons/react/24/outline'
import { creativeApi } from '@/lib/api'

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

interface CreativeAsset {
  id: string
  title: string
  type: 'IMAGE' | 'VIDEO' | 'COPY' | 'AUDIO'
  content: any
  status: 'PENDING' | 'GENERATING' | 'COMPLETED' | 'FAILED'
  createdAt: string
  prompt?: string
}

interface GenerationRequest {
  type: 'image' | 'video' | 'audio' | 'copy'
  prompt: string
  style?: string
  dimensions?: string
  tone?: string
  language?: string
}

export default function CreativeStudioPage() {
  const [selectedTool, setSelectedTool] = useState<string | null>(null)
  const [generationRequest, setGenerationRequest] = useState<GenerationRequest>({
    type: 'image',
    prompt: '',
    style: 'photorealistic',
    dimensions: '1024x1024',
    tone: 'professional',
    language: 'en'
  })
  const [activeGenerations, setActiveGenerations] = useState<Set<string>>(new Set())
  const [generationProgress, setGenerationProgress] = useState<Record<string, number>>({})
  const queryClient = useQueryClient()

  // Fetch creative assets
  const { data: creativesData, isLoading } = useQuery({
    queryKey: ['creatives'],
    queryFn: () => creativeApi.getAll().then(res => res.data),
    onError: (error: any) => {
      // Handle errors silently to prevent console spam
      let errorMessage = 'Failed to load creatives'
      
      // Handle different types of errors
      if (error.response?.data?.error && isMeaningfulError(error.response.data.error)) {
        errorMessage = error.response.data.error
      } else if (error.message && isMeaningfulError(error.message)) {
        errorMessage = error.message
      } else if (error.response?.status) {
        errorMessage = `HTTP Error: ${error.response.status}`
      }
      
      // Only show toast for significant errors
      if (isMeaningfulError(errorMessage)) {
        toast.error(errorMessage)
      }
    }
  })

  // Generate creative mutation
  const generateMutation = useMutation({
    mutationFn: (data: GenerationRequest) => creativeApi.generate(data).then(res => res.data),
    onSuccess: (data) => {
      toast.success(`🎨 ${data.creative.type} generation started!`)
      if (data.generationId) {
        setActiveGenerations(prev => new Set([...prev, data.generationId]))
        setGenerationProgress(prev => ({ ...prev, [data.generationId]: 0 }))
        pollGenerationStatus(data.generationId)
      }
      queryClient.invalidateQueries({ queryKey: ['creatives'] })
      setSelectedTool(null)
    },
    onError: (error: any) => {
      // Handle errors more carefully to prevent console spam
      let errorMessage = 'Generation failed'
      
      // Handle different types of errors
      if (error.response?.data?.error && isMeaningfulError(error.response.data.error)) {
        errorMessage = error.response.data.error
      } else if (error.message && isMeaningfulError(error.message)) {
        errorMessage = error.message
      } else if (error.response?.status) {
        errorMessage = `HTTP Error: ${error.response.status}`
      }
      
      // Only show toast for significant errors
      if (isMeaningfulError(errorMessage)) {
        toast.error(errorMessage)
      }
    }
  })

  // Generate variations mutation
  const generateVariationsMutation = useMutation({
    mutationFn: (data: { type: string; prompt: string; count: number }) => 
      creativeApi.generateVariations(data).then(res => res.data),
    onSuccess: (data) => {
      toast.success(`✨ Generating ${data.variations.length} variations!`)
      data.variations.forEach((variation: any) => {
        setActiveGenerations(prev => new Set([...prev, variation.id]))
        setGenerationProgress(prev => ({ ...prev, [variation.id]: 0 }))
        pollGenerationStatus(variation.id)
      })
      queryClient.invalidateQueries({ queryKey: ['creatives'] })
    },
    onError: (error: any) => {
      // Handle errors more carefully to prevent console spam
      let errorMessage = 'Variation generation failed'
      
      // Handle different types of errors
      if (error.response?.data?.error && isMeaningfulError(error.response.data.error)) {
        errorMessage = error.response.data.error
      } else if (error.message && isMeaningfulError(error.message)) {
        errorMessage = error.message
      } else if (error.response?.status) {
        errorMessage = `HTTP Error: ${error.response.status}`
      }
      
      // Only show toast for significant errors
      if (isMeaningfulError(errorMessage)) {
        toast.error(errorMessage)
      }
    }
  })

  // Content analysis mutation
  const analyzeMutation = useMutation({
    mutationFn: (data: { content: any; keywords?: string[] }) => 
      creativeApi.analyzeContent(data).then(res => res.data),
    onSuccess: (data) => {
      toast.success(`📊 Content analysis complete! Engagement score: ${data.analysis.engagement_score}%`)
    },
    onError: (error: any) => {
      // Handle errors more carefully to prevent console spam
      let errorMessage = 'Analysis failed'
      
      // Handle different types of errors
      if (error.response?.data?.error && isMeaningfulError(error.response.data.error)) {
        errorMessage = error.response.data.error
      } else if (error.message && isMeaningfulError(error.message)) {
        errorMessage = error.message
      } else if (error.response?.status) {
        errorMessage = `HTTP Error: ${error.response.status}`
      }
      
      // Only show toast for significant errors
      if (isMeaningfulError(errorMessage)) {
        toast.error(errorMessage)
      }
    }
  })

  // Poll generation status
  const pollGenerationStatus = async (generationId: string) => {
    const maxPolls = 30 // 5 minutes max
    let polls = 0
    
    const poll = async () => {
      try {
        const response = await creativeApi.getGenerationStatus(generationId)
        const status = response.data
        
        // Update progress
        if (status.progress !== undefined) {
          setGenerationProgress(prev => ({ ...prev, [generationId]: status.progress }))
        }
        
        if (status.status === 'completed') {
          setActiveGenerations(prev => {
            const newSet = new Set(prev)
            newSet.delete(generationId)
            return newSet
          })
          delete generationProgress[generationId]
          toast.success('🎉 Generation completed!')
          queryClient.invalidateQueries({ queryKey: ['creatives'] })
          return
        }
        
        if (status.status === 'failed') {
          setActiveGenerations(prev => {
            const newSet = new Set(prev)
            newSet.delete(generationId)
            return newSet
          })
          delete generationProgress[generationId]
          toast.error('❌ Generation failed')
          return
        }
        
        polls++
        if (polls < maxPolls) {
          setTimeout(poll, 10000) // Poll every 10 seconds
        } else {
          // Max polls reached, mark as failed
          setActiveGenerations(prev => {
            const newSet = new Set(prev)
            newSet.delete(generationId)
            return newSet
          })
          delete generationProgress[generationId]
          toast.error('⏰ Generation timed out')
        }
      } catch (error: any) {
        // Handle polling errors carefully
        let errorMessage = 'Error checking generation status'
        
        if (error.response?.data?.error && isMeaningfulError(error.response.data.error)) {
          errorMessage = error.response.data.error
        } else if (error.message && isMeaningfulError(error.message)) {
          errorMessage = error.message
        }
        
        // Only log meaningful errors
        if (isMeaningfulError(errorMessage)) {
          console.error('Polling error:', errorMessage)
        }
        
        setActiveGenerations(prev => {
          const newSet = new Set(prev)
          newSet.delete(generationId)
          return newSet
        })
        delete generationProgress[generationId]
        
        // Only show toast for significant errors
        if (isMeaningfulError(errorMessage)) {
          toast.error(errorMessage)
        }
      }
    }
    
    setTimeout(poll, 5000) // Start polling after 5 seconds
  }

  const handleGenerate = () => {
    if (!generationRequest.prompt.trim()) {
      toast.error('Please enter a prompt')
      return
    }
    generateMutation.mutate(generationRequest)
  }

  const handleGenerateVariations = (prompt: string, type: string) => {
    generateVariationsMutation.mutate({
      type,
      prompt,
      count: 3
    })
  }

  const creatives = creativesData?.creatives || []
  
  const aiTools = [
    {
      id: 'image',
      title: '🎨 AI Image Generator',
      description: 'Create stunning visuals with DALL-E and Stable Diffusion',
      gradient: 'from-purple-500 to-pink-600',
      features: ['Multiple styles', 'Custom dimensions', 'Brand consistency', 'Instant variations']
    },
    {
      id: 'video',
      title: '🎬 Video Creator',
      description: 'Generate engaging videos with AI-powered editing',
      gradient: 'from-blue-500 to-cyan-600',
      features: ['Auto editing', 'Scene generation', 'Music sync', 'Text overlay']
    },
    {
      id: 'audio',
      title: '🎵 Voice & Audio Studio',
      description: 'Create voiceovers and background music with AI',
      gradient: 'from-green-500 to-emerald-600',
      features: ['Voice cloning', 'Music generation', 'Sound effects', 'Multi-language']
    },
    {
      id: 'copy',
      title: '📝 AI Copywriter',
      description: 'Generate compelling marketing copy and headlines',
      gradient: 'from-orange-500 to-red-600',
      features: ['Multiple tones', 'A/B variants', 'SEO optimized', 'Brand voice']
    }
  ]

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'COMPLETED': return 'text-green-600 bg-green-100'
      case 'GENERATING': return 'text-blue-600 bg-blue-100'
      case 'PENDING': return 'text-yellow-600 bg-yellow-100'
      case 'FAILED': return 'text-red-600 bg-red-100'
      default: return 'text-gray-600 bg-gray-100'
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'COMPLETED': return <CheckCircleIcon className="w-5 h-5 text-green-500" />
      case 'GENERATING': return <ClockIcon className="w-5 h-5 text-blue-500" />
      case 'PENDING': return <ClockIcon className="w-5 h-5 text-yellow-500" />
      case 'FAILED': return <XCircleIcon className="w-5 h-5 text-red-500" />
      default: return <ClockIcon className="w-5 h-5 text-gray-500" />
    }
  }

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'IMAGE': return PhotoIcon
      case 'VIDEO': return VideoCameraIcon
      case 'COPY': return DocumentTextIcon
      case 'AUDIO': return SpeakerWaveIcon
      default: return PhotoIcon
    }
  }

  return (
    <div className="animate-slide-up space-y-8">
      {/* Premium Header */}
      <div className="surface-premium p-8 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-purple-500/20 via-pink-500/20 to-blue-500/20 animate-gradient-flow"></div>
        <div className="relative z-10">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center space-x-4 mb-4">
                <div className="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center shadow-lg">
                  <SparklesIcon className="w-8 h-8 text-white" />
                </div>
                <div>
                  <h1 className="text-display">AI Creative Studio</h1>
                  <p className="text-body text-gray-600 mt-2">
                    Generate stunning marketing content with cutting-edge AI • {creatives.length} assets created
                  </p>
                </div>
              </div>
              
              <div className="flex items-center space-x-6 text-sm">
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <CpuChipIcon className="w-4 h-4 text-purple-500" />
                  <span className="font-semibold">Neural Networks</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <BoltIcon className="w-4 h-4 text-yellow-500" />
                  <span className="font-semibold">{activeGenerations.size} Generating</span>
                </div>
                <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 rounded-full backdrop-blur-sm">
                  <LightBulbIcon className="w-4 h-4 text-blue-500" />
                  <span className="font-semibold">AI-Powered</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Active Generations Progress */}
      {activeGenerations.size > 0 && (
        <div className="surface-elevated-high p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Active Generations</h3>
          <div className="space-y-3">
            {Array.from(activeGenerations).map(generationId => (
              <div key={generationId} className="flex items-center justify-between p-3 bg-blue-50 rounded-lg">
                <div className="flex items-center space-x-3">
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-500"></div>
                  <span className="text-sm font-medium text-gray-700">Generating content...</span>
                </div>
                <div className="flex items-center space-x-2">
                  <span className="text-xs text-gray-500">{generationProgress[generationId] || 0}%</span>
                  <div className="w-24 h-2 bg-gray-200 rounded-full overflow-hidden">
                    <div 
                      className="h-full bg-blue-500 transition-all duration-300"
                      style={{ width: `${generationProgress[generationId] || 0}%` }}
                    ></div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* AI Tools Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {aiTools.map((tool, index) => (
          <div
            key={tool.id}
            className="surface-elevated-high p-8 hover-lift cursor-pointer group"
            style={{ animationDelay: `${index * 100}ms` }}
            onClick={() => setSelectedTool(tool.id)}
          >
            <div className="flex items-start justify-between mb-6">
              <div className={`w-14 h-14 bg-gradient-to-br ${tool.gradient} rounded-2xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform duration-300`}>
                <SparklesIcon className="w-7 h-7 text-white" />
              </div>
              <button className="btn-premium text-sm">
                Launch Studio
              </button>
            </div>
            
            <h3 className="text-xl font-bold text-gray-900 mb-3">{tool.title}</h3>
            <p className="text-gray-600 mb-4">{tool.description}</p>
            
            <div className="grid grid-cols-2 gap-2">
              {tool.features.map((feature, idx) => (
                <div key={idx} className="flex items-center space-x-2 text-sm text-gray-600">
                  <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                  <span>{feature}</span>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Generation Interface */}
      {selectedTool && (
        <div className="surface-elevated-high p-8">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-gray-900">
              {aiTools.find(t => t.id === selectedTool)?.title}
            </h2>
            <button
              onClick={() => setSelectedTool(null)}
              className="text-gray-500 hover:text-gray-700"
            >
              ✕
            </button>
          </div>
          
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <div className="space-y-6">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Description/Prompt *
                </label>
                <textarea
                  value={generationRequest.prompt}
                  onChange={(e) => setGenerationRequest({ ...generationRequest, prompt: e.target.value })}
                  placeholder={`Describe what you want to create...\n\nExample: "A professional product photo of a smartphone on a clean white background with soft lighting"`}
                  className="form-input w-full h-32 resize-none"
                />
              </div>
              
              {selectedTool === 'image' && (
                <>
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">Style</label>
                    <select
                      value={generationRequest.style}
                      onChange={(e) => setGenerationRequest({ ...generationRequest, style: e.target.value })}
                      className="form-input w-full"
                    >
                      <option value="photorealistic">Photorealistic</option>
                      <option value="artistic">Artistic</option>
                      <option value="minimalist">Minimalist</option>
                      <option value="vintage">Vintage</option>
                      <option value="modern">Modern</option>
                      <option value="3d-render">3D Render</option>
                      <option value="anime">Anime Style</option>
                      <option value="abstract">Abstract</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">Dimensions</label>
                    <select
                      value={generationRequest.dimensions}
                      onChange={(e) => setGenerationRequest({ ...generationRequest, dimensions: e.target.value })}
                      className="form-input w-full"
                    >
                      <option value="1024x1024">Square (1024x1024)</option>
                      <option value="1920x1080">Landscape (1920x1080)</option>
                      <option value="1080x1920">Portrait (1080x1920)</option>
                      <option value="1200x630">Social Media Banner</option>
                      <option value="512x512">Small Square (512x512)</option>
                      <option value="768x768">Medium Square (768x768)</option>
                    </select>
                  </div>
                </>
              )}
              
              {selectedTool === 'copy' && (
                <>
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">Tone</label>
                    <select
                      value={generationRequest.tone}
                      onChange={(e) => setGenerationRequest({ ...generationRequest, tone: e.target.value })}
                      className="form-input w-full"
                    >
                      <option value="professional">Professional</option>
                      <option value="casual">Casual</option>
                      <option value="enthusiastic">Enthusiastic</option>
                      <option value="urgent">Urgent</option>
                      <option value="friendly">Friendly</option>
                      <option value="humorous">Humorous</option>
                      <option value="persuasive">Persuasive</option>
                      <option value="informative">Informative</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">Language</label>
                    <select
                      value={generationRequest.language}
                      onChange={(e) => setGenerationRequest({ ...generationRequest, language: e.target.value })}
                      className="form-input w-full"
                    >
                      <option value="en">English</option>
                      <option value="fr">Français</option>
                      <option value="es">Español</option>
                      <option value="de">Deutsch</option>
                      <option value="it">Italiano</option>
                      <option value="pt">Português</option>
                      <option value="ja">日本語</option>
                      <option value="zh">中文</option>
                    </select>
                  </div>
                </>
              )}
              
              <div className="flex space-x-3">
                <button
                  onClick={handleGenerate}
                  disabled={generateMutation.isPending || !generationRequest.prompt.trim()}
                  className="btn-primary flex-1 flex items-center justify-center space-x-2"
                >
                  {generateMutation.isPending ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                      <span>Generating...</span>
                    </>
                  ) : (
                    <>
                      <SparklesIcon className="w-4 h-4" />
                      <span>Generate</span>
                    </>
                  )}
                </button>
                <button
                  onClick={() => handleGenerateVariations(generationRequest.prompt, selectedTool)}
                  disabled={generateVariationsMutation.isPending || !generationRequest.prompt.trim()}
                  className="btn-secondary flex items-center space-x-2"
                >
                  <BeakerIcon className="w-4 h-4" />
                  <span>3 Variations</span>
                </button>
              </div>
            </div>
            
            <div className="bg-gray-50 rounded-xl p-6">
              <h3 className="font-semibold text-gray-800 mb-4">✨ AI Tips</h3>
              <div className="space-y-3 text-sm text-gray-600">
                <div className="flex items-start space-x-2">
                  <div className="w-1.5 h-1.5 bg-blue-500 rounded-full mt-2"></div>
                  <span>Be specific about style, colors, and mood</span>
                </div>
                <div className="flex items-start space-x-2">
                  <div className="w-1.5 h-1.5 bg-green-500 rounded-full mt-2"></div>
                  <span>Mention lighting conditions for better results</span>
                </div>
                <div className="flex items-start space-x-2">
                  <div className="w-1.5 h-1.5 bg-purple-500 rounded-full mt-2"></div>
                  <span>Include brand elements in your description</span>
                </div>
                <div className="flex items-start space-x-2">
                  <div className="w-1.5 h-1.5 bg-orange-500 rounded-full mt-2"></div>
                  <span>Try generating variations for A/B testing</span>
                </div>
                <div className="flex items-start space-x-2">
                  <div className="w-1.5 h-1.5 bg-red-500 rounded-full mt-2"></div>
                  <span>Use clear, descriptive prompts for best results</span>
                </div>
              </div>
              
              <div className="mt-6 p-4 bg-blue-50 rounded-lg">
                <h4 className="font-semibold text-blue-800 mb-2">💡 Pro Tip</h4>
                <p className="text-sm text-blue-700">
                  For better results, include specific details like "professional product photo", 
                  "dramatic lighting", or "minimalist design" in your prompts.
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Recent Creatives */}
      <div className="surface-elevated-high">
        <div className="p-6 border-b border-gray-100">
          <div className="flex items-center justify-between">
            <h2 className="text-headline">Recent Creatives</h2>
            <div className="flex items-center space-x-2 text-sm text-gray-500">
              <BoltIcon className="w-4 h-4" />
              <span>AI Generated</span>
            </div>
          </div>
        </div>
        
        {isLoading ? (
          <div className="p-8 text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto"></div>
            <p className="text-gray-500 mt-2">Loading creatives...</p>
          </div>
        ) : creatives.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6">
            {creatives.map((creative: CreativeAsset, index: number) => {
              const TypeIcon = getTypeIcon(creative.type)
              return (
                <div
                  key={creative.id}
                  className="surface-elevated rounded-xl p-6 hover-lift"
                  style={{ animationDelay: `${index * 100}ms` }}
                >
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
                        <TypeIcon className="w-5 h-5 text-white" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-gray-900">{creative.type}</h3>
                        <p className="text-sm text-gray-600">{new Date(creative.createdAt).toLocaleDateString()}</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-1">
                      {getStatusIcon(creative.status)}
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(creative.status)}`}>
                        {creative.status}
                      </span>
                    </div>
                  </div>
                  
                  {creative.prompt && (
                    <p className="text-sm text-gray-600 mb-4 line-clamp-2">
                      {creative.prompt}
                    </p>
                  )}
                  
                  <div className="flex space-x-2">
                    <button className="flex-1 btn-secondary text-sm py-2">
                      <EyeIcon className="w-4 h-4 mr-1" />
                      View
                    </button>
                    <button 
                      onClick={() => analyzeMutation.mutate({ content: creative.content })}
                      className="px-3 py-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                      title="Analyze Performance"
                    >
                      <ChartBarIcon className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              )
            })}
          </div>
        ) : (
          <div className="p-12 text-center">
            <SparklesIcon className="w-16 h-16 text-gray-300 mx-auto mb-4" />
            <h3 className="text-headline text-gray-600 mb-2">No creatives yet</h3>
            <p className="text-body text-gray-500 mb-6">
              Start creating amazing content with our AI-powered tools!
            </p>
            <button
              onClick={() => setSelectedTool('image')}
              className="btn-primary"
            >
              <SparklesIcon className="w-5 h-5 mr-2" />
              Create Your First Asset
            </button>
          </div>
        )}
      </div>
    </div>
  )
}