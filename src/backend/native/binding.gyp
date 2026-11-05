{
  "targets": [
    {
      "target_name": "sqlite_native",
      "sources": [
        "sqlite_addon.cpp",
        "sqlite-src/sqlite3.c"
      ],
      "include_dirs": [
        "sqlite-src",
        "../../../node_modules/node-addon-api"
      ],
      "defines": [
        "SQLITE_THREADSAFE=1",
        "SQLITE_ENABLE_FTS5=1",
        "NAPI_DISABLE_CPP_EXCEPTIONS"
      ],
      "cflags!": [ "-fno-exceptions" ],
      "cflags_cc!": [ "-fno-exceptions" ]
    }
  ]
}
