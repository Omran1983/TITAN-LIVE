-- TITAN DECISION ATOMS FRAMEWORK
-- "Power comes from owning the futures you didn't choose."

-- 1. THE ATOM (The Core Decision Unit)
CREATE TABLE az_decision_atoms (
    atom_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    
    -- Context
    situation_snapshot JSONB NOT NULL DEFAULT '{}', -- What we knew
    unknowns_explicit JSONB NOT NULL DEFAULT '[]', -- What we knew we didn't know
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    decided_at TIMESTAMP WITH TIME ZONE,
    status TEXT CHECK (status IN ('draft', 'active', 'committed', 'archived')),
    
    -- Authority
    owner_agent TEXT,
    human_in_loop BOOLEAN DEFAULT FALSE,
    
    -- Regret Minimization
    regret_analysis TEXT, -- Fill only after outcome known
    scar_derived_id UUID -- Link to a specific structural scar if one was born here
);

-- 2. OPTIONS (The Counterfactuals)
CREATE TABLE az_decision_atom_options (
    option_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    atom_id UUID REFERENCES az_decision_atoms(atom_id),
    
    title TEXT NOT NULL,
    description TEXT,
    
    -- Simulation
    predicted_outcome JSONB,
    confidence_score FLOAT CHECK (confidence_score BETWEEN 0 AND 1),
    risk_profile JSONB, -- { "volatility": "high", "irreversibility": "true" }
    
    -- Selection
    is_chosen BOOLEAN DEFAULT FALSE,
    rejection_reason TEXT -- Why this futures was killed
);

-- 3. SIGNALS (Inputs)
CREATE TABLE az_decision_atom_signals (
    signal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    atom_id UUID REFERENCES az_decision_atoms(atom_id),
    
    source TEXT NOT NULL, -- e.g., "market_data", "policy_news"
    value JSONB NOT NULL,
    captured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. CONSTRAINTS (The Guardrails)
CREATE TABLE az_decision_atom_constraints (
    constraint_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    atom_id UUID REFERENCES az_decision_atoms(atom_id),
    
    rule_description TEXT NOT NULL,
    is_hard_block BOOLEAN DEFAULT TRUE,
    override_authorized_by TEXT
);

-- 5. OUTCOMES (The Reality)
CREATE TABLE az_decision_atom_outcomes (
    outcome_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    atom_id UUID REFERENCES az_decision_atoms(atom_id),
    
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actual_data JSONB NOT NULL,
    
    variance_from_prediction TEXT, -- "Better", "Worse", "Different"
    learnings TEXT
);

-- 6. SCARS (The Learned Rules)
CREATE TABLE az_structural_scars (
    scar_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_atom_id UUID REFERENCES az_decision_atoms(atom_id),
    
    rule_logic TEXT NOT NULL, -- Executable logic
    enforcement_level TEXT CHECK (enforcement_level IN ('block', 'warn', 'override_required')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
