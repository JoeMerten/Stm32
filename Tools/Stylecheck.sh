#!/bin/bash -e
########################################################################################################################
# Sourcen untersuchen auf Korrektheit der Doxygen Kommentare et cetera
#-----------------------------------------------------------------------------------------------------------------------
# \project    Multithreaded C++ Framework
# \file       Stylecheck.sh
# \creation   2015-02-26, Joe Merten
#-----------------------------------------------------------------------------------------------------------------------
# Achtung: Wegen bash -e sollte in diesem Skript weder "let" noch "expr" verwendet serden. ((i++)) ist ebenfalls problematisch.
# Workaround: "||:" dahinter schreiben, also z.B.:
#   let 'i++' ||:
# Siehe auch: http://unix.stackexchange.com/questions/63166/bash-e-exits-when-let-or-expr-evaluates-to-0
#-----------------------------------------------------------------------------------------------------------------------
# Status:
# - Kommentarheader von
# Weitere Ideen:
# - für .c und .cxx: Suche nach dem ersten #include, aber Ausnahmen zulassen (z.B. für WO_Bala.c)
# - für .h und .hxx: Includeschutz prüfen (wg. möglicher Copy & Paste Fehler)
# - einsammeln aller Projektnamen und Autoren -> optionale Ausgabe derer
########################################################################################################################

########################################################################################################################
# JoeBashLib.sh einbinden
########################################################################################################################

source JoeBashLib.sh


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

declare DIRS=()
declare FILE_PATTERNS=()


########################################################################################################################
# Prüfung des Header Kommentars
#-----------------------------------------------------------------------------------------------------------------------
# \in  filename  Dateiname
# \in  linenr    Zeilnummer
# \in  linestr   Zeile (String)
#-----------------------------------------------------------------------------------------------------------------------
# C Sourcen nach dem Schema:
#     /***********************************************************************************************************************
#       Template
#     ------------------------------------------------------------------------------------------------------------------------
#       \project    VISTRA-I LED Anzeigetafel der EEO GmbH
#       \file       Template.c
#       \creation   2015-02-15, Joe Merten, JME Engineering Berlin
#     ------------------------------------------------------------------------------------------------------------------------
#       Optional weitere Beschreibung
#     ***********************************************************************************************************************/
#
# Shellskripte & Makefiles nach dem Schema:
#     ########################################################################################################################
#     # Sourcen untersuchen auf Korrektheit der Doxygen Kommentare et cetera
#     #-----------------------------------------------------------------------------------------------------------------------
#     # \project    Multithreaded C++ Framework
#     # \file       Stylecheck.sh
#     # \creation   2015-02-26, Joe Merten
#     #-----------------------------------------------------------------------------------------------------------------------
#     # Optional weitere Beschreibung
#     ########################################################################################################################
# wobei jedoch bei Skripten die erste Zeile im Regelfall "#!/bin/bash -e" sein wird und der Kommentarheader somit erst bei Zeile 2 beginnt.
#
########################################################################################################################

DOXY_SOURCE_BEG_LINE='/***********************************************************************************************************************'
DOXY_SOURCE_SEP_LINE='------------------------------------------------------------------------------------------------------------------------'
DOXY_SOURCE_END_LINE='***********************************************************************************************************************/'
DOXY_BASH_BEG_LINE='########################################################################################################################'
DOXY_BASH_SEP_LINE='#-----------------------------------------------------------------------------------------------------------------------'
DOXY_BASH_END_LINE='########################################################################################################################'

function checkHeaderLine {
    local filename="$1"
    local linenr="$2"
    local linestr="$3"
    local warn="false"
    case "$linenr" in
        1) [  "$linestr" == "$DOXY_SOURCE_BEG_LINE" ] || warn="true";;
        2) [[ "$linestr" =~ ^"  "[^" "] ]] || warn="true";;
        3) [  "$linestr" == "$DOXY_SOURCE_SEP_LINE" ] || warn="true";;
        4) [[ "$linestr" =~ ^"  \\project    "[^" "] ]] || warn="true";;
        5) [[ "$linestr" =~ ^"  \\file       $(basename "$filename")"$ ]] || warn="true";;
        6) [[ "$linestr" =~ ^"  \\creation   20"[0-9][0-9]-[0-1][0-9]-[0-3][0-9]", " ]] || warn="true";;
        7) [  "$linestr" == "$DOXY_SOURCE_SEP_LINE" ] || [  "$linestr" == "$DOXY_SOURCE_END_LINE" ] || warn="true";;
    esac

    if [ "$warn" != "false" ]; then
        Warning "$filename:$linenr: \"$linestr\""
        if [ "$warn" != "true" ]; then
            Warning "$filename:$linenr: \"$warn\""
        fi
    fi
}

########################################################################################################################
# Behandlung von genau einer Datei
########################################################################################################################
function DoFile {
    local filename="$1"
    local name="$(basename "$filename")"
    local ext="$(GetFileExt "$filename")"
    local linenr="0"

    while IFS= read -r line || [[ -n "$line" ]]; do
        let 'linenr++' ||:
        checkHeaderLine "$filename" "$linenr" "$line"
        [ "$linenr" == "10" ] && break
    done < "$filename"

    return 0
}

########################################################################################################################
# Schleife über alle zu behandelnden Dateien
########################################################################################################################
function DoAllFiles {
    Trace "Collecting Files"

    # Umwandlung der FILE_PATTERNS in einen für find passenden Regular Expression
    local re=""
    for pat in "${FILE_PATTERNS[@]}"; do
      [ "$re" != "" ] && re+='|'
      re+="$pat"
    done
    re="($re)"
    #Trace "Find RE = \"$re\""

    # Etwas Aufwand um auch mit Leerzeichen in Dateinamen umgehen zu können
    local files=()
    local i="0"
    # Erst mal alle Files einsammeln
    while IFS= read -r -d $'\0' file; do
        files[i++]="$file"
    done < <(find "${DIRS[@]}" -type f -regextype posix-egrep -regex "${re}" -print0)

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
    echo "${AQUA}Stylecheck${TEAL}, Joe Merten 2015"
    echo "usage: $0 [options] ..."
    echo "Available options:"
    echo "  nocolor       - Dont use Ansi VT100 colors"
    #echo "  -m            - Modify files"
    #echo "  -e            - List file extentions"
    echo -n "${NORMAL}"
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
#   elif [ "$1" == "-m" ] || [ "$1" == "--modify" ]; then
#       MODIFY="true"
    else
        DIRS+=("$1")
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

# Wenn kein Verzeichnis angegeben, dann defaulten wir auf "."
[ "${#DIRS[@]}" == "0" ] && DIRS+=('.')

# Meine FilePatterns sind Regular Expressions (wg. find)
FILE_PATTERNS+=('.*\.h')
FILE_PATTERNS+=('.*\.c')
FILE_PATTERNS+=('.*\.hxx')
FILE_PATTERNS+=('.*\.cxx')
FILE_PATTERNS+=('.*\.hpp')
FILE_PATTERNS+=('.*\.cpp')

#FILE_PATTERNS+=('.*\.s')
#FILE_PATTERNS+=('.*\.S')
#FILE_PATTERNS+=('.*\.ld')
#FILE_PATTERNS+=('.*\.lds')

#FILE_PATTERNS+=('.*Makefile')
#FILE_PATTERNS+=('.*Makefile\..*') # z.B. für "Makefile.posix"
#FILE_PATTERNS+=('.*\.mk')
#FILE_PATTERNS+=('.*\.sh')
#FILE_PATTERNS+=('.*\.bsh')

# zus. für Android / Java
FILE_PATTERNS+=('.*\.java')
#FILE_PATTERNS+=('.*\.prefs')
#FILE_PATTERNS+=('.*\.properties')
#FILE_PATTERNS+=('.*\.xml')
#FILE_PATTERNS+=('.*\.classpath')
#FILE_PATTERNS+=('.*\.project')

DoAllFiles
