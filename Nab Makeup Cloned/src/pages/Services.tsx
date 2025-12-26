import { Link } from 'react-router-dom';

export const Services = () => {
    const services = [
        {
            title: 'Non-Bridal Ultra Glam',
            description: 'Full glam makeup for special events, photoshoots, and parties.',
            price: 'From Rs 2,500',
        },
        {
            title: 'Non-Bridal Soft Glam',
            description: 'Natural, elegant makeup perfect for daytime events.',
            price: 'From Rs 2,000',
        },
        {
            title: 'Acne Treatment',
            description: 'Professional medical-grade acne treatments and skincare solutions.',
            price: 'From Rs 1,500',
        },
        {
            title: 'Anti-Aging',
            description: 'Microdermabrasion, chemical peels, and anti-aging treatments.',
            price: 'From Rs 2,500',
        },
        {
            title: 'Bridal Makeup',
            description: 'Complete bridal makeup package with trial session included.',
            price: 'From Rs 5,000',
        },
        {
            title: 'Pigmentation Treatment',
            description: 'Advanced treatments for hyperpigmentation and dark spots.',
            price: 'From Rs 2,000',
        },
    ];

    return (
        <div className="min-h-screen bg-white">
            {/* Hero Section */}
            <section className="relative h-[50vh] min-h-[400px] flex items-center justify-center bg-gradient-to-br from-secondary to-secondary/80">
                <div className="absolute inset-0 bg-black/40"></div>
                <div className="relative z-10 text-center px-4">
                    <h1 className="text-5xl md:text-6xl font-bold text-white mb-4">MAKEUP AND</h1>
                    <h2 className="text-4xl md:text-5xl font-bold text-primary">MEDICAL AESTHETICS</h2>
                </div>
            </section>

            {/* Services Grid */}
            <section className="max-w-7xl mx-auto px-4 py-16">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                    {services.map((service, index) => (
                        <div key={index} className="bg-secondary text-white rounded-2xl p-8 hover:shadow-2xl transition-shadow">
                            <h3 className="text-2xl font-bold mb-4">{service.title}</h3>
                            <p className="text-gray-300 mb-6">{service.description}</p>
                            <div className="flex items-center justify-between">
                                <span className="text-primary font-semibold text-lg">{service.price}</span>
                                <Link
                                    to="/booking"
                                    className="bg-primary text-secondary px-6 py-2 rounded-lg font-semibold hover:bg-primary/90 transition-colors"
                                >
                                    BOOK NOW
                                </Link>
                            </div>
                        </div>
                    ))}
                </div>

                {/* Additional Info */}
                <div className="mt-16 bg-gray-50 p-8 rounded-2xl">
                    <h3 className="text-3xl font-bold mb-6 text-secondary text-center">Why Choose Our Services?</h3>
                    <div className="grid md:grid-cols-3 gap-8 text-center">
                        <div>
                            <div className="text-4xl mb-4">💄</div>
                            <h4 className="font-semibold text-lg mb-2">Professional Artists</h4>
                            <p className="text-gray-600">Certified makeup artists and aestheticians with years of experience</p>
                        </div>
                        <div>
                            <div className="text-4xl mb-4">✨</div>
                            <h4 className="font-semibold text-lg mb-2">Premium Products</h4>
                            <p className="text-gray-600">We use only high-end, authentic international brands</p>
                        </div>
                        <div>
                            <div className="text-4xl mb-4">🎯</div>
                            <h4 className="font-semibold text-lg mb-2">Personalized Care</h4>
                            <p className="text-gray-600">Customized treatments tailored to your unique needs</p>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    );
};
