import React, { createContext, useContext, useState, ReactNode } from 'react';

export interface CartItem {
    id: number;
    name: string;
    price: string;
    image: string;
    quantity: number;
}

interface CartContextType {
    items: CartItem[];
    total: number;
    addItem: (product: any) => void;
    removeItem: (id: number) => void;
    clearCart: () => void;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export const CartProvider = ({ children }: { children: ReactNode }) => {
    const [items, setItems] = useState<CartItem[]>([]);

    const addItem = (product: any) => {
        setItems(current => {
            const existing = current.find(item => item.id === product.id);
            if (existing) {
                return current.map(item =>
                    item.id === product.id
                        ? { ...item, quantity: item.quantity + 1 }
                        : item
                );
            }
            // Parse price string "1,500.00" -> 1500.00
            const priceClean = parseFloat(product.price.replace(/,/g, '').replace('Rs', '').trim()) || 0;
            return [...current, { ...product, price: product.price, quantity: 1, parsedPrice: priceClean }];
        });
    };

    const removeItem = (id: number) => {
        setItems(current => current.filter(item => item.id !== id));
    };

    const clearCart = () => setItems([]);

    const total = items.reduce((sum, item) => {
        const price = parseFloat(item.price.replace(/[^0-9.]/g, '')) || 0;
        return sum + (price * item.quantity);
    }, 0);

    return (
        <CartContext.Provider value={{ items, total, addItem, removeItem, clearCart }}>
            {children}
        </CartContext.Provider>
    );
};

export const useCart = () => {
    const context = useContext(CartContext);
    if (context === undefined) {
        throw new Error('useCart must be used within a CartProvider');
    }
    return context;
};
