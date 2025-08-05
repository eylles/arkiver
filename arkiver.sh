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

# command for performing the action
act_cmd=""
# arguments and flags for the command
cmd_arg=""
# password argument
pass_arg=""
# action specific handling
act_spec=""

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
        "so that it will be just another dot file under normal operation."
    printf '    %s\n' \
        "$myname will add new passwords to existing password files."
    exit "$code"
}

# return type: void
#       usage: get_command "archive" "action"
# description: does not return any output, it sets scope variables before
#              the invocation of command_handler, sets the following vars:
#                  act_cmd
#                  cmd_arg
#                  act_spec
#                  pass_arg
get_command () {
    archive="$1"
    act_hnd="$2"

    case "$archive" in
        *.tar.bz2|*.tbz2)
            case "$act_hnd" in
                "ext")
                    act_cmd="tar"
                    cmd_arg="xvjf"
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="tar"
                    cmd_arg="-tjf"
                    act_spec=""
                    pass_arg=""
                    ;;
            esac
            ;;
        *.tar.xz)
            case "$act_hnd" in
                "ext")
                    act_cmd="tar"
                    cmd_arg="-xf"
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="tar"
                    cmd_arg="-tJf"
                    act_spec=""
                    pass_arg=""
                    ;;
            esac
            ;;
        *.tar.gz|*.tgz)
            case "$act_hnd" in
                "ext")
                    act_cmd="tar"
                    cmd_arg="xvzf"
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="tar"
                    cmd_arg="-tzf"
                    act_spec=""
                    pass_arg=""
                    ;;
            esac
            ;;
        *.lzma)
            case "$act_hnd" in
                "ext")
                    act_cmd="unlzma"
                    cmd_arg=""
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="xz"
                    cmd_arg="--list"
                    act_spec=""
                    pass_arg=""
                    ;;
            esac
            ;;
        *.bz2)
            case "$act_hnd" in
                "ext")
                    act_cmd="bunzip2"
                    cmd_arg=""
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="lsar"
                    cmd_arg=""
                    act_spec="lsar"
                    pass_arg=""
                    [ -n "$pass" ] && pass_arg="-p "
                    ;;
            esac
            ;;
        *.rar)
            case "$act_hnd" in
                "ext")
                    act_cmd="unrar"
                    cmd_arg="x"
                    act_spec=""
                    pass_arg=""
                    [ -n "$pass" ] && pass_arg="-p"
                    ;;
                "lst")
                    # prefer lsar output
                    act_cmd="lsar"
                    cmd_arg=
                    act_spec="lsar"
                    pass_arg=""
                    [ -n "$pass" ] && pass_arg="-p "
                    ;;
            esac
            ;;
        *.gz)
            case "$act_hnd" in
                "ext")
                    act_cmd="gunzip"
                    cmd_arg=""
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="lsar"
                    cmd_arg=""
                    act_spec="lsar"
                    pass_arg=""
                    [ -n "$pass" ] && pass_arg="-p "
                    ;;
            esac
            ;;
        *.tar)
            case "$act_hnd" in
                "ext")
                    act_cmd="tar"
                    cmd_arg="xvf"
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="tar"
                    cmd_arg="tf"
                    act_spec=""
                    pass_arg=""
                    ;;
            esac
            ;;
        *.7z|*.zip)
            case "$act_hnd" in
                "ext")
                    act_cmd="7z"
                    cmd_arg="x"
                    act_spec=""
                    pass_arg=""
                    [ -n "$pass" ] && pass_arg="-p"
                    ;;
                "lst")
                    # prefer lsar output
                    act_cmd="lsar"
                    cmd_arg=""
                    act_spec="lsar"
                    pass_arg=""
                    [ -n "$pass" ] && pass_arg="-p "
                    ;;
            esac
            ;;
        *.Z)
            case "$act_hnd" in
                "ext")
                    act_cmd="uncompress"
                    cmd_arg=""
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="lsar"
                    cmd_arg=""
                    act_spec="lsar"
                    pass_arg=""
                    [ -n "$pass" ] && pass_arg="-p "
                    ;;
            esac
            ;;
        *.xz)
            case "$act_hnd" in
                "ext")
                    act_cmd="unxz"
                    cmd_arg=""
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="xz"
                    cmd_arg="--list"
                    act_spec=""
                    pass_arg=""
                    ;;
            esac
            ;;
        *.exe|*.cab)
            case "$act_hnd" in
                "ext")
                    act_cmd="cabextract"
                    cmd_arg=""
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="cabextract"
                    cmd_arg="-l"
                    act_spec=""
                    pass_arg=""
                    ;;
            esac
            ;;
        *.deb)
            case "$act_hnd" in
                "ext")
                    act_cmd="ar"
                    cmd_arg="x"
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="ar"
                    cmd_arg="t"
                    act_spec=""
                    pass_arg=""
                    ;;
            esac
            ;;
        *.zst)
            case "$act_hnd" in
                "ext")
                    act_cmd="tar"
                    cmd_arg="--zstd -xvf"
                    act_spec=""
                    pass_arg=""
                    ;;
                "lst")
                    act_cmd="tar"
                    cmd_arg="--zstd -tvf"
                    act_spec=""
                    pass_arg=""
                    ;;
            esac
            ;;
        *)
            case "$act_hnd" in
                "ext")
                    act_cmd="unar"
                    cmd_arg=""
                    act_spec=""
                    pass_arg=""
                    [ -n "$pass" ] && pass_arg="-p "
                    ;;
                "lst")
                    act_cmd="lsar"
                    cmd_arg=""
                    act_spec="lsar"
                    pass_arg=""
                    [ -n "$pass" ] && pass_arg="-p "
                    ;;
            esac
            ;;
    esac
}

# return type: string
#       usage: command_handler
# description: handling of action command for the archive, no arguments
#              are passed to this function, the variables to construct
#              the command are set in the invocation scope by first running
#              get_command "archive" "action" before running this function
command_handler () {
    if [ -n "$pass_arg" ]; then
        $act_cmd "$cmd_arg" "$pass_arg""$pass" "$archive"
    else
        $act_cmd "$cmd_arg" "$archive"
    fi
}

# return type: string
#       usage: archive_extractor archive
# description: extract archive, extraction in the current directory or a
#              new one is controlled by the $extracthere variable
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
    get_command "$archive" "ext"
    command_handler
    printf '\n'
    if [ -z "$extracthere" ]; then
        cd "$workdir" || die "Coudln't open dir: ${workdir}"
    fi
}

# return type: string
#       usage: archive_lister archive
# description: return the list of files within the archive in a
#              consistent format
archive_lister () {
    archive="$1"
    get_command "$archive" "lst"
    if [ -z "$act_spec" ]; then
        command_handler
    else
        command_handler | tail -n +2
    fi
}

# return type: void
#       usage: arkpass_manage archive
# description: fetch and record archive password from/to pass_file
arkpass_manage () {
    if [ -z "$pass" ] && [ -n "$pass_file" ]; then
        # search for password
        pass=$(grep -F "$1" "$pass_file" | awk -F":::" '{print $1}')
        if [ -z "$pass" ]; then
            # use master password
            pass=$(awk -F":::" 'NR==1{print $1}' "$pass_file")
        fi
    elif [ -n "$pass" ] && [ -n "$pass_file" ]; then
        if ! grep -q -F "${pass}:::\"${1}\"" "$pass_file"; then
            printf '%s\n' "${myname}: recording password to passwords file"
            printf '%s:::"%s"\n' "$pass" "$1" >> "$pass_file"
        fi
    fi
}

# return type: string
#       usage: archive_dispatcher archive
archive_dispatcher () {
    archive="$1"
    if [ -f "$archive" ] ; then
        arkpass_manage "$archive"
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
