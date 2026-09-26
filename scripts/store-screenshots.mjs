// App Store screenshots from the Flutter web build in SCREENSHOT_MODE
// (flutter build web --dart-define=SCREENSHOT_MODE=true -o build/web-shots).
// Usage: node scripts/store-screenshots.mjs <baseUrl> [outDir] [lang,lang...]
// Output: <outDir>/<device>/<lang>/<n>-<screen>.png
import { createRequire } from 'node:module'
import { mkdir } from 'node:fs/promises'

const require = createRequire(process.env.PLAYWRIGHT_FROM || import.meta.url)
const { chromium } = require('playwright-core')

const base = process.argv[2] || 'http://127.0.0.1:8765/'
const outDir = process.argv[3] || 'store/screenshots'
const LANGS = ['it', 'en', 'fr', 'de', 'es', 'pt', 'nl', 'pl', 'ro', 'sv', 'ru', 'uk', 'tr', 'ar', 'zh', 'ja']
const only = process.argv[4] ? process.argv[4].split(',') : LANGS

// iPhone 6.7" (1290x2796) and iPad Pro 12.9" (2048x2732).
const DEVICES = {
  iphone: { viewport: { width: 430, height: 932 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true },
  ipad: { viewport: { width: 1024, height: 1366 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true },
}
const SCREENS = [
  ['1-protection', 'tab=0'],
  ['2-lookup', 'tab=1'],
  ['3-report', 'tab=0&sheet=report'],
  ['4-lists', 'tab=2'],
  ['5-settings', 'tab=3'],
]

const browser = await chromium.launch({ channel: 'chrome' })
for (const [device, options] of Object.entries(DEVICES)) {
  for (const lang of only) {
    const dir = `${outDir}/${device}/${lang}`
    await mkdir(dir, { recursive: true })
    const context = await browser.newContext({ ...options, locale: lang, colorScheme: 'light' })
    const page = await context.newPage()
    for (const [name, query] of SCREENS) {
      await page.goto(`${base}?lang=${lang}&${query}`, { waitUntil: 'networkidle' })
      await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 30000 })
      await page.waitForTimeout(3500) // fonts for non-Latin scripts + sheet animation
      await page.screenshot({ path: `${dir}/${name}.png` })
    }
    await context.close()
    console.log(device, lang, 'ok')
  }
}
await browser.close()
