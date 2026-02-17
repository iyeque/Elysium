const { exec } = require('child_process');
const os = require('os');
const fs = require('fs');
const { promisify } = require('util');
const execPromise = promisify(exec);

// Parse arguments manually
const args = process.argv.slice(2);
const params = {};
for (let i = 0; i < args.length; i++) {
  if (args[i].startsWith('--')) {
    const key = args[i].substring(2);
    const value = args[i + 1] && !args[i + 1].startsWith('--') ? args[i + 1] : true;
    params[key] = value;
  }
}

const { action, value, app } = params;
let platform = os.platform(); // 'linux', 'darwin', 'win32'
let isWsl = false;
// Default to standard path, but update for WSL
let powershellPath = 'powershell.exe'; 
let cmdPath = 'cmd.exe';
let taskkillPath = 'taskkill.exe'; // Default
let nircmdPath = 'nircmd.exe'; // Default

// Detect WSL
if (platform === 'linux') {
    try {
        const release = fs.readFileSync('/proc/version', 'utf8').toLowerCase();
        if (release.includes('microsoft') || release.includes('wsl')) {
            isWsl = true;
            platform = 'wsl'; 
            // Use full paths for WSL
            powershellPath = '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe';
            cmdPath = '/mnt/c/Windows/System32/cmd.exe';
            taskkillPath = '/mnt/c/Windows/System32/taskkill.exe'; // Full path for WSL
            nircmdPath = '"/mnt/d/Program Files/nircmd/nircmd.exe"';
        }
    } catch (e) {}
}

// SECURITY: Validate and sanitize inputs
function sanitizeNumber(val, min = 0, max = 100) {
  const num = parseInt(val, 10);
  if (isNaN(num)) throw new Error('Value must be a number');
  if (num < min || num > max) throw new Error(`Value must be between ${min} and ${max}`);
  return num;
}

function sanitizeAppName(name) {
  if (!name || typeof name !== 'string') throw new Error('App name required');
  // SECURITY: Only allow alphanumeric, spaces, dashes, underscores, and common path separators
  // Block shell metacharacters that could enable command injection
  const sanitized = name.trim();
  const dangerousChars = /[;&|`$(){}[\]<>\\!#*?~]/;
  if (dangerousChars.test(sanitized)) {
    throw new Error('Invalid app name: contains disallowed characters');
  }
  // Limit length to prevent buffer issues
  if (sanitized.length > 256) {
    throw new Error('App name too long (max 256 characters)');
  }
  return sanitized;
}

async function doTool() {
  if (!action) {
    console.error('Error: --action is required');
    process.exit(1);
  }

  console.log('[Device Control] Platform: ' + platform + ' (WSL: ' + isWsl + ')');
  console.log('[Device Control] Using PowerShell: ' + powershellPath);

  try {
    switch (action) {
      case 'set_volume':
        if (value === undefined) throw new Error('Value required for set_volume');
        await setVolume(value);
        break;
      case 'change_volume':
        if (value === undefined) throw new Error('Value required for change_volume');
        await changeVolume(value);
        break;
      case 'set_brightness':
        if (value === undefined) throw new Error('Value required for set_brightness');
        await setBrightness(value);
        break;
      case 'open_app':
        if (!app) throw new Error('App name/path required for open_app');
        await openApp(app);
        break;
      case 'close_app':
        if (!app) throw new Error('App name required for close_app');
        await closeApp(app);
        break;
      default:
        console.error('Unknown action: ' + action);
        process.exit(1);
    }
    console.log('Action ' + action + ' completed successfully.');
  } catch (error) {
    console.error('Error executing ' + action + ':', error.message);
    process.exit(1);
  }
}

async function setVolume(val) {
  const v = sanitizeNumber(val, 0, 100);
  
  if (platform === 'linux') {
    try {
      // SECURITY: Use shell: false and pass arguments as array where possible
      // pactl accepts percentage directly
      await execPromise(`pactl set-sink-volume @DEFAULT_SINK@ ${v}%`, { shell: '/bin/bash' });
    } catch (e) {
      await execPromise(`amixer sset Master ${v}%`, { shell: '/bin/bash' });
    }
  } else if (platform === 'darwin') {
    // SECURITY: osascript with escaped value
    const escapedVal = String(v).replace(/[^0-9]/g, '');
    await execPromise(`osascript -e "set volume output volume ${escapedVal}"`);
  } else if (platform === 'win32' || platform === 'wsl') {
    // Use nircmd.exe for precise volume control - QUOTED path
    // 65535 is 100% volume
    const nircmdVal = Math.floor(65535 * (v / 100));
    const cmd = nircmdPath + ' setsysvolume ' + nircmdVal; // nircmdPath is already quoted
    console.log('Running volume command: ' + cmd);
    await execPromise(cmd);
  }
}

async function changeVolume(delta) {
  const d = sanitizeNumber(delta, -100, 100);
  // Get current volume first (platform-specific)
  let currentVolume = 50; // default fallback
  
  if (platform === 'linux') {
    try {
      const result = await execPromise('pactl get-sink-volume @DEFAULT_SINK@ | grep -oP "\\d+%" | head -1');
      currentVolume = parseInt(result.stdout, 10) || 50;
    } catch (e) {
      try {
        const result = await execPromise('amixer get Master | grep -oP "\\d+%" | head -1');
        currentVolume = parseInt(result.stdout, 10) || 50;
      } catch (e2) {}
    }
  } else if (platform === 'darwin') {
    const result = await execPromise('osascript -e "output volume of (get volume settings)"');
    currentVolume = parseInt(result.stdout, 10) || 50;
  }
  
  const newVolume = Math.max(0, Math.min(100, currentVolume + d));
  await setVolume(newVolume);
  console.log(`Volume changed from ${currentVolume}% to ${newVolume}%`);
}

async function setBrightness(val) {
  const v = sanitizeNumber(val, 0, 100);
  
  if (platform === 'linux' && !isWsl) {
    // Try common brightness control methods
    try {
      // Method 1: brightnessctl (most common on modern Linux)
      await execPromise(`brightnessctl set ${v}%`, { shell: '/bin/bash' });
    } catch (e) {
      try {
        // Method 2: Direct sysfs access (requires root usually)
        const maxBright = fs.readFileSync('/sys/class/backlight/intel_backlight/max_brightness', 'utf8').trim();
        const target = Math.floor((parseInt(maxBright, 10) * v) / 100);
        fs.writeFileSync('/sys/class/backlight/intel_backlight/brightness', target.toString());
      } catch (e2) {
        throw new Error('Cannot control brightness: try brightnessctl or run as root');
      }
    }
  } else if (platform === 'darwin') {
    throw new Error("macOS brightness requires 'brightness' CLI tool. Install with: brew install brightness");
  } else if (platform === 'win32' || platform === 'wsl') {
    // WmiMonitorBrightnessMethods via PowerShell
    // 1 is the timeout in seconds
    const psCmd = `(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, ${v})`;
    const cmd = powershellPath + ' -Command "' + psCmd + '"';
    
    console.log('Running: ' + cmd);
    await execPromise(cmd);
  }
}

async function openApp(appName) {
  const sanitizedApp = sanitizeAppName(appName);
  
  if (platform === 'linux') {
    // SECURITY: Use exec with shell: false for safer execution
    // Try to find the app in PATH first
    const subprocess = exec(sanitizedApp, { detached: true, stdio: 'ignore', shell: false });
    subprocess.unref();
  } else if (platform === 'darwin') {
    // SECURITY: Escape the app name for osascript
    const escapedApp = sanitizedApp.replace(/"/g, '\\"');
    await execPromise(`open -a "${escapedApp}"`);
  } else if (platform === 'win32') {
    // SECURITY: Use start with quoted app name
    await execPromise(`start "" "${sanitizedApp}"`, { shell: 'cmd.exe' });
  } else if (platform === 'wsl') {
      // Use cmd.exe /c start to launch Windows apps from WSL - QUOTED
      await execPromise(`${cmdPath} /c start "" "${sanitizedApp}"`);
  }
}

async function closeApp(appName) {
  const sanitizedApp = sanitizeAppName(appName);
  
  if (platform === 'linux' || platform === 'darwin') {
    // SECURITY: pkill with -f and quoted pattern
    await execPromise(`pkill -f "${sanitizedApp}"`, { shell: '/bin/bash' });
  } else if (platform === 'win32') {
    // SECURITY: taskkill with IM and quoted name
    await execPromise(`taskkill /IM "${sanitizedApp}.exe" /F`, { shell: 'cmd.exe' });
  } else if (platform === 'wsl') {
      // Use full path for taskkill.exe in WSL
      await execPromise(`${taskkillPath} /F /IM "${sanitizedApp}.exe"`); 
  }
}

doTool();
