#!/bin/sh

#########################################################################
# A general, all-purpose wrapper script over many utilities to extract  #
# and list the contents of as many archive types as possible from a     #
# single executable.                                                    #
#########################################################################

myname="${0##*/}"

# dir from which the script was called
workdir="$PWD"
# if the archive should be extracted in workdir
extracthere=""
# archive password
pass=""
# file containing passwords for archives in workdir
pass_file=""
if [ -e "${workdir}/.password" ]; then
    # printf '%s: %s\n' "$myname" "password file found"
    pass_file="${workdir}/.password"
fi
# action to take on archives
# possible values:
#     arkext ex ext arkls arls ls lst list
action=""

case "$myname" in
    arkext|ext|arkls|arls)
        action="$myname"
        ;;
esac

# usage: die "message"
die() {
    [ -n "$1" ] && printf '%s:%s\n' "$myname" "$*" >&2;
    exit 1
}

# return type: string
get_header_comment () {
    sed -n 's/^# /    / ; s/ #$// ; /^#####/,/^#####/p' "$0" | sed '1d;$d'
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
    case "$myname" in
        arkext|ext|arkls|arls)
            printf '    %s\n' "${myname}: [OPTION] <archives>"
        ;;
        *)
            printf '    %s\n' "${myname}: [action] [OPTION] <archives>"
        ;;
    esac
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
    printf '%s\n' "$myname"
    get_header_comment
    show_usage
    case "$myname" in
        arkext|ext|arkls|arls)
            : # do nothing
            ;;
        *)
            printf '%s\n' "Actions:"
            printf '    %s    %s\n' "ext" "extract archive"
            printf '    %s    %s\n' "lst" "list archive contents"
            ;;
    esac
    printf '%s\n' "Options:"
    case "$myname" in
        arkext|ext|arkiver*)
            printf '    %s\t\t\t%s\n' \
                "-c" \
                "Extract archive into current directory."
            ;;
        *)
            : # do nothing
            ;;
    esac
    printf '    %s\t%s\n' \
        "-p <password>" "not every archive type supports passwords."
    printf '    %s\t\t\t%s\n' "-h" "show this help message."
    printf '\n'
    printf '    %s\n' \
        "for convenience password files are supported, the password file is"
    printf '    %s\n' \
        "a simple text file with fields separated by ':::' triple colons"
    printf '    %s\n' \
        "the first line is always the master password for all archives in"
    printf '    %s\n' \
        "the current directory, it may be defined as:"
    printf '        %s\n' \
        "'password:::MASTER'"
    printf '    %s\n' \
        "however the suffix ':::MASTER' is not necessary and can be skipped"
    printf '    %s\n' \
        "all other passwords however are expected to be in the format of:"
    printf '        %s\n' \
        "'password:::\"file name\"'"
    printf '    %s\n' \
        "the password file itself is to be named as:"
    printf '        %s\n' \
        ".password"
    printf '    %s\n' \
        "so that it will be just another dot file under normal operation"
    exit "$code"
}

# return type: string
#       usage: archive_extractor archive
archive_extractor () {
    archive="$1"
    if [ -z "$extracthere" ]; then
        directory="$(echo "$archive" | sed 's/\.[^\/.]*$//')"
        mkdir -p "$directory"
        cd "$directory" || die "Couldn't open dir: ${directory}"
    fi
    printf '%s: %s\n' \
        "$myname" "extracting archive '${archive}' to '${directory}'"
    archive="${workdir}/${archive}"
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
        *.exe|*.cab)
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
}

archive_lister () {
    archive="$1"
    case "$archive" in
        *.tar.bz2|*.tbz2)
            tar -tjf "$archive"
            ;;
        *.tar.xz)
            tar -tJf "$archive"
            ;;
        *.tar.gz|*.tgz)
            tar -tzf "$archive"
            ;;
        *.lzma)
            xz --list "$archive"
            ;;
        *.rar)
            # prefer lsar output
            lsar -p "$pass" "$archive" | tail -n +2
            ;;
        *.tar)
            tar tf "$archive"
            ;;
        *.zip)
            # prefer lsar output
            lsar -p "$pass" "$archive" | tail -n +2
            ;;
        *.7z)
            # prefer lsar output
            lsar -p "$pass" "$archive" | tail -n +2
            ;;
        *.xz)
            xz --list "$archive"
            ;;
        *.exe|*.cab)
            cabextract -l "$archive"
            ;;
        *.deb)
            ar t "$archive"
            ;;
        *.zst)
            tar --zstd -tvf "$archive"
            ;;
        *)
            lsar -p "$pass" "$archive" | tail -n +2
            ;;
    esac
}

# return type: string
#       usage: archive_dispatcher archive
archive_dispatcher () {
    archive="$1"
    if [ -f "$archive" ] ; then
        if [ -z "$pass" ] && [ -n "$pass_file" ]; then
            # search for password
            pass=$(grep -F "$archive" "$pass_file" | awk -F":::" '{print $1}')
            if [ -z "$pass" ]; then
                # use master password
                pass=$(awk -F":::" 'NR==1{print $1}' "$pass_file")
            fi
        elif [ -n "$pass" ] && [ -n "$pass_file" ]; then
            if ! grep -q -F "${pass}:::\"${archive}\"" "$pass_file"; then
                printf '%s\n' "${myname}: recording password to passwords file"
                printf '%s:::"%s"\n' "$pass" "$archive" >> "$pass_file"
            fi
        fi
        case "$action" in
            ex|ext|arkext)
                archive_extractor "$archive"
            ;;
            ls|lst|list|arkls|arls)
                archive_lister "$archive"
            ;;
            *)
                printf '%s: %s\n' "$myname" "no action specified for $archive"
            ;;
        esac
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
        h|-h|help|--help)
            shift
            show_help 0
            ;;
        ex|ext|list|lst|ls)
            case "$myname" in
                arkext|ext|arkls|arls)
                    : # do nothing
                ;;
                *)
                    action="$1"
                ;;
            esac
            shift
        ;;
        *)
            archive_dispatcher "$1"
            shift
        ;;
    esac
done
