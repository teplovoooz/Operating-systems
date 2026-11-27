#!/bin/sh

if [ "$#" -ne 1 ]; then
    printf '%s\n' "Использование: sh build.sh файл.c" >&2
    exit 2
fi

if [ "${1#/}" = "$1" ]; then
    source=$PWD/$1
else
    source=$1
fi

if [ "${source%.c}" = "$source" ]; then
    printf '%s\n' "Ожидается файл с расширением .c." >&2
    exit 2
fi

if [ ! -f "$source" ] || [ ! -r "$source" ]; then
    printf 'Не удалось открыть исходник: %s\n' "$source" >&2
    exit 2
fi

name=$(
    sed -n 's|^[[:space:]]*//[[:space:]]*Output:[[:space:]]*||p' "$source" |
        head -n 1 |
        sed 's/[[:space:]]*$//'
)

if [ -z "$name" ] || [ "${name#*/}" != "$name" ] ||
   [ "$name" = "." ] || [ "$name" = ".." ] || [ "$name" = "${source##*/}" ]; then
    printf '%s\n' "Укажите допустимое имя в комментарии // Output: имя." >&2
    exit 3
fi

dir=${source%/*}
output=$dir/$name

if ! tmp=$(mktemp -d "$dir/.build.XXXXXXXX"); then
    printf '%s\n' "Не удалось создать временный каталог." >&2
    exit 4
fi

trap 'rm -rf "$tmp"; exit 1' HUP INT QUIT PIPE TERM

(
    cd "$tmp" || exit 1
    export TMPDIR="$tmp"
    cc -o result "$source"
)
compiler_status=$?

status=0
if [ "$compiler_status" -ne 0 ]; then
    printf 'Ошибка сборки (код компилятора %s).\n' "$compiler_status" >&2
    status=5
elif [ -d "$output" ] || ! mv -f "$tmp/result" "$output"; then
    printf 'Не удалось сохранить результат: %s\n' "$output" >&2
    status=6
fi

if ! rm -rf "$tmp"; then
    printf 'Не удалось удалить временный каталог: %s\n' "$tmp" >&2
    if [ "$status" -eq 0 ]; then
        status=7
    fi
fi

if [ "$status" -eq 0 ]; then
    printf 'Сборка завершена: %s\n' "$output"
fi

exit "$status"
