import { useState } from 'react';
import { ArrowLeft, ArrowRight, Sparkles } from 'lucide-react';
import { cn } from '../utils/cn';

const QUESTIONS = [
    {
        question: "What is your main skin concern?",
        options: ["Dryness", "Acne & Blemishes", "Aging & Fine Lines", "Dullness", "Oiliness"]
    },
    {
        question: "How would you describe your skin type?",
        options: ["Dry", "Oily", "Combination", "Normal", "Sensitive"]
    },
    {
        question: "What is your preferred finish for makeup?",
        options: ["Matte", "Dewy / Radiant", "Natural / Satin"]
    }
];

import { n8nService, AIRecommendation } from '../services/n8nService';

export const SkinQuiz = () => {
    const [step, setStep] = useState(0);
    const [answers, setAnswers] = useState<string[]>([]);
    const [finished, setFinished] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [recommendation, setRecommendation] = useState<AIRecommendation | null>(null);

    const handleAnswer = async (answer: string) => {
        const newAnswers = [...answers];
        newAnswers[step] = answer;
        setAnswers(newAnswers);

        if (step < QUESTIONS.length - 1) {
            setStep(step + 1);
        } else {
            // Quiz Finished - Call N8N Service
            setIsLoading(true);
            try {
                // Map answers to SkinProfile interface
                const profile = {
                    concern: newAnswers[0],
                    type: newAnswers[1],
                    finish: newAnswers[2]
                };

                const result = await n8nService.analyzeSkinProfile(profile);
                setRecommendation(result);
                setFinished(true);
            } catch (error) {
                console.error("Analysis Failed", error);
                // Fallback or error state
            } finally {
                setIsLoading(false);
            }
        }
    };

    if (isLoading) {
        return (
            <div className="max-w-2xl mx-auto px-4 py-32 text-center animate-fade-in">
                <div className="w-24 h-24 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-8"></div>
                <h2 className="text-2xl font-bold mb-2">Analyzing Skin Profile...</h2>
                <p className="text-gray-500">Connecting to AI Analysis Engine...</p>
            </div>
        );
    }

    if (finished && recommendation) {
        return (
            <div className="max-w-2xl mx-auto px-4 py-20 text-center animate-fade-in">
                <div className="w-20 h-20 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-6">
                    <Sparkles className="text-primary w-10 h-10" />
                </div>
                <h2 className="text-3xl font-bold mb-2">{recommendation.routineName}</h2>
                <p className="text-gray-600 mb-8 px-8">
                    {recommendation.description}
                </p>

                <div className="grid grid-cols-1 gap-6 mb-12">
                    {recommendation.products.map((product, i) => (
                        <div key={i} className="bg-white border hover:border-primary transition-colors rounded-xl p-6 text-left flex items-start space-x-6 shadow-sm">
                            <div className="w-20 h-20 bg-gray-100 rounded-lg flex-shrink-0" />
                            <div>
                                <h4 className="font-bold text-lg mb-1">{product.name}</h4>
                                <p className="text-primary font-semibold mb-2">{product.price}</p>
                                <p className="text-sm text-gray-500 bg-gray-50 p-2 rounded-lg">
                                    <span className="font-semibold text-black">Why?</span> {product.reason}
                                </p>
                            </div>
                        </div>
                    ))}
                </div>

                <button
                    onClick={() => { setStep(0); setAnswers([]); setFinished(false); }}
                    className="text-gray-500 underline hover:text-black"
                >
                    Retake Quiz
                </button>
            </div>
        );
    }

    return (
        <div className="max-w-3xl mx-auto px-4 py-20">
            {/* Progress Bar */}
            <div className="w-full bg-gray-100 h-2 rounded-full mb-12">
                <div
                    className={cn(
                        "bg-primary h-2 rounded-full transition-all duration-300",
                        step === 0 && "w-1/3",
                        step === 1 && "w-2/3",
                        step === 2 && "w-full"
                    )}
                />
            </div>

            <div className="text-center mb-12">
                <span className="text-primary font-bold tracking-widest text-sm uppercase mb-2 block">Question {step + 1} of {QUESTIONS.length}</span>
                <h2 className="text-3xl md:text-4xl font-bold">{QUESTIONS[step].question}</h2>
            </div>

            <div className="space-y-4 max-w-xl mx-auto">
                {QUESTIONS[step].options.map((option) => (
                    <button
                        key={option}
                        onClick={() => handleAnswer(option)}
                        className="w-full p-6 text-left border rounded-xl hover:border-primary hover:bg-primary/5 transition-all group flex justify-between items-center"
                    >
                        <span className="font-medium text-lg">{option}</span>
                        <ArrowRight className="opacity-0 group-hover:opacity-100 text-primary transition-opacity" />
                    </button>
                ))}
            </div>

            <div className="mt-12 flex justify-between max-w-xl mx-auto">
                <button
                    onClick={() => setStep(Math.max(0, step - 1))}
                    disabled={step === 0}
                    className="flex items-center text-gray-500 hover:text-black disabled:opacity-0 transition-opacity"
                >
                    <ArrowLeft size={20} className="mr-2" /> Previous
                </button>
            </div>
        </div>
    );
};
