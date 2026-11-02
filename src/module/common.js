// src/module/common.js

/**
 * Carga de forma asíncrona un archivo HTML de precontenido dentro de un contenedor del DOM.
 * @param {string} nombreVista - Nombre del archivo sin extensión (ej. 'inicio', 'configuraciones', 'estadisticas')
 * @param {string} contenedorId - ID del contenedor donde se inyectará el HTML (por defecto "root-main")
 */
async function cargarVistaPrecontenido(nombreVista, contenedorId = "root-main") {
    try {
        const response = await fetch(`precontenido/${nombreVista}.html`);
        if (!response.ok) throw new Error(`No se pudo cargar ${nombreVista}.html`);
        
        const html = await response.text();
        const container = document.getElementById(contenedorId);
        
        if (container) {
            container.innerHTML = html;
        } else {
            console.error(`Contenedor con ID '${contenedorId}' no encontrado en el DOM.`);
        }
    } catch (error) {
        console.error('Error al cambiar de vista de precontenido:', error);
    }
}

// Exportar las funciones para reutilizarlas en otros módulos mediante require()
module.exports = {
    cargarVistaPrecontenido
};
