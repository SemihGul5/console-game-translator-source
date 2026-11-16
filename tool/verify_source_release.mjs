import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const generated = new Set(['build', '.dart_tool', '.gradle', '.cxx', '.kotlin', '.idea', 'node_modules', '__pycache__', '.buildResult', 'output']);
const problems = [];
const testKeyFiles = new Set(['test/fixtures/tv_tls/a-key.pem', 'test/fixtures/tv_tls/b-key.pem']);
function list(folder) {
  return fs.readdirSync(folder, { withFileTypes: true }).flatMap(entry => {
    const absolute = path.join(folder, entry.name);
    if (entry.isSymbolicLink()) { problems.push({ path: path.relative(root, absolute), reason: 'unexpected symlink' }); return []; }
    if (entry.name === '.git') return [];
    if (entry.isDirectory()) return generated.has(entry.name) ? [] : list(absolute);
    return [absolute];
  });
}
const files = list(root);
for (const file of files) {
  const relative = path.relative(root, file).replaceAll('\\', '/');
  if (/(^|\/)(key|access|appcheck-debug|local)\.properties$|(^|\/)google-services\.json$|\.(jks|keystore|p12|pfx|apk|aab|apks)$|(^|\/)\.env(?:\.|$)|(^|\/)\.dev\.vars/.test(relative)) {
    problems.push({ path: relative, reason: 'local credentials/configuration or built package in source release' });
  }
  const bytes = fs.readFileSync(file);
  // Upstream source fixtures have their own public test keys/data. Local test
  // keys are explicitly identified above. Never whitelist production credentials.
  if (relative.startsWith('third_party/') || relative.startsWith('chiaki-native/third-party/')) continue;
  if (bytes.includes(0) || /\.(zip|png|jpg|ttf|jar)$/.test(relative)) continue;
  const text = bytes.toString('utf8');
  if (/-----BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----/.test(text) && !testKeyFiles.has(relative)) {
    problems.push({ path: relative, reason: 'unexpected private key material' });
  }
  const patterns = [
    ['Google API key', /AIza[0-9A-Za-z_-]{35}/g],
    ['GitHub token', /(?:gh[pousr]_[0-9A-Za-z]{30,}|github_pat_[0-9A-Za-z_]{50,})/g],
    ['AWS access key', /(?:AKIA|ASIA)[0-9A-Z]{16}/g],
    ['payment secret', /sk_(?:live|test)_[0-9A-Za-z]{16,}/g],
    ['embedded SDK key', /goog_[0-9A-Za-z]{16,}/g],
    ['JWT credential', /eyJ[0-9A-Za-z_-]{10,}\.[0-9A-Za-z_-]{10,}\.[0-9A-Za-z_-]{20,}/g],
  ];
  for (const [reason, pattern] of patterns) {
    if (pattern.test(text)) problems.push({ path: relative, reason });
  }
}
const sumsFile = path.join(root, 'release/SHA256SUMS');
if (!fs.existsSync(sumsFile)) problems.push({ reason: 'missing integrity inventory' });
else for (const line of fs.readFileSync(sumsFile, 'utf8').trim().split('\n')) {
  const match = /^([a-f0-9]{64})  (.+)$/.exec(line.trimEnd());
  if (!match) { problems.push({ reason: 'malformed integrity inventory' }); continue; }
  const file = path.resolve(root, match[2]);
  if (!file.startsWith(root + path.sep) || !fs.existsSync(file) || sha256(fs.readFileSync(file)) !== match[1]) {
    problems.push({ path: match[2], reason: 'missing or changed inventoried file' });
  }
}
const archive = path.join(root, 'third_party/archives/openssl-1.1.1w.tar.gz');
if (!fs.existsSync(archive) || sha256(fs.readFileSync(archive)) !== 'cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8') {
  problems.push({ reason: 'OpenSSL source archive missing or hash mismatch' });
}
const status = JSON.parse(fs.readFileSync(path.join(root, 'release/publication.json'), 'utf8'));
console.log(JSON.stringify({
  filesChecked: files.length,
  integrityAndPatternScanPassed: problems.length === 0,
  publicationStatus: status.status,
  releaseReady: Boolean(status.binarySourcePairingVerified && status.legalNoticesVerified && status.mlKitCombinedDistributionBasis && status.matchingSourceArchiveUrl),
  knownNonProductionTlsFixtures: [...testKeyFiles],
  problems,
}, null, 2));
if (problems.length) process.exitCode = 1;
