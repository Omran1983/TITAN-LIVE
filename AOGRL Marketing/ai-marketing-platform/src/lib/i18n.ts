'use client'

import { createContext, useContext, useEffect, useState } from 'react'
import enTranslations from './locales/en.json'
import frTranslations from './locales/fr.json'

export type Language = 'en' | 'fr'

const translations = {
  en: enTranslations,
  fr: frTranslations,
}

interface I18nContextType {
  language: Language
  setLanguage: (lang: Language) => void
  t: (key: string, params?: Record<string, string>) => string
}

export const I18nContext = createContext<I18nContextType | undefined>(undefined)

export function useI18n() {
  const context = useContext(I18nContext)
  if (!context) {
    throw new Error('useI18n must be used within an I18nProvider')
  }
  return context
}

export function getNestedValue(obj: any, path: string): string {
  return path.split('.').reduce((current, key) => {
    return current && current[key] !== undefined ? current[key] : undefined
  }, obj)
}

export function translate(language: Language, key: string, params?: Record<string, string>): string {
  const translation = getNestedValue(translations[language], key)
  
  if (!translation) {
    console.warn(`Translation missing for key: ${key} in language: ${language}`)
    return key
  }

  if (typeof translation !== 'string') {
    console.warn(`Translation for key: ${key} is not a string`)
    return key
  }

  // Replace parameters in translation
  if (params) {
    return Object.entries(params).reduce((str, [paramKey, paramValue]) => {
      return str.replace(new RegExp(`{${paramKey}}`, 'g'), paramValue)
    }, translation)
  }

  return translation
}

export function detectUserLanguage(): Language {
  if (typeof window === 'undefined') return 'en'
  
  try {
    // Check localStorage first
    const stored = localStorage.getItem('userLanguage')
    if (stored && (stored === 'en' || stored === 'fr')) {
      return stored as Language
    }

    // Detect from browser language
    const browserLang = navigator.language || navigator.languages?.[0] || 'en'
    
    if (browserLang.startsWith('fr')) {
      return 'fr'
    }
    
    return 'en'
  } catch {
    return 'en'
  }
}

export function setUserLanguage(language: Language): void {
  if (typeof window === 'undefined') return
  localStorage.setItem('userLanguage', language)
}