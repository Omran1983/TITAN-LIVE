export const Gallery = () => {
    const images = [
        'https://nabmakeup.com/wp-content/uploads/2023/05/dermaplaning.jpg',
        'https://nabmakeup.com/wp-content/uploads/2023/05/fat-dissolving.jpg',
        'https://nabmakeup.com/wp-content/uploads/2023/05/before-after-1.jpg',
        'https://nabmakeup.com/wp-content/uploads/2023/05/before-after-2.jpg',
        'https://nabmakeup.com/wp-content/uploads/2023/05/treatment-1.jpg',
        'https://nabmakeup.com/wp-content/uploads/2023/05/treatment-2.jpg',
    ];

    return (
        <div className="min-h-screen bg-white">
            {/* Header */}
            <section className="bg-secondary text-white py-16">
                <div className="max-w-6xl mx-auto px-4 text-center">
                    <h1 className="text-4xl md:text-5xl font-bold mb-4">GALLERY</h1>
                    <p className="text-xl text-gray-200">STAY TUNED WE WILL BE UPDATING OCCASIONALLY!</p>
                </div>
            </section>

            {/* Gallery Grid */}
            <section className="max-w-7xl mx-auto px-4 py-16">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {images.map((img, index) => (
                        <div key={index} className="group relative overflow-hidden rounded-lg shadow-lg hover:shadow-2xl transition-shadow aspect-square">
                            <img
                                src={img}
                                alt={`Gallery image ${index + 1}`}
                                className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                                onError={(e) => {
                                    e.currentTarget.src = 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=500';
                                }}
                            />
                            <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
                        </div>
                    ))}
                </div>

                {/* Placeholder for more images */}
                <div className="mt-12 text-center">
                    <p className="text-gray-600 text-lg">More transformations and treatments coming soon!</p>
                    <p className="text-gray-500 mt-2">Follow us on Instagram @nab_makeup_reseller for daily updates</p>
                </div>
            </section>
        </div>
    );
};
