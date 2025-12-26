
from .titan_kernel import AuthorityLevel

# THE CONSTITUTIONAL HIERARCHY (Canonical List)

DIRECTORS = [
    {"id": "bod_str", "name": "Chief of Staff / Strategy", "role": "Director", "level": AuthorityLevel.L1_STRATEGIC, "manager_id": "mgr_cos"},
    {"id": "bod_fin", "name": "Finance & Risk Director", "role": "Director", "level": AuthorityLevel.L1_STRATEGIC, "manager_id": "mgr_fin"},
    {"id": "bod_gro", "name": "Growth & Sales Director", "role": "Director", "level": AuthorityLevel.L1_STRATEGIC, "manager_id": "mgr_gro"},
    {"id": "bod_prod", "name": "Product & Delivery Director", "role": "Director", "level": AuthorityLevel.L1_STRATEGIC, "manager_id": "mgr_ops"},
    {"id": "bod_leg", "name": "Legal & Compliance Director", "role": "Director", "level": AuthorityLevel.L1_STRATEGIC, "manager_id": "mgr_comp"},
    {"id": "bod_sec", "name": "Security & Infra Director", "role": "Director", "level": AuthorityLevel.L1_STRATEGIC, "manager_id": "mgr_sec"},
]

MANAGERS = [
    {"id": "mgr_cos", "name": "CoS_Manager", "domain": "Strategy",  "level": AuthorityLevel.L2_MANAGERIAL, "bots": ["bot_meet", "bot_brief", "bot_kpi"]},
    {"id": "mgr_fin", "name": "Finance_Manager", "domain": "Finance", "level": AuthorityLevel.L2_MANAGERIAL, "bots": ["bot_ledger", "bot_recon", "bot_price", "bot_coll"]},
    {"id": "mgr_gro", "name": "Growth_Manager", "domain": "Growth",  "level": AuthorityLevel.L2_MANAGERIAL, "bots": ["bot_lead", "bot_reach", "bot_ads", "bot_seo"]},
    {"id": "mgr_ops", "name": "OpsDelivery_Manager", "domain": "Product", "level": AuthorityLevel.L2_MANAGERIAL, "bots": ["bot_route", "bot_disp", "bot_pod", "bot_inv", "bot_supp"]},
    {"id": "mgr_comp", "name": "Compliance_Manager", "domain": "Legal",   "level": AuthorityLevel.L2_MANAGERIAL, "bots": ["bot_stat", "bot_audit", "bot_pol"]},
    {"id": "mgr_sec", "name": "InfraSec_Manager", "domain": "Security","level": AuthorityLevel.L2_MANAGERIAL, "bots": ["bot_up", "bot_patch", "bot_back", "bot_acc"]},
]

BOTS = {
    # CoS
    "bot_meet": {"name": "MeetingBot", "role": "Scheduler", "level": AuthorityLevel.L4_TASK},
    "bot_brief": {"name": "BriefingBot", "role": "Reporter", "level": AuthorityLevel.L4_TASK},
    "bot_kpi": {"name": "KPIBot", "role": "Analyst", "level": AuthorityLevel.L4_TASK},
    
    # Finance
    "bot_ledger": {"name": "LedgerBot", "role": "Bookkeeper", "level": AuthorityLevel.L3_OPERATIONAL},
    "bot_recon": {"name": "ReconciliationBot", "role": "Analyst", "level": AuthorityLevel.L4_TASK},
    "bot_price": {"name": "PricingBot", "role": "Analyst", "level": AuthorityLevel.L4_TASK},
    "bot_coll": {"name": "CollectionsBot", "role": "Agent", "level": AuthorityLevel.L3_OPERATIONAL},

    # Growth
    "bot_lead": {"name": "LeadBot", "role": "Scraper", "level": AuthorityLevel.L4_TASK},
    "bot_reach": {"name": "OutreachBot", "role": "Sender", "level": AuthorityLevel.L3_OPERATIONAL},
    "bot_ads": {"name": "AdsBot", "role": "Marketer", "level": AuthorityLevel.L3_OPERATIONAL},
    "bot_seo": {"name": "SEOContentBot", "role": "Writer", "level": AuthorityLevel.L4_TASK},

    # Ops
    "bot_route": {"name": "RoutingBot", "role": "Logistics", "level": AuthorityLevel.L4_TASK},
    "bot_disp": {"name": "DispatchBot", "role": "Logistics", "level": AuthorityLevel.L3_OPERATIONAL},
    "bot_pod": {"name": "ProofOfDeliveryBot", "role": "Logistics", "level": AuthorityLevel.L4_TASK},
    "bot_inv": {"name": "InvoiceBot", "role": "Finance", "level": AuthorityLevel.L3_OPERATIONAL},
    "bot_supp": {"name": "SupportBot", "role": "Service", "level": AuthorityLevel.L4_TASK},

    # Compliance
    "bot_stat": {"name": "StatutoryBot", "role": "Compliance", "level": AuthorityLevel.L4_TASK},
    "bot_audit": {"name": "AuditTrailBot", "role": "Compliance", "level": AuthorityLevel.L4_TASK},
    "bot_pol": {"name": "PolicyCheckBot", "role": "Compliance", "level": AuthorityLevel.L4_TASK},

    # Security
    "bot_up": {"name": "UptimeBot", "role": "Monitor", "level": AuthorityLevel.L4_TASK},
    "bot_patch": {"name": "PatchBot", "role": "DevOps", "level": AuthorityLevel.L3_OPERATIONAL},
    "bot_back": {"name": "BackupBot", "role": "DevOps", "level": AuthorityLevel.L3_OPERATIONAL},
    "bot_acc": {"name": "AccessBot", "role": "Security", "level": AuthorityLevel.L3_OPERATIONAL},
}

AUTONOMY_LOOP = [
    {"name": "LearnBot", "status": "ONLINE"},
    {"name": "EvalBot", "status": "ONLINE"},
    {"name": "HealBot", "status": "ONLINE"},
    {"name": "ImproveBot", "status": "ONLINE"},
    {"name": "PatchBot", "status": "ONLINE"},
]
