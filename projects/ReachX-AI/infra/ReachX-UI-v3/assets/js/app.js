document.addEventListener("DOMContentLoaded", function () {
    var entity = document.body.getAttribute("data-entity") || "dashboard";

    // Highlight nav
    var navLinks = document.querySelectorAll("[data-nav]");
    for (var i = 0; i < navLinks.length; i++) {
        var link = navLinks[i];
        if (link.getAttribute("data-nav") === entity) {
            link.classList.add("is-active");
        }
    }

    // Dashboard has no data layer
    if (entity === "dashboard") {
        return;
    }

    var STORAGE_KEY = "reachx_v3_entities";
    var SEED_FLAG   = "reachx_v3_seeded";

    function loadAll() {
        try {
            var raw = window.localStorage.getItem(STORAGE_KEY);
            if (!raw) return {};
            return JSON.parse(raw);
        } catch (e) {
            return {};
        }
    }

    function saveAll(data) {
        try {
            window.localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
        } catch (e) {}
    }

    function ensureSeed() {
        if (window.localStorage.getItem(SEED_FLAG)) return;

        var seed = {
            staff: [
                { name: "Aisha Khan",     field1: "Mauritius",        field2: "Placement Lead",  status: "active" },
                { name: "Ravi Patel",     field1: "India",            field2: "Candidate Ops",   status: "active" }
            ],
            employers: [
                { name: "GulfCare Hospitals", field1: "Saudi Arabia", field2: "Healthcare",      status: "active" },
                { name: "Skyline Hotel",      field1: "Dubai, UAE",   field2: "Hospitality",     status: "pending" }
            ],
            agents: [
                { name: "TalentBridge Doha", field1: "Qatar",         field2: "Nursing",         status: "active" },
                { name: "MedLink India",     field1: "India",         field2: "Nursing / Allied",status: "active" }
            ],
            candidates: [
                { name: "John Matthew",      field1: "India",         field2: "ICU Nurse",       status: "pending" },
                { name: "Maria Santos",      field1: "Philippines",   field2: "Ward Nurse",      status: "active" }
            ],
            dormitories: [
                { name: "SkyView Residence", field1: "Dubai, UAE",    field2: "48 beds",         status: "active" },
                { name: "Harbour Heights",   field1: "Doha, Qatar",   field2: "24 beds",         status: "pending" }
            ],
            placements: [
                { name: "Batch 01 · GulfCare", field1: "John / Maria", field2: "SkyView Residence", status: "active" }
            ],
            comms: [
                { name: "WhatsApp to GulfCare HR", field1: "WhatsApp", field2: "Offer details",   status: "active" },
                { name: "Call with Agent · Doha",   field1: "Call",     field2: "New demand",     status: "pending" }
            ],
            contracts: [
                { name: "Q1 2026 Master Agreement", field1: "Employer", field2: "Bulk nursing",   status: "active" },
                { name: "Dorm Lease · SkyView",     field1: "Dorm",     field2: "12-month lease", status: "pending" }
            ],
            roles: [
                { name: "Admin",       field1: "Full access",    field2: "Owner / System",  status: "active" },
                { name: "Recruiter",   field1: "Candidates only",field2: "Limited employers",status: "active" }
            ]
        };

        saveAll(seed);
        window.localStorage.setItem(SEED_FLAG, "1");
    }

    function getList() {
        var all = loadAll();
        if (!Array.isArray(all[entity])) {
            all[entity] = [];
        }
        return all[entity];
    }

    function setList(list) {
        var all = loadAll();
        all[entity] = list;
        saveAll(all);
    }

    ensureSeed();

    var form        = document.getElementById("entity-form");
    var tbody       = document.getElementById("entity-tbody");
    var countLabel  = document.getElementById("entity-count");
    var searchInput = document.getElementById("search");
    var statusFilter= document.getElementById("statusFilter");
    var resetBtn    = document.getElementById("reset-demo");

    if (!form || !tbody) {
        return;
    }

    function render() {
        var list = getList().slice();

        // Status filter
        if (statusFilter) {
            var status = statusFilter.value;
            if (status && status !== "all") {
                list = list.filter(function (row) {
                    return (row.status || "active") === status;
                });
            }
        }

        // Search filter
        if (searchInput) {
            var q = searchInput.value.toLowerCase();
            if (q) {
                list = list.filter(function (row) {
                    var text = (row.name || "") + " " + (row.field1 || "") + " " + (row.field2 || "");
                    return text.toLowerCase().indexOf(q) !== -1;
                });
            }
        }

        tbody.innerHTML = "";
        for (var i = 0; i < list.length; i++) {
            var row = list[i];
            var status = row.status || "active";
            var tr = document.createElement("tr");
            tr.innerHTML =
                "<td>" + (row.name   || "-") + "</td>" +
                "<td>" + (row.field1 || "-") + "</td>" +
                "<td>" + (row.field2 || "-") + "</td>" +
                "<td><span class=\"badge badge-status badge-" + status + "\">" + status.toUpperCase() + "</span></td>" +
                "<td><button type=\"button\" class=\"btn btn-xs btn-outline btn-delete\" data-index=\"" + i + "\">Remove</button></td>";
            tbody.appendChild(tr);
        }

        if (countLabel) {
            countLabel.textContent = String(list.length);
        }
    }

    form.addEventListener("submit", function (e) {
        e.preventDefault();
        var data = new FormData(form);
        var row = {};
        data.forEach(function (value, key) {
            row[key] = String(value).trim();
        });
        if (!row.name) {
            return;
        }
        if (!row.status) {
            row.status = "active";
        }
        var list = getList();
        list.unshift(row);
        setList(list);
        form.reset();
        render();
    });

    tbody.addEventListener("click", function (e) {
        var target = e.target;
        if (!target || !target.classList.contains("btn-delete")) return;
        var idx = parseInt(target.getAttribute("data-index"), 10);
        if (isNaN(idx)) return;
        var list = getList();
        list.splice(idx, 1);
        setList(list);
        render();
    });

    if (searchInput) {
        searchInput.addEventListener("input", render);
    }
    if (statusFilter) {
        statusFilter.addEventListener("change", render);
    }
    if (resetBtn) {
        resetBtn.addEventListener("click", function () {
            window.localStorage.removeItem(STORAGE_KEY);
            window.localStorage.removeItem(SEED_FLAG);
            ensureSeed();
            render();
        });
    }

    render();
});
