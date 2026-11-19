// Classements — Lanterne des Profondeurs
//   Graines : AAAAMMJJ (Descente du jour), AAAASS (Défi de la semaine, semaine ISO), 1 (Défi des boss)
//   POST /score  {seed, diff, player_id, name, time, version, ghost?} → meilleur temps du joueur (+ son fantôme)
//   GET  /top?seed=…&diff=1&player_id=…                               → top 10 + rang du joueur
//   GET  /ghost?seed=…&diff=1                                         → fantôme du premier
//   GET  /discord/code?code=…      → {ok: true|false} : code du jour du serveur Discord (familier « Tube néon »)
// Données dans D1 (binding DB). Réponses JSON, ouvertes au navigateur (version web du jeu).
// Discord : secret DISCORD_WEBHOOK_URL (webhook d'un salon du serveur). Chaque jour, le Worker y
// poste le code du jour (tâche planifiée) ; seuls les membres du serveur le voient. Le code
// d'hier reste valable (fuseaux horaires, joueurs qui arrivent juste après minuit).

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json; charset=utf-8", ...CORS } });
}

// Graine du jour (AAAAMMJJ) acceptée : hier, aujourd'hui ou demain en UTC (fuseaux horaires des joueurs).
// Semaine ISO (AAAASS) d'une date
export function isoWeek(t) {
  const d = new Date(Date.UTC(t.getUTCFullYear(), t.getUTCMonth(), t.getUTCDate()));
  const day = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - day);
  const y0 = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return d.getUTCFullYear() * 100 + Math.ceil(((d - y0) / 86400000 + 1) / 7);
}

export const RUSH_SEED = 1;
export function kindOf(seed) {
  if (seed === RUSH_SEED) return "rush";
  if (seed >= 100000 && seed <= 999999) return "weekly";
  return "daily";
}

export function seedOk(seed, now = new Date()) {
  if (seed === RUSH_SEED) return true;
  if (kindOf(seed) === "weekly") {
    return [-7, 0, 7].some((d) => isoWeek(new Date(now.getTime() + d * 86400000)) === seed);
  }
  const ok = [];
  for (const d of [-1, 0, 1]) {
    const t = new Date(now.getTime() + d * 86400000);
    ok.push(t.getUTCFullYear() * 10000 + (t.getUTCMonth() + 1) * 100 + t.getUTCDate());
  }
  return ok.includes(seed);
}

export function cleanName(name) {
  let s = String(name ?? "").normalize("NFC").replace(/[\u0000-\u001f\u007f<>]/g, "").trim();
  s = s.replace(/\s+/g, " ").slice(0, 16);
  return s.length >= 2 ? s : null;
}

// ---------------------------------------------------------------- Discord (webhook)
const CODE_ALPHA = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";   // sans 0/O ni 1/I

export function dayKey(t = new Date()) {
  return t.getUTCFullYear() * 10000 + (t.getUTCMonth() + 1) * 100 + t.getUTCDate();
}

// Code du jour : dérivé du secret du webhook (rien à stocker), 8 caractères « XXXX-XXXX »
export async function dailyCode(secret, day) {
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(String(secret)), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode("neon:" + day)));
  let c = "";
  for (let i = 0; i < 8; i++) c += CODE_ALPHA[mac[i] % CODE_ALPHA.length];
  return c.slice(0, 4) + "-" + c.slice(4);
}

export function normCode(s) {
  const c = String(s || "").toUpperCase().replace(/[^A-Z0-9]/g, "");
  return c.length === 8 ? c.slice(0, 4) + "-" + c.slice(4) : "";
}

export async function codeOk(env, code, now = new Date()) {
  if (!env.DISCORD_WEBHOOK_URL) return false;
  const c = normCode(code);
  if (!c) return false;
  for (const d of [0, -1]) {
    if (c === await dailyCode(env.DISCORD_WEBHOOK_URL, dayKey(new Date(now.getTime() + d * 86400000)))) return true;
  }
  return false;
}

// Tâche planifiée : poste le code du jour une fois par jour (vérifié toutes les 30 min)
export async function postDailyCode(env, fetchFn = fetch, now = new Date()) {
  if (!env.DISCORD_WEBHOOK_URL) return "no_webhook";
  const day = dayKey(now);
  const last = await env.DB.prepare("SELECT value FROM meta WHERE key = 'neon_day'").first();
  if (last && Number(last.value) === day) return "already";
  const code = await dailyCode(env.DISCORD_WEBHOOK_URL, day);
  const r = await fetchFn(env.DISCORD_WEBHOOK_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      username: "Lanterne des Profondeurs",
      content: `🏮 **Code du jour** pour le familier « Tube néon » : \`${code}\`\nDans le jeu : écran-titre → Discord → tape le code. Valable aujourd'hui et demain.`,
    }),
  });
  if (!r.ok) return "error";
  await env.DB.prepare("INSERT INTO meta (key, value) VALUES ('neon_day', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value").bind(String(day)).run();
  return "posted";
}

async function sha(text) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].slice(0, 12).map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function top(env, seed, diff, playerId) {
  const rows = (await env.DB.prepare("SELECT name, time, player_id FROM scores WHERE seed = ? AND diff = ? ORDER BY time ASC, updated ASC LIMIT 10")
    .bind(seed, diff).all()).results || [];
  const total = (await env.DB.prepare("SELECT COUNT(*) AS n FROM scores WHERE seed = ? AND diff = ?").bind(seed, diff).first())?.n ?? 0;
  let me = null;
  if (playerId) {
    const mine = await env.DB.prepare("SELECT name, time FROM scores WHERE seed = ? AND diff = ? AND player_id = ?").bind(seed, diff, playerId).first();
    if (mine) {
      const better = (await env.DB.prepare("SELECT COUNT(*) AS n FROM scores WHERE seed = ? AND diff = ? AND time < ?").bind(seed, diff, mine.time).first())?.n ?? 0;
      me = { rank: better + 1, name: mine.name, time: mine.time };
    }
  }
  return {
    seed, diff, total, me,
    top: rows.map((r, i) => ({ rank: i + 1, name: r.name, time: r.time, you: playerId !== "" && r.player_id === playerId })),
  };
}

export default {
  async scheduled(event, env, ctx) {
    ctx.waitUntil(postDailyCode(env));
  },
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
    try {
      if (url.pathname === "/discord/code" && request.method === "GET") {
        // limite d'essais par adresse (deviner le code au hasard n'est pas jouable)
        const ip = request.headers.get("CF-Connecting-IP") || "?";
        const ipHash = await sha(ip + ":neon");
        const day = Math.floor(Date.now() / 86400000);
        const hit = await env.DB.prepare("INSERT INTO hits (ip_hash, day, n) VALUES (?, ?, 1) ON CONFLICT(ip_hash, day) DO UPDATE SET n = n + 1 RETURNING n")
          .bind(ipHash, day).first();
        if ((hit?.n ?? 0) > 30) return json({ error: "too_many" }, 429);
        if (!env.DISCORD_WEBHOOK_URL) return json({ ok: false, error: "not_configured" });
        return json({ ok: await codeOk(env, url.searchParams.get("code")) });
      }
      if (url.pathname === "/top" && request.method === "GET") {
        const seed = parseInt(url.searchParams.get("seed") || "0", 10);
        const diff = parseInt(url.searchParams.get("diff") || "1", 10);
        if (!seedOk(seed) || !(diff >= 0 && diff <= 3)) return json({ error: "bad_request" }, 400);
        return json(await top(env, seed, diff, String(url.searchParams.get("player_id") || "").slice(0, 64)));
      }
      if (url.pathname === "/ghost" && request.method === "GET") {
        const seed = parseInt(url.searchParams.get("seed") || "0", 10);
        const diff = parseInt(url.searchParams.get("diff") || "1", 10);
        if (!seedOk(seed) || !(diff >= 0 && diff <= 3)) return json({ error: "bad_request" }, 400);
        const g = await env.DB.prepare("SELECT s.name, s.time, g.data FROM scores s JOIN ghosts g ON g.seed = s.seed AND g.diff = s.diff AND g.player_id = s.player_id " +
          "WHERE s.seed = ? AND s.diff = ? ORDER BY s.time ASC, s.updated ASC LIMIT 1").bind(seed, diff).first();
        return json(g ? { name: g.name, time: g.time, data: g.data } : { none: true });
      }
      if (url.pathname === "/score" && request.method === "POST") {
        const b = await request.json().catch(() => null);
        if (!b) return json({ error: "bad_json" }, 400);
        const seed = parseInt(b.seed, 10);
        const diff = parseInt(b.diff, 10);
        const time = Number(b.time);
        const pid = String(b.player_id || "");
        const name = cleanName(b.name);
        if (!seedOk(seed) || !(diff >= 0 && diff <= 3)) return json({ error: "bad_seed" }, 400);
        if (!/^[a-f0-9]{16,64}$/.test(pid)) return json({ error: "bad_player" }, 400);
        if (!name) return json({ error: "bad_name" }, 400);
        const minT = kindOf(seed) === "rush" ? Number(env.MIN_RUSH_TIME || 60) : Number(env.MIN_TIME || 45);
        if (!Number.isFinite(time) || time < minT || time > 7200) return json({ error: "bad_time" }, 400);
        // limite d'envois par adresse et par jour
        const ip = request.headers.get("CF-Connecting-IP") || "?";
        const ipHash = await sha(ip + ":" + seed);
        const day = Math.floor(Date.now() / 86400000);
        const hit = await env.DB.prepare("INSERT INTO hits (ip_hash, day, n) VALUES (?, ?, 1) ON CONFLICT(ip_hash, day) DO UPDATE SET n = n + 1 RETURNING n")
          .bind(ipHash, day).first();
        if ((hit?.n ?? 0) > Number(env.MAX_POSTS_PER_DAY || 60)) return json({ error: "too_many" }, 429);
        // meilleur temps du joueur (le pseudo suit toujours le dernier envoi)
        await env.DB.prepare(
          "INSERT INTO scores (seed, diff, player_id, name, time, version, updated) VALUES (?, ?, ?, ?, ?, ?, ?) " +
          "ON CONFLICT(seed, diff, player_id) DO UPDATE SET name = excluded.name, version = excluded.version, " +
          "time = MIN(scores.time, excluded.time), updated = CASE WHEN excluded.time < scores.time THEN excluded.updated ELSE scores.updated END"
        ).bind(seed, diff, pid, name, Math.round(time * 100) / 100, String(b.version || "").slice(0, 16), Math.floor(Date.now() / 1000)).run();
        // fantôme : gardé seulement s'il correspond au meilleur temps enregistré du joueur
        const ghost = typeof b.ghost === "string" ? b.ghost : "";
        if (ghost && kindOf(seed) !== "rush" && ghost.length <= 400000) {
          const best = await env.DB.prepare("SELECT time FROM scores WHERE seed = ? AND diff = ? AND player_id = ?").bind(seed, diff, pid).first();
          if (best && Math.abs(best.time - Math.round(time * 100) / 100) < 0.005) {
            await env.DB.prepare("INSERT INTO ghosts (seed, diff, player_id, data) VALUES (?, ?, ?, ?) ON CONFLICT(seed, diff, player_id) DO UPDATE SET data = excluded.data")
              .bind(seed, diff, pid, ghost).run();
          }
        }
        return json(await top(env, seed, diff, pid));
      }
      if (url.pathname === "/" || url.pathname === "/health") return json({ ok: true, service: "lanterne-classement" });
      return json({ error: "not_found" }, 404);
    } catch (e) {
      return json({ error: "server", detail: String(e && e.message || e).slice(0, 200) }, 500);
    }
  },
};
