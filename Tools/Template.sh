#!/bin/bash -e
########################################################################################################################
# Shellskript Template
#-----------------------------------------------------------------------------------------------------------------------
# \project    Multithreaded C++ Framework
# \file       Template.sh
# \creation   2014-05-10, Joe Merten
#-----------------------------------------------------------------------------------------------------------------------
# Achtung: Wegen bash -e sollte in diesem Skript weder "let" noch "expr" verwendet serden. ((i++)) ist ebenfalls problematisch.
# Workaround: "||:" dahinter schreiben, also z.B.:
#   let 'i++' ||:
# Siehe auch: http://unix.stackexchange.com/questions/63166/bash-e-exits-when-let-or-expr-evaluates-to-0
########################################################################################################################


########################################################################################################################
#    ____ _       _           _
#   / ___| | ___ | |__   __ _| |
#  | |  _| |/ _ \| '_ \ / _` | |
#  | |_| | | (_) | |_) | (_| | |
#   \____|_|\___/|_.__/ \__,_|_|
########################################################################################################################

########################################################################################################################
# Konstanten & Globale Variablen
########################################################################################################################

#declare ...


########################################################################################################################
#    ____      _
#   / ___|___ | | ___  _ __
#  | |   / _ \| |/ _ \| '__|
#  | |__| (_) | | (_) | |
#   \____\___/|_|\___/|_|
########################################################################################################################

########################################################################################################################
# Die 16 Html Farbnamen
########################################################################################################################

declare ESC=$'\e'
#declare ESC="$(printf "\x1B")"
declare   BLACK="${ESC}[0m${ESC}[30m"           #     BLACK
declare  MAROON="${ESC}[0m${ESC}[31m"           #       RED
declare   GREEN="${ESC}[0m${ESC}[32m"           #     GREEN
declare   OLIVE="${ESC}[0m${ESC}[33m"           #     BROWN -> Dunkelgelb
declare    NAVY="${ESC}[0m${ESC}[34m"           #      BLUE
declare  PURPLE="${ESC}[0m${ESC}[35m"           #   MAGENTA
declare    TEAL="${ESC}[0m${ESC}[36m"           #      CYAN
declare  SILVER="${ESC}[0m${ESC}[37m"           #    LTGRAY -> Dunkelweiss
declare    GRAY="${ESC}[0m${ESC}[30m${ESC}[1m"  #      GRAY -> Hellschwarz
declare     RED="${ESC}[0m${ESC}[31m${ESC}[1m"  #     LTRED
declare    LIME="${ESC}[0m${ESC}[32m${ESC}[1m"  #   LTGREEN
declare  YELLOW="${ESC}[0m${ESC}[33m${ESC}[1m"  #    YELLOW
declare    BLUE="${ESC}[0m${ESC}[34m${ESC}[1m"  #    LTBLUE
declare FUCHSIA="${ESC}[0m${ESC}[35m${ESC}[1m"  # LTMAGENTA
declare    AQUA="${ESC}[0m${ESC}[36m${ESC}[1m"  #    LTCYAN
declare   WHITE="${ESC}[0m${ESC}[37m${ESC}[1m"  #     WHITE
declare  NORMAL="${ESC}[0m"
declare   LIGHT="${ESC}[1m"

########################################################################################################################
# Falls keine Ansi VT100 Farben gewünscht sind
#-----------------------------------------------------------------------------------------------------------------------
# Todo: Folgendes mal genauer angucken: http://stackoverflow.com/questions/64786/error-handling-in-bash
#     Color the output if it's an interactive terminal
#    test -t 1 && tput bold; tput setf 4                                 ## red bold
#    echo -e "\n(!) EXIT HANDLER:\n"
########################################################################################################################
function NoColor {
    BLACK=""; MAROON=""; GREEN=""; OLIVE=""; NAVY=""; PURPLE="" TEAL="" SILVER=""; GRAY=""
    RED=""; LIME=""; YELLOW=""; BLUE=""; FUCHSIA=""; AQUA=""; WHITE=""; NORMAL=""; LIGHT=""
    LOG_COLOR_FATAL=""; LOG_COLOR_ERROR=""
    LOG_COLOR_WARN="";  LOG_COLOR_INFO=""
    LOG_COLOR_DEBUG=""; LOG_COLOR_TRACE=""
}


########################################################################################################################
#   _____                    _   _
#  | ____|_  _____ ___ _ __ | |_(_) ___  _ __  ___
#  |  _| \ \/ / __/ _ \ '_ \| __| |/ _ \| '_ \/ __|
#  | |___ >  < (_|  __/ |_) | |_| | (_) | | | \__ \
#  |_____/_/\_\___\___| .__/ \__|_|\___/|_| |_|___/
#                     |_|
########################################################################################################################

# siehe auch http://stackoverflow.com/questions/64786/error-handling-in-bash
# Ohne "errtrace" wird mein OnError() nicht immer gerufen...
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

########################################################################################################################
# Terminalfarben restaurieren, ggf. Childprozesse beenden et cetera
########################################################################################################################
declare SHUTTING_DOWN=
function StopScript {
    SHUTTING_DOWN="true"
    local exitcode="$1"

    echo -n "${NORMAL}"
    echo -n "${NORMAL}" >&2

    # Kill, um ggf. gestartete Background Childprozesse auch zu beenden
    trap SIGINT
    kill -INT 0
    exit $exitcode
}

########################################################################################################################
# Terminalfarben restaurieren, wenn Abbruch via Ctrl+C
########################################################################################################################
function OnCtrlC {
    [ "$SHUTTING_DOWN" != "" ] && return 0
    echo "${RED}[*** interrupted ***]${NORMAL}" >&2
    # damit bei Ctrl+C auch alle Childprozesse beendet werden etc.
    StopScript 2
}
trap OnCtrlC SIGINT


########################################################################################################################
# Fehlerbehandlung Hook
#-----------------------------------------------------------------------------------------------------------------------
# Da wir das Skript mit "bash -e" ausführen, führt jeder Befehls- oder Funktionsaufruf, der mit !=0 returniert zu einem
# Skriptabbruch, sofern der entsprechende Exitcode nicht Skriptseitig ausgewertet wird.
# Siehe auch http://wiki.bash-hackers.org/commands/builtin/set -e
# Mit dem OnError() stellen wir hier noch mal einen Fuss in die Tür um genau diesen Umstand (unerwartete Skriptbeendigung)
# sichtbar zu machen.
########################################################################################################################
function OnError() {
    echo "${RED}Script error exception in line $1, exit code $2${NORMAL}" >&2

    # Stacktrace ausgeben
    # http://wiki.bash-hackers.org/commands/builtin/caller
    # http://stackoverflow.com/questions/685435/bash-stacktrace
    local i=0;
    local s=""
    echo -n "${MAROON}" >&2
    while s="$(caller $i)"; do
        echo "  ${MAROON}$s${NORMAL}" >&2
        ((i++)) ||:
    done
    StopScript 2
}
trap 'OnError $LINENO $?' ERR


########################################################################################################################
# Exit-Hook
#-----------------------------------------------------------------------------------------------------------------------
# OnExit() wird bei jeder Art der Skriptbeendigung aufgerufen, ggf. nach OnError()
# Siehe auch http://wiki.bash-hackers.org/commands/builtin/trap
#
# TODO: Näher untersuchen und für mich anpassen
#   tempfiles=( )
#   cleanup() {
#       rm -f "${tempfiles[@]}"
#   }
#   trap cleanup EXIT
########################################################################################################################
function OnExit() {
    local exitcode="$1"
        if [ "$2" != "0" ]; then
        echo "${RED}Script exitcode=$exitcode${NORMAL}" >&2
    else
        : # echo "${TEAL}Script exitcode=$exitcode${NORMAL}" >&2
    fi
    # TODO: Hier wirklich noch mal exit aufrufen?
    StopScript $exitcode
}
trap 'OnExit $LINENO $?' EXIT


########################################################################################################################
#   _____                        ___     _                      _
#  | ____|_ __ _ __ ___  _ __   ( _ )   | |    ___   __ _  __ _(_)_ __   __ _
#  |  _| | '__| '__/ _ \| '__|  / _ \/\ | |   / _ \ / _` |/ _` | | '_ \ / _` |
#  | |___| |  | | | (_) | |    | (_>  < | |__| (_) | (_| | (_| | | | | | (_| |
#  |_____|_|  |_|  \___/|_|     \___/\/ |_____\___/ \__, |\__, |_|_| |_|\__, |
#                                                   |___/ |___/         |___/
########################################################################################################################

########################################################################################################################
# Fehlerbehandlung & Logging
########################################################################################################################

declare LOG_COLOR_FATAL="${RED}"
declare LOG_COLOR_ERROR="${MAROON}"
declare  LOG_COLOR_WARN="${YELLOW}"
declare  LOG_COLOR_INFO="${TEAL}"
declare LOG_COLOR_DEBUG="${GREEN}"
declare LOG_COLOR_TRACE="${BLUE}"

function Fatal {
    echo "${LOG_COLOR_FATAL}*** Fatal: $*${NORMAL}" >&2
    StopScript 2
    echo "+++++++++++++++++++++++++++++++"
}

function Error {
    echo "${LOG_COLOR_ERROR}*** Error: $*${NORMAL}" >&2
}

function Warning {
    echo "${LOG_COLOR_WARN}Warning: $*${NORMAL}" >&2
}


function Info {
    echo "${LOG_COLOR_INFO}Info: $*${NORMAL}"
}

function Debug {
    echo "${LOG_COLOR_DEBUG}Debug: $*${NORMAL}" >&2
}

function Trace {
    echo "${LOG_COLOR_TRACE}Trace: $*${NORMAL}" >&2
}


########################################################################################################################
#   _____         _   _
#  |_   _|__  ___| |_(_)_ __   __ _
#    | |/ _ \/ __| __| | '_ \ / _` |
#    | |  __/\__ \ |_| | | | | (_| |
#    |_|\___||___/\__|_|_| |_|\__, |
#                             |___/
#-----------------------------------------------------------------------------------------------------------------------
# Ein Miniatur Testframework für Shellskripte
########################################################################################################################

########################################################################################################################
# Stringvergleich
#-----------------------------------------------------------------------------------------------------------------------
# \in  actual    Erhaltener Wert
# \in  expected  Erwarteter Wert
#-----------------------------------------------------------------------------------------------------------------------
# Vergleiche die beiden übergebenen Strings und gibt bei Ungleichheit eine Fehlermeldung aus
########################################################################################################################
function Test_Check {
    local actual="$1"
    local expected="$2"
    if [ "$actual" != "$expected" ]; then
        Error "Test failed. Expected \"$expected\" but got \"$actual\" from $(caller)."
    fi
}


########################################################################################################################
#   _   _ _   _ _ _ _
#  | | | | |_(_) (_) |_ _   _
#  | | | | __| | | | __| | | |
#  | |_| | |_| | | | |_| |_| |
#   \___/ \__|_|_|_|\__|\__, |
#                       |___/
########################################################################################################################

########################################################################################################################
# Hilfsfunktion: Numerischen Wert mit Tausenderpunkten ausgeben
########################################################################################################################
function WithDots {
    local RET="$1"
    local IDX
    local VORZ=""

    # Vorzeichen extrahieren
    if [ "${RET:0:1}" == "-" ] || [ "${RET:0:1}" == "+" ]; then
        VORZ="${RET:0:1}"
        RET=${RET:1}
    fi

    IDX=${#RET}

    # Dots einfügen
    while [ "$IDX" -gt "3" ]; do
        let "IDX -= 3" ||:
        L=${RET:0:$IDX}
        R=${RET:$IDX}
        RET="$L.$R"
    done

    RET="$VORZ$RET"

    if [ "$2" != "" ]; then
        # String auf Mindestlänge formatieren
        while [ "${#RET}" -lt "$2" ]; do
            RET=" $RET"
        done
    fi

    echo "$RET"
}


########################################################################################################################
# Ermittlung von File Base oder Ext
#-----------------------------------------------------------------------------------------------------------------------
# \in  filename  Kompletter Dateiname, optional mit Verzeichnis
# \in  mode      - "base" = File Base wird ermittelt
#                - "ext"  = File Ext wird ermittelt
#-----------------------------------------------------------------------------------------------------------------------

########################################################################################################################
function GetFileBaseExt {
    local filename="$1"
    local mode="$2"
    local name="$(basename "$filename")"

    # Vorabprüfung: Eine Fileext ist nur enthalten, wenn der String einen Punkt enthält, vor diesem aber eine "nicht-Punkt" ist
    if ! [[ "$name" =~ [^.]\. ]]; then
        [ "$mode" == "base" ] && echo "$name"
        [ "$mode" == "ext" ] && echo ""
        return 0
    fi

    # Prüfung, ob überhaupt ein Punkt enthalten ist
    #if [ "${name%.*}" == "$name" ]; then
    #    # Kein . enthalten → also auch keine Fileext
    #    echo ""
    #    return
    #fi

                            #echo "${name%%.*}"  #  example.a.b.c.d  →  example
    [ "$mode" == "base" ] && echo "${name%.*}"   #  example.a.b.c.d  →  example.a.b.c
                            #echo "${name#*.}"   #  example.a.b.c.d  →  a.b.c.d
    [ "$mode" == "ext" ]  && echo "${name##*.}"  #  example.a.b.c.d  →  d
    return 0
}

function GetFileBase {
    GetFileBaseExt "$1" base
}

function GetFileExt {
    GetFileBaseExt "$1" ext
}

function Test_GetFileBaseExt {
    Test_Check "$(GetFileExt "verzeichnis  /example.a")"       "a"
    Test_Check "$(GetFileExt "verzeichnis  /example.a.b.c.d")" "d"
    Test_Check "$(GetFileExt "verzeichnis  /example.")"        ""
    Test_Check "$(GetFileExt "verzeichnis  /example")"         ""

    Test_Check "$(GetFileExt "")"              ""
    Test_Check "$(GetFileExt ".")"             ""
    Test_Check "$(GetFileExt "..")"            ""
    Test_Check "$(GetFileExt "...")"           ""
    Test_Check "$(GetFileExt "/x.y.z./...")"   ""
    Test_Check "$(GetFileExt "/x.y.z./...a")"  ""

    Test_Check "$(GetFileExt "Basename.ext with space")"  "ext with space"

    Test_Check "$(GetFileExt ".project.bla")"  "bla"
    Test_Check "$(GetFileExt ".project")"      ""
    Test_Check "$(GetFileExt " .project")"     "project"


    Test_Check "$(GetFileBase "verzeichnis  /example.a")"       "example"
    Test_Check "$(GetFileBase "verzeichnis  /example.a.b.c.d")" "example.a.b.c"
    Test_Check "$(GetFileBase "verzeichnis  /example.")"        "example"
    Test_Check "$(GetFileBase "verzeichnis  /example")"         "example"

    Test_Check "$(GetFileBase "")"              ""
    Test_Check "$(GetFileBase ".")"             "."
    Test_Check "$(GetFileBase "..")"            ".."
    Test_Check "$(GetFileBase "...")"           "..."
    Test_Check "$(GetFileBase "/x.y.z./...")"   "..."
    Test_Check "$(GetFileBase "/x.y.z./...a")"  "...a"

    Test_Check "$(GetFileBase "Basename.ext with space")"  "Basename"

    Test_Check "$(GetFileBase ".project.bla")"  ".project"
    Test_Check "$(GetFileBase ".project")"      ".project"
    Test_Check "$(GetFileBase " .project")"     " "
}
#Test_GetFileBaseExt


########################################################################################################################
#   _   _ _ _  __
#  | | | (_) |/ _| ___
#  | |_| | | | |_ / _ \
#  |  _  | | |  _|  __/
#  |_| |_|_|_|_|  \___|
########################################################################################################################

########################################################################################################################
# Hilfe
########################################################################################################################
function ShowHelp {
    echo "${AQUA}Shellskript Template${TEAL}, Joe Merten 2014"
    echo "usage: $0 [options] ..."
    echo "Available options:"
    echo "  nocolor       - Dont use Ansi VT100 colors"
    echo "  -r            - Act on subdirectories"
    echo -n ${NORMAL}
}


########################################################################################################################
#   ____                                _
#  |  _ \ __ _ _ __ __ _ _ __ ___   ___| |_ ___ _ __
#  | |_) / _` | '__/ _` | '_ ` _ \ / _ \ __/ _ \ '__|
#  |  __/ (_| | | | (_| | | | | | |  __/ ||  __/ |
#  |_|   \__,_|_|  \__,_|_| |_| |_|\___|\__\___|_|
########################################################################################################################

########################################################################################################################
# Auswertung der Kommandozeilenparameter
########################################################################################################################
while (("$#")); do
  if [ "$1" == "?" ] || [ "$1" == "-?" ] || [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]; then
    ShowHelp
    exit 0
  elif [ "$1" == "nocolor" ]; then
    NoColor
  elif [ "$1" == "bla" ]; then
    echo "do anything"
  else
    echo "Unexpected parameter \"$1\"" >&2
    ShowHelp
    exit 1
  fi
  shift
done

########################################################################################################################
#   __  __       _
#  |  \/  | __ _(_)_ __
#  | |\/| |/ _` | | '_ \
#  | |  | | (_| | | | | |
#  |_|  |_|\__,_|_|_| |_|
########################################################################################################################

########################################################################################################################
# Main...
########################################################################################################################

echo "do something"
Trace   "Traceausgabe"
Debug   "Debugausgabe"
Info    "Infoausgabe"
Warning "Warnmeldung"
Error   "Fehlermeldung"

function func3() {
    ls $1
}
function func2() {
    func3 $1
}
function func1() {
    func2 $1
}
#ls asdfsadf
func1 tralala

Fatal   "Fatal Fehler"
echo "Ende"