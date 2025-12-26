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

    // Dashboard: no data handling
    if (entity === "dashboard") {
        return;
    }

    var STORAGE_KEY = "reachx_v2_entities";

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
        } catch (e) {
            // ignore
        }
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

    var form = document.getElementById("entity-form");
    var tbody = document.getElementById("entity-tbody");

    if (!form || !tbody) {
        return;
    }

    function render() {
        var list = getList();
        tbody.innerHTML = "";
        for (var i = 0; i < list.length; i++) {
            var row = list[i];
            var status = row.status || "active";
            var tr = document.createElement("tr");
            tr.innerHTML =
                "<td>" + (row.name || "-") + "</td>" +
                "<td>" + (row.field1 || "-") + "</td>" +
                "<td>" + (row.field2 || "-") + "</td>" +
                "<td><span class=\\"badge badge-status badge-" + status + "\\">" + status.toUpperCase() + "</span></td>" +
                "<td><button type=\\"button\\" class=\\"btn btn-xs btn-outline btn-delete\\" data-index=\\"" + i + "\\">Remove</button></td>";
            tbody.appendChild(tr);
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
        var btn = target.closest ? target.closest(".btn-delete") : null;
        if (!btn && target.classList.contains("btn-delete")) {
            btn = target;
        }
        if (!btn) {
            return;
        }
        var idx = parseInt(btn.getAttribute("data-index"), 10);
        if (isNaN(idx)) return;
        var list = getList();
        list.splice(idx, 1);
        setList(list);
        render();
    });

    render();
});
