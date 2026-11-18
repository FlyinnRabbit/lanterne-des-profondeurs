// Test local du Worker : `node test_worker.mjs` (D1 simulée avec node:sqlite).
import { DatabaseSync } from "node:sqlite";
import { readFileSync } from "node:fs";
import worker, { seedOk, cleanName, isoWeek } from "./worker.js";

const db = new DatabaseSync(":memory:");
db.exec(readFileSync(new URL("./schema.sql", import.meta.url), "utf8"));
const DB = {
  prepare(sql) {
    let args = [];
    const st = db.prepare(sql);
    return {
      bind(...a) { args = a; return this; },
      async all() { return { results: st.all(...args) }; },
      async first() { return st.get(...args) ?? null; },
      async run() { return st.run(...args); },
    };
  },
};
const env = { DB, MIN_TIME: "45", MAX_POSTS_PER_DAY: "5" };
const d = new Date();
const today = d.getUTCFullYear() * 10000 + (d.getUTCMonth() + 1) * 100 + d.getUTCDate();
let fails = 0;
const check = (cond, what) => { console.log((cond ? "✔ " : "✗ ") + what); if (!cond) fails++; };

async function post(body, ip = "1.2.3.4") {
  const r = await worker.fetch(new Request("https://x/score", { method: "POST", body: JSON.stringify(body), headers: { "CF-Connecting-IP": ip } }), env);
  return [r.status, await r.json()];
}
const A = "a".repeat(32), B = "b".repeat(32), C = "c".repeat(32);
let [s, j] = await post({ seed: today, diff: 1, player_id: A, name: "Thomas", time: 312.4, version: "2.5.4" });
check(s === 200 && j.me.rank === 1 && j.total === 1, "premier temps enregistré, rang 1");
[s, j] = await post({ seed: today, diff: 1, player_id: B, name: "Pote", time: 250 }, "5.6.7.8");
check(j.me.rank === 1 && j.top[1].name === "Thomas", "meilleur temps passe devant");
[s, j] = await post({ seed: today, diff: 1, player_id: A, name: "Thomas", time: 400 });
check(j.me.time === 312.4, "un temps moins bon ne remplace pas le record");
[s, j] = await post({ seed: today, diff: 1, player_id: A, name: "Tom", time: 200 });
check(j.me.rank === 1 && j.me.time === 200 && j.me.name === "Tom", "record battu et pseudo mis à jour");
[s, j] = await post({ seed: today, diff: 2, player_id: C, name: "Dur", time: 500 }, "9.9.9.9");
check(j.total === 1, "classements séparés par difficulté");
[s] = await post({ seed: today, diff: 1, player_id: A, name: "Tom", time: 10 });
check(s === 400, "temps impossible refusé");
[s] = await post({ seed: 20200101, diff: 1, player_id: A, name: "Tom", time: 100 });
check(s === 400, "graine d'un autre jour refusée");
[s] = await post({ seed: today, diff: 1, player_id: "zz", name: "Tom", time: 100 });
check(s === 400, "identifiant invalide refusé");
[s] = await post({ seed: today, diff: 1, player_id: A, name: "<", time: 100 });
check(s === 400, "pseudo vide/invalide refusé");
check(cleanName("  Le   <b>Veilleur</b> extra long name ") === "Le bVeilleur/b e", "pseudo nettoyé et limité à 16 caractères");
let last = 0;
for (let i = 0; i < 6; i++) [last] = await post({ seed: today, diff: 3, player_id: A, name: "Tom", time: 300 + i }, "7.7.7.7");
check(last === 429, "trop d'envois depuis la même adresse");
const r = await worker.fetch(new Request(`https://x/top?seed=${today}&diff=1&player_id=${B}`), env);
j = await r.json();
check(r.status === 200 && j.top.length === 2 && j.me.rank === 2 && j.top[1].you === true, "GET /top avec le rang du joueur");
check(r.headers.get("Access-Control-Allow-Origin") === "*", "CORS ouvert (version web)");
check(seedOk(today) && !seedOk(20200101), "graines acceptées : hier/aujourd'hui/demain");
// semaine et défi des boss
const week = isoWeek(new Date());
[s, j] = await post({ seed: week, diff: 1, player_id: A, name: "Tom", time: 600, ghost: '{"v":1}' }, "8.8.8.8");
check(s === 200 && j.me.rank === 1, "défi de la semaine enregistré");
[s] = await post({ seed: 202001, diff: 1, player_id: A, name: "Tom", time: 600 }, "8.8.8.8");
check(s === 400, "semaine passée refusée");
[s, j] = await post({ seed: 1, diff: 1, player_id: B, name: "Pote", time: 900 }, "8.8.8.9");
check(s === 200 && j.total === 1, "défi des boss enregistré (graine 1)");
let g = await (await worker.fetch(new Request(`https://x/ghost?seed=${week}&diff=1`), env)).json();
check(g.name === "Tom" && g.data === '{"v":1}', "fantôme du premier renvoyé");
[s] = await post({ seed: week, diff: 1, player_id: B, name: "Pote", time: 700, ghost: '{"v":2}' }, "8.8.8.10");
g = await (await worker.fetch(new Request(`https://x/ghost?seed=${week}&diff=1`), env)).json();
check(g.name === "Tom", "le fantôme reste celui du premier");
[s] = await post({ seed: week, diff: 1, player_id: B, name: "Pote", time: 500, ghost: '{"v":3}' }, "8.8.8.10");
g = await (await worker.fetch(new Request(`https://x/ghost?seed=${week}&diff=1`), env)).json();
check(g.name === "Pote" && g.data === '{"v":3}', "nouveau premier : son fantôme le remplace");
g = await (await worker.fetch(new Request(`https://x/ghost?seed=${today}&diff=0`), env)).json();
check(g.none === true, "pas de fantôme : réponse vide");
console.log(fails ? `ÉCHEC (${fails})` : "RÉSULTAT : OK");
process.exit(fails ? 1 : 0);
