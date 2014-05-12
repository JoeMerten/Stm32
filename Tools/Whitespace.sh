#!/bin/bash -e
########################################################################################################################
# Sourcen auf Whitespace Unsauberkeiten untersuchen
#-----------------------------------------------------------------------------------------------------------------------
# \project    Multithreaded C++ Framework
# \file       Whitespace.sh
# \creation   2014-05-10, Joe Merten
#-----------------------------------------------------------------------------------------------------------------------
# Achtung: Wegen bash -e sollte in diesem Skript weder "let" noch "expr" verwendet serden.
# Statt dessen besser $((...)) verwenden.
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

declare DIRS="."
declare FILE_PATTERNS=""
declare MODIFY=""

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
# Terminalfarben restaurieren, wenn Abbruch via Ctrl+C
########################################################################################################################
function OnCtrlC {
    echo "${RED}[*** interrupted ***]${NORMAL}"
#    # damit bei Ctrl+C auch alle Childprozesse beendet werden
#    trap SIGINT
#    kill -INT 0
#    #exit 1
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

    # Stacktrace Versuch
    # http://wiki.bash-hackers.org/commands/builtin/caller
    # http://stackoverflow.com/questions/685435/bash-stacktrace
    local i=0;
    echo -n "${MAROON}" >&2
    while caller $i >&2; do
         ((i++))
    done
    echo "==="
    backtrace
    echo "==="
    echo -n "${NORMAL}" >&2

    # Kill, um ggf. gestartete Background Childprozesse auch zu beenden
    trap SIGINT
    kill -INT 0
    exit 2
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
    if [ "$2" != "0" ]; then
        echo "${RED}Script exitcode=$2${NORMAL}" >&2
    else
        : # echo "${TEAL}Script exitcode=$2${NORMAL}" >&2
    fi

    # Ggf. Childprozesse beenden
    #trap SIGINT
    #kill -INT 0

    # Ggf. Terminalfarben restaurieren
    echo -n "${NORMAL}"
}
trap 'OnExit $LINENO $?' EXIT


# Zum Einbinden des Codes aus http://stackoverflow.com/questions/64786/error-handling-in-bash
# Weil der hat einen besseren Stacktrace.
# Allerding hebelt der meine eigenen obigen Hooks aus.
#[ -f /usr/local/bin/lib.trap.sh ] && set +o nounset && source /usr/local/bin/lib.trap.sh


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
    trap SIGINT
    kill -INT 0
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
        let "IDX -= 3"
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
# Fileext ermitteln
########################################################################################################################
function GetFileExt {
    local filename="$1"
    local base="$(basename "$filename")"

    # Vorabprüfung: Eine Fileext ist nur enthalten, wenn der String einen Punkt enthält, vor diesem aber eine "nicht-Punkt" ist
    if ! [[ "$base" =~ [^.]\. ]]; then
        echo ""
        return
    fi

    # Prüfung, ob überhaupt ein Punkt enthalten ist
    #if [ "${base%.*}" == "$base" ]; then
    #    # Kein . enthalten → also auch keine Fileext
    #    echo ""
    #    return
    #fi

    #echo "${base%%.*}"  #  example.a.b.c.d  →  example
    #echo "${base%.*}"   #  example.a.b.c.d  →  example.a.b.c
    #echo "${base#*.}"   #  example.a.b.c.d  →  a.b.c.d
    echo "${base##*.}"  #  example.a.b.c.d  →  d
}

function Test_GetFileExt {
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
}
#Test_GetFileExt


########################################################################################################################
#   _____ _                         _____            _    _   _
#  | ____(_) __ _  ___ _ __   ___  |  ___|   _ _ __ | | _| |_(_) ___  _ __   ___ _ __
#  |  _| | |/ _` |/ _ \ '_ \ / _ \ | |_ | | | | '_ \| |/ / __| |/ _ \| '_ \ / _ \ '_ \
#  | |___| | (_| |  __/ | | |  __/ |  _|| |_| | | | |   <| |_| | (_) | | | |  __/ | | |
#  |_____|_|\__, |\___|_| |_|\___| |_|   \__,_|_| |_|_|\_\\__|_|\___/|_| |_|\___|_| |_|
#           |___/
########################################################################################################################

declare TAB=$'\t'
declare CR=$'\t'

function CheckLineend {
    local filename="$1"

    if ! egrep -q "$CR" "$filename"; then
        return
    fi
    if [ "$MODIFY" == "" ]; then
        Warning "$filename contains cr"
        return
    fi

    Info "Remove CR from $filename"
    TMPFILE=foo42

    if [ -f "$TMPFILE" ]; then
        Fatal "Weird...the temp file $TMPFILE already exists.  Get rid of it."
    fi

    if tr -d '\015'  < "$filename" > "$TMPFILE"; then
        # TODO: Was ist mit den Permissions?
        mv "$TMPFILE" "$filename"
    else
        Fatal "Error $? while removing CR from $filename"
    fi
}

function CheckTabs {
    local filename="$1"
    local base="$(basename "$filename")"
    local ext="$(GetFileExt "$filename")"

    if [ "$base" == "Makefile" ] || [ "$ext" == "mk" ] || [ "$ext" == "mak" ]; then
        return
    fi

    if ! egrep -q "$TAB" "$filename"; then
        return
    fi
    if [ "$MODIFY" == "" ]; then
        Warning "$filename contains tabs"
        return
    fi

    Info "Remove Tabs from $filename"
    TMPFILE=foo42

    if [ -f "$TMPFILE" ]; then
        Fatal "Weird...the temp file $TMPFILE already exists.  Get rid of it."
    fi

    if expand -t4 < "$filename" > "$TMPFILE"; then
        # TODO: Was ist mit den Permissions?
        mv "$TMPFILE" "$filename"
    else
        Fatal "Error $? while removing tabs from $filename"
    fi
}


function CheckTrailingWhitespace {
    local filename="$1"
    # "\r?" ist hier im Pattern enthalten, damit ich die auch finde, wenn noch <CR> enthalten sind
    if ! egrep -q "[$TAB ]+$CR?$" "$filename"; then
        return
    fi
    if [ "$MODIFY" == "" ]; then
        Warning "$filename has trailing whitespace"
        return
    fi

    Info "Remove trailing whitespace from $filename"
    # Quelle: http://stackoverflow.com/questions/9264893/how-to-removing-trailing-whitespace-of-all-files-of-selective-file-types-in-a-di
    # -i = Modify inplace
    # -p = eine art While-Schleife? (http://stackoverflow.com/questions/2476919/what-does-perls-p-command-line-switch-do)
    perl -p -i -e "s/[ \t]*$//g" ${filename}
}

function CheckAnsiCodes {
    local filename="$1"
    local apo=$'\x92'
    local gans1=$'\x93'
    local gans2=$'\x94'
    if [ "$MODIFY" == "" ]; then
        Warning "$filename has ansi codes"
        return
    fi

    Info "Substituting some ansi codes from $filename"
    TMPFILE=foo42

    if [ -f "$TMPFILE" ]; then
        Fatal "Weird...the temp file $TMPFILE already exists.  Get rid of it."
    fi

    if iconv -f "windows-1252" -t "UTF-8" "$filename" -o "$TMPFILE"; then
        # TODO: Was ist mit den Permissions?
        mv "$TMPFILE" "$filename"
    else
        Fatal "Error $? while converting ansi codes from $filename"
    fi
}

########################################################################################################################
# Behandlung von genau einer Datei
########################################################################################################################
function DoFile {
    local filename="$1"
    local base="$(basename "$filename")"
    local ext="$(GetFileExt "$filename")"
    #Trace "Preparing ${filename}"
    #if [ "$ext" != "" ]; then
    #    Trace "Fileext = $ext"
    #else
    #    Trace "Base = $base"
    #fi

    # Hier etwas Sicherheitsprüfung, damit ich nicht mal versehentlich eine Binärdatei erwische
    local type="$(file --brief "$filename")"
    #Trace "$filename: $type"
    case "$type" in
        "ASCII text");;
        "ASCII text, with CRLF line terminators");;
        "ASCII English text");;
        "ASCII English text, with CRLF line terminators");;
        "UTF-8 Unicode text");;
        "UTF-8 Unicode text, with CRLF line terminators");;
        "UTF-8 Unicode English text");;
        "UTF-8 Unicode English text, with CRLF line terminators");;

        "ASCII English text, with CRLF, LF line terminators");;

        "UTF-8 Unicode C program text");;
        "UTF-8 Unicode C program text, with CRLF line terminators");;
        "ASCII C program text");;
        "ASCII C program text, with CRLF line terminators");;
        "ASCII C++ program text");;
        "ASCII C++ program text, with CRLF line terminators");;

        "HTML document");;
        "HTML document, ASCII text");;
        "HTML document, ASCII text, with CRLF line terminators");;
        "HTML document, UTF-8 Unicode text");;
        "HTML document, UTF-8 Unicode text, with CRLF line terminators");;

        "ASCII English text, with very long lines");&
        "ASCII English text, with very long lines, with CRLF line terminators");&
        "ASCII C program text, with very long lines");&
        "ASCII C program text, with very long lines, with CRLF line terminators");&
        "HIER NUR EIN DUMMY 1")
            Warning "$filename has type \"$type\""
            #return 0
            ;;

        "HTML document, Non-ISO extended-ASCII text, with CRLF line terminators")
            Warning "$filename has type \"$type\""
            [ "$base" == "readme.txt" ] && CheckAnsiCodes "$filename" # Komischerweise werden einige readme.txt als html eingestuft, wohl wegen der enthaltenen "<a href=...>"
            return 0;;

        "ISO-8859 English text, with CRLF line terminators");&
        "ISO-8859 C program text, with CRLF line terminators");&
        "Non-ISO extended-ASCII text, with CRLF line terminators");&
        "Non-ISO extended-ASCII C program text, with CRLF line terminators");&
        "Non-ISO extended-ASCII English text, with CRLF line terminators");&
        "HIER NUR EIN DUMMY 2")
            Warning "$filename has type \"$type\""
            CheckAnsiCodes "$filename"
            return 0;;

         *) Error "$filename has unhandled type \"$type\""
         return 1
    esac

    CheckLineend "$filename"
    CheckTabs "$filename"
    CheckTrailingWhitespace "$filename"
}

########################################################################################################################
# Schleife über alle zu behandelnden Dateien
########################################################################################################################
function DoAllFiles {
    Trace "Collecting Files"

    # Etwas Aufwand um auch mit Leerzeichen in Dateinamen umgehen zu können
    local files=()
    local i="0"
    # Erst mal alle Files einsammeln
    while IFS= read -r -d $'\0' file; do
        files[i++]="$file"
    done < <(find "${DIRS}" -type f -regextype posix-egrep -regex "${FILE_PATTERNS}" -print0)

    Trace "Found ${#files[@]} Files"

    for file in "${files[@]}"; do
        DoFile "$file"
    done
}


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
    echo "  -m            - Modify files"
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
  elif [ "$1" == "-m" ]; then
    MODIFY="true"
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

# Beispieldaten
# - Lib/Stm/Stm32F10x_StdPeriph_Lib_V3.5.0/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x/startup/gcc_ride7/startup_stm32f10x_ld.s
#   -> hat Tabs, CR und Trailing WS
# - Lib/Stm/Stm32F10x_StdPeriph_Lib_V3.5.0/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x/stm32f10x.h
#   -> Enthält Ansi-kodierte Apostrophe (92h)
#      Sobald man das File mit Eclipse als Utf-8 öffnet und dann speichert, werden die in � ersetzt (EF BF BD)
# - Lib/Stm/Stm32F10x_StdPeriph_Lib_V3.5.0/Project/STM32F10x_StdPeriph_Template/TrueSTUDIO/STM32100E-EVAL/stm32_flash.ld
#   -> Enthält Ansi-kodierte Anführungszeichen (93h und 94h)
#      -> The file is distributed "as is," ...
# - Lib/Stm/Stm32F4xx_DSP_StdPeriph_Lib_V1.3.0/Libraries/CMSIS/DSP_Lib/Examples/arm_graphic_equalizer_example/arm_graphic_equalizer_data.c
#   -> Überwiegend CR-LF aber auch eine Zeile mit nur LF
# - Lib/Stm/Stm32F2xx_StdPeriph_Lib_V1.1.0/Project/STM32F2xx_StdPeriph_Examples/PWR/STOP/readme.txt
#   -> enthält Ansicode ™ in "Cortex™-M3"


DIRS="Lib"
FILE_PATTERNS="("
FILE_PATTERNS="${FILE_PATTERNS}.*\.h|"
FILE_PATTERNS="${FILE_PATTERNS}.*\.c|"
FILE_PATTERNS="${FILE_PATTERNS}.*\.hxx|"
FILE_PATTERNS="${FILE_PATTERNS}.*\.cxx|"
FILE_PATTERNS="${FILE_PATTERNS}.*\.s|"
FILE_PATTERNS="${FILE_PATTERNS}.*\.S|"
FILE_PATTERNS="${FILE_PATTERNS}.*\.ld|"
FILE_PATTERNS="${FILE_PATTERNS}.*\.lds|"
FILE_PATTERNS="${FILE_PATTERNS}.*\.txt|"
FILE_PATTERNS="${FILE_PATTERNS}.*\.md|"
FILE_PATTERNS="${FILE_PATTERNS}DUMMY_EINTRAG)"
#FILE_PATTERNS=".*"

#FILE_PATTERNS="(Lib/Stm/Stm32F10x_StdPeriph_Lib_V3.5.0/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x/startup/gcc_ride7/startup_stm32f10x_ld.s|.*\.md)"
#FILE_PATTERNS="(.*/startup_stm32f10x_ld.s|.*\.md)"

DoAllFiles
