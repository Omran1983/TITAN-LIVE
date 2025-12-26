# AION Omni-Store: The Unified Showcase & E-Commerce Platform

**Status**: 🅿️ PARKED (Planned for Future Execution)

## 📌 Objective
Create a single, cohesive E-Commerce platform to showcase, sell, and deploy all AION-ZERO projects (engines, agents, automation packs).
This replaces the simple "Showcase UI" with a transactional, customer-facing storefront.

## 🛍️ Features Checklist

### 1. Product Page Template ("The Pitch")
Each project (e.g., Grant Architect, Sentinel, Risk Analyzer) gets a dedicated landing page containing:
-   **The Hook**: High-level value proposition.
-   **ELI5 Walkthrough**: "Explain Like I'm 5" breakdown of how it works.
-   **Full Technical Details**: Stack, Inputs, Outputs, Architecture.
-   **Interactive Demo/Walkthrough**: screenshots or video of the tool in action.
-   **"Expected Outcomes"**: Concrete deliverables (e.g., "A 40-page Grant Proposal in 20 mins").

### 2. Pricing & Commercials
-   **Pricing Tiers**:
    -   *Starter* (Source Code / One-off)
    -   *Professional* (Managed / Support)
    -   *Enterprise* (Custom Integration / SLA)
-   **Purchase Flow**: Integration with Stripe/LemonSqueezy? (TBD).
-   **License Management**: Token generation for deployed agents.

### 3. "Assisted Purchase" Logic
-   **Needs Assessment**: "Not sure what you need? Tell us your problem." (AI Assistant).
-   **Bundles**: "The NGO Compliance Pack" (Sentinel + Automator).

## 🏗️ Technical Architecture (Proposed)
-   **Framework**: Next.js (React) for dynamic, fast e-commerce UI.
-   **Data Source**: `titan.json` files in each project directory will serve as the "Product Database" (Single Source of Truth).
    -   We will enhance `titan.json` to include `price`, `tagline`, `eli5` fields.
-   **Design System**: Glassmorphism (evolved from Showcase UI) + "Premium SaaS" aesthetic.

## 🔜 Next Steps (When Unparked)
1.  [ ] Enhance `titan.json` schema with `commerce` details.
2.  [ ] Scaffold `projects/omni-store` (Next.js).
3.  [ ] Design the "Master Product Page" template.
