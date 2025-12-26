'use client'

import { useState, useEffect } from 'react'
import { I18nContext, Language, translate, detectUserLanguage, setUserLanguage } from '@/lib/i18n'

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [language, setLanguage] = useState<Language>('en')
  const [isLoaded, setIsLoaded] = useState(false)

  useEffect(() => {
    const detected = detectUserLanguage()
    setLanguage(detected)
    setIsLoaded(true)
  }, [])

  const changeLanguage = (lang: Language) => {
    setLanguage(lang)
    setUserLanguage(lang)
    
    // Update HTML lang attribute for accessibility
    if (typeof document !== 'undefined') {
      document.documentElement.lang = lang
    }
  }

  const t = (key: string, params?: Record<string, string>) => {
    return translate(language, key, params)
  }

  // Don't render until language is detected to prevent hydration mismatches
  if (!isLoaded) {
    return null
  }

  return (
    <I18nContext.Provider value={{ language, setLanguage: changeLanguage, t }}>
      {children}
    </I18nContext.Provider>
  )
}