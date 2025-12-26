import { Link } from 'react-router-dom';
import { Sparkles, ShoppingCart, Star, Users, MessageCircle, TrendingUp } from 'lucide-react';

export const NewFeatures = () => {
    const features = [
        {
            icon: <ShoppingCart className="w-8 h-8" />,
            title: 'Dynamic Shopping Cart',
            description: 'Real-time cart with live price updates. Add products from the shop and watch the total update instantly in the navbar.',
            status: 'Live',
            color: 'bg-green-500',
        },
        {
            icon: <Star className="w-8 h-8" />,
            title: 'Client Testimonials',
            description: 'Showcasing real 5-star reviews from Facebook. Features 94% recommendation rate from 48+ verified customers.',
            status: 'Live',
            color: 'bg-green-500',
        },
        {
            icon: <Users className="w-8 h-8" />,
            title: 'Social Media Integration',
            description: 'Direct links to Facebook, Instagram, and TikTok profiles. Contact information prominently displayed in footer.',
            status: 'Live',
            color: 'bg-green-500',
        },
        {
            icon: <MessageCircle className="w-8 h-8" />,
            title: 'Contact Form',
            description: 'Professional contact form with embedded Google Maps showing the Chemin Grenier location.',
            status: 'Live',
            color: 'bg-green-500',
        },
        {
            icon: <TrendingUp className="w-8 h-8" />,
            title: 'Complete Navigation',
            description: '8-tab navigation system matching the live site: Home, Shop, About, Services, Contact, Appointment, Gallery, My Account.',
            status: 'Live',
            color: 'bg-green-500',
        },
        {
            icon: <Sparkles className="w-8 h-8" />,
            title: 'Authentic Product Data',
            description: 'Real product listings scraped from nabmakeup.com with actual images, prices, and brand categories.',
            status: 'Live',
            color: 'bg-green-500',
        },
    ];

    return (
        <div className="min-h-screen bg-white">
            {/* Hero Section */}
            <section className="relative h-[40vh] min-h-[300px] flex items-center justify-center bg-gradient-to-br from-purple-600 to-pink-600">
                <div className="absolute inset-0 bg-black/20"></div>
                <div className="relative z-10 text-center px-4">
                    <div className="inline-block mb-4">
                        <span className="bg-yellow-400 text-purple-900 px-4 py-2 rounded-full font-bold text-sm uppercase tracking-wide">
                            New Features
                        </span>
                    </div>
                    <h1 className="text-5xl md:text-6xl font-bold text-white mb-4">What's New</h1>
                    <p className="text-xl text-white/90">Latest enhancements to your shopping experience</p>
                </div>
            </section>

            {/* Features Grid */}
            <section className="max-w-7xl mx-auto px-4 py-16">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                    {features.map((feature, index) => (
                        <div key={index} className="bg-white border-2 border-gray-100 rounded-2xl p-8 hover:shadow-2xl hover:border-purple-200 transition-all">
                            <div className="flex items-start justify-between mb-4">
                                <div className="bg-purple-100 text-purple-600 p-3 rounded-xl">
                                    {feature.icon}
                                </div>
                                <span className={`${feature.color} text-white text-xs font-bold px-3 py-1 rounded-full`}>
                                    {feature.status}
                                </span>
                            </div>
                            <h3 className="text-2xl font-bold mb-3 text-gray-900">{feature.title}</h3>
                            <p className="text-gray-600 leading-relaxed">{feature.description}</p>
                        </div>
                    ))}
                </div>

                {/* Coming Soon Section */}
                <div className="mt-16 bg-gradient-to-r from-purple-50 to-pink-50 p-8 rounded-2xl border-2 border-purple-100">
                    <h2 className="text-3xl font-bold mb-6 text-center text-gray-900">Coming Soon</h2>
                    <div className="grid md:grid-cols-2 gap-6">
                        <div className="bg-white p-6 rounded-xl border border-purple-100">
                            <h4 className="font-semibold text-lg mb-2 text-purple-600">🔍 Advanced Product Search</h4>
                            <p className="text-gray-600 text-sm">Search by brand, category, price range, and skin type</p>
                        </div>
                        <div className="bg-white p-6 rounded-xl border border-purple-100">
                            <h4 className="font-semibold text-lg mb-2 text-purple-600">💳 Checkout System</h4>
                            <p className="text-gray-600 text-sm">Complete payment integration with local payment methods</p>
                        </div>
                        <div className="bg-white p-6 rounded-xl border border-purple-100">
                            <h4 className="font-semibold text-lg mb-2 text-purple-600">📱 Mobile App</h4>
                            <p className="text-gray-600 text-sm">Native iOS and Android apps for on-the-go shopping</p>
                        </div>
                        <div className="bg-white p-6 rounded-xl border border-purple-100">
                            <h4 className="font-semibold text-lg mb-2 text-purple-600">🎁 Loyalty Program</h4>
                            <p className="text-gray-600 text-sm">Earn points with every purchase and unlock exclusive rewards</p>
                        </div>
                    </div>
                </div>

                {/* CTA */}
                <div className="mt-12 text-center">
                    <Link
                        to="/shop"
                        className="inline-block bg-gradient-to-r from-purple-600 to-pink-600 text-white px-8 py-4 rounded-xl font-bold text-lg hover:shadow-2xl transition-all transform hover:scale-105"
                    >
                        Start Shopping Now
                    </Link>
                </div>
            </section>
        </div>
    );
};
