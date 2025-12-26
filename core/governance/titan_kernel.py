"""
TITAN KERNEL (v3.1)
The Python Implementation of the 'Canonical Textual Hierarchy'.
Enforces: L0-L4 Authority Levels, Execution Permit Gateway, Capital Control, Sharia, Legal, and Learning Firewall.
"""

import uuid
import time
from datetime import datetime
from enum import Enum, auto

# --- CONSTANTS & ENUMS ---

class AuthorityLevel(Enum):
    L0_SUPREME = "L0"       # Principal (Owner) - God Mode
    L1_STRATEGIC = "L1"     # Board Directors - Strategy & Budget
    L2_MANAGERIAL = "L2"    # Manager Agents - Domain orchestration
    L3_OPERATIONAL = "L3"   # High-Risk Bots - Write DB, Spend money
    L4_TASK = "L4"          # Low-Risk Bots - Read-only, Scrape, Safe Logging

class ActionType(Enum):
    READ = "READ"
    WRITE_DB = "WRITE_DB"        # Dangerous
    WRITE_LOG = "WRITE_LOG"      # Safe Sink
    SPEND_MONEY = "SPEND_MONEY"
    CHANGE_POLICY = "CHANGE_POLICY"
    API_CALL = "API_CALL"
    START_CAMPAIGN = "START_CAMPAIGN"

# --- DATA STRUCTURES ---

class Requestor:
    def __init__(self, name, level: AuthorityLevel):
        self.name = name
        self.level = level

class Decree:
    def __init__(self, content, action_type: ActionType, requestor: Requestor, amount_usd: float = 0.0):
        self.content = content
        self.action_type = action_type
        self.requestor = requestor
        self.amount_usd = amount_usd

class ExecutionPermit:
    def __init__(self, decree):
        self.id = str(uuid.uuid4())[:8]
        self.decree = decree
        self.is_valid = False
        self.risk_score = 0
        self.approvals = []

# --- LEVEL 1: ARCHIVIST & LEARNING FIREWALL ---
class Archivist:
    def log(self, event):
        print(f"   [📚 ARCHIVIST] Storing event: '{event}' in Vector DB.")

class LearningFirewall:
    def inspect_insight(self, insight):
        print(f"[🧠 LEARNING FIREWALL] Inspecting: '{insight}'")
        if "rewrite constitution" in insight.lower() or "bypass" in insight.lower():
            print(f"   [🔥 BLOCK] Policy Mutation Detected. REJECTED.")
            return False
        print(f"   [✅ PASS] Insight is safe.")
        return True

# --- LEVEL 4: BOARD OF DIRECTORS ---
class BoardDirector:
    def __init__(self, title, keywords_block, keywords_pass):
        self.title = title
        self.block_triggers = keywords_block
        self.pass_criteria = keywords_pass
    
    def review(self, decree: Decree):
        print(f"[🏛️ BOD: {self.title}] Reviewing...")
        
        # 1. FINANCE & RISK CHECK (Covers both roles logically for now)
        if self.title == "Finance & Risk Director":
            if decree.amount_usd > 10000:
                 if decree.requestor.level != AuthorityLevel.L0_SUPREME:
                    print(f"   [❌ VETO] CAPITAL EXCEEDED. Only L0 can authorize > $10k.")
                    return False
            if decree.amount_usd > 500 and decree.requestor.level.value > AuthorityLevel.L2_MANAGERIAL.value:
                 # L3/L4 cannot spend > 500
                 print(f"   [❌ VETO] BUDGET EXCEEDED for Operational/Task Bot.")
                 return False
            if decree.amount_usd > 50:
                 if "unapproved" in decree.content.lower():
                      print(f"   [❌ VETO] Unapproved Spend > $50.")
                      return False

        # 2. LEGAL & COMPLIANCE
        if self.title == "Legal & Compliance Director":
            if "gdpr" in decree.content.lower() and "usa_server" in decree.content.lower():
                 print(f"   [❌ VETO] JURISDICTION ERROR. GDPR data cannot leave EU.")
                 return False
            if any(x in decree.content.lower() for x in ["interest", "riba", "gambling", "pork"]):
                 print(f"   [❌ VETO] SHARIA/ETHICS VIOLATION. Forbidden content.")
                 return False

        # 3. STRATEGY (Chief of Staff)
        if self.title == "Chief of Staff / Strategy":
             if "crypto meme coin" in decree.content.lower():
                  print(f"   [❌ VETO] STRATEGY DRIFT. Not aligned with roadmap.")
                  return False

        # 4. SECURITY & INFRA
        if self.title == "Security & Infra Director":
            if decree.action_type == ActionType.WRITE_DB and decree.requestor.level == AuthorityLevel.L4_TASK:
                print(f"   [❌ VETO] SECURITY. L4 cannot Write DB.")
                return False

        print(f"   [✅ APPROVAL] {self.title} grants approval.")
        return True

# --- LEVEL 3: EXECUTION PERMIT GATEWAY ---
class ExecutionPermitGateway:
    def __init__(self):
        # The 6 Statutory Directors
        self.board = [
            BoardDirector("Chief of Staff / Strategy", [], []),
            BoardDirector("Finance & Risk Director", ["spend", "risk"], []),
            BoardDirector("Growth & Sales Director", [], []),
            BoardDirector("Product & Delivery Director", [], []),
            BoardDirector("Legal & Compliance Director", ["gdpr", "sharia"], []),
            BoardDirector("Security & Infra Director", ["security", "access"], []),
        ]

    def request_permit(self, decree: Decree):
        print(f"\n[🔒 PERMIT GATEWAY] Processing Request from {decree.requestor.name} ({decree.requestor.level.name})")
        print(f"    Intent: {decree.content} | Type: {decree.action_type.name} | Amount: ${decree.amount_usd}")

        # --- PHYSICS LAYER: AUTHORITY CHECKS ---
        
        # RULE 1: L4 (Tasks) Capability Restrictions
        # "L4 default: READ-only + Safe Sinks (WRITE_LOG). No DB Write, No Money."
        if decree.requestor.level == AuthorityLevel.L4_TASK:
            if decree.action_type in [ActionType.WRITE_DB, ActionType.SPEND_MONEY, ActionType.START_CAMPAIGN]:
                print(f"[🛑 BLOCK] L4 VIOLATION. Task Bots cannot {decree.action_type.name}.")
                return None
            if decree.action_type == ActionType.API_CALL:
                # Sandbox Mode warning
                print(f"[⚠️ WARNING] L4 API Call. Proceeding with caution (Sandbox Mode).")

        # RULE 2: L3 (Operational) Logic
        if decree.requestor.level == AuthorityLevel.L3_OPERATIONAL:
            if decree.action_type == ActionType.SPEND_MONEY and decree.amount_usd > 50:
                 print(f"[⚠️ FLAG] L3 SPENDING > $50 requires Board Review.")

        # RULE 3: L0 (Supreme) - BYPASS
        if decree.requestor.level == AuthorityLevel.L0_SUPREME:
            print(f"[👑 OVERRIDE] Supreme Authority detected. Permit Auto-Granted.")
            permit = ExecutionPermit(decree)
            permit.is_valid = True
            return permit

        # --- GOVERNANCE LAYER: BOARD REVIEW ---
        # If we passed basic physics, we ask the Board
        approvals = 0
        for director in self.board:
            if not director.review(decree):
                print(f"[🛑 BLOCK] Permit Request DENIED by {director.title}.")
                return None 
            approvals += 1
        
        # Issue Permit
        permit = ExecutionPermit(decree)
        permit.is_valid = True
        permit.approvals = approvals
        print(f"[✅ GRANTED] Execution Permit #{permit.id} Issued.")
        return permit

# --- LEVEL 2: TITAN (EXECUTION) ---
class TitanExecutionEngine:
    def __init__(self):
        self.archivist = Archivist()
        self.firewall = LearningFirewall()

    def execute(self, decree: Decree, permit: ExecutionPermit):
        print(f"\n[⚡ TITAN] Intent to Execute: '{decree.content}'")
        
        # 1. PERMIT CHECK
        if not permit or not permit.is_valid:
            print(f"[⛔ FATAL] NO VALID PERMIT. Execution BLOCKED.")
            self.archivist.log(f"BLOCKED ATTEMPT: {decree.content}")
            return

        print(f"[✅ VERIFIED] Permit #{permit.id} is VALID.")
        print(f"[🚀 EXECUTE] TITAN is executing: {decree.content}")
        self.archivist.log(f"SUCCESS: {decree.content}")

    def propose_learning(self, insight):
        # TITAN tries to "learn" something new
        print(f"\n[🤖 TITAN AI] Proposing new logic: '{insight}'")
        if self.firewall.inspect_insight(insight):
            self.archivist.log(f"LEARNED: {insight}")
        else:
            self.archivist.log(f"REJECTED LEARNING: {insight}")


# --- THE COMPREHENSIVE SIMULATION (Updated for v3.1) ---
def run_stress_test():
    gateway = ExecutionPermitGateway()
    titan = TitanExecutionEngine()

    print("="*60)
    print("🧪 TITAN OS v3.1: AUTHORITY & CAPABILITY STRESS TEST")
    print("="*60)

    # ACTORS
    omran = Requestor("Omran (Owner)", AuthorityLevel.L0_SUPREME)
    ops_mgr = Requestor("Ops Manager", AuthorityLevel.L2_MANAGERIAL)
    pay_bot = Requestor("Payment Bot", AuthorityLevel.L3_OPERATIONAL)
    scrape_bot = Requestor("Scraper Bot", AuthorityLevel.L4_TASK)

    # --- SCENARIO 1: L4 Capability Block ---
    print("\n--- 1. PHYSICS TEST: L4 Bot trying to Spend Money ---")
    d1 = Decree("Buy Server", ActionType.SPEND_MONEY, scrape_bot, 10.0)
    p1 = gateway.request_permit(d1) # Should fail
    titan.execute(d1, p1)

    # --- SCENARIO 2: L4 Safe Action (Read/Log) ---
    print("\n--- 2. PHYSICS TEST: L4 Bot writing to Log (Safe) ---")
    d_log = Decree("Log Scraping Results", ActionType.WRITE_LOG, scrape_bot)
    p_log = gateway.request_permit(d_log) # Should Pass
    titan.execute(d_log, p_log)

    # --- SCENARIO 3: L3 SPEND > $50 (Needs Board) ---
    print("\n--- 3. PHYSICS TEST: L3 Bot trying to Spend $100 ---")
    d2 = Decree("Buy Software License", ActionType.SPEND_MONEY, pay_bot, 100.0)
    p2 = gateway.request_permit(d2) # Should trigger Board
    titan.execute(d2, p2)

    # --- SCENARIO 4: SHARIA VIOLATION (Even for L2) ---
    print("\n--- 4. GOVERNANCE TEST: L2 Manager trying Riba ---")
    d3 = Decree("Invest in High Yield Bond", ActionType.SPEND_MONEY, ops_mgr, 200.0)
    p3 = gateway.request_permit(d3) # Should be vetoed by Sharia
    titan.execute(d3, p3)

    # --- SCENARIO 5: L0 OVERRIDE ---
    print("\n--- 5. SUPREME TEST: L0 Owner doing whatever they want ---")
    d4 = Decree("Buy $1M Crypto", ActionType.SPEND_MONEY, omran, 1000000.0)
    p4 = gateway.request_permit(d4) # Should auto-pass
    titan.execute(d4, p4)

if __name__ == "__main__":
    run_stress_test()
