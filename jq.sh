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
        gpg -r "$KEYID" -o "$DIR/$NAME.gpg" -e "$TMP" 2>/dev/null
        shred -u "$TMP"
    else
        printf "/!\\ Unencrypted /!\\ \n"
        mv "$TMP" "$DIR"
    fi

    rm -r "$(dirname "$TMP")"
    printf "Created new entry : $CURY/$CURM/$CURD/$NAME\n"
}

function add_file ()
{
    CURY="$(date +%Y)"
    CURM="$(date +%m)"
    CURD="$(date +%d)"
    NAME="$(date +%H:%M:%S)"
    DIR="$HOME/.jq/$CURY/$CURM/$CURD/"
    OUTNAME="$(test -n "$2" && echo "$2" || echo "$1")"

    test -d "$DIR" || mkdir -p "$DIR"

    if [ -n "$KEYID" ] ; then
        gpg -r "$KEYID" -o "$DIR/$OUTNAME.gpg" -e "$1"
    else
        printf "/!\\ Unencrypted /!\\ \n"
        cp "$1" "$DIR/$OUTNAME"
    fi

    printf "Added file : $DIR/$OUTNAME\n"
}

function read_entry ()
{
    for i in $(find "$HOME/.jq/$1" -name *:*:* | sort) ; do
        NAME=${i#$HOME/.jq/}
        DATE="$(dirname "$NAME")"
        TIME="$(basename "$NAME")"
        TIME=${TIME%.gpg}
        DATE="$(date -d "$DATE $TIME" -R)"

        printf "                   \x1b[33m~~ $DATE ~~\x1b[39m\n"
        if [ -n "$KEYID" ] ; then
            gpg --no-tty -d "$i" 2>/dev/null
        else
            cat "$i"
        fi
        printf "\n                                    ***\n\n"
    done
}

function open_file ()
{
    NAME="$HOME/.jq/$1"
    TMP="$(mktemp -d)"
    OUTNAME=${NAME%.gpg}
    OUTNAME="$TMP/$(basename "$OUTNAME")"

    if [ -n "$KEYID" ] ; then
        gpg -o "$OUTNAME" -d "$NAME.gpg"
    else
        cp "$NAME" "$OUTNAME"
    fi

    xdg-open "$OUTNAME"
    read -n1 -p "Press a touch to continue..."
    shred "$OUTNAME"
    rm -r "$TMP"
}

function extract_file ()
{
    NAME="$HOME/.jq/$1"
    TMP="$(mktemp -d)"
    OUTNAME=${NAME%.gpg}
    OUTNAME="$2/$(basename "$OUTNAME")"

    if [ -n "$KEYID" ] ; then
        gpg -o "$OUTNAME" -d "$NAME"
    else
        cp "$NAME" "$OUTNAME"
    fi
}

function init ()
{
    printf "Please give the gpg key identifier to associate with this journal. If none given, the journal will not be encrypted\n"
    read KEYID
    printf "$KEYID" > "$HOME/.jq/.id"
}

if [ "$1" = "ls" ] ; then
    printf "Journal $2\n"
    tree "$HOME/.jq/$2" --noreport -C | tail -n +2 | sed 's/.gpg$//g'
elif [ "$1" = "add" ] ; then
    test -n "$2" && add_file "$2" "$3" || add_entry
elif [ "$1" = "init" ] ; then
    init
elif [ "$1" = "read" ] ; then
    read_entry "$2" | less -r
elif [ "$1" = "open" ] ; then
    open_file "$2"
elif [ "$1" = "extract" ] ; then
    extract_file "$2" "$3"
elif [ "$1" = "git" ] ; then
    if [ "$2" = "init" ] ; then
        if [ -d "$HOME/.jq/.git" ] ; then
            printf "Git already initialized\n"
            exit
        else
            cd "$HOME/.jq/"
            git init
            echo "*.gpg diff=gpg" > .gitattributes
            git config diff.gpg.binary true
            git config diff.gpg.textconv "gpg2 -d --quiet --yes --compress-algo=none --no-encrypt-to --batch --use-agent"
            git add .gitattributes
            git commit .gitattributes -m "Set git diff to gpg mode"
            git add .id
            git commit -m "Added key id file"
            git add *
            git commit -a -m "Added current content of journal"
        fi
    else
        shift
        git "$@"
    fi
else
    print_help
fi
