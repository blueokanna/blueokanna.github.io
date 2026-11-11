import {readdir, readFile, writeFile, mkdir, copyFile} from 'node:fs/promises';
import {existsSync} from 'node:fs';
import {fileURLToPath, pathToFileURL} from 'node:url';
import path from 'node:path';
import {createHash} from 'node:crypto';
import puppeteer from 'puppeteer';
import {renderMermaid} from '@mermaid-js/mermaid-cli';

const root = fileURLToPath(new URL('../', import.meta.url));
const source = path.join(root, 'content/diagrams');
const output = path.join(root, 'assets/diagrams');
await mkdir(output, {recursive: true});
const cache = path.join(root, '.cache');
await mkdir(cache, {recursive: true});
let fontCSS = await readFile(path.join(root, 'scripts/diagram-fonts.css'), 'utf8');
for (const match of [...fontCSS.matchAll(/url\('([^']+)'\)/g)]) {
  const bytes = await readFile(path.resolve(root, 'scripts', match[1]));
  fontCSS = fontCSS.replace(match[0], `url('data:font/ttf;base64,${bytes.toString('base64')}')`);
}
const fontFile = path.join(cache, 'diagram-fonts.css');
await writeFile(fontFile, fontCSS);
const executablePath = process.env.PUPPETEER_EXECUTABLE_PATH || [
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  '/usr/bin/google-chrome', '/usr/bin/chromium',
].find(existsSync);
const browser = await puppeteer.launch({headless: true, executablePath,
  // The isolated CI container may run without a user namespace sandbox.
  args: process.env.CI ? ['--no-sandbox'] : [],
});
try {
  for (const filename of (await readdir(source)).filter(name => name.endsWith('.mmd')).sort()) {
    if (!/^[a-z-]+-(zh-CN|zh-TW|en|ja|de|fr|es|ru|pt|it)\.mmd$/.test(filename)) {
      throw new Error(`Invalid diagram filename: ${filename}`);
    }
    const definition = await readFile(path.join(source, filename), 'utf8');
    const hash = createHash('sha256').update(definition).digest('hex');
    await copyFile(path.join(source, filename), path.join(output, filename));
    for (const mode of ['light', 'dark']) {
      const dark = mode === 'dark';
      const {data} = await renderMermaid(browser, definition, 'png', {
        backgroundColor: 'transparent', fontEmbed: false,
        viewport: {width: 1100, height: 900, deviceScaleFactor: 2},
        customFontCSS: [{cssUrl: pathToFileURL(fontFile)}],
        mermaidConfig: {securityLevel: 'strict', startOnLoad: false,
          theme: 'base', look: 'classic', htmlLabels: false,
          fontFamily: filename.includes('-ja.') ? 'Google Sans, Noto Sans JP, sans-serif'
            : filename.includes('-zh-TW.') ? 'Google Sans, Noto Sans TC, sans-serif' : 'Google Sans, Noto Sans SC, sans-serif',
          flowchart: {htmlLabels: false, curve: 'basis', padding: 20, nodeSpacing: 32, rankSpacing: 44},
          themeVariables: {darkMode: dark, fontSize: '17px',
            primaryColor: dark ? '#284f37' : '#d3eac8',
            primaryTextColor: dark ? '#e0efdb' : '#18351f',
            primaryBorderColor: dark ? '#8aaa80' : '#5b7655',
            lineColor: dark ? '#b7cdb1' : '#4c6446',
            secondaryColor: dark ? '#244e50' : '#ceefed',
            tertiaryColor: dark ? '#3a4434' : '#e7edde',
            edgeLabelBackground: dark ? '#1a241c' : '#f1f5ec'},
        },
      });
      await writeFile(path.join(output, filename.replace('.mmd', `-${mode}.png`)), data);
    }
    console.log(`${filename}: light + dark (${hash.slice(0, 12)})`);
  }
} finally { await browser.close(); }
