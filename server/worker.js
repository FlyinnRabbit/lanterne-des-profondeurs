// Classement de la Descente du jour — Lanterne des Profondeurs
//   POST /score  {seed, diff, player_id, name, time, version}  → enregistre le meilleur temps du joueur
//   GET  /top?seed=AAAAMMJJ&diff=1&player_id=…                   → top 10 + rang du joueur
// Données dans D1 (binding DB). Réponses JSON, ouvertes au navigateur (version web du jeu).

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json; charset=utf-8", ...CORS } });
}

// Graine du jour (AAAAMMJJ) acceptée : hier, aujourd'hui ou demain en UTC (fuseaux horaires des joueurs).
export function seedOk(seed, now = new Date()) {
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
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
    try {
      if (url.pathname === "/top" && request.method === "GET") {
        const seed = parseInt(url.searchParams.get("seed") || "0", 10);
        const diff = parseInt(url.searchParams.get("diff") || "1", 10);
        if (!seedOk(seed) || !(diff >= 0 && diff <= 3)) return json({ error: "bad_request" }, 400);
        return json(await top(env, seed, diff, String(url.searchParams.get("player_id") || "").slice(0, 64)));
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
        if (!Number.isFinite(time) || time < Number(env.MIN_TIME || 45) || time > 7200) return json({ error: "bad_time" }, 400);
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
        return json(await top(env, seed, diff, pid));
      }
      if (url.pathname === "/" || url.pathname === "/health") return json({ ok: true, service: "lanterne-classement" });
      return json({ error: "not_found" }, 404);
    } catch (e) {
      return json({ error: "server", detail: String(e && e.message || e).slice(0, 200) }, 500);
    }
  },
};
