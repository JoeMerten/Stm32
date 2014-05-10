#!/bin/bash -e
########################################################################################################################
# Sourcen auf Whitespace Unsauberkeiten untersuchen
#-----------------------------------------------------------------------------------------------------------------------
# \project    Multithreaded C++ Framework
# \file       Whitespace.sh
# \creation   2014-05-10, Joe Merten
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
########################################################################################################################
function NoColor {
    BLACK=""; MAROON=""; GREEN=""; OLIVE=""; NAVY=""; PURPLE="" TEAL="" SILVER=""; GRAY=""
    RED=""; LIME=""; YELLOW=""; BLUE=""; FUCHSIA=""; AQUA=""; WHITE=""; NORMAL=""; LIGHT=""
    LOG_COLOR_FATAL=""; LOG_COLOR_ERROR=""
    LOG_COLOR_WARN="";  LOG_COLOR_INFO=""
    LOG_COLOR_DEBUG=""; LOG_COLOR_TRACE=""
}


########################################################################################################################
# Terminalfarben restaurieren, wenn Abbruch via Ctrl+C
########################################################################################################################
function OnCtrlC {
    echo "${RED}[*** interrupted ***]${NORMAL}"
    # damit bei Ctrl+C auch alle Childprozesse beendet werden
    kill -INT 0
    #exit 1
}
trap OnCtrlC SIGINT

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


# TODO: Näher untersuchen und für mich anpassen
#tempfiles=( )
#cleanup() {
    #rm -f "${tempfiles[@]}"
#}
#trap cleanup EXIT
#trap "echo "${RED}**EXIT**${NORMAL}"; kill 0" EXIT


# TODO: Näher untersuchen und für mich anpassen
function OnError() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  exit "${code}"
}
trap 'OnError ${LINENO}' ERR

function my_trap_handler() {
        MYSELF="$0"               # equals to my script name
        LASTLINE="$1"            # argument 1: last line of error occurence
        LASTERR="$2"             # argument 2: error code of last command
        echo "script error encountered at `date` in ${MYSELF}: line ${LASTLINE}: exit status of last command: ${LASTERR}" >&2

        # do additional processing: send email or SNMP trap, write result to database, etc.
    #
    # let's assume we send an email message with
    # subject: "script error encountered at `date` in ${MYSELF}: line ${LASTLINE}: exit status of last command: ${LASTERR}"
    # with additional contents of ${my_log_file} as email body
}
trap 'my_trap_handler ${LINENO} ${$?}' ERR
trap 'my_trap_handler ${LINENO} $?' ERR



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


function CheckTabs {
    local filename="$1"
    local base="$(basename "$filename")"
    local ext="$(GetFileExt "$filename")"

    # Todo: Auch Makefiele.posix etc abfangen
    if [ "$base" == "Makefile" ] || [ "$ext" == "mk" ] || [ "$ext" == "mak" ]; then
        return
    fi

    if ! egrep -q $'\t' "$filename"; then
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

    CheckTabs "$filename"
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

DIRS="Lib"
FILE_PATTERNS="("
#FILE_PATTERNS="${FILE_PATTERNS}.*\.h|"
#FILE_PATTERNS="${FILE_PATTERNS}.*\.c|"
#FILE_PATTERNS="${FILE_PATTERNS}.*\.hxx|"
#FILE_PATTERNS="${FILE_PATTERNS}.*\.cxx|"
#FILE_PATTERNS="${FILE_PATTERNS}.*\.s|"
#FILE_PATTERNS="${FILE_PATTERNS}.*\.S|"
#FILE_PATTERNS="${FILE_PATTERNS}.*\.ld|"
#FILE_PATTERNS="${FILE_PATTERNS}.*\.lds|"
#FILE_PATTERNS="${FILE_PATTERNS}.*\.txt|"
FILE_PATTERNS="${FILE_PATTERNS}.*\.md"
FILE_PATTERNS="${FILE_PATTERNS})"
#FILE_PATTERNS=".*"

#FILE_PATTERNS="(Lib/Stm/Stm32F10x_StdPeriph_Lib_V3.5.0/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x/startup/gcc_ride7/startup_stm32f10x_ld.s|.*\.md)"
FILE_PATTERNS="(.*/startup_stm32f10x_ld.s|.*\.md)"
DoAllFiles

exit 2


echo "do something"
Trace   "Traceausgabe"
Debug   "Debugausgabe"
Info    "Infoausgabe"
Warning "Warnmeldung"
Error   "Fehlermeldung"
Fatal   "Fatal Fehler"







##
##  <CR>
##  #!/bin/sh
##
##  TMPFILE=foo42
##
##  if [ -f $TMPFILE ] ; then
##      echo Weird...the temp file $TMPFILE already exists.  Get rid of it.
##      exit 0
##  fi
##
##  while [ $# -ne 0 ] ; do
##      tr -d '\015' < $1 > $TMPFILE
##      if [ $? -eq 0 ] ; then
##          mv $TMPFILE $1
##          echo Successfully translated $1 from a DOS text file.
##      fi
##      shift
##  done
##
##  rm -f $TMPFILE
##
##

