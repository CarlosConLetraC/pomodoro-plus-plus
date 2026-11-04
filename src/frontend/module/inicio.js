// src/module/inicio.js

function initTimerView() {
    const stateReposo = document.getElementById('state-reposo');
    const stateCurso = document.getElementById('state-curso');
    const statePausa = document.getElementById('state-pausa');
    const stateDescanso = document.getElementById('state-descanso');
    const modalAlarma = document.getElementById('modal-alarma');

    if (!stateReposo) return;

    function ocultarTodos() {
        if (stateReposo) stateReposo.style.display = 'none';
        if (stateCurso) stateCurso.style.display = 'none';
        if (statePausa) statePausa.style.display = 'none';
        if (stateDescanso) stateDescanso.style.display = 'none';
        if (modalAlarma) modalAlarma.style.display = 'none';
    }

    // Transición: Iniciar (Reposo -> Curso)
    const btnIniciar = document.getElementById('btn-iniciar');
    if (btnIniciar) {
        btnIniciar.addEventListener('click', () => {
            ocultarTodos();
            if (stateCurso) stateCurso.style.display = 'block';
        });
    }

    // Transición: Pausar (Curso -> Pausa)
    const btnPausar = document.getElementById('btn-pausar');
    if (btnPausar) {
        btnPausar.addEventListener('click', () => {
            ocultarTodos();
            if (statePausa) statePausa.style.display = 'block';
        });
    }

    // Transición: Reanudar (Pausa -> Curso)
    const btnReanudar = document.getElementById('btn-reanudar');
    if (btnReanudar) {
        btnReanudar.addEventListener('click', () => {
            ocultarTodos();
            if (stateCurso) stateCurso.style.display = 'block';
        });
    }

    // Simular fin del tiempo al hacer clic en el display (Muestra Modal de Alarma)
    const displayTime = document.getElementById('display-time');
    if (displayTime) {
        displayTime.addEventListener('click', () => {
            if (modalAlarma) modalAlarma.style.display = 'block';
        });
    }

    // Transición desde el modal de alarma a Descanso
    const btnIniciarDescanso = document.getElementById('btn-iniciar-descanso');
    if (btnIniciarDescanso) {
        btnIniciarDescanso.addEventListener('click', () => {
            ocultarTodos();
            if (stateDescanso) stateDescanso.style.display = 'block';
        });
    }

    // Silenciar alarma (cierra el modal)
    const btnSilenciar = document.getElementById('btn-silenciar-alarma');
    if (btnSilenciar) {
        btnSilenciar.addEventListener('click', () => {
            if (modalAlarma) modalAlarma.style.display = 'none';
        });
    }

    // Botones de reinicio / cancelación que devuelven a Reposo
    const resetBtns = [
        'btn-saltar-descanso', 
        'btn-reiniciar-curso', 
        'btn-cancelar-curso', 
        'btn-reiniciar-pausa', 
        'btn-cancelar-pausa'
    ];
    
    resetBtns.forEach(id => {
        const btn = document.getElementById(id);
        if (btn) {
            btn.addEventListener('click', () => {
                ocultarTodos();
                if (stateReposo) stateReposo.style.display = 'block';
            });
        }
    });

    // Desplegable del engrane de ajustes
    const gearBtn = document.getElementById('btn-settings-gear');
    const settingsMenu = document.getElementById('settings-menu');
    if (gearBtn && settingsMenu) {
        gearBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            settingsMenu.style.display = settingsMenu.style.display === 'block' ? 'none' : 'block';
        });

        // Ocultar menú al hacer clic fuera
        document.addEventListener('click', () => {
            settingsMenu.style.display = 'none';
        });
    }

    // Establecer un tema por defecto si no existe
    if (!document.body.classList.contains('light-mode') && !document.body.classList.contains('dark-mode')) {
        document.body.classList.add('light-mode');
    }

    // Toggle explícito entre light-mode y dark-mode
    const btnToggleDark = document.getElementById('btn-toggle-dark');
    if (btnToggleDark) {
        btnToggleDark.addEventListener('click', () => {
            if (document.body.classList.contains('dark-mode')) {
                document.body.classList.remove('dark-mode');
                document.body.classList.add('light-mode');
            } else {
                document.body.classList.remove('light-mode');
                document.body.classList.add('dark-mode');
            }
        });
    }
}

module.exports = { initTimerView };