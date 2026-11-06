// src/backend/index.js
const { app, BrowserWindow, ipcMain, screen } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { isOnIgnoredList } = require('./ignoreKeybinds');
const OFFSET = 0.7;

require('./db_controller');

let mainWindow = null;
let popupWindow = null;

// Ruta estricta sincronizada con el motor de configuración Lua (~/.config/pomodoro-plus-plus/config/)
const getConfigDir = () => {
    return path.join(os.homedir(), '.config', 'pomodoro-plus-plus', 'config');
};

// Funciones auxiliares para gestionar archivos JSON en ~/.config/pomodoro-plus-plus/config/
const loadConfig = (filename) => {
    try {
        const configPath = path.join(getConfigDir(), filename);
        if (fs.existsSync(configPath)) {
            const data = fs.readFileSync(configPath, 'utf8');
            return JSON.parse(data);
        }
    } catch (error) {
        console.error(`Error leyendo la configuración ${filename}:`, error);
    }
    return null;
};

const saveConfig = (filename, content) => {
    try {
        const configDir = getConfigDir();
        if (!fs.existsSync(configDir)) {
            fs.mkdirSync(configDir, { recursive: true });
        }
        const configPath = path.join(configDir, filename);
        fs.writeFileSync(configPath, JSON.stringify(content, null, 2), 'utf8');
    } catch (error) {
        console.error(`Error guardando la configuración ${filename}:`, error);
    }
};

// === MANEJADORES IPC PARA CONFIGURACIONES Y SESIÓN ===

// Tema visual
ipcMain.handle('get-current-theme', () => {
    const themeConfig = loadConfig('theme.json');
    return themeConfig?.mode || 'light';
});

ipcMain.on('set-theme', (_, mode) => {
    saveConfig('theme.json', { mode });
});

// Información de la última sesión (last-session-info.json)
ipcMain.handle('get-last-session', () => {
    return loadConfig('last-session-info.json') || {
        lastCycle: 1,
        totalCycles: 4,
        mode: "Trabajo"
    };
});

ipcMain.on('save-last-session', (_, sessionData) => {
    saveConfig('last-session-info.json', sessionData);
});

// Configuración general de Pomodoro (pomodoro-config.json)
ipcMain.handle('get-pomodoro-config', () => {
    return loadConfig('pomodoro-config.json');
});

// Guardar actualizaciones de configuración o presets
ipcMain.on('save-pomodoro-config', (_, newConfig) => {
    saveConfig('pomodoro-config.json', newConfig);
});

// Función para calcular las coordenadas x, y según la posición configurada
const calculatePopupPosition = (width, height) => {
    const primaryDisplay = screen.getPrimaryDisplay();
    const { width: screenWidth, height: screenHeight } = primaryDisplay.workAreaSize;

    const config = loadConfig('pomodoro-config.json');
    const position = config?.popup?.position || 'bottom-right';
    const margin = config?.popup?.offsetMargin || 20;

    let x = 0;
    let y = 0;

    switch (position) {
        case 'top-left':
            x = margin;
            y = margin;
            break;
        case 'top-right':
            x = screenWidth - width - margin;
            y = margin;
            break;
        case 'bottom-left':
            x = margin;
            y = screenHeight - height - margin;
            break;
        case 'bottom-right':
        default:
            x = screenWidth - width - margin;
            y = screenHeight - height - margin;
            break;
        case 'center-left':
            x = margin;
            y = Math.round((screenHeight - height) / 2);
            break;
        case 'center-right':
            x = screenWidth - width - margin;
            y = Math.round((screenHeight - height) / 2);
            break;
    }

    return { x, y };
};

const currentTheme = loadConfig('theme.json')?.mode || 'light';
const initialBgColor = currentTheme === 'dark' ? '#010101' : '#FFFFFF';

const createWindow = () => {
    mainWindow = new BrowserWindow({
        width: 1565 * OFFSET,
        height: 800 * OFFSET,
        autoHideMenuBar: true,
        roundedCorners: true,
        frame: false,
        backgroundColor: initialBgColor,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    mainWindow.loadFile(path.join(__dirname, '../frontend/index.html'));

    mainWindow.webContents.on('before-input-event', (event, input) => {
        if (isOnIgnoredList(input)) {
            event.preventDefault();
        }
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
    });

    ipcMain.on('window-minimize', () => {
        if (mainWindow && !mainWindow.isDestroyed()) {
            mainWindow.minimize();
        }
    });

    ipcMain.on('window-maximize', () => {
        if (mainWindow && !mainWindow.isDestroyed()) {
            if (mainWindow.isMaximized()) {
                mainWindow.unmaximize();
            } else {
                mainWindow.maximize();
            }
        }
    });

    ipcMain.on('window-close', () => {
        if (mainWindow && !mainWindow.isDestroyed()) {
            mainWindow.close();
        }
    });
};

ipcMain.on('close-popup-window', () => {
    if (popupWindow && !popupWindow.isDestroyed()) {
        popupWindow.close();
    }
});

// === GESTIÓN DE VENTANA FLOTANTE (POPUP) CON POSICIONAMIENTO DINÁMICO ===
ipcMain.on('open-popup-window', () => {
    if (popupWindow) {
        popupWindow.focus();
        return;
    }

    const pomodoroConfig = loadConfig('pomodoro-config.json');
    const popupWidth = pomodoroConfig?.popup?.width || 310;
    const popupHeight = pomodoroConfig?.popup?.height || 210;
    const topmost = pomodoroConfig?.popup?.topmost !== false;

    const { x, y } = calculatePopupPosition(popupWidth, popupHeight);

    popupWindow = new BrowserWindow({
        width: popupWidth,
        height: popupHeight,
        x: x,
        y: y,
        autoHideMenuBar: true,
        frame: false,
        alwaysOnTop: topmost,
        type: 'utility', // 'utility' permite que el gestor de ventanas de Linux respete mejor el modo flotante
        resizable: false,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    if (topmost) {
        popupWindow.setAlwaysOnTop(true, 'floating', 1);
        popupWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
    }

    popupWindow.loadFile(path.join(__dirname, '../frontend/precontenido/popup.html'));

    if (mainWindow && !mainWindow.isDestroyed()) {
        mainWindow.hide();
    }

    popupWindow.on('closed', () => {
        popupWindow = null;
        if (mainWindow && !mainWindow.isDestroyed()) {
            mainWindow.show();
        }
    });
});

app.whenReady().then(() => {
    createWindow();

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit();
});
