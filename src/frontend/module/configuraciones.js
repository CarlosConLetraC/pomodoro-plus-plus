// src/module/configuraciones.js

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
}

module.exports = { initConfigView };