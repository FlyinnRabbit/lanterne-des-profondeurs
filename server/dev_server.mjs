// Serveur local pour tester le jeu sans Cloudflare : `node dev_server.mjs [port]`
// puis lancer le jeu avec LANTERNE_LEADERBOARD_URL=http://127.0.0.1:8787
import { DatabaseSync } from "node:sqlite";
import { readFileSync } from "node:fs";
import { createServer } from "node:http";
import worker from "./worker.js";

const db = new DatabaseSync(":memory:");
db.exec(readFileSync(new URL("./schema.sql", import.meta.url), "utf8"));
const DB = { prepare(sql) { let a = []; const st = db.prepare(sql); return {
  bind(...x) { a = x; return this; }, async all() { return { results: st.all(...a) }; },
  async first() { return st.get(...a) ?? null; }, async run() { return st.run(...a); } }; } };
const env = { DB, MIN_TIME: "45", MAX_POSTS_PER_DAY: "60" };
const port = parseInt(process.argv[2] || "8787", 10);
createServer(async (req, res) => {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  const body = chunks.length ? Buffer.concat(chunks) : undefined;
  const r = await worker.fetch(new Request(`http://127.0.0.1:${port}${req.url}`, { method: req.method, headers: req.headers, body: req.method === "GET" ? undefined : body }), env);
  res.writeHead(r.status, Object.fromEntries(r.headers));
  res.end(Buffer.from(await r.arrayBuffer()));
}).listen(port, "127.0.0.1", () => console.log(`classement local : http://127.0.0.1:${port}`));
