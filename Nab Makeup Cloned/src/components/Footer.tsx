import { Link } from 'react-router-dom';
import { Instagram, Facebook } from 'lucide-react';

export const Footer = () => {
    return (
        <footer className="bg-black text-white pt-16 pb-8">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-12">
                    {/* Brand */}
                    <div className="space-y-4">
                        <h3 className="text-2xl font-bold">NAB<span className="text-primary">MAKEUP</span> & SKINCARE</h3>
                        <p className="text-gray-400 text-sm">
                            Our Online Platform gives you professionally curated Make-Up and Skincare products. Contact us for personalised skincare advice.
                        </p>
                    </div>

                    {/* Links */}
                    <div>
                        <h4 className="font-semibold mb-4 text-primary">Shop</h4>
                        <ul className="space-y-2 text-sm text-gray-400">
                            <li><Link to="/shop" className="hover:text-white transition-colors">All Products</Link></li>
                            <li><Link to="/shop?cat=face" className="hover:text-white transition-colors">Face</Link></li>
                            <li><Link to="/shop?cat=eyes" className="hover:text-white transition-colors">Eyes</Link></li>
                            <li><Link to="/shop?cat=lips" className="hover:text-white transition-colors">Lips</Link></li>
                        </ul>
                    </div>

                    <div>
                        <h4 className="font-semibold mb-4 text-primary">Service</h4>
                        <ul className="space-y-2 text-sm text-gray-400">
                            <li><Link to="/booking" className="hover:text-white transition-colors">Book Consultation</Link></li>
                            <li><Link to="/skin-quiz" className="hover:text-white transition-colors">Skin Analysis</Link></li>
                            <li><a href="#" className="hover:text-white transition-colors">Shipping & Returns</a></li>
                            <li><a href="#" className="hover:text-white transition-colors">Contact Us</a></li>
                        </ul>
                    </div>

                    <div>
                        <h4 className="font-semibold mb-4 text-primary">Connect</h4>
                        <div className="flex space-x-4 mb-6">
                            <a href="https://www.instagram.com/nab_makeup_reseller/?hl=en" target="_blank" rel="noopener noreferrer" className="text-gray-400 hover:text-white transition-colors" aria-label="Instagram"><Instagram size={20} /></a>
                            <a href="https://www.facebook.com/NabilaAhmadMUA/" target="_blank" rel="noopener noreferrer" className="text-gray-400 hover:text-white transition-colors" aria-label="Facebook"><Facebook size={20} /></a>
                            <a href="https://www.tiktok.com/@nabmakeup" target="_blank" rel="noopener noreferrer" className="text-gray-400 hover:text-white transition-colors" aria-label="TikTok">
                                {/* Simple text fallback or icon for TikTok if lucide doesn't have it, reusing Twitter for now or generic */}
                                <span className="font-bold text-xs border border-current px-1 rounded">TK</span>
                            </a>
                        </div>
                        <div className="space-y-2 text-sm text-gray-400">
                            <p>Call: 57545715</p>
                            <p>Email: admin@nabmakeup.com</p>
                            <p>Location: Chemin Grenier</p>
                        </div>
                    </div>
                </div>

                <div className="border-t border-gray-800 mt-12 pt-8 text-center text-sm text-gray-500">
                    © {new Date().getFullYear()} Nab Makeup. All rights reserved.
                </div>
            </div>
        </footer>
    );
};
