import { readFile, writeFile } from 'node:fs/promises';

const [reportPath] = process.argv.slice(2);

if (!reportPath) {
  throw new Error('Usage: node normalize-junit-times.mjs <report.xml>');
}

const report = await readFile(reportPath, 'utf8');
const normalized = report.replace(/\btime="([0-9]+(?:\.[0-9]+)?)"/g, (_match, value) => {
  const seconds = Number(value);
  return `time="${seconds.toFixed(3)}"`;
});

await writeFile(reportPath, normalized, 'utf8');
