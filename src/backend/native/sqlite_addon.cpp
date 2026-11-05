#include <napi.h>
#include "sqlite3.h"

class SQLiteNativeWrapper : public Napi::ObjectWrap<SQLiteNativeWrapper> {
public:
    static Napi::Object Init(Napi::Env env, Napi::Object exports) {
        Napi::Function func = DefineClass(env, "SQLiteNativeWrapper", {
            InstanceMethod("exec", &SQLiteNativeWrapper::Exec),
            InstanceMethod("query", &SQLiteNativeWrapper::Query)
        });

        Napi::FunctionReference* constructor = new Napi::FunctionReference();
        *constructor = Napi::Persistent(func);
        env.SetInstanceData(constructor);

        exports.Set("SQLiteNativeWrapper", func);
        return exports;
    }

    SQLiteNativeWrapper(const Napi::CallbackInfo& info) : Napi::ObjectWrap<SQLiteNativeWrapper>(info) {
        Napi::Env env = info.Env();
        std::string dbPath = info[0].As<Napi::String>().Utf8Value();

        int rc = sqlite3_open(dbPath.c_str(), &db);
        if (rc != SQLITE_OK) {
            std::string err = sqlite3_errmsg(db);
            sqlite3_close(db);
            Napi::Error::New(env, "Error al abrir la base de datos: " + err).ThrowAsJavaScriptException();
        }
    }

    ~SQLiteNativeWrapper() {
        if (db) {
            sqlite3_close(db);
        }
    }

private:
    sqlite3* db = nullptr;

    // Método para ejecutar sentencias DDL/DML (CREATE, INSERT, UPDATE, DELETE)
    Napi::Value Exec(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();
        std::string sql = info[0].As<Napi::String>().Utf8Value();

        char* errMsg = nullptr;
        int rc = sqlite3_exec(db, sql.c_str(), nullptr, nullptr, &errMsg);

        if (rc != SQLITE_OK) {
            std::string err(errMsg);
            sqlite3_free(errMsg);
            Napi::Error::New(env, err).ThrowAsJavaScriptException();
            return env.Null();
        }

        return Napi::Boolean::New(env, true);
    }

    // Método para consultas SELECT (retorna un arreglo de objetos JSON con los registros)
    Napi::Value Query(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();
        std::string sql = info[0].As<Napi::String>().Utf8Value();

        sqlite3_stmt* stmt;
        int rc = sqlite3_prepare_v2(db, sql.c_str(), -1, &stmt, nullptr);
        if (rc != SQLITE_OK) {
            Napi::Error::New(env, sqlite3_errmsg(db)).ThrowAsJavaScriptException();
            return env.Null();
        }

        Napi::Array results = Napi::Array::New(env);
        int rowIndex = 0;

        while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
            Napi::Object row = Napi::Object::New(env);
            int cols = sqlite3_column_count(stmt);

            for (int i = 0; i < cols; i++) {
                const char* colName = sqlite3_column_name(stmt, i);
                int colType = sqlite3_column_type(stmt, i);

                switch (colType) {
                    case SQLITE_INTEGER:
                        row.Set(colName, Napi::Number::New(env, sqlite3_column_int64(stmt, i)));
                        break;
                    case SQLITE_FLOAT:
                        row.Set(colName, Napi::Number::New(env, sqlite3_column_double(stmt, i)));
                        break;
                    case SQLITE_TEXT:
                        row.Set(colName, Napi::String::New(env, reinterpret_cast<const char*>(sqlite3_column_text(stmt, i))));
                        break;
                    case SQLITE_BLOB:
                    case SQLITE_NULL:
                    default:
                        row.Set(colName, env.Null());
                        break;
                }
            }
            results.Set(rowIndex++, row);
        }

        sqlite3_finalize(stmt);
        return results;
    }
};

Napi::Object RegisterModule(Napi::Env env, Napi::Object exports) {
    return SQLiteNativeWrapper::Init(env, exports);
}

NODE_API_MODULE(sqlite_native, RegisterModule)