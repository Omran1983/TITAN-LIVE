document.addEventListener("DOMContentLoaded", () => {
    // NAV HANDLING (Dashboard + Views)
    const views = document.querySelectorAll(".view");
    const navLinks = document.querySelectorAll("[data-nav]");
    const pageLabel = document.querySelector("[data-page-label]");
    const searchInput = document.querySelector("[data-search-input]");

    function activateView(key) {
        views.forEach(v => {
            v.classList.toggle("view--active", v.dataset.view === key);
        });
        navLinks.forEach(link => {
            link.classList.toggle("is-active", link.dataset.nav === key);
        });
        if (pageLabel) {
            const active = document.querySelector("[data-nav='" + key + "']");
            if (active) pageLabel.textContent = active.dataset.label || "Dashboard";
        }
    }

    navLinks.forEach(link => {
        link.addEventListener("click", (e) => {
            e.preventDefault();
            const key = link.dataset.nav;
            activateView(key);
        });
    });

    // Simple search filter (within active table)
    if (searchInput) {
        searchInput.addEventListener("input", () => {
            const q = searchInput.value.toLowerCase();
            const activeView = document.querySelector(".view.view--active");
            if (!activeView) return;
            const rows = activeView.querySelectorAll("tbody tr");
            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(q) ? "" : "none";
            });
        });
    }

    activateView("dashboard");

    // ---------------------------------------------------------------------
    // SIMPLE LOCALSTORAGE DATA LAYER (demo only)
    // ---------------------------------------------------------------------
    const STORAGE_KEY = "reachx_demo_data_v1";

    function loadAll() {
        try {
            const raw = window.localStorage.getItem(STORAGE_KEY);
            if (!raw) return {};
            return JSON.parse(raw);
        } catch (_) {
            return {};
        }
    }

    function saveAll(data) {
        try {
            window.localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
        } catch (_) {
            // ignore
        }
    }

    function getEntityList(entity) {
        const all = loadAll();
        if (!all[entity]) all[entity] = [];
        return all[entity];
    }

    function pushEntity(entity, record) {
        const all = loadAll();
        if (!all[entity]) all[entity] = [];
        all[entity].unshift(record);
        saveAll(all);
        return all[entity];
    }

    // ---------------------------------------------------------------------
    // GENERIC FORM + TABLE WIRING
    // ---------------------------------------------------------------------
    const entityConfigs = [
        { entity: "staff",        label: "Staff" },
        { entity: "employers",    label: "Employers" },
        { entity: "agents",       label: "Agents" },
        { entity: "candidates",   label: "Candidates" },
        { entity: "dormitories",  label: "Dormitories" },
        { entity: "contracts",    label: "Contracts" },
        { entity: "comms",        label: "Communications" }
    ];

    function renderTable(entity) {
        const tbody = document.querySelector("[data-entity-table='" + entity + "']");
        if (!tbody) return;
        tbody.innerHTML = "";
        const list = getEntityList(entity);
        list.forEach((row, idx) => {
            const tr = document.createElement("tr");
            tr.innerHTML = `
                <td>${row.name || "-"}</td>
                <td>${row.country || row.channel || "-"}</td>
                <td>${row.note || row.role || "-"}</td>
                <td>
                    <span class="badge-status ${row.status || "active"}">
                        ${(row.status || "active").toUpperCase()}
                    </span>
                </td>
            `;
            tbody.appendChild(tr);
        });
    }

    function initEntity(entity) {
        renderTable(entity);

        const openBtn = document.querySelector("[data-open-modal='" + entity + "']");
        const modal = document.querySelector("[data-modal='" + entity + "']");
        const closeBtn = modal ? modal.querySelector("[data-modal-close]") : null;
        const form = modal ? modal.querySelector("form") : null;

        function openModal() {
            if (modal) modal.classList.add("is-open");
        }

        function closeModal() {
            if (modal) modal.classList.remove("is-open");
        }

        if (openBtn && modal) {
            openBtn.addEventListener("click", openModal);
        }
        if (closeBtn) {
            closeBtn.addEventListener("click", closeModal);
        }
        if (modal) {
            modal.addEventListener("click", (e) => {
                if (e.target === modal) closeModal();
            });
        }

        if (form) {
            form.addEventListener("submit", (e) => {
                e.preventDefault();
                const payload = {};
                const fd = new FormData(form);
                fd.forEach((value, key) => {
                    payload[key] = String(value).trim();
                });
                if (!payload.name) return;
                payload.status = payload.status || "active";
                payload.created_at = new Date().toISOString();

                pushEntity(entity, payload);
                renderTable(entity);
                form.reset();
                closeModal();
            });
        }
    }

    entityConfigs.forEach(cfg => initEntity(cfg.entity));

    // Seed some sample data for first-time use
    const firstBootFlag = "reachx_demo_seed_v1";
    if (!window.localStorage.getItem(firstBootFlag)) {
        const now = new Date().toISOString();
        pushEntity("staff", {
            name: "Aisha Khan",
            country: "Mauritius",
            role: "Placement Lead",
            note: "Senior recruiter",
            status: "active",
            created_at: now
        });
        pushEntity("employers", {
            name: "GulfCare Hospitals",
            country: "Saudi Arabia",
            note: "Healthcare",
            status: "active",
            created_at: now
        });
        pushEntity("agents", {
            name: "TalentBridge Doha",
            country: "Qatar",
            note: "Nursing",
            status: "active",
            created_at: now
        });
        pushEntity("candidates", {
            name: "John Matthew",
            country: "India",
            note: "ICU Nurse",
            status: "pending",
            created_at: now
        });
        pushEntity("dormitories", {
            name: "SkyView Residence",
            country: "Dubai",
            note: "48 beds",
            status: "active",
            created_at: now
        });
        pushEntity("contracts", {
            name: "Q1 2026 Master Agreement",
            country: "KSA",
            note: "Bulk nursing deployment",
            status: "active",
            created_at: now
        });
        pushEntity("comms", {
            name: "Welcome email to new employer",
            channel: "Email",
            note: "Onboarding",
            status: "active",
            created_at: now
        });
        window.localStorage.setItem(firstBootFlag, "1");
        entityConfigs.forEach(cfg => renderTable(cfg.entity));
    }
});
