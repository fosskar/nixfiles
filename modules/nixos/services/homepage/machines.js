// machines tab: renders /machines.json (homepage-beszel-export.service) as one
// card per machine; a click opens that machine's storage below its row. it
// mounts into the "machines" group, whose plain tiles stay as the fallback
(() => {
  const ROOT_ID = "machines-view";
  const REFRESH_MS = 30000;
  const PALETTE = ["#2dd4bf", "#38bdf8", "#a78bfa", "#f472b6", "#94a3b8"];
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

  // zfs: headline is usable space from the root dataset, the bar splits it by
  // top-level dataset; btrfs: allocated of size
  function pool(p) {
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
    const groups = [];
    for (const v of p.vdevs) {
      if (
        /^(raidz\d*|mirror|draid\d*|spare|log|cache|special|dedup)(-\d+)?/.test(
          v,
        )
      )
        groups.push({ name: v, bays: [] });
      else {
        if (!groups.length)
          groups.push({
            name: p.kind === "btrfs" ? "device" : "stripe",
            bays: [],
          });
        groups[groups.length - 1].bays.push(/nvme/i.test(v) ? "nv" : "");
      }
    }
    const scrub =
      p.scrub && p.scrub.state
        ? p.scrub.state === "FINISHED" && !p.scrub.errors
          ? "scrub ok · 0 errors"
          : `scrub ${String(p.scrub.state).toLowerCase()} · ${p.scrub.errors ?? 0} errors`
        : "";
    const healthy = String(p.health).toUpperCase() === "ONLINE";
    return `<div class="mv-pool"><div class="mv-ph"><h3>${esc(p.name)} <span>· ${esc(p.kind)}</span></h3><span class="mv-chip ${healthy ? "ok" : "bad"}">${esc(String(p.health).toLowerCase())}${scrub ? ` · ${scrub}` : ""}</span></div>
      <div class="mv-big"><b>${bytes(used)}</b><span>of ${bytes(total)}${p.kind === "zfs" ? " usable" : ""} · ${Math.round((used / total) * 100)}% used${p.kind === "zfs" ? ` · ${bytes(p.alloc)} of ${bytes(p.size)} raw` : ""}</span></div>
      <div class="mv-seg">${segs.map(([, v, c]) => `<i style="width:${(v / total) * 100}%;background:${c}"></i>`).join("")}</div>
      ${p.kind === "zfs" ? `<div class="mv-legend">${segs.map(([n, v, c]) => `<span style="--c:${c}">${esc(n)} ${bytes(v)}</span>`).join("")}<span style="--c:rgba(255,255,255,.12)">free ${bytes(total - used)}</span></div>` : ""}
      <div class="mv-layout">${groups.map((g) => `<div class="mv-vgroup"><div class="mv-bays">${g.bays.map((b) => `<i class="mv-bay ${b}"></i>`).join("")}</div><small>${esc(g.name)}</small></div>`).join("")}</div></div>`;
  }

  // filesystems beszel reports outside zfs_pools: the root filesystem of
  // machines without pools (ext4, overlayfs) and every extra filesystem
  function fs(name, f) {
    const v = (f.used / f.size) * 100;
    return `<div class="mv-fs"><div class="mv-ph"><h3>${esc(name)}</h3><span class="mv-meta">${bytes(f.used)} / ${bytes(f.size)}</span></div><div class="mv-big"><b>${pct(v)}</b><span>used</span></div><div class="mv-bar"><i class="${lvl(v)}" style="width:${v}%"></i></div></div>`;
  }

  function detail(m) {
    const pools = poolsOf(m),
      drives = drivesOf(m);
    const gpu = (m.gpus || [])
      .map(
        (g) =>
          `${g.name} · ${(g.memUsed / 1024).toFixed(1)} of ${(g.memTotal / 1024).toFixed(1)} GB vram`,
      )
      .join(" · ");
    const filesystems = [
      ...(!pools.length && m.rootFs ? [fs("root filesystem", m.rootFs)] : []),
      ...(m.extraFs || []).map((e) => fs(e.name, e)),
    ];
    const body =
      (pools.length
        ? `<div class="mv-pools ${pools.length === 1 ? "one" : ""}">${pools.map(pool).join("")}</div>`
        : "") +
        (filesystems.length
          ? `<div class="mv-fss">${filesystems.join("")}</div>`
          : "") || `<div class="mv-meta">no filesystems reported</div>`;
    const table = drives.length
      ? `<div class="mv-drives"><span class="h">drive</span><span class="h">model</span><span class="h">size</span><span class="h">smart</span><span class="h">temp</span><span class="h">hours</span>${drives
          .map(
            (d) =>
              `<span>${esc(d.name.replace("/dev/", ""))}</span><span>${esc(d.model)}</span><span>${bytes(d.capacity)}</span><span class="${d.state === "PASSED" ? "ok" : "bad"}">${esc(String(d.state).toLowerCase())}</span><span>${d.temp ? `${d.temp} °C` : "–"}</span><span>${d.hours ? d.hours.toLocaleString("en") : "–"}</span>`,
          )
          .join("")}</div>`
      : "";
    return `<div class="mv-detail"><div class="mv-dh">${icon(m.name)}<b>${esc(m.name)} storage</b><span class="mv-meta">load ${(m.load || []).join(" ")}${gpu ? ` · ${esc(gpu)}` : ""}</span></div>${body}${table}</div>`;
  }

  function render() {
    const root = document.getElementById(ROOT_ID);
    if (!root) return;
    if (!data) {
      root.innerHTML = `<div class="mv-meta">${error ? `machines.json: ${esc(error)}` : "loading machines…"}</div>`;
      return;
    }
    if (!data.machines.some((m) => m.name === open)) open = null;
    root.innerHTML = `<div class="mv-grid ${open ? "has-open" : ""}"></div>`;
    const grid = root.firstChild;
    const cols = Math.max(
      1,
      getComputedStyle(grid).gridTemplateColumns.split(" ").length,
    );
    const idx = data.machines.findIndex((m) => m.name === open);
    const cells = [];
    data.machines.forEach((m, i) => {
      cells.push(card(m, i === idx));
      const rowEnd = i % cols === cols - 1 || i === data.machines.length - 1;
      if (idx >= 0 && rowEnd && Math.floor(idx / cols) === Math.floor(i / cols))
        cells.push(detail(data.machines[idx]));
    });
    grid.innerHTML = cells.join("");
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

  async function load() {
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
  window.addEventListener("resize", () => render());
  load();
  setInterval(() => {
    if (!document.hidden) load();
  }, REFRESH_MS);
  mount();
})();
