/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                primary: '#304C4B', // Official Nab Teal
                secondary: '#1B2C24', // Header/Footer Background
                accent: '#FF8484', // Brand Pink Highlight
                gold: '#CC9595', // Muted Gold/Copper
                paper: '#051709', // Deep Dark Green (Live Site Body Background)
            }
        },
    },
    plugins: [],
}
