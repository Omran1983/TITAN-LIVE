'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useCreateCampaign, useProducts } from '@/lib/hooks'
import {
  XMarkIcon,
  PlusIcon,
  MegaphoneIcon,
  CalendarIcon,
  BanknotesIcon,
  UserGroupIcon,
  TagIcon,
  SparklesIcon
} from '@heroicons/react/24/outline'

const campaignSchema = z.object({
  name: z.string().min(1, 'Campaign name is required').max(100, 'Name too long'),
  description: z.string().optional(),
  budget: z.number().min(1, 'Budget must be at least $1').max(1000000, 'Budget too high'),
  startDate: z.string().min(1, 'Start date is required'),
  endDate: z.string().min(1, 'End date is required'),
  audienceAge: z.string(),
  audienceGender: z.string(),
  audienceLocation: z.string(),
  audienceInterests: z.string(),
  productIds: z.array(z.string()).min(1, 'Select at least one product'),
})

type CampaignFormData = z.infer<typeof campaignSchema>

interface CreateCampaignModalProps {
  isOpen: boolean
  onClose: () => void
}

export default function CreateCampaignModal({ isOpen, onClose }: CreateCampaignModalProps) {
  const [step, setStep] = useState(1)
  const createCampaign = useCreateCampaign()
  const { data: products = [], isLoading: productsLoading } = useProducts()

  const {
    register,
    handleSubmit,
    formState: { errors },
    watch,
    setValue,
    reset,
  } = useForm<CampaignFormData>({
    resolver: zodResolver(campaignSchema),
    defaultValues: {
      audienceAge: '25-54',
      audienceGender: 'all',
      audienceLocation: 'United States',
      productIds: [],
    },
  })

  const selectedProductIds = watch('productIds') || []

  const onSubmit = async (data: CampaignFormData) => {
    try {
      // Format the audience data as JSON
      const audienceData = {
        age: data.audienceAge,
        gender: data.audienceGender,
        location: data.audienceLocation,
        interests: data.audienceInterests.split(',').map(i => i.trim()),
      }

      const campaignData = {
        ...data,
        audience: JSON.stringify(audienceData),
        startDate: new Date(data.startDate).toISOString(),
        endDate: new Date(data.endDate).toISOString(),
      }

      await createCampaign.mutateAsync(campaignData)
      reset()
      setStep(1)
      onClose()
    } catch (error) {
      console.error('Campaign creation failed:', error)
    }
  }

  const handleProductToggle = (productId: string) => {
    const current = selectedProductIds
    const updated = current.includes(productId)
      ? current.filter(id => id !== productId)
      : [...current, productId]
    setValue('productIds', updated)
  }

  const nextStep = () => setStep(prev => Math.min(prev + 1, 3))
  const prevStep = () => setStep(prev => Math.max(prev - 1, 1))

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="surface-premium max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="p-6 border-b border-gray-200 relative">
          <div className="absolute inset-0 bg-gradient-to-r from-blue-500/10 via-purple-500/10 to-pink-500/10"></div>
          <div className="relative z-10 flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
                <MegaphoneIcon className="w-6 h-6 text-white" />
              </div>
              <div>
                <h2 className="text-headline">Create New Campaign</h2>
                <p className="text-body text-gray-600">Launch AI-powered marketing campaigns</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <XMarkIcon className="w-6 h-6 text-gray-400" />
            </button>
          </div>
        </div>

        {/* Progress Steps */}
        <div className="p-6 border-b border-gray-100">
          <div className="flex items-center justify-center space-x-8">
            {[
              { step: 1, title: 'Campaign Details', icon: MegaphoneIcon },
              { step: 2, title: 'Target Audience', icon: UserGroupIcon },
              { step: 3, title: 'Select Products', icon: TagIcon },
            ].map(({ step: stepNumber, title, icon: Icon }) => (
              <div key={stepNumber} className="flex items-center space-x-3">
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center transition-all duration-300 ${
                    step >= stepNumber
                      ? 'bg-gradient-to-br from-blue-500 to-purple-600 text-white shadow-lg'
                      : 'bg-gray-100 text-gray-400'
                  }`}
                >
                  <Icon className="w-5 h-5" />
                </div>
                <span
                  className={`font-medium transition-colors ${
                    step >= stepNumber ? 'text-blue-600' : 'text-gray-400'
                  }`}
                >
                  {title}
                </span>
              </div>
            ))}
          </div>
        </div>

        <form onSubmit={handleSubmit(onSubmit)}>
          <div className="p-6">
            {/* Step 1: Campaign Details */}
            {step === 1 && (
              <div className="space-y-6 animate-fade-in">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="form-label">Campaign Name *</label>
                    <input
                      {...register('name')}
                      className="form-input w-full"
                      placeholder="e.g., Summer Sale 2024"
                    />
                    {errors.name && (
                      <p className="text-red-500 text-sm mt-1">{errors.name.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="form-label">Budget (USD) *</label>
                    <input
                      {...register('budget', { valueAsNumber: true })}
                      type="number"
                      min="1"
                      max="1000000"
                      className="form-input w-full"
                      placeholder="50000"
                    />
                    {errors.budget && (
                      <p className="text-red-500 text-sm mt-1">{errors.budget.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="form-label">Start Date *</label>
                    <input
                      {...register('startDate')}
                      type="date"
                      className="form-input w-full"
                      min={new Date().toISOString().split('T')[0]}
                    />
                    {errors.startDate && (
                      <p className="text-red-500 text-sm mt-1">{errors.startDate.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="form-label">End Date *</label>
                    <input
                      {...register('endDate')}
                      type="date"
                      className="form-input w-full"
                      min={new Date().toISOString().split('T')[0]}
                    />
                    {errors.endDate && (
                      <p className="text-red-500 text-sm mt-1">{errors.endDate.message}</p>
                    )}
                  </div>
                </div>

                <div>
                  <label className="form-label">Description</label>
                  <textarea
                    {...register('description')}
                    className="form-input w-full h-24"
                    placeholder="Describe your campaign goals and strategy..."
                  />
                </div>
              </div>
            )}

            {/* Step 2: Audience Targeting */}
            {step === 2 && (
              <div className="space-y-6 animate-fade-in">
                <div className="text-center mb-6">
                  <div className="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
                    <UserGroupIcon className="w-8 h-8 text-white" />
                  </div>
                  <h3 className="text-title font-bold">Define Your Target Audience</h3>
                  <p className="text-body text-gray-600 mt-2">
                    AI will optimize targeting based on your specifications
                  </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="form-label">Age Range</label>
                    <select {...register('audienceAge')} className="form-input w-full">
                      <option value="18-24">18-24 years</option>
                      <option value="25-34">25-34 years</option>
                      <option value="35-44">35-44 years</option>
                      <option value="45-54">45-54 years</option>
                      <option value="55-64">55-64 years</option>
                      <option value="65+">65+ years</option>
                      <option value="25-54">25-54 years (Broad)</option>
                    </select>
                  </div>

                  <div>
                    <label className="form-label">Gender</label>
                    <select {...register('audienceGender')} className="form-input w-full">
                      <option value="all">All Genders</option>
                      <option value="male">Male</option>
                      <option value="female">Female</option>
                      <option value="non-binary">Non-binary</option>
                    </select>
                  </div>

                  <div>
                    <label className="form-label">Primary Location</label>
                    <input
                      {...register('audienceLocation')}
                      className="form-input w-full"
                      placeholder="e.g., United States, California, San Francisco"
                    />
                  </div>

                  <div>
                    <label className="form-label">Interests (comma-separated)</label>
                    <input
                      {...register('audienceInterests')}
                      className="form-input w-full"
                      placeholder="e.g., technology, fitness, cooking"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Step 3: Product Selection */}
            {step === 3 && (
              <div className="space-y-6 animate-fade-in">
                <div className="text-center mb-6">
                  <div className="w-16 h-16 bg-gradient-to-br from-green-500 to-emerald-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
                    <TagIcon className="w-8 h-8 text-white" />
                  </div>
                  <h3 className="text-title font-bold">Select Products to Promote</h3>
                  <p className="text-body text-gray-600 mt-2">
                    Choose which products this campaign will feature
                  </p>
                </div>

                {productsLoading ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {[...Array(6)].map((_, i) => (
                      <div key={i} className="surface p-4 animate-shimmer rounded-xl">
                        <div className="h-32 bg-gray-200 rounded-lg mb-3"></div>
                        <div className="h-4 bg-gray-200 rounded mb-2"></div>
                        <div className="h-3 bg-gray-200 rounded w-20"></div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 max-h-96 overflow-y-auto">
                    {products.map((product: any) => (
                      <div
                        key={product.id}
                        onClick={() => handleProductToggle(product.id)}
                        className={`surface p-4 rounded-xl cursor-pointer transition-all duration-300 ${
                          selectedProductIds.includes(product.id)
                            ? 'border-2 border-blue-500 bg-blue-50'
                            : 'hover:border-blue-300'
                        }`}
                      >
                        <div className="flex items-center justify-between mb-3">
                          <div
                            className={`w-4 h-4 rounded border-2 transition-all ${
                              selectedProductIds.includes(product.id)
                                ? 'bg-blue-500 border-blue-500'
                                : 'border-gray-300'
                            }`}
                          >
                            {selectedProductIds.includes(product.id) && (
                              <svg className="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                                <path
                                  fillRule="evenodd"
                                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                  clipRule="evenodd"
                                />
                              </svg>
                            )}
                          </div>
                        </div>
                        <div className="h-24 bg-gradient-to-br from-blue-100 to-purple-100 rounded-lg mb-3 flex items-center justify-center">
                          <TagIcon className="w-8 h-8 text-blue-500" />
                        </div>
                        <h4 className="font-semibold text-sm mb-1">{product.name}</h4>
                        <p className="text-xs text-gray-600 mb-2 line-clamp-2">{product.description}</p>
                        <div className="text-lg font-bold text-green-600">${product.price}</div>
                      </div>
                    ))}
                  </div>
                )}

                {errors.productIds && (
                  <p className="text-red-500 text-sm text-center">{errors.productIds.message}</p>
                )}
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="p-6 border-t border-gray-100 flex justify-between">
            <div>
              {step > 1 && (
                <button
                  type="button"
                  onClick={prevStep}
                  className="btn-secondary"
                >
                  Previous
                </button>
              )}
            </div>
            <div className="flex space-x-3">
              <button
                type="button"
                onClick={onClose}
                className="btn-secondary"
              >
                Cancel
              </button>
              {step < 3 ? (
                <button
                  type="button"
                  onClick={nextStep}
                  className="btn-primary"
                >
                  Next Step
                </button>
              ) : (
                <button
                  type="submit"
                  disabled={createCampaign.isPending}
                  className="btn-premium flex items-center space-x-2"
                >
                  {createCampaign.isPending ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                      <span>Creating...</span>
                    </>
                  ) : (
                    <>
                      <SparklesIcon className="w-5 h-5" />
                      <span>Create Campaign</span>
                    </>
                  )}
                </button>
              )}
            </div>
          </div>
        </form>
      </div>
    </div>
  )
}