// src/module/navigation.js
const common = require('./module/common');

// Cargar la vista inicial por defecto al arrancar la app
document.addEventListener('DOMContentLoaded', () => {
    common.cargarVistaPrecontenido('inicio');

    // Enlace seguro a botones de navegación (si están presentes en el DOM)
    const btnInicio = document.getElementById('btn-inicio');
    if (btnInicio) {
        btnInicio.addEventListener('click', () => {
            common.cargarVistaPrecontenido('inicio');
        });
    }

    const btnConfig = document.getElementById('btn-config');
    if (btnConfig) {
        btnConfig.addEventListener('click', () => {
            common.cargarVistaPrecontenido('configuraciones');
        });
    }
});