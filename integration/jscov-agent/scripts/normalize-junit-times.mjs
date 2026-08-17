import { readFile, writeFile } from 'node:fs/promises';

const [reportPath] = process.argv.slice(2);

if (!reportPath) {
  throw new Error('Usage: node normalize-junit-times.mjs <report.xml>');
}

const report = await readFile(reportPath, 'utf8');
const normalized = report.replace(/\btime="([^"]*)"/g, (_match, value) => {
  const seconds = Number(value);
  return `time="${(Number.isFinite(seconds) ? seconds : 0).toFixed(3)}"`;
});

await writeFile(reportPath, normalized, 'utf8');
