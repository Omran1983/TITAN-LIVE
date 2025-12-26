import React, { useState } from 'react';
import { Calendar, Clock, Check } from 'lucide-react';


import { n8nService, BookingData } from '../services/n8nService';

export const Booking = () => {
    const [submitted, setSubmitted] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [statusMessage, setStatusMessage] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);

        // Extract form data
        const formData: BookingData = {
            firstName: (document.getElementById('firstName') as HTMLInputElement).value,
            lastName: (document.getElementById('lastName') as HTMLInputElement).value,
            email: (document.getElementById('email') as HTMLInputElement).value,
            serviceType: (document.getElementById('serviceType') as HTMLSelectElement).value,
            date: (document.getElementById('date') as HTMLInputElement).value,
            time: (document.getElementById('time') as HTMLInputElement).value,
            notes: (document.getElementById('notes') as HTMLTextAreaElement).value,
        };

        try {
            const result = await n8nService.submitBooking(formData);
            if (result.success) {
                setStatusMessage(result.message);
                setSubmitted(true);
            } else {
                alert("Something went wrong. Please try again.");
            }
        } catch (error) {
            console.error(error);
            alert("Connection error.");
        } finally {
            setIsLoading(false);
        }
    };

    if (submitted) {
        return (
            <div className="max-w-2xl mx-auto px-4 py-20 text-center">
                <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
                    <Check className="text-green-600 w-10 h-10" />
                </div>
                <h2 className="text-3xl font-bold mb-4">Request Received!</h2>
                <p className="text-gray-600 mb-8">
                    {statusMessage || "Thank you for booking with us. Our automated system is checking availability."}
                </p>
                <button
                    onClick={() => setSubmitted(false)}
                    className="px-8 py-3 bg-black text-white rounded-lg hover:bg-gray-900"
                >
                    Book Another
                </button>
            </div>
        )
    }

    return (
        <div className="max-w-7xl mx-auto px-4 py-12">
            <div className="max-w-2xl mx-auto">
                <div className="text-center mb-12">
                    <h1 className="text-4xl font-bold mb-4">Book a Consultation</h1>
                    <p className="text-gray-600">
                        Meet with our professional artists for a personalized makeup session or skincare analysis.
                    </p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6 bg-white p-8 border border-gray-100 rounded-2xl shadow-sm">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div>
                            <label htmlFor="firstName" className="block text-sm font-medium text-gray-700 mb-2">First Name</label>
                            <input id="firstName" type="text" required className="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-colors" />
                        </div>
                        <div>
                            <label htmlFor="lastName" className="block text-sm font-medium text-gray-700 mb-2">Last Name</label>
                            <input id="lastName" type="text" required className="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-colors" />
                        </div>
                    </div>

                    <div>
                        <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">Email</label>
                        <input id="email" type="email" required className="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-colors" />
                    </div>

                    <div>
                        <label htmlFor="serviceType" className="block text-sm font-medium text-gray-700 mb-2">Service Type</label>
                        <select id="serviceType" className="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-colors">
                            <option value="" disabled>Select a Service</option>
                            <optgroup label="Makeup & Styling">
                                <option>Bridal Makeup</option>
                                <option>Non Bridal Ultra Glam</option>
                                <option>Non Bridal Soft Glam</option>
                                <option>Hairstyling</option>
                                <option>Hijaab Styling</option>
                            </optgroup>
                            <optgroup label="Medical Aesthetics">
                                <option>Acne Treatment</option>
                                <option>Anti Aging (Microdermabrasion/Peels)</option>
                                <option>Fat Burning</option>
                                <option>Hair Loss Treatment</option>
                                <option>Lip Mesotherapy (Hydration)</option>
                                <option>Pigmentation Treatment</option>
                                <option>Underarm Whitening</option>
                            </optgroup>
                        </select>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div>
                            <label htmlFor="date" className="block text-sm font-medium text-gray-700 mb-2">Preferred Date</label>
                            <div className="relative">
                                <Calendar className="absolute left-3 top-3 text-gray-400" size={20} />
                                <input id="date" type="date" required className="w-full pl-10 pr-4 py-3 rounded-lg border border-gray-200 focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-colors" />
                            </div>
                        </div>
                        <div>
                            <label htmlFor="time" className="block text-sm font-medium text-gray-700 mb-2">Preferred Time</label>
                            <div className="relative">
                                <Clock className="absolute left-3 top-3 text-gray-400" size={20} />
                                <input id="time" type="time" required className="w-full pl-10 pr-4 py-3 rounded-lg border border-gray-200 focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-colors" />
                            </div>
                        </div>
                    </div>

                    <div>
                        <label htmlFor="notes" className="block text-sm font-medium text-gray-700 mb-2">Notes</label>
                        <textarea id="notes" rows={4} className="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-colors" placeholder="Any allergies or specific looks you're interested in?" />
                    </div>

                    <button
                        type="submit"
                        disabled={isLoading}
                        className="w-full bg-black text-white font-bold py-4 rounded-lg hover:bg-gray-900 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex justify-center items-center"
                    >
                        {isLoading ? (
                            <>
                                <span className="animate-spin mr-2">⏳</span> Processing Request...
                            </>
                        ) : (
                            "Request Appointment"
                        )}
                    </button>
                </form>
            </div>
        </div>
    );
};
