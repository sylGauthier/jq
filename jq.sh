#! /usr/bin/bash

if [ ! -d "$HOME/.jq" ] ; then
    mkdir "$HOME/.jq"
fi

if [ ! -f "$HOME/.jq/.id" ] ; then
    touch "$HOME/.jq/.id"
fi

ED="$(test -n "$EDITOR" && echo "$EDITOR" || echo "/usr/bin/vi")"
KEYID="$(cat "$HOME/.jq/.id")"

function print_help ()
{
    printf "Usage: $0 [command]
                ls: displays list of entries.
                add: add a new entry at the current date and time.
                read <date>: read the entries at the specified date.\n"
}

function add_entry ()
{
    CURY="$(date +%Y)"
    CURM="$(date +%m)"
    CURD="$(date +%d)"
    NAME="$(date +%H:%M:%S)"
    DIR="$HOME/.jq/$CURY/$CURM/$CURD/"
    TMP="$(mktemp -d)/$NAME.jq"

    test -d "$DIR" || mkdir -p "$DIR"
    $ED "$TMP"

    if [ -n "$KEYID" ] ; then
        gpg -r "$KEYID" -o "$DIR/$NAME.gpg" -e "$TMP"
        shred -u "$TMP"
    else
        printf "/!\\ Unencrypted /!\\ \n"
        mv "$TMP" "$DIR"
    fi

    rm -r "$(dirname "$TMP")"
    printf "Created new entry : $CURY/$CURM/$CURD/$NAME\n"
}

function read_entry ()
{
    for i in $(find "$HOME/.jq/$1" -name *:*:* | sort) ; do
        NAME=${i#$HOME/.jq/}
        DATE=$(dirname "$NAME")
        TIME=$(basename "$NAME")
        TIME=${TIME%.gpg}

        printf "                          ~~ $DATE $TIME ~~\n"
        gpg -d "$i" 2>/dev/null
        printf "\n                                    ***\n\n"
    done
}

function init ()
{
    printf "Please give the gpg key identifier to associate with this journal. If none given, the journal will not be encrypted\n"
    read KEYID
    printf "$KEYID" > "$HOME/.jq/.id"
}

if [ "$1" = "ls" ] ; then
    printf "Journal $2\n"
    tree "$HOME/.jq/$2" --noreport -C | tail -n +2
elif [ "$1" = "add" ] ; then
    add_entry
elif [ "$1" = "init" ] ; then
    init
elif [ "$1" = "read" ] ; then
    read_entry "$2" | less
else
    print_help
fi
