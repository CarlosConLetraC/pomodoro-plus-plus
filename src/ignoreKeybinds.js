// src/module/ignoreKeybinds.js

// Lista de atajos que deseas bloquear/ignorar
const ignoredShortcuts = [
    'F5',
    'Ctrl+R',
    'Ctrl+T',
    'Ctrl+N',
    'Ctrl+Shift+I',
    'Ctrl+A',
    'Ctrl+Shift+N',
    'F12'
];

/**
 * Analiza si el input actual del teclado coincide con algún atajo de la lista.
 * @param {Object} input - Objeto provisto por Electron (webContents.on('before-input-event'))
 * @returns {boolean} True si debe ignorarse/bloquearse, false de lo contrario.
 */
function isOnIgnoredList(input) {
    // Evaluamos preferentemente en el evento de pulsación (keyDown)
    if (input.type && input.type !== 'keyDown') {
        return false;
    }

    const currentKey = input.key.toUpperCase();

    for (const shortcut of ignoredShortcuts) {
        const parts = shortcut.toUpperCase().split('+');
        const targetKey = parts[parts.length - 1];

        const needsCtrl = parts.includes('CTRL');
        const needsShift = parts.includes('SHIFT');
        const needsAlt = parts.includes('ALT');
        const needsMeta = parts.includes('META') || parts.includes('CMD');

        const matchesKey = currentKey === targetKey || input.code.toUpperCase() === `KEY_${targetKey}`;
        const matchesCtrl = !!input.control === needsCtrl;
        const matchesShift = !!input.shift === needsShift;
        const matchesAlt = !!input.alt === needsAlt;
        const matchesMeta = !!input.meta === needsMeta;

        if (matchesKey && matchesCtrl && matchesShift && matchesAlt && matchesMeta) {
            return true;
        }
    }

    return false;
}

module.exports = {
    isOnIgnoredList
};