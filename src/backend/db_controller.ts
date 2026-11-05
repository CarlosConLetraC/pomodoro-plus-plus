// src/backend/db_controller.ts
import * as path from 'path';
import * as fs from 'fs';
import { app } from 'electron';

// Interfaces tipadas para las operaciones de la base de datos
export interface PomodoroSession {
    id?: number;
    mode: string;
    duration: number;
    created_at?: string;
}

// Interfaz para tipar el wrapper nativo expuesto por C++ (N-API)
interface NativeSQLiteWrapperInstance {
    exec(sql: string): boolean;
    query(sql: string): any[];
}

interface NativeSQLiteWrapperClass {
    new (dbPath: string): NativeSQLiteWrapperInstance;
}

// Ruta al binario nativo compilado por node-gyp
const binaryPath = path.join(__dirname, 'native', 'build', 'Release', 'sqlite_native.node');

if (!fs.existsSync(binaryPath)) {
    console.error(`[FAIL]: No se encontró el binario nativo de SQLite en ${binaryPath}. Ejecute la compilación nativa.`);
}

// Carga segura del módulo nativo C++
const nativeModule = require(binaryPath);
const SQLiteNativeWrapper: NativeSQLiteWrapperClass = nativeModule.SQLiteNativeWrapper;

class DatabaseController {
    private db: NativeSQLiteWrapperInstance;

    constructor(dbFileName: string = 'pomodoro_data.db') {
        const userDataPath = app ? app.getPath('userData') : __dirname;
        const dbPath = path.join(userDataPath, dbFileName);
        
        this.db = new SQLiteNativeWrapper(dbPath);
        this.initSchema();
    }

    private initSchema(): void {
        // Inicialización de esquemas nativos para ciclos y estadísticas
        this.db.exec(`
            CREATE TABLE IF NOT EXISTS pomodoro_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                mode TEXT NOT NULL,
                duration INTEGER NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        `);
    }

    public run(sql: string): boolean {
        return this.db.exec(sql);
    }

    public query<T = any>(sql: string): T[] {
        return this.db.query(sql);
    }

    // Ejemplo de método tipado para insertar sesiones
    public insertSession(mode: string, duration: number): boolean {
        const escapedMode = mode.replace(/'/g, "''");
        const sql = `INSERT INTO pomodoro_sessions (mode, duration) VALUES ('${escapedMode}', ${duration});`;
        return this.run(sql);
    }

    // Ejemplo de método tipado para obtener el historial
    public getSessions(): PomodoroSession[] {
        return this.query<PomodoroSession>('SELECT * FROM pomodoro_sessions ORDER BY created_at DESC;');
    }
}

export default new DatabaseController();
console.log("log generado en typescript.");