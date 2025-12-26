-- =========================================================
-- AION-ZERO EXTERNAL SOURCES (az_graph_sources)
-- Tracks external repos/docs for ingestion.
-- =========================================================

create table if not exists public.az_graph_sources (
  id          uuid primary key default gen_random_uuid(),
  url         text not null unique,           -- git url or doc url
  type        text not null,                  -- 'github', 'doc_url', 'rss'
  project     text not null default 'global', -- 'AION-ZERO', 'reachx', or 'global'
  trust_level text not null default 'untrusted', -- 'untrusted', 'scanning', 'trusted', 'blocked'
  category    text,                           -- 'research', 'repo', 'market_intel', 'personal'
  last_scanned timestamptz,
  meta        jsonb default '{}'::jsonb,      -- { "branch": "main", "files_found": 100 }
  created_at  timestamptz default now()
);

-- Seed Initial Intelligence Sources (from Unified Inventory & AI Research)
insert into az_graph_sources (url, type, category, trust_level) values 
-- A. Research & Frameworks
('https://github.com/microsoft/graphrag', 'github', 'research', 'trusted'),
('https://arxiv.org/abs/2305.15334', 'doc_url', 'research', 'trusted'), -- Gorilla pattern
('https://github.com/google/adk-docs', 'github', 'framework', 'trusted'), -- Google ADK
('https://machinelearningmastery.com/top-5-agentic-ai-llm-models', 'doc_url', 'research', 'trusted'),
('https://github.com/modelcontextprotocol/servers', 'github', 'technical_tooling', 'trusted'), -- MCP

-- B. Technical Specs (My Additions)
('https://github.com/PowerShell/PowerShell', 'github', 'technical_docs', 'trusted'),
('https://docs.python.org/3/library', 'doc_url', 'technical_docs', 'trusted'),
('https://supabase.com/docs', 'doc_url', 'technical_docs', 'trusted'),
('https://github.com/vercel/next.js', 'github', 'technical_docs', 'trusted'),

-- C. Strategic Wisdom
('https://www.gutenberg.org/files/132/132-h/132-h.htm', 'doc_url', 'strategy_classic', 'trusted'), -- Art of War (Giles)
('https://en.wikipedia.org/wiki/The_Toyota_Way', 'doc_url', 'strategy_classic', 'trusted'), -- Toyota Way Summary

-- D. Agent Ecosystem
('https://github.com/langchain-ai/langgraph', 'github', 'framework', 'trusted'),
('https://github.com/joaomdmoura/crewAI', 'github', 'framework', 'trusted'),
('https://github.com/microsoft/autogen', 'github', 'framework', 'trusted'),
('https://github.com/Significant-Gravitas/Auto-GPT', 'github', 'framework', 'trusted'),

-- E. Security & Hacking (Red/White/Black Hat Knowledge)
('https://owasp.org/Top10/', 'doc_url', 'security_redteam', 'trusted'),
('http://pentest-standard.org/', 'doc_url', 'security_redteam', 'trusted'),
('https://www.kali.org/docs/', 'doc_url', 'security_redteam', 'trusted'),
('https://cheatsheetseries.owasp.org/', 'doc_url', 'security_blueteam', 'trusted'),

-- F. Innovation & Future Trends
('http://theleanstartup.com/principles', 'doc_url', 'innovation_strategy', 'trusted'),
('https://www.technologyreview.com/feed', 'rss', 'future_tech', 'trusted'),
('https://singularityhub.com/feed/', 'rss', 'future_tech', 'trusted'),
('https://www.kaizen.com/what-is-kaizen', 'doc_url', 'innovation_strategy', 'trusted'),

-- G. Sales, Marketing & Negotiation
('https://farnamstreet.com/influence-summary/', 'doc_url', 'marketing_psychology', 'trusted'), -- Cialdini/Psych
('https://readingraphics.com/book-summary-100m-offers/', 'doc_url', 'marketing_strategy', 'trusted'), -- Hormozi Offers
('https://www.pon.harvard.edu/feed/', 'rss', 'negotiation', 'trusted'),          -- Harvard Negotiation

-- H. Law, Arbitration & Global Finance
('https://attorneygeneral.govmu.org/Pages/Laws%20of%20Mauritius/Laws-of-Mauritius.aspx', 'doc_url', 'law_mauritius', 'trusted'),
('https://uncitral.un.org/sites/uncitral.un.org/files/media-documents/uncitral/en/19-09955_e_ebook.pdf', 'doc_url', 'law_arbitration', 'trusted'), -- UNCITRAL Rules
('https://www.fatf-gafi.org/en/publications/Fatfrecommendations/Fatf-recommendations.html', 'doc_url', 'finance_aml', 'trusted'),             -- Anti-Money Laundering
('https://www.acfe.com/-/media/files/acfe/pdfs/rttn/2024/2024-report-to-the-nations.pdf', 'doc_url', 'finance_fraud', 'trusted')                -- Fraud Monitoring

on conflict (url) do nothing;
