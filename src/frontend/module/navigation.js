// src/module/navigation.js
const common = require('./module/common');

document.addEventListener('DOMContentLoaded', () => {
    // Cargar la vista inicial por defecto al arrancar la app
    common.cargarVistaPrecontenido('inicio');

    // Delegación de eventos global para los cambios de vista
    document.addEventListener('click', (e) => {
        const target = e.target;
        if (!target) return;

        // Ir a Estadísticas
        if (target.id === 'btn-nav-stats') {
            common.cargarVistaPrecontenido('estadisticas');
        }
        // Ir a Configuración (desde los menús de Presets o Alarma)
        else if (target.id === 'menu-presets' || target.id === 'btn-goto-presets' || target.id === 'menu-alarma' || target.id === 'btn-goto-alarma') {
            common.cargarVistaPrecontenido('configuraciones');
        }
        // Ir a Modo Ventana (Popup)
        else if (target.id === 'btn-modo-ventana' || target.id === 'btn-modo-ventana-2' || target.id === 'btn-modo-ventana-3' || target.id === 'btn-modo-ventana-4') {
            common.cargarVistaPrecontenido('popup');
        }
        // Regresar a Inicio desde Configuración, Estadísticas o Popup
        else if (target.id === 'btn-back-inicio' || target.id === 'btn-back-from-stats' || target.id === 'btn-expand-window') {
            common.cargarVistaPrecontenido('inicio');
        }
    });
});