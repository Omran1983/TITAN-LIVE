import React, { useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { Star, Truck, Shield } from 'lucide-react';
import { cn } from '../utils/cn';

export const Product = () => {
    const { id } = useParams();
    const [quantity, setQuantity] = useState(1);
    const [selectedShade, setSelectedShade] = useState('Deep Red');

    // Mock data - in real app would fetch by ID
    const product = {
        name: 'Velvet Matte Lipstick',
        price: 24.00,
        description: 'A long-wearing, hydrating matte lipstick that provides intense color payoff in a single stroke.',
        shades: ['Deep Red', 'Nude Pink', 'Berry', 'Coral'],
        images: ['bg-red-100', 'bg-red-200', 'bg-red-50']
    };

    return (
        <div className="max-w-7xl mx-auto px-4 py-12">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
                {/* Images */}
                <div className="space-y-4">
                    <div className={cn("aspect-square rounded-2xl w-full", product.images[0])} />
                    <div className="grid grid-cols-3 gap-4">
                        {product.images.map((img, i) => (
                            <div key={i} className={cn("aspect-square rounded-lg cursor-pointer hover:opacity-80 transition-opacity", img)} />
                        ))}
                    </div>
                </div>

                {/* Info */}
                <div>
                    <h1 className="text-4xl font-bold mb-2">{product.name}</h1>
                    <div className="flex items-center space-x-2 mb-6">
                        <div className="flex text-primary">
                            {[1, 2, 3, 4, 5].map(i => <Star key={i} size={16} fill="currentColor" />)}
                        </div>
                        <span className="text-sm text-gray-500">(128 reviews)</span>
                    </div>

                    <p className="text-2xl font-semibold mb-6">${product.price.toFixed(2)}</p>

                    <p className="text-gray-600 mb-8 leading-relaxed">
                        {product.description}
                    </p>

                    <div className="mb-8">
                        <h3 className="font-semibold mb-3">Select Shade: <span className="text-gray-500 font-normal">{selectedShade}</span></h3>
                        <div className="flex flex-wrap gap-3">
                            {product.shades.map(shade => (
                                <button
                                    key={shade}
                                    onClick={() => setSelectedShade(shade)}
                                    className={cn(
                                        "px-4 py-2 rounded-full border text-sm transition-all",
                                        selectedShade === shade
                                            ? "border-primary bg-primary text-black font-semibold"
                                            : "border-gray-300 text-gray-600 hover:border-gray-400"
                                    )}
                                >
                                    {shade}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div className="flex gap-4 mb-8">
                        <div className="flex items-center border border-gray-300 rounded-lg">
                            <button
                                onClick={() => setQuantity(Math.max(1, quantity - 1))}
                                className="px-4 py-2 text-xl font-medium hover:bg-gray-50 text-gray-600"
                            >-</button>
                            <span className="px-4 font-semibold w-12 text-center">{quantity}</span>
                            <button
                                onClick={() => setQuantity(quantity + 1)}
                                className="px-4 py-2 text-xl font-medium hover:bg-gray-50 text-gray-600"
                            >+</button>
                        </div>
                        <button className="flex-grow bg-black text-white font-bold py-3 rounded-lg hover:bg-gray-900 transition-colors">
                            Add to Cart - ${(product.price * quantity).toFixed(2)}
                        </button>
                    </div>

                    <div className="space-y-4 border-t pt-8">
                        <div className="flex items-center text-sm text-gray-600">
                            <Truck size={20} className="mr-3" />
                            <span>Free shipping on orders over $50</span>
                        </div>
                        <div className="flex items-center text-sm text-gray-600">
                            <Shield size={20} className="mr-3" />
                            <span>30-day money-back guarantee</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};
