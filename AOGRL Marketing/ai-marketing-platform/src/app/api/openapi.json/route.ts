import { NextResponse } from 'next/server'

const openApiSpec = {
  openapi: '3.0.0',
  info: {
    title: 'AI Marketing Platform API',
    version: '1.0.0',
    description: 'REST API for AI-first marketing platform with campaign management, creative generation, and analytics'
  },
  servers: [
    {
      url: '/api',
      description: 'API Server'
    }
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer'
      }
    },
    schemas: {
      Product: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          name: { type: 'string' },
          description: { type: 'string', nullable: true },
          price: { type: 'number' },
          imageUrl: { type: 'string', nullable: true },
          category: { type: 'string', nullable: true },
          isActive: { type: 'boolean' },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' }
        }
      },
      Creative: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          type: { type: 'string', enum: ['IMAGE', 'COPY', 'VIDEO'] },
          content: { type: 'object' },
          prompt: { type: 'string', nullable: true },
          status: { type: 'string', enum: ['PENDING', 'GENERATING', 'COMPLETED', 'FAILED'] },
          createdAt: { type: 'string', format: 'date-time' }
        }
      },
      Campaign: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          name: { type: 'string' },
          description: { type: 'string', nullable: true },
          budget: { type: 'number' },
          audience: { type: 'object' },
          status: { type: 'string', enum: ['DRAFT', 'SCHEDULED', 'RUNNING', 'PAUSED', 'COMPLETED', 'CANCELLED'] },
          startDate: { type: 'string', format: 'date-time', nullable: true },
          endDate: { type: 'string', format: 'date-time', nullable: true },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' }
        }
      },
      Analytics: {
        type: 'object',
        properties: {
          campaignId: { type: 'string' },
          date: { type: 'string', format: 'date' },
          impressions: { type: 'integer' },
          clicks: { type: 'integer' },
          conversions: { type: 'integer' },
          spend: { type: 'number' },
          revenue: { type: 'number' }
        }
      },
      Error: {
        type: 'object',
        properties: {
          error: { type: 'string' }
        }
      }
    }
  },
  security: [
    {
      bearerAuth: []
    }
  ],
  paths: {
    '/health': {
      get: {
        summary: 'Health check',
        tags: ['System'],
        security: [],
        responses: {
          '200': {
            description: 'Service is healthy',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    ok: { type: 'boolean' }
                  }
                }
              }
            }
          }
        }
      }
    },
    '/products': {
      get: {
        summary: 'List products',
        tags: ['Products'],
        parameters: [
          {
            name: 'page',
            in: 'query',
            schema: { type: 'integer', default: 1 }
          },
          {
            name: 'limit',
            in: 'query',
            schema: { type: 'integer', default: 10 }
          },
          {
            name: 'search',
            in: 'query',
            schema: { type: 'string' }
          }
        ],
        responses: {
          '200': {
            description: 'List of products',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    products: {
                      type: 'array',
                      items: { $ref: '#/components/schemas/Product' }
                    },
                    pagination: {
                      type: 'object',
                      properties: {
                        page: { type: 'integer' },
                        limit: { type: 'integer' },
                        total: { type: 'integer' },
                        pages: { type: 'integer' }
                      }
                    }
                  }
                }
              }
            }
          },
          '401': {
            description: 'Unauthorized',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Error' }
              }
            }
          }
        }
      },
      post: {
        summary: 'Create product',
        tags: ['Products'],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['name', 'price'],
                properties: {
                  name: { type: 'string' },
                  description: { type: 'string' },
                  price: { type: 'number' },
                  imageUrl: { type: 'string' },
                  category: { type: 'string' }
                }
              }
            }
          }
        },
        responses: {
          '201': {
            description: 'Product created',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Product' }
              }
            }
          },
          '400': {
            description: 'Bad request',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Error' }
              }
            }
          },
          '401': {
            description: 'Unauthorized',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Error' }
              }
            }
          }
        }
      }
    },
    '/creatives': {
      post: {
        summary: 'Generate creative',
        tags: ['Creatives'],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['type', 'prompt'],
                properties: {
                  type: { type: 'string', enum: ['IMAGE', 'COPY', 'VIDEO'] },
                  prompt: { type: 'string' },
                  productIds: {
                    type: 'array',
                    items: { type: 'string' }
                  },
                  audience: { type: 'string' }
                }
              }
            }
          }
        },
        responses: {
          '201': {
            description: 'Creative generated',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Creative' }
              }
            }
          },
          '400': {
            description: 'Bad request',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Error' }
              }
            }
          },
          '401': {
            description: 'Unauthorized',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Error' }
              }
            }
          }
        }
      }
    },
    '/campaigns': {
      post: {
        summary: 'Create campaign',
        tags: ['Campaigns'],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['name', 'budget'],
                properties: {
                  name: { type: 'string' },
                  description: { type: 'string' },
                  budget: { type: 'number' },
                  audience: { type: 'object' },
                  productIds: {
                    type: 'array',
                    items: { type: 'string' }
                  },
                  creativeId: { type: 'string' },
                  startDate: { type: 'string', format: 'date-time' },
                  endDate: { type: 'string', format: 'date-time' }
                }
              }
            }
          }
        },
        responses: {
          '201': {
            description: 'Campaign created',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Campaign' }
              }
            }
          },
          '400': {
            description: 'Bad request',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Error' }
              }
            }
          },
          '401': {
            description: 'Unauthorized',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Error' }
              }
            }
          }
        }
      }
    },
    '/analytics': {
      get: {
        summary: 'Get campaign analytics',
        tags: ['Analytics'],
        parameters: [
          {
            name: 'campaignId',
            in: 'query',
            required: true,
            schema: { type: 'string' }
          },
          {
            name: 'startDate',
            in: 'query',
            schema: { type: 'string', format: 'date' }
          },
          {
            name: 'endDate',
            in: 'query',
            schema: { type: 'string', format: 'date' }
          }
        ],
        responses: {
          '200': {
            description: 'Analytics data',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    analytics: {
                      type: 'array',
                      items: { $ref: '#/components/schemas/Analytics' }
                    },
                    summary: {
                      type: 'object',
                      properties: {
                        totalImpressions: { type: 'integer' },
                        totalClicks: { type: 'integer' },
                        totalConversions: { type: 'integer' },
                        totalSpend: { type: 'number' },
                        totalRevenue: { type: 'number' },
                        ctr: { type: 'number' },
                        conversionRate: { type: 'number' },
                        cpa: { type: 'number' },
                        roas: { type: 'number' }
                      }
                    }
                  }
                }
              }
            }
          },
          '400': {
            description: 'Bad request',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Error' }
              }
            }
          },
          '401': {
            description: 'Unauthorized',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Error' }
              }
            }
          }
        }
      }
    }
  }
}

export async function GET() {
  return NextResponse.json(openApiSpec)
}