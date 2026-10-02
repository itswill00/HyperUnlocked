<!--
# Copyright (C) 2025-2026 ukriu (Contact: contact@ukriu.com)
# Tanzanite variant port by @noticesa
# Read LICENSE_NOTICE.txt for further info.
#
# Vue 3 port of the classic WebUI: same commands, same strings, same
# Material You theme — only the foundation changed (no more separate
# index.js / stylesheets; everything builds into one file).
-->
<template>
  <main :class="{ blurred: modal.visible && modal.blur }">
    <section class="header card" @click="onTitleClick">
      <h1 class="title">Tanzanite-HyperUnlocked</h1>
      <p class="subtitle">{{ subtitle }}</p>
      <p class="tagline">{{ tagline }}</p>
      <div v-if="pendingConfig" class="warning-banner">
        There are unapplied changes queued. Press <strong>Apply staged settings</strong> to commit them.
      </div>
    </section>

    <section class="card">
      <h2>Settings</h2>

      <div class="row">
        <div>
          <div class="row-title">Device level list</div>
          <div class="row-description">Choose level from v:1,c:1,g:1 to v:1,c:3,g:3.</div>
        </div>
        <select class="select" :value="deviceLevelValue" @change="onDeviceLevelChange">
          <option v-for="opt in deviceLevelOptions" :key="opt.value" :value="opt.value">
            {{ opt.label }}
          </option>
        </select>
      </div>

      <div class="row">
        <div>
          <div class="row-title">System blur</div>
          <div class="row-description">Enable/disable blur related props.</div>
        </div>
        <input class="switch" type="checkbox" :checked="flags.blur" @change="onToggle('blur', $event)">
      </div>

      <div class="row">
        <div>
          <div class="row-title">High-End mode props</div>
          <div class="row-description">Enable/disable high-end related props.</div>
        </div>
        <input class="switch" type="checkbox" :checked="flags.highend" @change="onToggle('highend', $event)">
      </div>

      <div class="row">
        <div>
          <div class="row-title">Screenshot blur overlay</div>
          <div class="row-description">Toggle screenshot blur overlay package.</div>
        </div>
        <input class="switch" type="checkbox" :checked="flags.screenshot_blur" @change="onToggle('screenshot_blur', $event)">
      </div>

      <div class="row">
        <div>
          <div class="row-title">LEICA Camera Spoof</div>
          <div class="row-description">Spoof camera app to be LEICA branded. (Requires Camera v6.4.*)</div>
        </div>
        <input class="switch" type="checkbox" :checked="flags.leica" @change="onToggle('leica', $event)">
      </div>

      <div class="row">
        <div>
          <div class="row-title">Enable Dynamic Island</div>
          <div class="row-description">Enables Dynamic Island. (Requires HyperOS 3+)</div>
        </div>
        <input class="switch" type="checkbox" :checked="flags.island" @change="onToggle('island', $event)">
      </div>

      <div class="button-group">
        <button class="btn-primary" @click="executeShell('sh webui.sh apply')">Apply staged settings</button>
        <button class="btn-danger" @click="executeShell('sh webui.sh clear')">Clear staged settings</button>
        <button class="btn-danger" @click="executeShell('sh webui.sh soft_restart')">Soft Restart (Only for props)</button>
      </div>

      <p class="hint">Staged values are stored in <code>/data/adb/Tanzanite-HyperUnlocked/config</code> until you press Apply.</p>
    </section>

    <section class="card">
      <h2>Terminal</h2>
      <div ref="terminalEl" class="terminal">
        <div v-for="(line, i) in terminal" :key="i" :class="['terminal-line', line.type]">{{ line.text }}</div>
      </div>
      <h3>Debug</h3>
      <div class="button-group">
        <button class="btn-danger" @click="executeShell('reboot')">Reboot Device</button>
        <button class="btn-tonal" @click="executeShell('cat /data/adb/Tanzanite-HyperUnlocked/config 2>/dev/null || echo No staged config')">Show staged config</button>
        <button class="btn-tonal" @click="executeShell('sh webui.sh status')">Show current status</button>
        <button class="btn-danger" @click="terminal.length = 0">Clear terminal view</button>
      </div>
    </section>

    <section class="card">
      <h2>Extra</h2>
      <div class="button-group">
        <button class="btn-danger" @click="executeShell('sh webui.sh extra_tiles all')">Add ALL additional QS tiles</button>
        <button class="btn-tonal" @click="executeShell('sh webui.sh extra_tiles custom mictoggle')">Add Mic Toggle tile</button>
        <button class="btn-tonal" @click="executeShell('sh webui.sh extra_tiles custom cameratoggle')">Add Camera Toggle tile</button>
        <button class="btn-tonal" @click="executeShell('sh webui.sh extra_tiles custom reduce_brightness')">Add Extra Dim tile</button>
        <button class="btn-tonal" @click="executeShell('sh webui.sh extra_tiles custom saver')">Add Data Saver tile</button>
        <button class="btn-tonal" @click="executeShell('sh webui.sh extra_tiles custom taplus_tile')">Add taplus tile</button>
      </div>
      <p class="hint">Some of these will only work in global versions, CN needs testing.</p>
    </section>
  </main>

  <div v-if="modal.visible" class="modal-backdrop" role="dialog" aria-modal="true" @click.self="closeWarningModal(false)">
    <div class="modal card">
      <h3 class="modal-title">{{ modal.title }}</h3>
      <p class="modal-description">{{ modal.description }}</p>
      <div class="button-group modal-actions">
        <button class="btn-tonal" @click="closeWarningModal(false)">Cancel</button>
        <button class="btn-primary" @click="closeWarningModal(true)">OK</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, nextTick } from 'vue'

const MODULE_DIR = '/data/adb/modules/Tanzanite-HyperUnlocked'
const SHELL_PATH = '/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH'
const DEFAULT_DEVICE_LEVEL_LIST_FILE = '/data/adb/Tanzanite-HyperUnlocked/default_deviceLevelList.txt'
const DEVICE_LEVEL_REGEX = /v:\d+,c:\d+,g:\d+/g
const DEVICE_LEVELS = [
  'v:1,c:1,g:1', 'v:1,c:1,g:2', 'v:1,c:1,g:3',
  'v:1,c:2,g:1', 'v:1,c:2,g:2', 'v:1,c:2,g:3',
  'v:1,c:3,g:1', 'v:1,c:3,g:2', 'v:1,c:3,g:3',
]

const COMMAND_WARNINGS = [
  {
    pattern: /^sh\s+webui\.sh\s+set\s+leica\s+true$/,
    title: 'Warning',
    description: 'LEICA Camera Spoof only works if your camera is the latest version (v6.4 and above).\nThis feature has only been tested on Xiaomi 17 Series and WILL clear camera app data.\nContinue?',
  },
  {
    pattern: /^reboot$/,
    title: 'Warning',
    description: 'Your device WILL reboot.',
  },
  {
    pattern: /^sh\s+webui\.sh\s+soft_restart$/,
    title: 'Info',
    description: 'This will restart all apps which are modified with system props, hence avoiding a full device restart.',
  },
]

// --- shell bridge (KernelSU ksu.exec, MMRL exec() fallback) ---
let callbackCounter = 0
function bridgeExec(command, options = {}) {
  return new Promise((resolve, reject) => {
    const name = `exec_callback_${Date.now()}_${callbackCounter++}`
    window[name] = (errno, stdout, stderr) => {
      resolve({ errno, stdout, stderr })
      delete window[name]
    }
    try {
      if (typeof ksu !== 'undefined' && typeof ksu.exec === 'function') {
        ksu.exec(command, JSON.stringify(options), name)
      } else if (typeof exec === 'function') {
        exec(command).then((r) => {
          if (r && typeof r === 'object') {
            resolve({ errno: r.errno ?? 0, stdout: r.stdout || '', stderr: r.stderr || '' })
          } else {
            resolve({ errno: 0, stdout: String(r ?? ''), stderr: '' })
          }
          delete window[name]
        }).catch((e) => {
          delete window[name]
          reject(e)
        })
      } else {
        resolve({ errno: 1, stdout: '', stderr: 'ksu is not defined' })
        delete window[name]
      }
    } catch (e) {
      delete window[name]
      reject(e)
    }
  })
}

function toast(message) {
  if (typeof ksu !== 'undefined' && typeof ksu.toast === 'function') {
    ksu.toast(message)
  } else {
    console.log(message)
  }
}

// --- state ---
const status = ref({})
const defaultDeviceLevels = ref(new Set())
const terminal = ref([])
const terminalEl = ref(null)
const pendingConfig = ref(false)
const modal = reactive({ visible: false, blur: false, title: '', description: '', resolver: null })

const subtitle = computed(() => {
  const s = status.value
  if (s.version && s.versionCode) return `${s.version} (${s.versionCode})`
  if (s.version) return s.version
  return 'Version unavailable'
})

const tagline = computed(() => {
  const s = status.value
  const base = 'High-end features for Redmi Note 14 4G (tanzanite)'
  if (s['device.codename'] && s['device.os']) return `${base} · ${s['device.codename']} · ${s['device.os']}`
  return base
})

function isTrue(value) {
  return String(value).toLowerCase() === 'true'
}

function effective(key) {
  const s = status.value
  const pending = `pending.${key}`
  if (Object.prototype.hasOwnProperty.call(s, pending)) return s[pending]
  return s[`current.${key}`]
}

const flags = computed(() => ({
  blur: isTrue(effective('blur')),
  highend: isTrue(effective('highend')),
  screenshot_blur: isTrue(effective('screenshot_blur')),
  leica: isTrue(effective('leica')),
  island: isTrue(effective('island')),
}))

const deviceLevelOptions = computed(() =>
  DEVICE_LEVELS.map((v) => ({
    value: v,
    label: defaultDeviceLevels.value.has(v) ? `${v} (Default)` : v,
  }))
)

const deviceLevelValue = computed(() => {
  const s = status.value
  let v = effective('device_level') || s['current.device_level'] || ''
  if (v === 'default') {
    const first = Array.from(defaultDeviceLevels.value)[0]
    v = first || s['current.device_level'] || ''
  }
  return DEVICE_LEVELS.includes(v) ? v : ''
})

// --- terminal ---
function scrollTerminal() {
  nextTick(() => {
    const el = terminalEl.value
    if (el) el.scrollTop = el.scrollHeight
  })
}

function appendLine(text, type = '') {
  terminal.value.push({ text, type })
  scrollTerminal()
}

function appendChunk(chunk, type = '') {
  const normalized = String(chunk || '').replace(/\r/g, '')
  if (!normalized) return
  normalized.split('\n').forEach((line) => {
    if (line !== '') appendLine(line, type)
  })
}

// --- commands ---
function buildCommand(command) {
  return `if [ -d "${MODULE_DIR}" ]; then cd "${MODULE_DIR}"; fi; ${command}`
}

function normalizeCommand(command) {
  return String(command || '').trim().replace(/\s+/g, ' ')
}

async function runShellCommand(command, { silent = false } = {}) {
  if (!command || typeof command !== 'string') {
    if (!silent) appendLine('[js] Invalid command', 'error')
    return { errno: 1, stdout: '', stderr: 'Invalid command' }
  }

  if (!silent) appendLine(`$ ${command}`, 'command')

  try {
    const { errno, stdout, stderr } = await bridgeExec(buildCommand(command), {
      env: { PATH: SHELL_PATH },
    })

    if (!silent) {
      appendChunk(stdout)
      appendChunk(stderr, 'error')
      if (errno !== 0) appendLine(`[exit ${errno}]`, 'error')
    }

    if (errno !== 0) toast(`Command exited with ${errno}`)
    return { errno, stdout, stderr }
  } catch (error) {
    const message = error?.message || String(error)
    if (!silent) appendLine(`[js] ${message}`, 'error')
    toast('Unexpected JS error')
    return { errno: 1, stdout: '', stderr: message }
  }
}

function parseStatus(stdout = '') {
  const parsed = {}
  String(stdout)
    .replace(/\r/g, '')
    .split('\n')
    .forEach((line) => {
      const idx = line.indexOf('=')
      if (idx <= 0) return
      const key = line.slice(0, idx).trim()
      const value = line.slice(idx + 1).trim()
      if (key) parsed[key] = value
    })
  return parsed
}

function applyStatus(stdout) {
  if (typeof stdout !== 'string') return
  status.value = parseStatus(stdout)
  pendingConfig.value = isTrue(status.value['pending.config'])
}

function parseDeviceLevelList(text = '') {
  return new Set(String(text).match(DEVICE_LEVEL_REGEX) || [])
}

async function refreshStatus({ silent = true } = {}) {
  const dl = await runShellCommand(`cat ${DEFAULT_DEVICE_LEVEL_LIST_FILE} 2>/dev/null || true`, { silent: true })
  defaultDeviceLevels.value = parseDeviceLevelList(dl.stdout)
  const result = await runShellCommand('sh webui.sh status', { silent })
  if (result && typeof result.stdout === 'string') applyStatus(result.stdout)
  return result
}

function shouldAutoRefreshStatus(command) {
  return /^sh\s+webui\.sh\s+(set|apply|clear)\b/.test(normalizeCommand(command))
}

function isStatusCommand(command) {
  return /^sh\s+webui\.sh\s+status\b/.test(normalizeCommand(command))
}

function getCommandWarning(command) {
  return COMMAND_WARNINGS.find((rule) => rule.pattern.test(normalizeCommand(command)))
}

function closeWarningModal(confirmed) {
  modal.visible = false
  modal.blur = false
  const resolver = modal.resolver
  modal.resolver = null
  if (resolver) resolver(Boolean(confirmed))
}

function showWarningModal({ title, description }) {
  if (modal.resolver) {
    modal.resolver(false)
    modal.resolver = null
  }
  modal.title = title
  modal.description = description
  modal.visible = true
  modal.blur = true
  return new Promise((resolve) => {
    modal.resolver = resolve
  })
}

async function executeShell(command, source = null) {
  const warning = getCommandWarning(command)

  if (warning) {
    const confirmed = await showWarningModal(warning)
    if (!confirmed) {
      if (source && source.type === 'checkbox') source.checked = !source.checked
      return { errno: 130, stdout: '', stderr: 'Cancelled by user' }
    }
  }

  const result = await runShellCommand(command, { silent: false })

  if (isStatusCommand(command) && result && typeof result.stdout === 'string') {
    applyStatus(result.stdout)
    return result
  }

  if (shouldAutoRefreshStatus(command)) {
    await refreshStatus({ silent: true })
  }

  return result
}

async function onToggle(setting, event) {
  const checked = !!event?.target?.checked
  await executeShell(
    `sh webui.sh set ${setting} ${checked ? 'true' : 'false'}`,
    event?.target || null,
  )
}

async function onDeviceLevelChange(event) {
  await executeShell(`sh webui.sh set device_level ${event.target.value}`)
}

// title easter egg: 4 clicks -> about dialog
let titleClickCount = 0
let titleClickTimer = null

function onTitleClick() {
  titleClickCount++
  clearTimeout(titleClickTimer)

  if (titleClickCount >= 4) {
    titleClickCount = 0
    showWarningModal({
      title: 'Hello there!',
      description: 'Tanzanite-HyperUnlocked by @noticesa\nBased on HyperUnlocked by ukriu',
    })
    return
  }

  titleClickTimer = setTimeout(() => {
    titleClickCount = 0
  }, 1000)
}

onMounted(async () => {
  appendLine('[-] Tanzanite-HyperUnlocked WebUI ready.')
  appendLine(`[-] Working directory: ${MODULE_DIR}`)
  await refreshStatus({ silent: false })
})
</script>
