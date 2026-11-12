#!/usr/bin/env bash
set -euo pipefail
source common.sh
OLD_PWD="${PWD}"

#if [ ! -f "/usr/bin/luajit" ] || ! luajit -v | grep -q "2.1.178"; then
if [ ! -f "/usr/bin/luajit" ] || ! { 
    version=$(luajit -v 2>&1 | awk '{print $2}')
    [ "$(printf '%s\n' "2.1.178" "$version" | sort -V | head -n1)" = "2.1.178" ]
}; then
	prettyprint 0 "Compilando la versión más reciente de LuaJIT desde la fuente oficial. . ."
	cd /tmp
	git clone https://github.com/LuaJIT/LuaJIT.git
	cd LuaJIT
	make PREFIX=/usr
	sudo make install PREFIX=/usr
	cd /tmp
	rm -rf LuaJIT
    cd $OLD_PWD
fi
