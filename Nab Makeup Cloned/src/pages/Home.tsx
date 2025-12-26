import { Link } from 'react-router-dom';
import { ArrowRight, Star, Shield, Truck } from 'lucide-react';

export const Home = () => {
    return (
        <div className="space-y-20 pb-20 bg-[#051709] text-white min-h-screen">
            {/* Hero Section */}
            <section className="relative h-[80vh] min-h-[600px] flex items-center justify-center overflow-hidden bg-[#051709] bg-fixed bg-center bg-cover bg-[url('https://nabmakeup.com/wp-content/uploads/2023/05/edz-norton-PEttXYw9hi8-unsplash-2.webp')]">
                <div className="absolute inset-0 bg-black/40 z-0"></div>

                <div className="relative z-10 text-center px-4 max-w-5xl mx-auto mt-10">
                    <h1 className="text-5xl md:text-7xl font-bold text-white mb-6 tracking-tight drop-shadow-sm font-serif">
                        NAB MAKEUP <span className="block text-white">& SKINCARE CORNER.</span>
                    </h1>
                    <p className="text-gray-200 text-xl md:text-2xl mb-10 font-medium max-w-2xl mx-auto">
                        Our Online Platform gives you professionally curated Make-Up and Skincare products.
                    </p>
                    <div className="flex flex-col sm:flex-row gap-4 justify-center">
                        <Link
                            to="/shop"
                            className="px-8 py-4 bg-primary text-black font-bold rounded-full hover:bg-white hover:text-black transition-all transform hover:scale-105"
                        >
                            Shop Collection
                        </Link>
                        <Link
                            to="/booking"
                            className="px-8 py-4 border-2 border-white text-white font-bold rounded-full hover:bg-white hover:text-black transition-all"
                        >
                            Book Service
                        </Link>
                    </div>
                </div>
            </section>

            {/* Value Props */}
            <section className="max-w-7xl mx-auto px-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
                    <div className="p-8 border border-white/10 rounded-2xl hover:bg-white/5 transition-colors">
                        <Star className="w-12 h-12 text-primary mx-auto mb-4" />
                        <h3 className="text-xl font-bold mb-2">Premium Quality</h3>
                        <p className="text-gray-400">Ingredients sourced from the finest suppliers.</p>
                    </div>
                    <div className="p-8 border border-white/10 rounded-2xl hover:bg-white/5 transition-colors">
                        <Shield className="w-12 h-12 text-primary mx-auto mb-4" />
                        <h3 className="text-xl font-bold mb-2">Skin Safe</h3>
                        <p className="text-gray-400">Dermatologically tested and cruelty-free.</p>
                    </div>
                    <div className="p-8 border border-white/10 rounded-2xl hover:bg-white/5 transition-colors">
                        <Truck className="w-12 h-12 text-primary mx-auto mb-4" />
                        <h3 className="text-xl font-bold mb-2">Fast Delivery</h3>
                        <p className="text-gray-400">Free shipping on orders over $50.</p>
                    </div>
                </div>
            </section>

            {/* Featured Collection */}
            <section className="max-w-7xl mx-auto px-4">
                <div className="flex justify-between items-end mb-12">
                    <div>
                        <h2 className="text-3xl font-bold mb-2">Trending Now</h2>
                        <p className="text-gray-400">Our most coveted items.</p>
                    </div>
                    <Link to="/shop" className="text-primary flex items-center hover:underline">
                        View All <ArrowRight size={16} className="ml-2" />
                    </Link>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
                    {[
                        { name: 'ABIB QUICK SUNSTICK', price: '995.00', image: 'https://nabmakeup.com/wp-content/uploads/2023/08/abib-quick-sunstick-protection-bar-spf50-pa-22g-132_720x-300x300.webp' },
                        { name: 'ANASTASIA COSMOS PALETTE', price: '3,500.00', image: 'https://nabmakeup.com/wp-content/uploads/2024/03/1000152440-300x300.jpg' },
                        { name: 'ADVANCED CLINICALS RETINOL', price: '1,500.00', image: 'https://nabmakeup.com/wp-content/uploads/2023/06/s-l640-300x300.jpg' },
                        { name: 'AIRSPUN FACE POWDER', price: '800.00', image: 'https://nabmakeup.com/wp-content/uploads/2023/11/71m7oZgwWAL._SL1500_-300x300.jpg' }
                    ].map((product, i) => (
                        <div key={i} className="group cursor-pointer">
                            <div className="aspect-[3/4] bg-white rounded-lg mb-4 relative overflow-hidden border border-gray-100">
                                <img
                                    src={product.image}
                                    alt={product.name}
                                    className="w-full h-full object-contain p-4 group-hover:scale-110 transition-transform duration-500"
                                />
                                <button className="absolute bottom-4 left-4 right-4 bg-white/90 text-black py-3 font-semibold rounded-lg translate-y-full opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all shadow-md">
                                    Add to Cart
                                </button>
                            </div>
                            <h3 className="font-semibold text-lg group-hover:text-primary transition-colors text-white">{product.name}</h3>
                            <p className="text-gray-400">Rs {product.price}</p>
                        </div>
                    ))}
                </div>
            </section>

            {/* Client Love / Recommendations Section */}
            <section className="max-w-7xl mx-auto px-4 py-12">
                <div className="text-center mb-12">
                    <h2 className="text-3xl font-bold mb-4 text-white">Client Love</h2>
                    <p className="text-gray-400">Trusted by beauty enthusiasts across Mauritius</p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                    {/* Review 1 */}
                    <div className="bg-white/5 p-8 rounded-2xl border border-white/10 backdrop-blur-sm">
                        <div className="flex text-yellow-500 mb-4">
                            {[1, 2, 3, 4, 5].map(i => <Star key={i} size={16} fill="currentColor" />)}
                        </div>
                        <p className="text-gray-300 mb-6 italic">"If you want to purchase high-end, authentic & top-notch international brands then there's no second place besides Nab Makeup Corner. Got my products within 48hrs only."</p>
                        <div className="font-semibold text-primary">- Aye SHaa</div>
                        <div className="text-xs text-gray-500 mt-1">via Facebook Reviews</div>
                    </div>

                    {/* Review 2 */}
                    <div className="bg-white/5 p-8 rounded-2xl border border-white/10 backdrop-blur-sm">
                        <div className="flex text-yellow-500 mb-4">
                            {[1, 2, 3, 4, 5].map(i => <Star key={i} size={16} fill="currentColor" />)}
                        </div>
                        <p className="text-gray-300 mb-6 italic">"Nab makeup and skincare corner is very helpful. Their products are amazing. Nabila is indeed a very helpful, kind, down to earth person."</p>
                        <div className="font-semibold text-primary">- Mandira Kurmah</div>
                        <div className="text-xs text-gray-500 mt-1">via Facebook Reviews</div>
                    </div>

                    {/* Review 3 - Summary */}
                    <div className="bg-white/5 p-8 rounded-2xl border border-white/10 backdrop-blur-sm flex flex-col justify-center items-center text-center">
                        <div className="text-5xl font-bold text-white mb-2">94%</div>
                        <div className="text-xl text-primary font-medium mb-4">Recommended</div>
                        <p className="text-gray-400 text-sm">Based on 48+ Reviews on Facebook</p>
                        <a href="https://www.facebook.com/NabilaAhmadMUA/reviews/" target="_blank" rel="noopener noreferrer" className="mt-6 text-white underline hover:text-primary transition-colors">
                            Read all reviews
                        </a>
                    </div>
                </div>
            </section>

            {/* Quiz Callout */}
            <section className="bg-white py-24 border-y border-gold/20">
                <div className="max-w-4xl mx-auto px-4 text-center">
                    <h2 className="text-4xl font-bold mb-6 text-gray-900">Discover Your Personalized Routine</h2>
                    <p className="text-gray-600 text-xl mb-10">
                        Take our AI-powered skin analysis quiz to discover products tailored to your unique skin concerns.
                    </p>
                    <Link
                        to="/skin-quiz"
                        className="inline-block px-10 py-5 bg-primary text-black font-bold rounded-full hover:bg-white transition-colors"
                    >
                        Start Quiz
                    </Link>
                </div>
            </section>
        </div>
    );
};
