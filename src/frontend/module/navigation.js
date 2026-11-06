const common = require('./module/common');

document.addEventListener('DOMContentLoaded', () => {
    // Cargar la vista inicial por defecto al arrancar la app
    common.cargarVistaPrecontenido('inicio');

    // Delegación de eventos global mejorada con .closest()
    document.addEventListener('click', (e) => {
        const actionTarget = e.target.closest('button, [id]');
        if (!actionTarget) return;

        const id = actionTarget.id;

        // Ir a Estadísticas
        if (id === 'btn-nav-stats') {
            common.cargarVistaPrecontenido('estadisticas');
        }
        // Ir a Configuración (desde los menús de Presets o Alarma)
        else if (id === 'menu-presets' || id === 'btn-goto-presets' || id === 'menu-alarma' || id === 'btn-goto-alarma') {
            common.cargarVistaPrecontenido('configuraciones');
        }
        // Ir a Modo Ventana (Popup) en ventana independiente
        else if (id === 'btn-modo-ventana' || id === 'btn-modo-ventana-2' || id === 'btn-modo-ventana-3' || id === 'btn-modo-ventana-4') {
            const { ipcRenderer } = require('electron');
            ipcRenderer.send('open-popup-window');
        }
        // Regresar a Inicio desde Configuración, Estadísticas o Popup
        else if (id === 'btn-back-inicio' || id === 'btn-back-from-stats' || id === 'btn-expand-window') {
            common.cargarVistaPrecontenido('inicio');
        }
    });
});