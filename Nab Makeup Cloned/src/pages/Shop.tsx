import { useState } from 'react';
import { Filter } from 'lucide-react';
import { cn } from '../utils/cn';
import { useCart } from '../context/CartContext';

const PRODUCTS = [
    { id: 1, name: 'ABIB QUICK SUNSTICK PROTECTION BAR', price: '995.00', category: 'Abib', image: 'https://nabmakeup.com/wp-content/uploads/2023/08/abib-quick-sunstick-protection-bar-spf50-pa-22g-132_720x-300x300.webp' },
    { id: 2, name: 'ADAPALENE GEL (DIFFERIN)', price: '1,200 - 1,750', category: 'Differin', image: 'https://nabmakeup.com/wp-content/uploads/2023/05/11979142-2984642655004447-300x300.webp' },
    { id: 3, name: 'ADVANCED CLINICALS ALOE VERA CREAM', price: '1,500.00', category: 'Advanced Clinicals', image: 'https://nabmakeup.com/wp-content/uploads/2023/06/61aeN4MIWxL._SL1500_600x-300x300.webp' },
    { id: 4, name: 'ADVANCED CLINICALS ARGAN OIL CREAM', price: '1,350.00', category: 'Advanced Clinicals', image: 'https://nabmakeup.com/wp-content/uploads/2023/06/Capture3-1-300x300.png' },
    { id: 5, name: 'ADVANCED CLINICALS BULGARIAN ROSE', price: '1,500.00', category: 'Advanced Clinicals', image: 'https://nabmakeup.com/wp-content/uploads/2024/10/BulgarianRose_2048x-300x300.webp' },
    { id: 6, name: 'ADVANCED CLINICALS RETINOL CREAM', price: '1,500.00', category: 'Advanced Clinicals', image: 'https://nabmakeup.com/wp-content/uploads/2023/06/s-l640-300x300.jpg' },
    { id: 7, name: 'ADVANCED CLINICALS VITAMIN C CREAM', price: '1,500.00', category: 'Advanced Clinicals', image: 'https://nabmakeup.com/wp-content/uploads/2023/06/CL10141-R2-VitaminCCream-front_296921f2-9fb8-475e-b976-ae7344e12a33_600x-300x300.webp' },
    { id: 8, name: 'AIRSPUN LOOSE FACE POWDER', price: '800.00', category: 'Airspun', image: 'https://nabmakeup.com/wp-content/uploads/2023/11/71m7oZgwWAL._SL1500_-300x300.jpg' },
    { id: 9, name: 'AMLACTIN DAILY LOTION', price: '1,350 - 2,150', category: 'Amlactin', image: 'https://nabmakeup.com/wp-content/uploads/2023/05/51mPiGIWZLL-300x300.jpg' },
    { id: 10, name: 'ANASTASIA BEVERLY HILLS COSMOS PALETTE', price: '3,500.00', category: 'Anastasia Beverly Hills', image: 'https://nabmakeup.com/wp-content/uploads/2024/03/1000152440-300x300.jpg' },
    { id: 11, name: 'ANASTASIA BEVERLY HILLS LIP VELVET', price: '2,250.00', category: 'Anastasia Beverly Hills', image: 'https://nabmakeup.com/wp-content/uploads/2025/08/1000363172-1-300x300.jpg' },
    { id: 12, name: 'ANUA AZELAIC ACID SERUM', price: '1,450.00', category: 'Anua', image: 'https://nabmakeup.com/wp-content/uploads/2025/03/1000283668-300x300.png' }
];

const CATEGORIES = ['All', 'Advanced Clinicals', 'Anastasia Beverly Hills', 'Skincare', 'Makeup'];

export const Shop = () => {
    const [activeCategory, setActiveCategory] = useState('All');
    const { addItem } = useCart();

    const filteredProducts = activeCategory === 'All'
        ? PRODUCTS
        : PRODUCTS.filter(p => p.category === activeCategory);

    return (
        <div className="max-w-7xl mx-auto px-4 py-12 bg-white text-gray-900 min-h-screen">
            <h1 className="text-4xl font-bold mb-8">Shop Collection</h1>

            {/* Filters */}
            <div className="flex flex-col md:flex-row gap-8 mb-12">
                <div className="w-full md:w-64 flex-shrink-0">
                    <div className="sticky top-24">
                        <h3 className="font-bold text-lg mb-4 flex items-center">
                            <Filter size={20} className="mr-2" /> Filters
                        </h3>
                        <div className="space-y-2">
                            {CATEGORIES.map(cat => (
                                <button
                                    key={cat}
                                    onClick={() => setActiveCategory(cat)}
                                    className={cn(
                                        "block w-full text-left px-4 py-2 rounded-lg transition-colors",
                                        activeCategory === cat
                                            ? "bg-primary text-black font-semibold"
                                            : "text-gray-600 hover:bg-gray-50"
                                    )}
                                >
                                    {cat}
                                </button>
                            ))}
                        </div>
                    </div>
                </div>

                {/* Grid */}
                <div className="flex-grow">
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8">
                        {filteredProducts.map((product) => (
                            <div key={product.id} className="group cursor-pointer">
                                <div className="aspect-square rounded-xl mb-4 relative overflow-hidden bg-white">
                                    {product.image.startsWith('http') ? (
                                        <img
                                            src={product.image}
                                            alt={product.name}
                                            className="w-full h-full object-contain p-4 hover:scale-110 transition-transform duration-500"
                                        />
                                    ) : (
                                        <div className={cn("w-full h-full", product.image)}></div>
                                    )}
                                    <div className="absolute inset-0 flex items-center justify-center text-gray-400 font-medium opacity-0">
                                        {/* Hidden text for SEO/Accessibility if image fails */}
                                        {product.name}
                                    </div>
                                    <button
                                        onClick={() => {
                                            addItem(product);
                                            // Optional: Add simple toast here
                                        }}
                                        className="absolute bottom-4 left-4 right-4 bg-black text-white py-3 font-semibold rounded-lg translate-y-full opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all hover:bg-primary hover:text-black"
                                    >
                                        Add to Cart
                                    </button>
                                </div>
                                <div className="flex justify-between items-start">
                                    <div>
                                        <h3 className="font-semibold text-lg mb-1">{product.name}</h3>
                                        <p className="text-sm text-gray-500">{product.category}</p>
                                    </div>
                                    <span className="font-bold text-lg">Rs {product.price}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
};
