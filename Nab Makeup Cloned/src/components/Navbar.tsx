import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Menu, X, ShoppingBag, Search } from 'lucide-react';
import { cn } from '../utils/cn';
import { useCart } from '../context/CartContext';

export const Navbar = () => {
    const [isOpen, setIsOpen] = useState(false);
    const location = useLocation();
    const { total } = useCart();

    // Format price: 1250 -> "Rs 1,250.00"
    const formattedTotal = total.toLocaleString('en-PK', { style: 'currency', currency: 'PKR' }).replace('PKR', 'Rs');

    const navItems = [
        { name: 'Home', path: '/' },
        { name: 'Shop', path: '/shop' },
        { name: 'About', path: '/about' },
        { name: 'Services', path: '/services' },
        { name: 'Contact', path: '/contact' },
        { name: 'Appointment', path: '/booking' },
        { name: 'Gallery', path: '/gallery' },
        { name: 'NEW', path: '/new', highlight: true },
        { name: 'My Account', path: '/account' },
    ];

    return (
        <nav className="fixed w-full bg-secondary text-white z-50 border-b border-secondary shadow-md">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between h-20 items-center">
                    {/* Logo */}
                    <Link to="/" className="flex-shrink-0 flex items-center mr-4 lg:mr-8">
                        <img
                            className="h-12 lg:h-16 w-auto"
                            src="https://nabmakeup.com/wp-content/uploads/2024/03/cropped-Untitled-design.png"
                            alt="NAB Makeup & Skincare"
                        />
                    </Link>

                    {/* Desktop Nav */}
                    <div className="hidden xl:flex space-x-5">
                        {navItems.map((item) => (
                            <Link
                                key={item.name}
                                to={item.path}
                                className={cn(
                                    "text-sm font-medium transition-colors hover:text-accent uppercase tracking-wide",
                                    location.pathname === item.path ? "text-accent" : "text-gray-200",
                                    item.highlight && "bg-gradient-to-r from-yellow-400 to-pink-500 text-black px-3 py-1 rounded-full animate-pulse"
                                )}
                            >
                                {item.name}
                            </Link>
                        ))}
                    </div>

                    {/* Right Side Actions */}
                    <div className="hidden md:flex items-center space-x-4 lg:space-x-6 ml-4">
                        <button className="text-white hover:text-accent transition-colors" aria-label="Search">
                            <Search size={20} />
                        </button>

                        {/* Cart Button with Price */}
                        <button className="flex items-center space-x-2 border border-white/20 px-4 py-2 rounded hover:border-accent transition-colors group">
                            <ShoppingBag size={18} className="text-accent" />
                            <span className="font-semibold text-sm group-hover:text-accent">{formattedTotal}</span>
                        </button>
                    </div>

                    {/* Mobile Menu Button */}
                    <div className="md:hidden flex items-center space-x-4">
                        <button className="flex items-center space-x-1 border border-white/20 px-2 py-1 rounded">
                            <ShoppingBag size={16} className="text-accent" />
                            <span className="font-semibold text-xs">{formattedTotal}</span>
                        </button>
                        <button onClick={() => setIsOpen(!isOpen)} className="text-white hover:text-accent" aria-label="Menu">
                            {isOpen ? <X size={24} /> : <Menu size={24} />}
                        </button>
                    </div>
                </div>
            </div>

            {/* Mobile Menu */}
            {
                isOpen && (
                    <div className="md:hidden bg-white border-t">
                        <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3">
                            {navItems.map((item) => (
                                <Link
                                    key={item.path}
                                    to={item.path}
                                    onClick={() => setIsOpen(false)}
                                    className="block px-3 py-2 text-base font-medium text-gray-700 hover:text-primary hover:bg-gray-50 rounded-md"
                                >
                                    {item.name}
                                </Link>
                            ))}
                        </div>
                    </div>
                )
            }
        </nav >
    );
};
