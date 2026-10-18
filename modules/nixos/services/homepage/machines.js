// machines tab: renders /machines.json (homepage-beszel-export.service) as one
// card per machine; a click opens that machine's details below its row. it
// mounts into the "machines" group, whose plain tiles stay as the fallback.
// window.homepageMachineAddresses (machines.nix) carries the static addresses
// from flake.hosts, since beszel collects none
(() => {
  const ROOT_ID = "machines-view";
  const REFRESH_MS = 30000;
  const PALETTE = [
    "var(--accent-2)",
    "#38bdf8",
    "#a78bfa",
    "#f472b6",
    "#94a3b8",
  ];
  const ADDRESSES = window.homepageMachineAddresses || {};
  let data = null;
  let error = null;
  let open = sessionStorage.getItem("machines-open");

  const esc = (s) =>
    String(s ?? "").replace(
      /[&<>"]/g,
      (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c],
    );
  const lvl = (v) => (v >= 90 ? "danger" : v >= 80 ? "warn" : "");
  const pct = (v) => (v == null ? "–" : `${Math.round(v)}%`);
  const bytes = (b) => {
    if (b == null) return "–";
    const units = ["B", "KB", "MB", "GB", "TB", "PB"];
    let i = 0;
    while (b >= 1000 && i < units.length - 1) {
      b /= 1000;
      i++;
    }
    return `${b >= 100 ? Math.round(b) : +b.toFixed(b >= 10 ? 1 : 2)} ${units[i]}`;
  };
  const uptime = (s) => {
    if (!s) return "–";
    const d = Math.floor(s / 86400),
      h = Math.floor((s % 86400) / 3600),
      m = Math.floor((s % 3600) / 60);
    return d ? `${d}d` : h ? `${h}h` : `${m}m`;
  };
  const natural = (a, b) =>
    String(a).localeCompare(String(b), "en", {
      numeric: true,
      sensitivity: "base",
    });
  // the plain tile carries the icon homepage already resolved
  const icon = (name) => {
    const img = document.querySelector(
      `li[id="machine-${CSS.escape(name)}"] .service-icon img`,
    );
    return img ? `<img class="mv-ic" src="${esc(img.src)}" alt="">` : "";
  };
  // "AMD Ryzen 7 5700X 8-Core Processor" -> "AMD Ryzen 7 5700X", "NixOS 26.11 (Zokor)" -> "NixOS 26.11"
  const short = (s) =>
    (s || "")
      .replace(/\(.*?\)|\b\d+-Core\b|\bProcessor\b|\bCPU\b|@.*$/gi, "")
      .replace(/\s+/g, " ")
      .trim();
  const temps = (m) => {
    const t = m.temps || {},
      out = [];
    const cpuKey = Object.keys(t).find((k) =>
      /tctl|tdie|package|coretemp|cpu|soc/i.test(k),
    );
    if (cpuKey) out.push(["cpu", t[cpuKey]]);
    const nvme = Object.keys(t)
      .filter((k) => /nvme/i.test(k))
      .map((k) => t[k]);
    if (nvme.length) out.push(["nvme", Math.max(...nvme)]);
    for (const g of m.gpus || [])
      if (t[g.name] != null) out.push(["gpu", t[g.name]]);
    return out;
  };

  const meter = (k, v) =>
    `<div class="mv-meter"><span class="k">${k}</span><div class="mv-bar"><i class="${lvl(v)}" style="width:${Math.min(v ?? 0, 100)}%"></i></div><span class="v ${lvl(v)}">${pct(v)}</span></div>`;
  const ring = (label, v, sub) =>
    `<div class="mv-ring ${lvl(v)}" style="--p:${Math.min(v ?? 0, 100)}"><div class="mv-ring-in"><b>${pct(v)}</b></div><span class="k">${esc(label)}</span>${sub ? `<span class="mv-meta">${esc(sub)}</span>` : ""}</div>`;
  const panel = (title, body, cls = "") =>
    `<div class="mv-panel ${cls}"><h3>${esc(title)}</h3>${body}</div>`;
  const kv = (rows) =>
    `<div class="mv-kv">${rows
      .filter(([, v]) => v)
      .map(([k, v]) => `<span>${esc(k)}</span><span>${esc(v)}</span>`)
      .join("")}</div>`;
  const poolsOf = (m) => data.pools.filter((p) => p.system === m.name);
  const drivesOf = (m) => data.drives.filter((d) => d.system === m.name);

  function card(m, sel) {
    const down = m.status !== "up";
    const pools = poolsOf(m)
      .map((p) => {
        const v = (p.alloc / p.size) * 100;
        return `<div class="mv-pline"><b>${esc(p.name)}</b><div class="mv-bar"><i class="${lvl(v)}" style="width:${v}%"></i></div><span>${bytes(p.alloc)} / ${bytes(p.size)}</span></div>`;
      })
      .join("");
    const t = temps(m).map(([k, v]) => `${k} ${Math.round(v)} °C`);
    const sys = [
      short(m.os),
      short(m.cpuModel),
      m.cores && `${m.cores} cores`,
      m.memTotal && bytes(m.memTotal),
      ...t,
    ]
      .filter(Boolean)
      .map(esc)
      .join(" · ");
    return `<div class="mv-card ${sel ? "sel" : ""} ${down ? "down" : ""}" role="button" tabindex="0" aria-expanded="${sel}" data-m="${esc(m.name)}">
      <div class="mv-top">${icon(m.name)}<b>${esc(m.name)}</b><span class="mv-chip ${down ? "bad" : "ok"}">${down ? esc(m.status) : `up ${uptime(m.uptime)}`}</span></div>
      <div class="mv-meters">${meter("memory", m.mem)}${meter("cpu", m.cpu)}${meter("disk", m.disk)}</div>
      ${pools ? `<div class="mv-plines">${pools}</div>` : ""}
      <div class="mv-meta">${sys}</div>
      <div class="mv-more">${sel ? "hide details" : "details"} <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><path d="m6 9 6 6 6-6"/></svg></div></div>`;
  }

  // a member table: one row per drive, with the bay drawn in front
  function driveRows(drives) {
    return drives
      .map(
        (d) =>
          `<i class="mv-bay ${/nvme|mmc/i.test(d.name) ? "nv" : ""} ${d.state === "PASSED" ? "" : "bad"}"></i><span>${esc(d.name.replace("/dev/", ""))}</span><span class="mv-model" title="${esc(d.model)}">${esc(d.model)}</span><span>${bytes(d.capacity)}</span><span>${d.temp ? `${d.temp} °C` : "–"}</span><span class="hrs">${d.hours ? `${d.hours.toLocaleString("en")} h` : "–"}</span><span class="${d.state === "PASSED" ? "ok" : "bad"}">${esc(String(d.state).toLowerCase())}</span>`,
      )
      .join("");
  }
  const memberTable = (groups) =>
    `<div class="mv-members">${groups
      .map(
        (g) =>
          `${g.name ? `<span class="mv-vdev">${esc(g.name)}</span>` : ""}${driveRows(g.drives)}`,
      )
      .join("")}</div>`;

  // zfs vdev names embed the drive serial (ata-…_<serial>, wwn-0x<serial>),
  // which is how smart devices map onto pool members
  function members(p, drives, claimed) {
    const groups = [];
    for (const v of p.vdevs) {
      if (
        /^(raidz\d*|mirror|draid\d*|spare|log|cache|special|dedup)(-\d+)?$/.test(
          v,
        )
      ) {
        groups.push({ name: v, drives: [], missing: 0 });
        continue;
      }
      if (!groups.length) groups.push({ name: "", drives: [], missing: 0 });
      const d = drives.find(
        (d) =>
          d.serial && v.toLowerCase().includes(String(d.serial).toLowerCase()),
      );
      if (d) {
        groups[groups.length - 1].drives.push(d);
        claimed.add(d);
      } else groups[groups.length - 1].missing++;
    }
    for (const g of groups) g.drives.sort((a, b) => natural(a.name, b.name));
    return groups;
  }

  // zfs: headline is usable space from the root dataset, the bar splits it by
  // top-level dataset; btrfs: allocated of size
  function pool(p, groups) {
    const root = p.datasets.find((d) => d.name === p.name);
    let used,
      total,
      segs = [];
    if (p.kind === "zfs" && root) {
      used = root.used;
      total = root.used + root.avail;
      const top = p.datasets
        .filter((d) => d.name.split("/").length === 2)
        .sort((a, b) => b.used - a.used);
      const shown = top.slice(0, 4);
      const rest = root.used - shown.reduce((s, d) => s + d.used, 0);
      segs = shown.map((d, i) => [d.name.split("/")[1], d.used, PALETTE[i]]);
      if (rest > total * 0.005) segs.push(["other", rest, PALETTE[4]]);
    } else {
      used = p.alloc;
      total = p.size;
      segs = [["used", used, PALETTE[0]]];
    }
    const scrub =
      p.scrub && p.scrub.state
        ? p.scrub.state === "FINISHED" && !p.scrub.errors
          ? "scrub ok · 0 errors"
          : `scrub ${String(p.scrub.state).toLowerCase()} · ${p.scrub.errors ?? 0} errors`
        : "";
    const healthy = String(p.health).toUpperCase() === "ONLINE";
    const hasDrives = groups.some((g) => g.drives.length);
    return `<div class="mv-pool"><div class="mv-ph"><h3>${esc(p.name)} <span>· ${esc(p.kind)}</span></h3><span class="mv-chip ${healthy ? "ok" : "bad"}">${esc(String(p.health).toLowerCase())}${scrub ? ` · ${scrub}` : ""}</span></div>
      <div class="mv-big"><b>${bytes(used)}</b><span>of ${bytes(total)}${p.kind === "zfs" ? " usable" : ""} · ${Math.round((used / total) * 100)}% used${p.kind === "zfs" ? ` · ${bytes(p.alloc)} of ${bytes(p.size)} raw` : ""}</span></div>
      <div class="mv-seg">${segs.map(([, v, c]) => `<i style="width:${(v / total) * 100}%;background:${c}"></i>`).join("")}</div>
      ${p.kind === "zfs" ? `<div class="mv-legend">${segs.map(([n, v, c]) => `<span style="--c:${c}">${esc(n)} ${bytes(v)}</span>`).join("")}<span style="--c:rgba(255,255,255,.12)">free ${bytes(total - used)}</span></div>` : ""}
      ${datasets(p, total)}
      ${hasDrives ? memberTable(groups) : ""}</div>`;
  }

  // every dataset below the pool root, indented by depth; used includes children
  function datasets(p, total) {
    if (p.kind !== "zfs") return "";
    const rows = p.datasets
      .filter((d) => d.name !== p.name)
      .sort((a, b) => natural(a.name, b.name))
      .map((d) => {
        const depth = d.name.split("/").length - 2;
        return `<span class="n" style="--d:${depth}">${esc(d.name.split("/").pop())}</span><div class="mv-bar"><i style="width:${Math.max((d.used / total) * 100, 0.5)}%"></i></div><span class="s">${bytes(d.used)}</span>`;
      });
    return rows.length ? `<div class="mv-tree">${rows.join("")}</div>` : "";
  }

  // filesystems beszel reports outside zfs_pools: the root filesystem of
  // machines without pools (ext4, overlayfs) and every extra filesystem
  function fs(name, f, drives = []) {
    const v = (f.used / f.size) * 100;
    return `<div class="mv-pool small"><div class="mv-ph"><h3>${esc(name)}</h3><span class="mv-meta">${bytes(f.used)} / ${bytes(f.size)}</span></div><div class="mv-big"><b>${pct(v)}</b><span>used</span></div><div class="mv-bar"><i class="${lvl(v)}" style="width:${v}%"></i></div>${drives.length ? memberTable([{ name: "", drives }]) : ""}</div>`;
  }

  function storage(m) {
    const pools = poolsOf(m);
    const drives = drivesOf(m).sort((a, b) => natural(a.name, b.name));
    const claimed = new Set();
    const zfs = pools
      .filter((p) => p.kind === "zfs")
      .map((p) => pool(p, members(p, drives, claimed)));
    let free = drives.filter((d) => !claimed.has(d));
    // btrfs and plain root filesystems name no members; a machine with a
    // single such filesystem owns all its remaining drives
    const rest = pools.filter((p) => p.kind !== "zfs");
    const single = rest.length + (!pools.length && m.rootFs ? 1 : 0) === 1;
    const other = rest.map((p) => {
      const own = single ? free : [];
      if (single) free = [];
      return pool(p, [{ name: "", drives: own }]);
    });
    // pools take the wide slots; small cards stack in one column beside them
    const small = [];
    if (!pools.length && m.rootFs) {
      small.push(fs("root filesystem", m.rootFs, single ? free : []));
      if (single) free = [];
    }
    for (const e of m.extraFs || []) small.push(fs(e.name, e));
    if (free.length)
      small.push(
        `<div class="mv-pool small"><div class="mv-ph"><h3>other drives</h3><span class="mv-meta">in no pool</span></div>${memberTable([{ name: "", drives: free }])}</div>`,
      );
    const big = [...zfs, ...other];
    if (!big.length && !small.length) return "";
    return `<div class="mv-storage">${big.join("")}${small.length ? `<div class="mv-smalls">${small.join("")}</div>` : ""}</div>`;
  }

  function usagePanel(m) {
    return panel(
      "Usage",
      `<div class="mv-rings">${ring("cpu", m.cpu, m.load?.length ? `load ${m.load[0]}` : "")}${ring("memory", m.mem, m.memTotal ? `${bytes(m.memUsed)} of ${bytes(m.memTotal)}` : "")}${m.swap ? ring("swap", (m.swapUsed / m.swap) * 100, `${bytes(m.swapUsed)} of ${bytes(m.swap)}`) : ""}</div>`,
      "rings",
    );
  }

  function systemPanel(m) {
    return panel(
      "System",
      kv([
        ["os", short(m.os)],
        ["kernel", m.kernel],
        [
          "cpu",
          [short(m.cpuModel), m.cores && `${m.cores} cores`]
            .filter(Boolean)
            .join(" · "),
        ],
        ["uptime", uptime(m.uptime)],
        ["load", (m.load || []).join(" · ")],
        ["zfs arc", m.memZfsArc ? bytes(m.memZfsArc) : ""],
        ["cache", m.memBuffCache ? bytes(m.memBuffCache) : ""],
      ]),
    );
  }

  function gpuPanel(m, g) {
    const t = (m.temps || {})[g.name];
    // amd adds gtt (system memory the gpu may map) to its vram; intel xe
    // exposes no memory to beszel
    const mem = g.memTotal
      ? `${meter("memory", (g.memUsed / g.memTotal) * 100)}<div class="mv-meta">${bytes(g.memUsed * 1048576)} of ${bytes(g.memTotal * 1048576)}${/amd/i.test(g.name) ? " · includes shared system memory (gtt)" : ""}</div>`
      : `<div class="mv-meta">memory not reported</div>`;
    return panel(
      g.name,
      `${meter("usage", g.usage)}${mem}${kv([
        ["power", g.power ? `${g.power.toFixed(1)} W` : ""],
        ["temp", t != null ? `${Math.round(t)} °C` : ""],
      ])}`,
    );
  }

  function tempsPanel(m) {
    const rows = Object.entries(m.temps || {})
      .sort((a, b) => b[1] - a[1])
      .map(
        ([k, v]) =>
          `<span title="${esc(k)}">${esc(k.replace(/_/g, " "))}</span><span class="v ${lvl(v)}">${Math.round(v)} °C</span>`,
      );
    return rows.length
      ? panel("Temperatures", `<div class="mv-kv temps">${rows.join("")}</div>`)
      : "";
  }

  // beszel reports physical interfaces only, without addresses
  const RJ45 =
    '<svg class="mv-port" viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="5" width="18" height="15" rx="2.5" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M9 5v3h6V5" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M7.5 15h9" stroke="currentColor" stroke-width="1.6" stroke-dasharray="1.2 1.6"/></svg>';
  const WIFI =
    '<svg class="mv-port" viewBox="0 0 24 24" aria-hidden="true"><path d="M4 9.5a12 12 0 0 1 16 0M7 13a7.5 7.5 0 0 1 10 0M10 16.5a3 3 0 0 1 4 0" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/><circle cx="12" cy="19.5" r="1" fill="currentColor"/></svg>';
  function netPanel(m) {
    const ifaces = (m.net || [])
      .map((n) => n.name)
      .sort(natural)
      .map(
        (n) =>
          `<span class="mv-iface">${/^(phy|wl|wlan)/.test(n) ? WIFI : RJ45}${esc(n)}</span>`,
      )
      .join("");
    const addrs = (ADDRESSES[m.name] || [])
      .map((a) => `<span>${esc(a.label)}</span><span>${esc(a.address)}</span>`)
      .join("");
    if (!ifaces && !addrs) return "";
    return panel(
      "Network",
      `${ifaces ? `<div class="mv-ifaces">${ifaces}</div>` : ""}${addrs ? `<div class="mv-kv">${addrs}</div>` : ""}`,
    );
  }

  function detail(m) {
    const panels = [
      usagePanel(m),
      systemPanel(m),
      ...(m.gpus || []).map((g) => gpuPanel(m, g)),
      tempsPanel(m),
      netPanel(m),
    ].join("");
    const store = storage(m);
    return `<div class="mv-detail"><div class="mv-dh">${icon(m.name)}<b>${esc(m.name)}</b><span class="mv-chip ok">up ${uptime(m.uptime)}</span></div>
      <div class="mv-panels">${panels}</div>
      ${store ? `<h3 class="mv-sec">Storage</h3>${store}` : ""}</div>`;
  }

  // columns follow the grid's breakpoints in machines.css
  const columns = () =>
    window.innerWidth <= 640 ? 1 : window.innerWidth <= 1050 ? 2 : 3;

  function render() {
    const root = document.getElementById(ROOT_ID);
    if (!root) return;
    let html;
    if (!data) {
      html = `<div class="mv-meta">${error ? `machines.json: ${esc(error)}` : "loading machines…"}</div>`;
    } else {
      if (!data.machines.some((m) => m.name === open)) open = null;
      const cols = columns();
      const idx = data.machines.findIndex((m) => m.name === open);
      const cells = [];
      data.machines.forEach((m, i) => {
        cells.push(card(m, i === idx));
        const rowEnd = i % cols === cols - 1 || i === data.machines.length - 1;
        if (
          idx >= 0 &&
          rowEnd &&
          Math.floor(idx / cols) === Math.floor(i / cols)
        )
          cells.push(detail(data.machines[idx]));
      });
      html = `<div class="mv-grid ${open ? "has-open" : ""}">${cells.join("")}</div>`;
    }
    // one swap keeps the page height, so the browser keeps the scroll position
    const y = window.scrollY;
    root.innerHTML = html;
    if (window.scrollY !== y) window.scrollTo(0, y);
  }

  function toggle(name) {
    open = open === name ? null : name;
    if (open) sessionStorage.setItem("machines-open", open);
    else sessionStorage.removeItem("machines-open");
    render();
    document
      .querySelector(`#${ROOT_ID} [data-m="${CSS.escape(name)}"]`)
      ?.focus({ preventScroll: true });
  }

  // fetch only while someone looks: the machines tab is mounted (homepage
  // drops inactive tabs from the dom) and the browser tab is visible
  let loadedAt = 0;
  const watched = () =>
    !document.hidden && document.getElementById(ROOT_ID)?.offsetParent != null;
  const loadIfStale = () => {
    if (watched() && Date.now() - loadedAt >= REFRESH_MS) load();
  };

  async function load() {
    loadedAt = Date.now();
    try {
      const res = await fetch("/machines.json", { cache: "no-store" });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      data = await res.json();
      data.machines.sort((a, b) => a.name.localeCompare(b.name));
      error = null;
    } catch (e) {
      error = e.message;
    }
    render();
  }

  // homepage re-renders its groups on tab switches; re-mount whenever the
  // machines group exists without the view
  function mount() {
    const tile = document.querySelector('li[id^="machine-"]');
    const group = tile?.closest(".services-group");
    if (!group || group.querySelector(`#${ROOT_ID}`)) return;
    const root = document.createElement("div");
    root.id = ROOT_ID;
    root.addEventListener("click", (e) => {
      const c = e.target.closest("[data-m]");
      if (c) toggle(c.dataset.m);
    });
    root.addEventListener("keydown", (e) => {
      const c = e.target.closest("[data-m]");
      if (c && (e.key === "Enter" || e.key === " ")) {
        e.preventDefault();
        toggle(c.dataset.m);
      }
      if (e.key === "Escape" && open) toggle(open);
    });
    group.appendChild(root);
    render();
    loadIfStale();
  }

  let queued = false;
  new MutationObserver(() => {
    if (queued) return;
    queued = true;
    requestAnimationFrame(() => {
      queued = false;
      mount();
    });
  }).observe(document.body, { childList: true, subtree: true });
  let lastCols = columns();
  window.addEventListener("resize", () => {
    if (columns() !== lastCols) {
      lastCols = columns();
      render();
    }
  });
  document.addEventListener("visibilitychange", loadIfStale);
  setInterval(loadIfStale, 1000);
  mount();
})();
