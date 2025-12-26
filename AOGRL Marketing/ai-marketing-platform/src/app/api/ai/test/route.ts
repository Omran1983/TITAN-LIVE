import { apiResponse, apiError } from '@/lib/api-utils'
import { huggingFaceService } from '@/lib/huggingface-service'

export async function GET() {
  try {
    const models = await huggingFaceService.listModels()
    return apiResponse({ 
      message: 'Hugging Face service is available',
      models,
      endpoints: {
        sentiment: 'POST with { "action": "sentiment", "text": "your text" }',
        summarize: 'POST with { "action": "summarize", "text": "your text" }',
        generate: 'POST with { "action": "generate", "prompt": "your prompt" }',
        models: 'POST with { "action": "models" }',
        test: 'POST with { "action": "test-key" }'
      },
      note: 'If you encounter permissions errors, consider upgrading your Hugging Face account or using alternative free AI services.'
    })
  } catch (error: any) {
    return apiError('Hugging Face service unavailable: ' + error.message, 500)
  }
}