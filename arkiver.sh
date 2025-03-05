#!/bin/sh

# A general, all-purpose extraction script. Not all extraction programs here
# are installed by LARBS automatically.
#
# Default behavior: Extract archive into new directory
# Behavior with `-c` option: Extract contents into current directory

myname="${0##*/}"

# dir from which the script was called
workdir="$PWD"
# if the archive should be extracted in workdir
extracthere=""
# archive password
pass=""

# usage: die "message"
die() {
    [ -n "$1" ] && printf '%s:%s\n' "$myname" "$*" >&2;
    exit 1
}

# return type: string
#       usage: show_usage [code] [message]
#        code: int, if provided will exit the script with the code
#     message: string to display at exit as "prog_name: message"
show_usage () {
    if [ -n "$2" ]; then
        printf '%s: %s\n' "$myname" "$2"
    fi
    printf '%s:\n' "Usage"
    printf '    %s\n' "${myname}: [OPTION] <archives>"
    if [ -n "$1" ]; then
        exit "$1"
    fi

}

# return type: string
#       usage: show_help [code]
#        code: int, if provided will exit the script with the code
show_help () {
    code=0
    if [ -n "$1" ]; then
        code="$1"
    fi
    show_usage 
    printf '%s\n' "Options:"
    printf '    %s\n' "-c: Extract archive into current directory rather than a new one."
    printf '    %s\n' "-p: password."
    exit "$code"
}


# return type: string
#       usage: archive_dispatcher archive
archive_dispatcher () {
    archive="$1"
    if [ -f "$archive" ] ; then
        if [ -z "$extracthere" ]; then
            directory="$(echo "$archive" | sed 's/\.[^\/.]*$//')"
            mkdir -p "$directory"
            cd "$directory" || die "Couldn't open dir: ${directory}"
        fi
        printf '%s: %s\n' "$myname" "extracting archive '${archive}' to '${directory}'"
        case "$archive" in
            *.tar.bz2|*.tbz2)
                tar xvjf "$archive"
                ;;
            *.tar.xz)
                tar -xf "$archive"
                ;;
            *.tar.gz|*.tgz)
                tar xvzf "$archive"
                ;;
            *.lzma)
                unlzma "$archive"
                ;;
            *.bz2)
                bunzip2 "$archive"
                ;;
            *.rar)
                unrar x -p"$pass" "$archive"
                ;;
            *.gz)
                gunzip "$archive"
                ;;
            *.tar)
                tar xvf "$archive"
                ;;
            *.zip)
                7z x -p"$pass" "$archive"
                ;;
            *.Z)
                uncompress "$archive"
                ;;
            *.7z)
                7z x -p"$pass" "$archive"
                ;;
            *.xz)
                unxz "$archive"
                ;;
            *.exe)
                cabextract "$archive"
                ;;
            *.deb)
                ar x "$archive"
                ;;
            *.zst)
                tar --zstd -xvf "$archive"
                ;;
            *) 
                unar -p "$pass" "$archive"
                ;;
        esac
        printf '\n'
        if [ -z "$extracthere" ]; then
            cd "$workdir" || die "Coudln't open dir: ${workdir}"
        fi
    else
        printf '%s: %s\n' "$myname" "archive '${archive}' doesn't exist!"
    fi
}

if [ "${#}" -eq 0 ]; then
    show_usage 1 "no arguments passed"
fi

while [ "$#" -gt 0 ]; do
    case "$1" in
        c|-c|--current-dir)
            shift
            extracthere="True"
            ;;
        p|-p|--password)
            shift
            pass="$1"
            shift
            ;;
        h|-h|--help)
            shift
            show_help 0
            ;;
        *)
            archive_dispatcher "$1"
            shift
        ;;
    esac
done
