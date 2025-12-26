// reachx-employer-view.js

// TODO: replace with real env or let your PS env patcher inject these.
const SUPABASE_URL = "https://YOUR_PROJECT.supabase.co";
const SUPABASE_ANON_KEY = "YOUR_PUBLIC_ANON_KEY";

// Tables (adjust if needed)
const EMPLOYERS_TABLE = "reachx_employers";
const DORM_TABLE = "reachx_dormitories";
const WORKERS_TABLE = "reachx_workers";
const COMMS_TABLE = "reachx_communications";
const COMMERCIAL_TABLE = "reachx_projects";

let supabaseClient = null;

let state = {
    employers: [],
    dorms: [],
    workers: [],
    comms: [],
    commercial: [],
    shortlist: {}, // employer_id -> [workerIds]
    selectedEmployerId: null,
    currency: "MUR"
};

document.addEventListener("DOMContentLoaded", async () => {
    supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    attachUIHandlers();
    await loadAllData();
    renderFiltersFromEmployers();
    renderEmployerList();
    updateHeaderStats();
});

function attachUIHandlers() {
    const currencySelect = document.getElementById("rx-currency-select");
    if (currencySelect) {
        currencySelect.addEventListener("change", (e) => {
            state.currency = e.target.value;
            renderEmployerList();
            renderSelectedEmployer();
        });
    }

    const headMin = document.getElementById("rx-headcount-min");
    const headMax = document.getElementById("rx-headcount-max");
    const headLabel = document.getElementById("rx-headcount-label");
    function updateHeadLabel() {
        if (!headMin || !headMax || !headLabel) return;
        const min = Math.min(parseInt(headMin.value, 10), parseInt(headMax.value, 10));
        const max = Math.max(parseInt(headMin.value, 10), parseInt(headMax.value, 10));
        headLabel.textContent = `${min} – ${max === 500 ? "500+" : max}`;
        renderEmployerList();
        renderSelectedEmployer();
    }
    if (headMin && headMax) {
        headMin.addEventListener("input", updateHeadLabel);
        headMax.addEventListener("input", updateHeadLabel);
        updateHeadLabel();
    }

    const filterEmployer = document.getElementById("rx-filter-employer");
    if (filterEmployer) {
        filterEmployer.addEventListener("change", () => {
            renderEmployerList();
        });
    }

    document.querySelectorAll(".rx-filter-recruiter-type").forEach(el => {
        el.addEventListener("change", renderEmployerList);
    });
    document.querySelectorAll(".rx-filter-sector").forEach(el => {
        el.addEventListener("change", renderEmployerList);
    });
    document.querySelectorAll(".rx-filter-demand-status").forEach(el => {
        el.addEventListener("change", renderEmployerList);
    });
    document.getElementById("rx-filter-location")?.addEventListener("change", renderEmployerList);

    document.querySelectorAll(".rx-filter-origin").forEach(el => {
        el.addEventListener("change", () => {
            renderSelectedEmployer();
        });
    });
    document.querySelectorAll(".rx-filter-cand-status").forEach(el => {
        el.addEventListener("change", () => {
            renderSelectedEmployer();
        });
    });

    document.querySelectorAll(".rx-tab").forEach(tab => {
        tab.addEventListener("click", () => {
            switchTab(tab.dataset.tab);
        });
    });

    document.getElementById("rx-add-comm-btn")?.addEventListener("click", () => {
        alert("In v1, add communication is not wired. Store via Supabase COMMS_TABLE later.");
    });

    document.getElementById("rx-export-btn")?.addEventListener("click", () => {
        alert("In v1, export snapshot will copy a summary to clipboard. Implement file export later.");
        copySummaryToClipboard();
    });

    document.getElementById("rx-export-proposal-btn")?.addEventListener("click", () => {
        alert("In v1, proposal snapshot will copy shortlist summary to clipboard. Implement PDF later.");
        copyShortlistSummaryToClipboard();
    });

    document.getElementById("rx-create-assignment-btn")?.addEventListener("click", () => {
        alert("Create Assignment stub — later hook into Supabase assignments table.");
    });
}

async function loadAllData() {
    try {
        const [{ data: employers }, { data: dorms }, { data: workers }, { data: comms }, { data: projects }] =
            await Promise.all([
                supabaseClient.from(EMPLOYERS_TABLE).select("*").eq("country", "Mauritius"),
                supabaseClient.from(DORM_TABLE).select("*"),
                supabaseClient.from(WORKERS_TABLE).select("*").in("origin_country", [
                    "India", "Nepal", "Sri Lanka", "Bangladesh", "Kenya", "Ethiopia", "Mozambique"
                ]),
                supabaseClient.from(COMMS_TABLE).select("*"),
                supabaseClient.from(COMMERCIAL_TABLE).select("*")
            ]);

        state.employers = employers || [];
        state.dorms = dorms || [];
        state.workers = workers || [];
        state.comms = comms || [];
        state.commercial = projects || [];
    } catch (err) {
        console.error("Error loading data:", err);
    }
}

function renderFiltersFromEmployers() {
    const empSelect = document.getElementById("rx-filter-employer");
    if (!empSelect) return;

    // Clear existing (keep "All clients")
    while (empSelect.options.length > 1) {
        empSelect.remove(1);
    }
    state.employers.forEach(emp => {
        const opt = document.createElement("option");
        opt.value = emp.id;
        opt.textContent = emp.name || `Employer #${emp.id}`;
        empSelect.appendChild(opt);
    });
}

function getSelectedRecruiterTypes() {
    const vals = [];
    document.querySelectorAll(".rx-filter-recruiter-type:checked").forEach(el => vals.push(el.value));
    return vals;
}

function getSelectedSectors() {
    const vals = [];
    document.querySelectorAll(".rx-filter-sector:checked").forEach(el => vals.push(el.value));
    return vals;
}

function getSelectedDemandStatuses() {
    const vals = [];
    document.querySelectorAll(".rx-filter-demand-status:checked").forEach(el => vals.push(el.value));
    return vals;
}

function getHeadcountRange() {
    const minEl = document.getElementById("rx-headcount-min");
    const maxEl = document.getElementById("rx-headcount-max");
    if (!minEl || !maxEl) return { min: 1, max: 500 };
    const min = Math.min(parseInt(minEl.value, 10), parseInt(maxEl.value, 10));
    const max = Math.max(parseInt(minEl.value, 10), parseInt(maxEl.value, 10));
    return { min, max };
}

function renderEmployerList() {
    const container = document.getElementById("rx-employer-list");
    if (!container) return;
    container.innerHTML = "";

    const filterEmployer = document.getElementById("rx-filter-employer");
    const selectedEmployerValue = filterEmployer ? filterEmployer.value : "";
    const recruiterTypes = getSelectedRecruiterTypes();
    const sectors = getSelectedSectors();
    const demandStatuses = getSelectedDemandStatuses();
    const locationFilter = document.getElementById("rx-filter-location")?.value || "";
    const { min: headMin, max: headMax } = getHeadcountRange();

    const employers = state.employers.filter(emp => {
        if (selectedEmployerValue && String(emp.id) !== selectedEmployerValue) return false;
        if (recruiterTypes.length && emp.recruiter_type && !recruiterTypes.includes(emp.recruiter_type)) return false;
        if (sectors.length && emp.sector && !sectors.includes(emp.sector)) return false;
        if (demandStatuses.length && emp.demand_status && !demandStatuses.includes(emp.demand_status)) return false;
        if (locationFilter && emp.city && emp.city !== locationFilter && locationFilter !== "Other") return false;
        if (locationFilter === "Other" && ["Port Louis","Grand Baie","Flic-en-Flac","Ebène","Quatre Bornes","Curepipe"].includes(emp.city)) return false;

        const headcount = emp.headcount_required || emp.total_required || 0;
        if (headcount < headMin || headcount > headMax) return false;

        return true;
    });

    employers.forEach(emp => {
        const card = document.createElement("div");
        card.className = "rx-employer-card";

        const left = document.createElement("div");
        left.className = "rx-employer-card-header";

        const name = document.createElement("div");
        name.className = "rx-employer-card-name";
        name.textContent = emp.name || "Unknown Employer";

        const meta = document.createElement("div");
        meta.className = "rx-employer-card-meta";

        const cityTag = document.createElement("span");
        cityTag.className = "rx-tag";
        cityTag.textContent = emp.city || "Mauritius";

        const sectorTag = document.createElement("span");
        sectorTag.className = "rx-tag";
        sectorTag.textContent = emp.sector || "N/A";

        const demandStatusTag = document.createElement("span");
        demandStatusTag.className = "rx-tag";
        if (emp.demand_status === "active") {
            demandStatusTag.classList.add("rx-tag-hot");
            demandStatusTag.textContent = "Active demand";
        } else if (emp.demand_status === "monitoring") {
            demandStatusTag.classList.add("rx-tag-warm");
            demandStatusTag.textContent = "Monitoring only";
        } else if (emp.demand_status === "closed") {
            demandStatusTag.textContent = "Closed";
        } else if (emp.demand_status === "cancelled") {
            demandStatusTag.textContent = "Cancelled";
        } else {
            demandStatusTag.textContent = "Status unknown";
        }

        meta.appendChild(cityTag);
        meta.appendChild(sectorTag);
        meta.appendChild(demandStatusTag);

        left.appendChild(name);
        left.appendChild(meta);

        const demandInfo = document.createElement("div");
        demandInfo.className = "rx-employer-card-demand";
        const total = emp.headcount_required || emp.total_required || 0;
        const summary = emp.demand_summary || "";
        demandInfo.textContent = `${total || "0"} roles – ${summary || "No summary"}`;

        left.appendChild(demandInfo);

        const right = document.createElement("div");
        right.className = "rx-employer-card-footer";

        const dormInfo = document.createElement("div");
        const dorm = state.dorms.find(d => d.employer_id === emp.id);
        if (dorm) {
            const free = (dorm.capacity || 0) - (dorm.occupied || 0);
            dormInfo.textContent = `Dormitory: ${dorm.capacity || 0} beds | ${free} free`;
        } else {
            dormInfo.textContent = "Dormitory: N/A";
        }

        const valueInfo = document.createElement("div");
        const projectValue = emp.project_value || 0;
        valueInfo.textContent = formatCurrency(projectValue, state.currency);

        right.appendChild(dormInfo);
        right.appendChild(valueInfo);

        card.appendChild(left);
        card.appendChild(right);

        card.addEventListener("click", () => {
            state.selectedEmployerId = emp.id;
            renderSelectedEmployer();
        });

        container.appendChild(card);
    });

    if (employers.length === 0) {
        const empty = document.createElement("div");
        empty.className = "rx-empty-state";
        empty.innerHTML = "<h2>No employers match the filters</h2><p>Adjust filters on the left to view more opportunities.</p>";
        container.appendChild(empty);
    }
}

function renderSelectedEmployer() {
    const employerId = state.selectedEmployerId;
    const panel = document.getElementById("rx-employer-panel");
    const empty = document.getElementById("rx-empty-state");
    if (!employerId) {
        if (panel) panel.classList.add("rx-hidden");
        if (empty) empty.classList.remove("rx-hidden");
        return;
    }
    if (panel) panel.classList.remove("rx-hidden");
    if (empty) empty.classList.add("rx-hidden");

    const emp = state.employers.find(e => e.id === employerId);
    if (!emp) return;

    document.getElementById("rx-employer-name").textContent = emp.name || "Employer";
    document.getElementById("rx-employer-location").textContent = emp.city || "Mauritius";
    document.getElementById("rx-employer-sector").textContent = emp.sector || "N/A";

    const demandSummary = emp.demand_summary || "";
    const total = emp.headcount_required || emp.total_required || 0;
    document.getElementById("rx-employer-demand-summary").textContent =
        `${total || 0} roles – ${demandSummary || "No summary"}`;

    document.getElementById("rx-employer-contact-name").textContent =
        emp.contact_name || "Contact: –";
    document.getElementById("rx-employer-contact-phone").textContent =
        emp.contact_phone ? `Phone: ${emp.contact_phone}` : "";
    document.getElementById("rx-employer-contact-email").textContent =
        emp.contact_email ? `Email: ${emp.contact_email}` : "";

    renderMatchesTab(emp);
    renderCommsTab(emp);
    renderCommercialTab(emp);
    renderShortlistTab(emp);
}

function getSelectedOrigins() {
    const vals = [];
    document.querySelectorAll(".rx-filter-origin:checked").forEach(el => vals.push(el.value));
    return vals;
}

function getSelectedCandidateStatuses() {
    const vals = [];
    document.querySelectorAll(".rx-filter-cand-status:checked").forEach(el => vals.push(el.value));
    return vals;
}

function renderMatchesTab(emp) {
    const list = document.getElementById("rx-candidate-list");
    const matchCount = document.getElementById("rx-match-count");
    if (!list || !matchCount) return;

    list.innerHTML = "";

    const origins = getSelectedOrigins();
    const statusFilters = getSelectedCandidateStatuses();

    const requestedRoles = (emp.requested_roles || "").toLowerCase();

    const matches = state.workers.filter(w => {
        if (w.employer_id && w.employer_id !== emp.id) {
            // Only show unassigned or for this employer
            return false;
        }
        if (origins.length && w.origin_country && !origins.includes(w.origin_country)) return false;
        if (statusFilters.length && w.deployment_status && !statusFilters.includes(w.deployment_status)) return false;

        if (requestedRoles && w.role) {
            const roleLower = String(w.role).toLowerCase();
            if (!requestedRoles.includes(roleLower)) {
                // Soft filter – but for now, allow all; we can tighten later
            }
        }
        return true;
    });

    matchCount.textContent = `Matches: ${matches.length}`;

    matches.forEach(w => {
        const card = document.createElement("div");
        card.className = "rx-candidate-card";

        const main = document.createElement("div");
        main.className = "rx-candidate-main";

        const name = document.createElement("div");
        name.className = "rx-candidate-name";
        const originFlag = flagForCountry(w.origin_country);
        name.textContent = `${w.full_name || "Unnamed"} ${originFlag ? originFlag : ""}`;

        const meta = document.createElement("div");
        meta.className = "rx-candidate-meta";
        meta.textContent = `${w.role || "Role N/A"} • ${w.years_experience || 0} yrs exp • ${w.origin_country || "N/A"}`;

        const tags = document.createElement("div");
        tags.className = "rx-candidate-tags";

        const statusTag = document.createElement("span");
        statusTag.className = "rx-tag";
        statusTag.textContent = formatDeploymentStatus(w.deployment_status);
        tags.appendChild(statusTag);

        const readinessTag = document.createElement("span");
        readinessTag.className = "rx-tag";
        readinessTag.textContent = w.readiness || "Readiness N/A";
        tags.appendChild(readinessTag);

        main.appendChild(name);
        main.appendChild(meta);
        main.appendChild(tags);

        const docs = document.createElement("div");
        docs.className = "rx-candidate-docs";
        docs.textContent = buildDocsSummary(w);

        const actions = document.createElement("div");
        const btn = document.createElement("button");
        btn.className = "rx-button rx-shortlist-btn";
        btn.textContent = "+ Shortlist";
        btn.addEventListener("click", () => {
            addToShortlist(emp.id, w);
        });
        actions.appendChild(btn);

        card.appendChild(main);
        card.appendChild(docs);
        card.appendChild(actions);

        list.appendChild(card);
    });

    if (matches.length === 0) {
        const empty = document.createElement("div");
        empty.className = "rx-empty-state";
        empty.innerHTML = "<h2>No candidates match filters</h2><p>Relax origin/status filters to see more candidates.</p>";
        list.appendChild(empty);
    }
}

function flagForCountry(country) {
    switch (country) {
        case "India": return "🇮🇳";
        case "Nepal": return "🇳🇵";
        case "Sri Lanka": return "🇱🇰";
        case "Bangladesh": return "🇧🇩";
        case "Kenya": return "🇰🇪";
        case "Ethiopia": return "🇪🇹";
        case "Mozambique": return "🇲🇿";
        default: return "";
    }
}

function formatDeploymentStatus(status) {
    if (!status) return "Status N/A";
    const map = {
        confirmed: "Confirmed",
        medical: "In Process – Medical",
        passport: "In Process – Passport",
        visa: "In Process – Visa",
        permit: "In Process – Work Permit",
        closed: "Closed",
        cancelled: "Cancelled"
    };
    return map[status] || status;
}

function buildDocsSummary(w) {
    const docs = [];
    if (w.has_passport) docs.push("Passport");
    if (w.has_pcc) docs.push("PCC");
    if (w.has_medical) docs.push("Medical");
    if (w.has_contract) docs.push("Contract");
    if (!docs.length) return "Documents: –";
    return `Documents: ${docs.join(", ")}`;
}

function addToShortlist(empId, worker) {
    if (!state.shortlist[empId]) state.shortlist[empId] = [];
    const list = state.shortlist[empId];
    if (!list.find(w => w.id === worker.id)) list.push(worker);
    renderShortlistTab({ id: empId });
}

function renderShortlistTab(emp) {
    const tbody = document.getElementById("rx-shortlist-table")?.querySelector("tbody");
    if (!tbody) return;

    tbody.innerHTML = "";
    const list = state.shortlist[emp.id] || [];

    list.forEach(w => {
        const tr = document.createElement("tr");

        const tdName = document.createElement("td");
        tdName.textContent = w.full_name || "Unnamed";

        const tdOrigin = document.createElement("td");
        tdOrigin.textContent = `${flagForCountry(w.origin_country)} ${w.origin_country || ""}`;

        const tdRole = document.createElement("td");
        tdRole.textContent = w.role || "N/A";

        const tdStatus = document.createElement("td");
        tdStatus.textContent = formatDeploymentStatus(w.deployment_status);

        const tdSalary = document.createElement("td");
        tdSalary.textContent = formatCurrency(w.expected_salary || 0, state.currency);

        const tdRemove = document.createElement("td");
        const btn = document.createElement("button");
        btn.className = "rx-button rx-button-secondary";
        btn.style.fontSize = "10px";
        btn.textContent = "Remove";
        btn.addEventListener("click", () => {
            state.shortlist[emp.id] = (state.shortlist[emp.id] || []).filter(x => x.id !== w.id);
            renderShortlistTab(emp);
        });
        tdRemove.appendChild(btn);

        tr.appendChild(tdName);
        tr.appendChild(tdOrigin);
        tr.appendChild(tdRole);
        tr.appendChild(tdStatus);
        tr.appendChild(tdSalary);
        tr.appendChild(tdRemove);

        tbody.appendChild(tr);
    });

    if (!list.length) {
        const tr = document.createElement("tr");
        const td = document.createElement("td");
        td.colSpan = 6;
        td.textContent = "No candidates shortlisted yet.";
        td.style.color = "#a9b0d6";
        tr.appendChild(td);
        tbody.appendChild(tr);
    }
}

function renderCommsTab(emp) {
    const tbody = document.getElementById("rx-comms-table")?.querySelector("tbody");
    if (!tbody) return;
    tbody.innerHTML = "";

    const entries = state.comms.filter(c => c.employer_id === emp.id)
        .sort((a, b) => new Date(a.contact_date || a.created_at) - new Date(b.contact_date || b.created_at));

    entries.forEach(c => {
        const tr = document.createElement("tr");

        const tdDate = document.createElement("td");
        tdDate.textContent = formatDate(c.contact_date || c.created_at);

        const tdMode = document.createElement("td");
        tdMode.textContent = c.mode || "N/A";

        const tdStaff = document.createElement("td");
        tdStaff.textContent = c.staff_name || "N/A";

        const tdSummary = document.createElement("td");
        tdSummary.textContent = c.summary || "";

        const tdFollow = document.createElement("td");
        tdFollow.textContent = formatDate(c.next_follow_up);

        const tdStatus = document.createElement("td");
        tdStatus.textContent = c.status || "";

        tr.appendChild(tdDate);
        tr.appendChild(tdMode);
        tr.appendChild(tdStaff);
        tr.appendChild(tdSummary);
        tr.appendChild(tdFollow);
        tr.appendChild(tdStatus);

        tbody.appendChild(tr);
    });

    if (!entries.length) {
        const tr = document.createElement("tr");
        const td = document.createElement("td");
        td.colSpan = 6;
        td.textContent = "No communication entries yet.";
        tr.appendChild(td);
        tbody.appendChild(tr);
    }
}

function renderCommercialTab(emp) {
    const tbody = document.getElementById("rx-commercial-table")?.querySelector("tbody");
    const summaryDiv = document.getElementById("rx-commercial-total");
    if (!tbody || !summaryDiv) return;
    tbody.innerHTML = "";

    const projects = state.commercial.filter(p => p.employer_id === emp.id);

    let totalValue = 0;
    let totalMarginValue = 0;

    projects.forEach(p => {
        const tr = document.createElement("tr");

        const tdProject = document.createElement("td");
        tdProject.textContent = p.project_name || "Project";

        const headcount = p.headcount || 0;
        const pricePer = p.price_per_worker || 0;
        const projectValue = headcount * pricePer;
        const margin = p.margin_percentage || 0;

        totalValue += projectValue;
        totalMarginValue += projectValue * (margin / 100);

        const tdHeadcount = document.createElement("td");
        tdHeadcount.textContent = headcount;

        const tdPrice = document.createElement("td");
        tdPrice.textContent = formatCurrency(pricePer, state.currency);

        const tdTotal = document.createElement("td");
        tdTotal.textContent = formatCurrency(projectValue, state.currency);

        const tdClose = document.createElement("td");
        tdClose.textContent = formatDate(p.expected_close_date);

        const tdMargin = document.createElement("td");
        tdMargin.textContent = `${margin || 0}%`;

        tr.appendChild(tdProject);
        tr.appendChild(tdHeadcount);
        tr.appendChild(tdPrice);
        tr.appendChild(tdTotal);
        tr.appendChild(tdClose);
        tr.appendChild(tdMargin);

        tbody.appendChild(tr);
    });

    if (!projects.length) {
        const tr = document.createElement("tr");
        const td = document.createElement("td");
        td.colSpan = 6;
        td.textContent = "No commercial projects yet.";
        tr.appendChild(td);
        tbody.appendChild(tr);
    }

    summaryDiv.textContent =
        `Total project value: ${formatCurrency(totalValue, state.currency)} • ` +
        `Potential earnings (margin): ${formatCurrency(totalMarginValue, state.currency)}`;
}

function switchTab(tabName) {
    document.querySelectorAll(".rx-tab").forEach(btn => {
        btn.classList.toggle("rx-tab-active", btn.dataset.tab === tabName);
    });

    document.querySelectorAll(".rx-tab-content").forEach(content => {
        const id = content.id.replace("rx-tab-", "");
        content.classList.toggle("rx-hidden", id !== tabName);
    });
}

function formatCurrency(amount, currency) {
    if (!amount || isNaN(amount)) amount = 0;
    // We'll keep simple formatting; you can later localize properly.
    switch (currency) {
        case "MUR":
            return `Rs ${amount.toLocaleString("en-MU")}`;
        case "USD":
            return `$${amount.toLocaleString("en-US")}`;
        case "EUR":
            return `€${amount.toLocaleString("de-DE")}`;
        case "AED":
            return `AED ${amount.toLocaleString("en-AE")}`;
        case "GBP":
            return `£${amount.toLocaleString("en-GB")}`;
        case "INR":
            return `₹${amount.toLocaleString("en-IN")}`;
        default:
            return `${currency} ${amount.toLocaleString("en-US")}`;
    }
}

function formatDate(value) {
    if (!value) return "";
    try {
        const d = new Date(value);
        if (isNaN(d.getTime())) return value;
        return d.toLocaleDateString("en-MU");
    } catch {
        return value;
    }
}

function updateHeaderStats() {
    const empCountEl = document.getElementById("rx-employer-count");
    const dormCountEl = document.getElementById("rx-dorm-count");
    const workerCountEl = document.getElementById("rx-worker-count");

    if (empCountEl) empCountEl.textContent = `Employers: ${state.employers.length}`;
    if (dormCountEl) dormCountEl.textContent = `Dormitories: ${state.dorms.length}`;
    if (workerCountEl) workerCountEl.textContent = `Available workers: ${state.workers.length}`;
}

function copySummaryToClipboard() {
    const employersCount = state.employers.length;
    const workersCount = state.workers.length;
    const summary = `ReachX Snapshot\nEmployers (Mauritius): ${employersCount}\nAvailable workers (IN/NP/LK/BD/AF): ${workersCount}`;
    navigator.clipboard?.writeText(summary).catch(() => {});
}

function copyShortlistSummaryToClipboard() {
    const empId = state.selectedEmployerId;
    if (!empId) return;
    const emp = state.employers.find(e => e.id === empId);
    const list = state.shortlist[empId] || [];
    const lines = [`Shortlist for: ${emp?.name || "Employer"}`];
    list.forEach(w => {
        lines.push(`- ${w.full_name || "Unnamed"} (${w.origin_country || ""}, ${w.role || ""})`);
    });
    navigator.clipboard?.writeText(lines.join("\n")).catch(() => {});
}
