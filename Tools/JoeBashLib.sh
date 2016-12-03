########################################################################################################################
# Joe’s kleine Bash Funktionssammlung
#-----------------------------------------------------------------------------------------------------------------------
# \project    Multithreaded C++ Framework
# \file       JoeBashLib.sh
# \creation   2014-05-10, Joe Merten
#-----------------------------------------------------------------------------------------------------------------------
# Achtung: Wegen bash -e sollte in diesem Skript weder "let" noch "expr" verwendet serden. ((i++)) ist ebenfalls problematisch.
# Workaround: "||:" dahinter schreiben, also z.B.:
#   let 'i++' ||:
# Siehe auch: http://unix.stackexchange.com/questions/63166/bash-e-exits-when-let-or-expr-evaluates-to-0
########################################################################################################################


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
# Host system detection
#-----------------------------------------------------------------------------------------------------------------------
# setzt die Variable HOST_SYSTEM
########################################################################################################################
function detectHost() {
    local UNAME_S=$(uname -s)
    if [ "$UNAME_S" == "Linux" ]; then
        HOST_SYSTEM="Linux"
    elif [ "$UNAME_S" == "Darwin" ]; then
        HOST_SYSTEM="Darwin"
    elif [[ "$UNAME_S" =~ ^CYGWIN_NT-*$ ]]; then
        # might be "CYGWIN_NT-5.1" or "CYGWIN_NT-6.3" ...
        HOST_SYSTEM="Cygwin"
    else
        echo "Error: Unknown host system '$UNAME_S'" >/dev/stderr
        exit 1
    fi
}


########################################################################################################################
# Hilfsfunktion: Numerischen Wert mit Tausenderpunkten ausgeben
#-----------------------------------------------------------------------------------------------------------------------
# \in  valueString  String, in dem die Tausenderseparatoren eingefügt werden sollen
# \in  minLength    Mindestlänge, Rückgabestring wird ggf. rechtsbündig formatiert
#-----------------------------------------------------------------------------------------------------------------------
# TODO: Eigentlich nicht mehr erforderlich, da die Bash das selbst kann, z.B.:
#    printf "%'d" -123456789
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

    if [ "$#" == "2" ]; then
        # String auf Mindestlänge formatieren
        while [ "${#RET}" -lt "$2" ]; do
            RET=" $RET"
        done
    fi

    echo "$RET"
}

function JoeBashLib_Test_WithDots {
    Test_Check "$(WithDots           "")"              ""
    Test_Check "$(WithDots          "0")"             "0"

    Test_Check "$(WithDots          "1")"             "1"
    Test_Check "$(WithDots         "12")"            "12"
    Test_Check "$(WithDots        "133")"           "133"
    Test_Check "$(WithDots       "1234")"         "1.234"
    Test_Check "$(WithDots      "12345")"        "12.345"
    Test_Check "$(WithDots     "123456")"       "123.456"
    Test_Check "$(WithDots    "1234567")"     "1.234.567"
    Test_Check "$(WithDots   "12345678")"    "12.345.678"
    Test_Check "$(WithDots  "123456789")"   "123.456.789"

    Test_Check "$(WithDots         "-1")"            "-1"
    Test_Check "$(WithDots        "-12")"           "-12"
    Test_Check "$(WithDots       "-133")"          "-133"
    Test_Check "$(WithDots      "-1234")"        "-1.234"
    Test_Check "$(WithDots     "-12345")"       "-12.345"
    Test_Check "$(WithDots    "-123456")"      "-123.456"
    Test_Check "$(WithDots   "-1234567")"    "-1.234.567"
    Test_Check "$(WithDots  "-12345678")"   "-12.345.678"
    Test_Check "$(WithDots "-123456789")"  "-123.456.789"

    Test_Check "$(WithDots         "+1")"            "+1"
    Test_Check "$(WithDots        "+12")"           "+12"
    Test_Check "$(WithDots       "+133")"          "+133"
    Test_Check "$(WithDots      "+1234")"        "+1.234"
    Test_Check "$(WithDots     "+12345")"       "+12.345"
    Test_Check "$(WithDots    "+123456")"      "+123.456"
    Test_Check "$(WithDots   "+1234567")"    "+1.234.567"
    Test_Check "$(WithDots  "+12345678")"   "+12.345.678"
    Test_Check "$(WithDots "+123456789")"  "+123.456.789"

    Test_Check "$(WithDots      "12345" 9)"   "   12.345"
    Test_Check "$(WithDots     "-12345" 9)"   "  -12.345"
    Test_Check "$(WithDots     "+12345" 9)"   "  +12.345"
}


########################################################################################################################
# Hilfsfunktion: Trim Strings
#-----------------------------------------------------------------------------------------------------------------------
# siehe auch: http://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-bash-variable
########################################################################################################################
function Trim {
    local var="$1"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo "$var"
}

function TrimLeft {
    local var="$1"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    echo "$var"
}

function TrimRight {
    local var="$1"
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo "$var"
}

function JoeBashLib_Test_Trim {
    Test_Check "$(Trim        "")"              ""
    Test_Check "$(TrimLeft    "")"              ""
    Test_Check "$(TrimRight   "")"              ""

    Test_Check "$(Trim           "a b c")"                 "a b c"
    Test_Check "$(TrimLeft       "a b c")"                 "a b c"
    Test_Check "$(TrimRight      "a b c")"                 "a b c"

    Test_Check "$(Trim        "   d e f")"                 "d e f"
    Test_Check "$(TrimLeft    "   d e f")"                 "d e f"
    Test_Check "$(TrimRight   "   d e f")"              "   d e f"

    Test_Check "$(Trim           "g h i   ")"              "g h i"
    Test_Check "$(TrimLeft       "g h i   ")"              "g h i   "
    Test_Check "$(TrimRight      "g h i   ")"              "g h i"

    Test_Check "$(Trim        "   j k l   ")"              "j k l"
    Test_Check "$(TrimLeft    "   j k l   ")"              "j k l   "
    Test_Check "$(TrimRight   "   j k l   ")"           "   j k l"
}


########################################################################################################################
# Ermittlung von File Base oder Ext
#-----------------------------------------------------------------------------------------------------------------------
# \in  filename  Kompletter Dateiname, optional mit Verzeichnis
# \in  mode      - "base" = File Base wird ermittelt
#                - "ext"  = File Ext wird ermittelt
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

function JoeBashLib_Test_GetFileBaseExt {
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


########################################################################################################################
# Ausführung aller Tests
########################################################################################################################
function JoeBashLib_Test_All {
    JoeBashLib_Test_WithDots
    JoeBashLib_Test_Trim
    JoeBashLib_Test_GetFileBaseExt
}
