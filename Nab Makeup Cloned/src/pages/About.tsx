export const About = () => {
    return (
        <div className="min-h-screen bg-white">
            {/* Hero Section */}
            <section className="relative h-[40vh] min-h-[300px] flex items-center justify-center bg-gradient-to-br from-secondary to-secondary/80">
                <div className="absolute inset-0 bg-black/40"></div>
                <div className="relative z-10 text-center px-4">
                    <h1 className="text-5xl md:text-6xl font-bold text-primary mb-4">ABOUT US</h1>
                </div>
            </section>

            {/* Main Content */}
            <section className="max-w-6xl mx-auto px-4 py-16">
                <div className="prose prose-lg max-w-none mb-16">
                    <p className="text-gray-700 text-lg leading-relaxed">
                        Welcome to <span className="font-semibold text-primary">NAB Makeup & Skincare Corner</span>, your premier destination for authentic beauty and skincare products in Mauritius. We specialize in importing and exporting high-end international brands, ensuring you have access to the finest cosmetics and treatments available.
                    </p>
                    <p className="text-gray-700 text-lg leading-relaxed mt-4">
                        Our mission is to provide professionally curated makeup and skincare solutions, combined with expert facial treatments and personalized consultations to help you achieve your beauty goals.
                    </p>
                </div>

                {/* Specializations Grid */}
                <div className="mb-12">
                    <h2 className="text-4xl font-bold text-center mb-12 text-secondary">WE SPECIALISE IN</h2>
                    <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-6">
                        {[
                            'Beauty Products',
                            'Skincare Products',
                            'Skin Treatments',
                            'Hair Loss Treatment',
                            'Fat Burning',
                            'Bridal Makeup',
                            'Hijab Styling',
                            'Acne Treatments',
                            'Anti-Aging',
                            'Pigmentation'
                        ].map((item) => (
                            <div key={item} className="bg-secondary text-white p-6 rounded-lg text-center hover:bg-secondary/90 transition-colors">
                                <p className="font-semibold">{item}</p>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Why Choose Us */}
                <div className="bg-gray-50 p-8 rounded-2xl">
                    <h3 className="text-3xl font-bold mb-6 text-secondary">Why Choose Us?</h3>
                    <ul className="space-y-4 text-gray-700">
                        <li className="flex items-start">
                            <span className="text-primary font-bold mr-3">✓</span>
                            <span><strong>Authentic Products:</strong> We import genuine, high-end international brands</span>
                        </li>
                        <li className="flex items-start">
                            <span className="text-primary font-bold mr-3">✓</span>
                            <span><strong>Expert Guidance:</strong> Personalized skincare advice from trained professionals</span>
                        </li>
                        <li className="flex items-start">
                            <span className="text-primary font-bold mr-3">✓</span>
                            <span><strong>Fast Delivery:</strong> Products delivered within 48 hours</span>
                        </li>
                        <li className="flex items-start">
                            <span className="text-primary font-bold mr-3">✓</span>
                            <span><strong>Customer Satisfaction:</strong> 94% of our clients recommend us</span>
                        </li>
                    </ul>
                </div>
            </section>
        </div>
    );
};
