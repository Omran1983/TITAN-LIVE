# TITAN AI CODE POLICY (GUARDRAILS)

> **Status**: ACTIVE
> **Enforced By**: `titan_guardrail.py`

## The Reality
AI-generated code is a **force multiplier** but introduces **1.7x more defects**, reduces refactoring, and can introduce subtle security flaws. TITAN treats AI as a "Junior Developer on Speed" — fast, but requires strict supervision.

## The 6 Golden Guardrails

### 1. Small Unit Rule (<300 Lines)
*   **Rule**: No single file should exceed 300 lines of logic (excluding data/config).
*   **Why**: AI loses context in large files. Humans cannot review them effectively.
*   **Enforcement**: Guardrail script warns on large files.

### 2. Test-First Mandate
*   **Rule**: Every Block must have a corresponding `tests/` folder or `test_*.py` script.
*   **Why**: "It runs" != "It is correct".
*   **Enforcement**: Guardrail fails if no tests found for a Block.

### 3. Security Scan Gate (SAST)
*   **Rule**: All code must pass a Static Application Security Testing (SAST) scan.
*   **Why**: AI often hallucinates insecure patterns (e.g., hardcoded paths, `shell=True`, weak hashes).
*   **Enforcement**: `bandit` scan required.

### 4. Refactor Quota
*   **Rule**: 20% of effort should be cleaning/refactoring, not just appending.
*   **Measure**: Qualitative for now; enforced via Review.

### 5. Style & Naming Lock
*   **Rule**: Code must follow PEP8 and standardized directory structures.
*   **Why**: AI drifts into random naming styles.
*   **Enforcement**: `ruff` linter.

### 6. Business Context Checklist
*   **Rule**: Code must handle:
    *   Edge cases (Empty inputs)
    *   Timezones (UTC default)
    *   Currencies (Decimal, not Float)

---

## Operational Workflow

Before deploying or finalizing a Block:

1.  **Run Guardrail**: `python core/quality/titan_guardrail.py --target blocks/<block_name>`
2.  **Green Light**: Only proceed if Guardrail returns `PASS`.

**Signed**: Atlas (Director of Automation)
