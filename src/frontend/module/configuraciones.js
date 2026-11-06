// src/module/configuraciones.js
const { ipcRenderer } = require('electron');

function initConfigView() {
    const secPresets = document.getElementById('section-presets');
    const secAdaptativos = document.getElementById('section-adaptativos');
    const secAlarma = document.getElementById('section-alarma');

    if (!secPresets) return;

    function ocultarSecConfig() {
        if (secPresets) secPresets.style.display = 'none';
        if (secAdaptativos) secAdaptativos.style.display = 'none';
        if (secAlarma) secAlarma.style.display = 'none';
    }

    const tabPresets = document.getElementById('tab-presets-btn');
    const tabAdaptativos = document.getElementById('tab-adaptativos-btn');
    const tabAlarma = document.getElementById('tab-alarma-btn');

    if (tabPresets) {
        tabPresets.addEventListener('click', () => {
            ocultarSecConfig();
            secPresets.style.display = 'block';
        });
    }
    if (tabAdaptativos) {
        tabAdaptativos.addEventListener('click', () => {
            ocultarSecConfig();
            secAdaptativos.style.display = 'block';
        });
    }
    if (tabAlarma) {
        tabAlarma.addEventListener('click', () => {
            ocultarSecConfig();
            secAlarma.style.display = 'block';
        });
    }

    // Cargar y enlazar datos reales desde last-session-info.json y pomodoro-config.json
    ipcRenderer.invoke('get-last-session').then((session) => {
        if (!session) return;
        const inputCiclos = document.getElementById('input-total-cycles');
        if (inputCiclos) {
            inputCiclos.value = session.totalCycles || 4;
        }
    }).catch(err => console.error('Error al cargar sesión en config:', err));

    ipcRenderer.invoke('get-pomodoro-config').then((config) => {
        if (!config || !config.popup) return;
        // Aquí puedes enlazar más propiedades de configuración si lo requieres
    }).catch(err => console.error('Error al cargar pomodoro-config:', err));
}

module.exports = { initConfigView };