// src/index.js
const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { isOnIgnoredList } = require('./ignoreKeybinds'); // Importado de forma segura en el proceso principal
const OFFSET = 0.7;

const createWindow = () => {
    const mainWindow = new BrowserWindow({
        width: 1565 * OFFSET,
        height: 800 * OFFSET,
        autoHideMenuBar: true,
        roundedCorners: true,
        frame: false,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    mainWindow.loadFile(path.join(__dirname, '../frontend/index.html'));

    // Filtro de seguridad: Interceptar y bloquear atajos colisionantes
    mainWindow.webContents.on('before-input-event', (event, input) => {
        if (isOnIgnoredList(input)) {
            event.preventDefault();
        }
    });

    // Manejadores IPC para la barra de título personalizada
    ipcMain.on('window-minimize', () => {
        mainWindow.minimize();
    });

    ipcMain.on('window-maximize', () => {
        if (mainWindow.isMaximized()) {
            mainWindow.unmaximize();
        } else {
            mainWindow.maximize();
        }
    });

    ipcMain.on('window-close', () => {
        mainWindow.close();
    });
};

app.whenReady().then(() => {
    createWindow();

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit();
});