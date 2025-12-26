'use client'

import { useState, useEffect, useRef } from 'react'
import { PlusIcon, PencilIcon, TrashIcon, MagnifyingGlassIcon, FunnelIcon } from '@heroicons/react/24/outline'
import { toast } from 'react-hot-toast'

interface Product {
  id: string
  name: string
  description?: string
  price: number
  category?: string
  imageUrl?: string
  isActive: boolean
  createdAt: string
}

export default function Products() {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [showAddForm, setShowAddForm] = useState(false)
  const [editingProduct, setEditingProduct] = useState<Product | null>(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [categoryFilter, setCategoryFilter] = useState('')
  const [newProduct, setNewProduct] = useState({
    name: '',
    description: '',
    price: '',
    category: '',
    imageUrl: ''
  })
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    fetchProducts()
  }, [])

  const fetchProducts = async () => {
    try {
      const response = await fetch('/api/products')
      
      if (!response.ok) {
        const errorText = await response.text()
        console.error('Products API Error:', errorText)
        toast.error('Failed to load products. Please check your connection.')
        return
      }
      
      const data = await response.json()
      setProducts(data.products || [])
      
    } catch (error) {
      console.error('Failed to fetch products:', error)
      toast.error('Unable to connect to the server. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0] || null
    setImageFile(file)
    
    if (file) {
      const reader = new FileReader()
      reader.onloadend = () => {
        setImagePreview(reader.result as string)
      }
      reader.readAsDataURL(file)
      // Clear imageUrl when file is selected
      setNewProduct({ ...newProduct, imageUrl: '' })
    } else {
      setImagePreview(null)
    }
  }

  const handleAddProduct = async (e: React.FormEvent) => {
    e.preventDefault()
    
    try {
      let response: Response
      
      if (imageFile) {
        // Handle file upload
        const formData = new FormData()
        formData.append('name', newProduct.name)
        formData.append('description', newProduct.description)
        formData.append('price', newProduct.price)
        formData.append('category', newProduct.category)
        formData.append('file', imageFile)
        
        response = await fetch('/api/products', {
          method: 'POST',
          body: formData,
        })
      } else {
        // Handle URL or no image
        response = await fetch('/api/products', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(newProduct),
        })
      }

      if (!response.ok) {
        const errorData = await response.json()
        toast.error(errorData.error || 'Failed to add product')
        return
      }

      toast.success('Product added successfully! 🎉')
      await fetchProducts()
      setShowAddForm(false)
      resetForm()
      
    } catch (error) {
      console.error('Failed to add product:', error)
      toast.error('Unable to add product. Please try again.')
    }
  }

  const handleUpdateProduct = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!editingProduct) return
    
    try {
      let response: Response
      
      if (imageFile) {
        // Handle file upload
        const formData = new FormData()
        formData.append('name', newProduct.name)
        formData.append('description', newProduct.description)
        formData.append('price', newProduct.price)
        formData.append('category', newProduct.category)
        formData.append('file', imageFile)
        
        response = await fetch(`/api/products?id=${editingProduct.id}`, {
          method: 'PUT',
          body: formData,
        })
      } else {
        // Handle URL or no image
        response = await fetch(`/api/products?id=${editingProduct.id}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            ...newProduct,
            imageUrl: newProduct.imageUrl || editingProduct.imageUrl
          }),
        })
      }

      if (!response.ok) {
        const errorData = await response.json()
        toast.error(errorData.error || 'Failed to update product')
        return
      }

      toast.success('Product updated successfully! 🎉')
      await fetchProducts()
      setEditingProduct(null)
      resetForm()
      
    } catch (error) {
      console.error('Failed to update product:', error)
      toast.error('Unable to update product. Please try again.')
    }
  }

  const resetForm = () => {
    setNewProduct({ name: '', description: '', price: '', category: '', imageUrl: '' })
    setImageFile(null)
    setImagePreview(null)
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }

  const handleEditProduct = (product: Product) => {
    setEditingProduct(product)
    setNewProduct({
      name: product.name,
      description: product.description || '',
      price: product.price.toString(),
      category: product.category || '',
      imageUrl: product.imageUrl || ''
    })
    setImagePreview(product.imageUrl || null)
    setShowAddForm(true)
  }

  const filteredProducts = products.filter(product => {
    const matchesSearch = product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         product.description?.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesCategory = !categoryFilter || product.category === categoryFilter
    return matchesSearch && matchesCategory
  })

  const categories = Array.from(new Set(products.map(p => p.category).filter(Boolean)))

  if (loading) {
    return (
      <div className="animate-fade-in space-y-6">
        <div className="flex justify-between items-start">
          <div>
            <div className="h-8 bg-gray-200 rounded w-48 mb-2 skeleton"></div>
            <div className="h-4 bg-gray-200 rounded w-96 skeleton"></div>
          </div>
          <div className="h-10 bg-gray-200 rounded w-32 skeleton"></div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="surface-elevated p-6">
              <div className="h-40 bg-gray-200 rounded-lg mb-4 skeleton"></div>
              <div className="h-6 bg-gray-200 rounded mb-2 skeleton"></div>
              <div className="h-4 bg-gray-200 rounded w-24 skeleton"></div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="animate-slide-up space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-display">Product Catalog</h1>
          <p className="text-body mt-2">
            Manage your product inventory and marketing assets
          </p>
        </div>
        <div className="mt-4 sm:mt-0">
          <button
            onClick={() => {
              setEditingProduct(null)
              resetForm()
              setShowAddForm(true)
            }}
            className="btn btn-primary"
          >
            <PlusIcon className="h-4 w-4 mr-2" />
            Add Product
          </button>
        </div>
      </div>

      {/* Filters and Search */}
      <div className="surface-elevated p-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search products..."
                className="form-input pl-10"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>
          <div className="sm:w-48">
            <div className="relative">
              <FunnelIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <select
                className="form-input pl-10 appearance-none"
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
              >
                <option value="">All Categories</option>
                {categories.map(category => (
                  <option key={category} value={category}>{category}</option>
                ))}
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* Add/Edit Product Form */}
      {showAddForm && (
        <div className="surface-elevated-high animate-scale-in">
          <div className="p-6 border-b border-gray-100">
            <h2 className="text-headline">{editingProduct ? 'Edit Product' : 'Add New Product'}</h2>
            <p className="text-body mt-1">
              {editingProduct ? 'Update product details' : 'Create a new product for your catalog'}
            </p>
          </div>
          
          <form onSubmit={editingProduct ? handleUpdateProduct : handleAddProduct} className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="form-label">Product Name</label>
                <input
                  type="text"
                  required
                  className="form-input"
                  placeholder="Enter product name"
                  value={newProduct.name}
                  onChange={(e) => setNewProduct({ ...newProduct, name: e.target.value })}
                />
              </div>
              <div>
                <label className="form-label">Price</label>
                <input
                  type="number"
                  step="0.01"
                  required
                  className="form-input"
                  placeholder="0.00"
                  value={newProduct.price}
                  onChange={(e) => setNewProduct({ ...newProduct, price: e.target.value })}
                />
              </div>
              <div>
                <label className="form-label">Category</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="e.g., Electronics, Clothing"
                  value={newProduct.category}
                  onChange={(e) => setNewProduct({ ...newProduct, category: e.target.value })}
                />
              </div>
              <div>
                <label className="form-label">Image</label>
                <div className="flex items-center space-x-4">
                  <label className="btn btn-secondary flex-1 text-center">
                    Choose File
                    <input
                      type="file"
                      ref={fileInputRef}
                      accept="image/*"
                      className="hidden"
                      onChange={handleFileChange}
                    />
                  </label>
                  {(imageFile || newProduct.imageUrl || (editingProduct && editingProduct.imageUrl)) && (
                    <button
                      type="button"
                      className="btn btn-outline"
                      onClick={() => {
                        setImageFile(null)
                        setImagePreview(null)
                        setNewProduct({ ...newProduct, imageUrl: '' })
                        if (fileInputRef.current) {
                          fileInputRef.current.value = ''
                        }
                      }}
                    >
                      Clear
                    </button>
                  )}
                </div>
                {imageFile && (
                  <p className="text-sm text-gray-500 mt-1 truncate">
                    {imageFile.name} ({(imageFile.size / 1024).toFixed(1)} KB)
                  </p>
                )}
                {!imageFile && (
                  <>
                    <div className="mt-2">
                      <label className="form-label text-sm">Or enter image URL</label>
                      <input
                        type="url"
                        className="form-input"
                        placeholder="https://example.com/image.jpg"
                        value={newProduct.imageUrl}
                        onChange={(e) => setNewProduct({ ...newProduct, imageUrl: e.target.value })}
                      />
                    </div>
                  </>
                )}
              </div>
              <div className="md:col-span-2">
                <label className="form-label">Description</label>
                <textarea
                  rows={3}
                  className="form-input"
                  placeholder="Product description..."
                  value={newProduct.description}
                  onChange={(e) => setNewProduct({ ...newProduct, description: e.target.value })}
                />
              </div>
            </div>
            
            {/* Image Preview */}
            {(imagePreview || newProduct.imageUrl || (editingProduct && editingProduct.imageUrl)) && (
              <div className="mt-4">
                <label className="form-label">Image Preview</label>
                <div className="border rounded-lg p-2 bg-gray-50">
                  <img
                    src={imagePreview || newProduct.imageUrl || (editingProduct?.imageUrl || '')}
                    alt="Preview"
                    className="max-h-40 mx-auto"
                    onError={(e) => {
                      const target = e.target as HTMLImageElement
                      target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiBmaWxsPSIjZGRkIi8+PHRleHQgeD0iMzIiIHk9IjMyIiBmb250LWZhbWlseT0iQXJpYWwiIGZvbnQtc2l6ZT0iMTIiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGRvbWluYW50LWJhc2VsaW5lPSJtaWRkbGUiPk5vIEltYWdlPC90ZXh0Pjwvc3ZnPg=='
                    }}
                  />
                </div>
              </div>
            )}
            
            <div className="mt-6 flex justify-end space-x-3">
              <button
                type="button"
                onClick={() => {
                  setShowAddForm(false)
                  setEditingProduct(null)
                  resetForm()
                }}
                className="btn btn-secondary"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="btn btn-primary"
              >
                {editingProduct ? 'Update Product' : 'Add Product'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Products Grid */}
      {filteredProducts.length === 0 ? (
        <div className="surface-elevated text-center py-12">
          <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <PlusIcon className="h-8 w-8 text-gray-400" />
          </div>
          <h3 className="text-title mb-2">No products found</h3>
          <p className="text-body mb-4">
            {searchQuery || categoryFilter 
              ? 'Try adjusting your search or filter criteria' 
              : 'Get started by adding your first product'}
          </p>
          {!searchQuery && !categoryFilter && (
            <button
              onClick={() => {
                setEditingProduct(null)
                resetForm()
                setShowAddForm(true)
              }}
              className="btn btn-primary"
            >
              Add Your First Product
            </button>
          )}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredProducts.map((product, index) => (
            <div 
              key={product.id} 
              className="surface-elevated-high hover-lift group"
              style={{ animationDelay: `${index * 50}ms` }}
            >
              {product.imageUrl ? (
                <div className="h-48 bg-gray-100 overflow-hidden rounded-t-lg">
                  <img
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    src={product.imageUrl}
                    alt={product.name}
                    onError={(e) => {
                      const target = e.target as HTMLImageElement
                      target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiBmaWxsPSIjZGRkIi8+PHRleHQgeD0iMzIiIHk9IjMyIiBmb250LWZhbWlseT0iQXJpYWwiIGZvbnQtc2l6ZT0iMTIiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGRvbWluYW50LWJhc2VsaW5lPSJtaWRkbGUiPk5vIEltYWdlPC90ZXh0Pjwvc3ZnPg=='
                    }}
                  />
                </div>
              ) : (
                <div className="h-48 bg-gradient-to-br from-gray-50 to-gray-100 rounded-t-lg flex items-center justify-center">
                  <div className="text-gray-400 text-center">
                    <div className="w-12 h-12 bg-gray-200 rounded-lg mx-auto mb-2"></div>
                    <span className="text-sm">No image</span>
                  </div>
                </div>
              )}
              
              <div className="p-6">
                <div className="flex items-start justify-between mb-3">
                  <h3 className="text-title font-semibold line-clamp-1">{product.name}</h3>
                  <div className="text-right">
                    <div className="text-lg font-bold text-gray-900">
                      ${product.price.toFixed(2)}
                    </div>
                  </div>
                </div>
                
                {product.category && (
                  <span className="status-badge bg-blue-50 text-blue-700 mb-3 inline-block">
                    {product.category}
                  </span>
                )}
                
                {product.description && (
                  <p className="text-body line-clamp-2 mb-4">{product.description}</p>
                )}
                
                <div className="flex items-center justify-between">
                  <span className={`status-badge ${
                    product.isActive ? 'status-active' : 'status-inactive'
                  }`}>
                    {product.isActive ? 'Active' : 'Inactive'}
                  </span>
                  
                  <div className="flex space-x-1">
                    <button 
                      className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                      onClick={() => handleEditProduct(product)}
                    >
                      <PencilIcon className="h-4 w-4" />
                    </button>
                    <button className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors">
                      <TrashIcon className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}