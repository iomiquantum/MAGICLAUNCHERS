const http = require("http");
const { execSync } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

const PORT = 3200;
const HOME = process.env.HOME;
const DATA = `${HOME}/.claude-launchers`;
const PROMPT_FILE = `${DATA}/orquestador-prompt.txt`;

if (!fs.existsSync(DATA)) fs.mkdirSync(DATA, { recursive: true });

function run(cmd) {
  try { return execSync(cmd, { encoding: "utf8", timeout: 5000 }).trim(); }
  catch { return ""; }
}

// ── System stats ──
function getStats() {
  const total = os.totalmem(), free = os.freemem(), used = total - free;
  const load = os.loadavg()[0], cores = os.cpus().length;
  return {
    memUsed: +(used / 1073741824).toFixed(1),
    memTotal: +(total / 1073741824).toFixed(1),
    memPct: Math.round((used / total) * 100),
    cpuPct: Math.min(100, Math.round((load / cores) * 100)),
    cores
  };
}

// ── Sessions ──
function getSessions() {
  const raw = run("tmux ls -F '#{session_name}|#{session_created}|#{session_activity}' 2>/dev/null");
  if (!raw) return [];
  return raw.split("\n").filter(Boolean).map(line => {
    const [name, created, activity] = line.split("|");
    return { name, createdTs: +created, activityTs: +activity };
  });
}

// ── Counters ──
function nextCounter(model) {
  const f = `${DATA}/${model}-counter`;
  let n = 1;
  try { n = parseInt(fs.readFileSync(f, "utf8")) + 1; } catch {}
  fs.writeFileSync(f, String(n));
  return n;
}

const MODELS = { opus: "claude-opus-4-6", sonnet: "claude-sonnet-4-6", haiku: "claude-haiku-4-5-20251001" };

function createSession(model) {
  const id = MODELS[model];
  if (!id) return { error: "Invalid model" };
  const n = nextCounter(model);
  const name = `${model.toUpperCase()}-${n}`;
  run(`tmux new -d -s "${name}" "caffeinate -s claude --model ${id} --name ${name} --dangerously-skip-permissions --rc"`);
  return { ok: true, name };
}

function createOrquestador() {
  if (run("tmux has-session -t ORQUESTADOR 2>/dev/null && echo y") === "y")
    return { ok: true, name: "ORQUESTADOR", existing: true };
  const pf = fs.existsSync(PROMPT_FILE) ? `--append-system-prompt-file ${PROMPT_FILE}` : "";
  run(`tmux new -d -s ORQUESTADOR "caffeinate -s claude --model claude-opus-4-6 --name ORQUESTADOR ${pf} --dangerously-skip-permissions --rc"`);
  return { ok: true, name: "ORQUESTADOR" };
}

function sendTask(session, task) {
  if (run(`tmux has-session -t "${session}" 2>/dev/null && echo y`) !== "y")
    return { error: "Session not found" };
  const esc = task.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\$/g, "\\$").replace(/`/g, "\\`");
  run(`tmux send-keys -t "${session}" "${esc}" Enter`);
  return { ok: true };
}

function killSession(s) { run(`tmux kill-session -t "${s}" 2>/dev/null`); return { ok: true }; }
function killAll() { run("tmux kill-server 2>/dev/null"); return { ok: true }; }

function capturePane(s, lines = 80) {
  return run(`tmux capture-pane -t "${s}" -p -S -${lines} 2>/dev/null`);
}
function captureFullPane(s) {
  return run(`tmux capture-pane -t "${s}" -p -S - 2>/dev/null`);
}

// ── Persistence (history, notes, queue) ──
function readJSON(file) { try { return JSON.parse(fs.readFileSync(file, "utf8")); } catch { return null; } }
function writeJSON(file, data) { fs.writeFileSync(file, JSON.stringify(data)); }

function getHistory(s) { return readJSON(`${DATA}/hist-${s}.json`) || []; }
function addHistory(s, task) {
  const h = getHistory(s);
  h.push({ task, time: new Date().toISOString() });
  if (h.length > 100) h.shift();
  writeJSON(`${DATA}/hist-${s}.json`, h);
}

function getNotes(s) { try { return fs.readFileSync(`${DATA}/note-${s}.txt`, "utf8"); } catch { return ""; } }
function setNotes(s, text) { fs.writeFileSync(`${DATA}/note-${s}.txt`, text); }

function getQueue(s) { return readJSON(`${DATA}/queue-${s}.json`) || []; }
function setQueue(s, q) { writeJSON(`${DATA}/queue-${s}.json`, q); }

// ── Proxy to usage dashboard ──
const USAGE_PORT = 8420;
function proxyUsage(urlPath) {
  return new Promise((resolve) => {
    const req = http.get(`http://localhost:${USAGE_PORT}${urlPath}`, { timeout: 3000 }, (res) => {
      let body = "";
      res.on("data", c => body += c);
      res.on("end", () => { try { resolve(JSON.parse(body)); } catch { resolve(null); } });
    });
    req.on("error", () => resolve(null));
    req.on("timeout", () => { req.destroy(); resolve(null); });
  });
}

// ── Favorites ──
function getFavorites() { return readJSON(`${DATA}/favorites.json`) || []; }
function setFavorites(list) { writeJSON(`${DATA}/favorites.json`, list); }

// ── Projects ──
function getProjects() { return readJSON(`${DATA}/projects.json`) || []; }
function saveProjects(list) { writeJSON(`${DATA}/projects.json`, list); }

function createProject(name, desc) {
  const projects = getProjects();
  const id = 'proj-' + Date.now();
  projects.push({ id, name, desc: desc || '', sessions: [], created: new Date().toISOString() });
  saveProjects(projects);
  return { ok: true, id };
}

function deleteProject(id) {
  let projects = getProjects();
  projects = projects.filter(p => p.id !== id);
  saveProjects(projects);
  return { ok: true };
}

function updateProject(id, updates) {
  const projects = getProjects();
  const p = projects.find(x => x.id === id);
  if (!p) return { error: "Project not found" };
  if (updates.name !== undefined) p.name = updates.name;
  if (updates.desc !== undefined) p.desc = updates.desc;
  if (updates.sessions !== undefined) p.sessions = updates.sessions;
  saveProjects(projects);
  return { ok: true };
}

function addSessionToProject(projId, sessionName) {
  const projects = getProjects();
  const p = projects.find(x => x.id === projId);
  if (!p) return { error: "Project not found" };
  if (!p.sessions.includes(sessionName)) p.sessions.push(sessionName);
  saveProjects(projects);
  return { ok: true };
}

function removeSessionFromProject(projId, sessionName) {
  const projects = getProjects();
  const p = projects.find(x => x.id === projId);
  if (!p) return { error: "Project not found" };
  p.sessions = p.sessions.filter(s => s !== sessionName);
  saveProjects(projects);
  return { ok: true };
}

// ── Broadcast Lab ──
function createBroadcastSession(task) {
  const id = 'bcast-' + Date.now();
  const models = ['haiku', 'sonnet', 'opus'];
  const names = {};

  // Create 3 sessions with claude --print (non-interactive, returns result)
  const ts = Date.now();
  for (let i = 0; i < models.length; i++) {
    const m = models[i];
    const modelId = MODELS[m];
    const sessName = `BCAST-${m.toUpperCase()}-${ts}-${i}`;
    names[m] = sessName;
    const escaped = task.replace(/'/g, "'\"'\"'");
    const outFile = `${DATA}/bcast-${id}-${m}.txt`;
    run(`tmux new -d -s "${sessName}" "claude --model ${modelId} --print -p '${escaped}' --dangerously-skip-permissions > '${outFile}' 2>&1"`);
  }

  const session = { id, task, models: names, created: new Date().toISOString(), status: 'running' };
  const labs = readJSON(`${DATA}/broadcast-labs.json`) || [];
  labs.push(session);
  if (labs.length > 20) labs.shift();
  writeJSON(`${DATA}/broadcast-labs.json`, labs);
  return { ok: true, id, names };
}

function getBroadcastResults(id) {
  const labs = readJSON(`${DATA}/broadcast-labs.json`) || [];
  const lab = labs.find(l => l.id === id);
  if (!lab) return { error: "Not found" };

  const results = {};
  for (const [model, sessName] of Object.entries(lab.models)) {
    const file = `${DATA}/bcast-${id}-${model}.txt`;
    try {
      results[model] = { output: fs.readFileSync(file, "utf8"), done: true };
    } catch {
      // Check if tmux session still running
      const running = run(`tmux has-session -t "${sessName}" 2>/dev/null && echo y`) === "y";
      results[model] = { output: running ? "(procesando...)" : "(sin resultado)", done: !running };
    }
  }
  return { ok: true, lab, results };
}

function getBroadcastList() {
  return readJSON(`${DATA}/broadcast-labs.json`) || [];
}

// ── Static files ──
const STATIC = {
  "/": { file: "index.html", type: "text/html; charset=utf-8" },
  "/manifest.json": { file: "manifest.json", type: "application/json" },
  "/sw.js": { file: "sw.js", type: "application/javascript" },
  "/icon-192.png": { file: "icon-192.png", type: "image/png" },
  "/icon-512.png": { file: "icon-512.png", type: "image/png" },
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  res.setHeader("Access-Control-Allow-Origin", "*");

  // Static
  if (req.method === "GET" && STATIC[url.pathname]) {
    const s = STATIC[url.pathname];
    const fp = path.join(__dirname, s.file);
    if (!fs.existsSync(fp)) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { "Content-Type": s.type });
    return res.end(fs.readFileSync(fp));
  }

  // API GET
  if (req.method === "GET" && url.pathname.startsWith("/api/")) {
    const route = url.pathname.slice(4);
    const s = url.searchParams.get("s");
    let data;

    if (route === "/sessions") data = getSessions();
    else if (route === "/stats") data = getStats();
    else if (route === "/preview") data = s ? { output: capturePane(s) } : { output: "" };
    else if (route === "/fullpane") data = s ? { output: captureFullPane(s) } : { output: "" };
    else if (route === "/history") data = s ? getHistory(s) : [];
    else if (route === "/notes") data = s ? { text: getNotes(s) } : { text: "" };
    else if (route === "/queue") data = s ? getQueue(s) : [];
    else if (route === "/favorites") data = getFavorites();
    else if (route === "/projects") data = getProjects();
    else if (route === "/broadcast-labs") data = getBroadcastList();
    else if (route === "/broadcast-results") {
      const bid = url.searchParams.get("id");
      data = bid ? getBroadcastResults(bid) : { error: "Missing id" };
    }
    else if (route === "/usage") {
      // Proxy to python usage dashboard
      proxyUsage("/api/usage").then(d => {
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify(d || { error: "Usage API not available. Start the usage server." }));
      });
      return;
    }
    else { res.writeHead(404); return res.end(); }

    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify(data));
  }

  // API POST
  if (req.method === "POST" && url.pathname.startsWith("/api/")) {
    let body = "";
    req.on("data", c => body += c);
    req.on("end", () => {
      let d = {};
      try { d = JSON.parse(body); } catch {}
      const route = url.pathname.slice(4);
      let result = { error: "Unknown route" };

      if (route === "/create") {
        result = d.model === "orquestador" ? createOrquestador() : createSession(d.model);
      } else if (route === "/send") {
        result = sendTask(d.session, d.task);
        if (result.ok) addHistory(d.session, d.task);
      } else if (route === "/broadcast") {
        const ss = d.sessions || getSessions().map(x => x.name);
        let sent = 0;
        ss.forEach(name => { const r = sendTask(name, d.task); if (r.ok) { addHistory(name, d.task); sent++; } });
        result = { ok: true, count: sent };
      } else if (route === "/kill") {
        result = killSession(d.session);
      } else if (route === "/kill-all") {
        result = killAll();
      } else if (route === "/notes") {
        setNotes(d.session, d.text || "");
        result = { ok: true };
      } else if (route === "/queue/add") {
        const q = getQueue(d.session);
        q.push({ task: d.task, added: new Date().toISOString() });
        setQueue(d.session, q);
        result = { ok: true, length: q.length };
      } else if (route === "/queue/clear") {
        setQueue(d.session, []);
        result = { ok: true };
      } else if (route === "/queue/next") {
        const q = getQueue(d.session);
        if (q.length) {
          const next = q.shift();
          setQueue(d.session, q);
          const r = sendTask(d.session, next.task);
          if (r.ok) addHistory(d.session, next.task);
          result = { ok: true, sent: next.task, remaining: q.length };
        } else {
          result = { ok: true, sent: null, remaining: 0 };
        }
      } else if (route === "/favorites") {
        setFavorites(d.list || []);
        result = { ok: true };
      } else if (route === "/projects/create") {
        result = createProject(d.name, d.desc);
      } else if (route === "/projects/delete") {
        result = deleteProject(d.id);
      } else if (route === "/projects/update") {
        result = updateProject(d.id, d);
      } else if (route === "/projects/add-session") {
        result = addSessionToProject(d.id, d.session);
      } else if (route === "/projects/remove-session") {
        result = removeSessionFromProject(d.id, d.session);
      } else if (route === "/broadcast-lab") {
        result = createBroadcastSession(d.task);
      } else if (route === "/export") {
        const output = captureFullPane(d.session);
        result = { output };
      }

      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify(result));
    });
    return;
  }

  res.writeHead(404);
  res.end("Not found");
});

server.listen(PORT, () => {
  console.log(`\n  Claude Orchestrator → http://localhost:${PORT}\n`);
});
