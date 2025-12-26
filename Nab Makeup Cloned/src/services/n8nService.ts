export interface BookingData {
    firstName: string;
    lastName: string;
    email: string;
    serviceType: string;
    date: string;
    time: string;
    notes: string;
}

export interface SkinProfile {
    concern: string;
    type: string;
    finish: string;
}

export interface AIRecommendation {
    routineName: string;
    description: string;
    products: Array<{
        name: string;
        price: string;
        reason: string;
    }>;
}

// TOGGLE THIS TO FALSE WHEN N8N BACKEND IS READY
const DEMO_MODE = true;

// PLACEHOLDER URLS - Replace with actual N8N Webhook URLs when ready
const N8N_URLS = {
    BOOKING: 'https://webhook.site/placeholder-booking',
    SKIN_ANALYSIS: 'https://webhook.site/placeholder-analysis'
};

export const n8nService = {
    /**
     * Submits booking data to the N8N Booking Workflow.
     * Use N8N to trigger: Email Confirmation -> Calendar Invite -> Slack Notification
     */
    submitBooking: async (data: BookingData): Promise<{ success: boolean; message: string }> => {
        if (DEMO_MODE) {
            // Simulate Network Latency
            await new Promise(resolve => setTimeout(resolve, 1500));

            console.log("DEMO MODE: Booking Data submitted:", data);
            return {
                success: true,
                message: "Booking request received! Our automated system is checking availability."
            };
        }

        try {
            const response = await fetch(N8N_URLS.BOOKING, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
            return await response.json();
        } catch (error) {
            console.error("Booking submission failed:", error);
            return { success: false, message: "Network error. Please try again." };
        }
    },

    /**
     * Sends skin profile to N8N "AI Agent" Workflow.
     * Use N8N to: Classify Skin Type -> Select Products from Database -> Generate Personalized Routine
     */
    analyzeSkinProfile: async (profile: SkinProfile): Promise<AIRecommendation> => {
        if (DEMO_MODE) {
            // Simulate AI "Thinking" time
            await new Promise(resolve => setTimeout(resolve, 2500));

            // Simple "Mock AI" Logic to make the demo feel real
            const isOily = profile.type.toLowerCase().includes('oily');
            const isDry = profile.type.toLowerCase().includes('dry');
            const isAcne = profile.concern.toLowerCase().includes('acne');

            if (isAcne || isOily) {
                return {
                    routineName: "Clear & Balance Routine",
                    description: "Based on your unique profile, we've designed a routine to control excess oil while gently treating blemishes without stripping your skin barrier.",
                    products: [
                        { name: "Adapalene Gel (Differin)", price: "Rs 1,200", reason: "Gold standard for treating acne at the source." },
                        { name: "Abib Quick Sunstick", price: "Rs 995", reason: "Lightweight sun protection that won't clog pores." }
                    ]
                };
            } else if (isDry) {
                return {
                    routineName: "Deep Hydration Glow",
                    description: "Your skin needs barrier reinforcement. This routine focuses on locking in moisture and restoring your natural radiance.",
                    products: [
                        { name: "Advanced Clinicals Argan Oil Cream", price: "Rs 1,350", reason: "Intensive moisture to heal dry patches." },
                        { name: "Advanced Clinicals Vitamin C Cream", price: "Rs 1,500", reason: "Brightens dullness often associated with dry skin." }
                    ]
                };
            }

            // Default "Normal/Combination" Fallback
            return {
                routineName: "Radiance Maintenance Routine",
                description: "A balanced approach to maintain your healthy skin barrier while preventing future issues.",
                products: [
                    { name: "Advanced Clinicals Bulgarian Rose", price: "Rs 1,500", reason: "Balances pH and hydrates." },
                    { name: "Airspun Loose Face Powder", price: "Rs 800", reason: "For that perfect, soft-focus finish." }
                ]
            };
        }

        try {
            const response = await fetch(N8N_URLS.SKIN_ANALYSIS, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(profile)
            });
            return await response.json();
        } catch (error) {
            console.error("AI Analysis failed:", error);
            throw error;
        }
    }
};
