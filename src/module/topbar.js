// src/module/topbar.js

class TopBar {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        this.init();
    }

    async init() {
        if (!this.container) return;

        try {
            // Carga el esqueleto HTML físico desde precontenido/
            const response = await fetch('precontenido/topbar.html');
            if (!response.ok) throw new Error('No se pudo cargar topbar.html');
            
            const htmlContent = await response.text();
            this.container.innerHTML = htmlContent;

            // Enlazar eventos una vez inyectado el HTML en el DOM
            this.attachEvents();
        } catch (error) {
            console.error('Error al inicializar la TopBar:', error);
        }
    }

    attachEvents() {
        const minBtn = document.getElementById('tb-min');
        const maxBtn = document.getElementById('tb-max');
        const closeBtn = document.getElementById('tb-close');

        const { ipcRenderer } = require('electron');

        if (minBtn) {
            minBtn.addEventListener('click', () => {
                ipcRenderer.send('window-minimize');
            });
        }
        if (maxBtn) {
            maxBtn.addEventListener('click', () => {
                ipcRenderer.send('window-maximize');
            });
        }
        if (closeBtn) {
            closeBtn.addEventListener('click', () => {
                ipcRenderer.send('window-close');
            });
        }
    }

    setTitle(newTitle) {
        const titleEl = document.getElementById('topbar-title-text');
        if (titleEl) {
            titleEl.textContent = newTitle;
        }
    }
}

// Inicialización automática al cargar el DOM
document.addEventListener('DOMContentLoaded', () => {
    window.appTopBar = new TopBar('root-header');
});