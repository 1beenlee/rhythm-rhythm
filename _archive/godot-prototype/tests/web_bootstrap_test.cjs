// Simulate the injected HTML bootstrap's cache state, independent of a browser.
// Actual browser/service-worker/airplane-mode verification remains manual QA.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const html = fs.readFileSync(process.argv[2] || 'build/web/index.html', 'utf8');
const match = html.match(/<script>\(function\(\)\{const prefix="Rhythm Rhythm-sw-cache-"[\s\S]*?<\/script>/);
assert(match, 'injected offline bootstrap missing from exported HTML');
const js = match[0].replace(/^<script>/, '').replace(/<\/script>$/, '');
const stored = new Set(['index.html','index.js','index.offline.html','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js']);
let online = true;
let added = [];
async function scenario() {
  const callbacks = {};
  const window = {addEventListener(name, fn) { callbacks[name] = fn; }};
  const document = {documentElement: { dataset: {} }};
  const navigator = {serviceWorker: {async register() { return {}; }, ready: Promise.resolve({})}};
  const cache = {
    async match(name) { return stored.has(name) ? {} : undefined; },
    async addAll(names) {
      if (!online) throw new Error('network offline');
      added.push(...names);
      for (const name of names) stored.add(name);
    },
  };
  const caches = {async keys() { return ['Rhythm Rhythm-sw-cache-test']; },async open() { return cache; }};
  window.caches = caches;
  const context = {window,document,navigator,caches,console};
  vm.runInNewContext(js, context);
  await callbacks.load();
  return {ready: window.rhythmOfflineReady, state: document.documentElement.dataset.rhythmOffline};
}
(async () => {
  let result = await scenario();
  assert.equal(result.ready, true);
  for (const file of ['index.wasm','index.pck','index.manifest.json','index.512x512.png']) assert(stored.has(file),file);
  online = false;
  added = [];
  result = await scenario();
  assert.equal(result.ready, true, 'offline boot should use existing complete cache');
  assert.equal(added.length, 0, 'offline boot should not issue network prefetch requests');
  stored.delete('index.pck');
  result = await scenario();
  assert.equal(result.ready, false, 'missing PCK must not claim offline readiness');
  console.log('RhythmWebOfflineBootstrap: PASS (online prime, offline read, missing-pack guard)');
})().catch(err => { console.error(err); process.exitCode = 1; });
