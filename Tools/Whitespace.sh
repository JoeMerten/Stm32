#!/bin/bash -e
########################################################################################################################
# Sourcen auf Whitespace Unsauberkeiten untersuchen
#-----------------------------------------------------------------------------------------------------------------------
# \project    Multithreaded C++ Framework
# \file       Whitespace.sh
# \creation   2014-05-10, Joe Merten
#-----------------------------------------------------------------------------------------------------------------------
# Achtung: Wegen bash -e sollte in diesem Skript weder "let" noch "expr" verwendet serden. ((i++)) ist ebenfalls problematisch.
# Workaround: "||:" dahinter schreiben, also z.B.:
#   let 'i++' ||:
# Siehe auch: http://unix.stackexchange.com/questions/63166/bash-e-exits-when-let-or-expr-evaluates-to-0
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
declare MODIFY=""
declare LIST_EXTENTIONS=""
declare FOLLOW_SYMLINKS=""
declare ALLOW_TABS_CONSEQUENT=""


########################################################################################################################
#   _____ _                         _____            _    _   _
#  | ____(_) __ _  ___ _ __   ___  |  ___|   _ _ __ | | _| |_(_) ___  _ __   ___ _ __
#  |  _| | |/ _` |/ _ \ '_ \ / _ \ | |_ | | | | '_ \| |/ / __| |/ _ \| '_ \ / _ \ '_ \
#  | |___| | (_| |  __/ | | |  __/ |  _|| |_| | | | |   <| |_| | (_) | | | |  __/ | | |
#  |_____|_|\__, |\___|_| |_|\___| |_|   \__,_|_| |_|_|\_\\__|_|\___/|_| |_|\___|_| |_|
#           |___/
########################################################################################################################

declare TAB=$'\t'
declare CR=$'\r'

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
    #blubber="$(ls blubber)" # Testcode um das Skriptverhalten bei Fehlern zu testen
    local filename="$1"
    local base="$(GetFileBase "$filename")"
    local ext="$(GetFileExt "$filename")"

    if [ "$base" == "Makefile" ] || [ "$ext" == "mk" ] || [ "$ext" == "mak" ]; then
        # Bei Makefiles haben Tabs syntaktische Bedeutung
        return
    fi

    if [ "$base" == ".project" ] || [ "$base" == ".cproject" ] ||
       [ "$base.$ext" == "language.settings.xml" ] ||
       [ "$base" == ".classpath" ]; then
        # Bei Eclipse Projectfiles und Java Classpath behalte ich die Tabs bei, da es sich im Regelfall um generierte Dateien handelt
        return
    fi

    ! egrep -q "$TAB" "$filename" && return
    # Tabs detected ...

    local pureTabs="true"
    # Check if also has space indentation
    egrep -q "^(    )+[^ ]" "$filename" && pureTabs="false"
    # Check if also has mixed space / tab indentation like this:
    #   "→   ☐☐☐☐Abc..."
    #   "☐☐☐☐→   Abc..."
    # etc, but allow:
    #   "→   /* Abc..."
    #   "→   ☐☐☐dev..."
    egrep -q "$TAB(    )+[^ ]" "$filename" && pureTabs="false"
    egrep -q "    $TAB" "$filename" && pureTabs="false"

    [ "$ALLOW_TABS_CONSEQUENT" == "true" ] && [ "$pureTabs" == "true" ] && return

    if [ "$MODIFY" == "" ]; then
        if [ "$pureTabs" == "true" ]; then
            Warning "$filename contains tabs"
        else
            Warning "$filename contains tabs and also uses space and / or mixed indentation"
        fi
        #Trace "Base=\"$base\" Ext=\"$ext\""
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
    perl -p -i -e "s/[ \t]*$//g" "${filename}"
}

function CheckAnsiCodes {
    local filename="$1"
    #local apo=$'\x92'
    #local gans1=$'\x93'
    #local gans2=$'\x94'
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
# Ergebnis von "file" zerlegen
#-----------------------------------------------------------------------------------------------------------------------
# \in  String     Zu untersuchender String (Ergebnis von "file")
# \in  Substring  Zu suchender Substring
# \ret            String, ggf. mit entferntem Substring
# \ret            0 = Falls Substring gefunden (und entfernt) werden konnte
# \ret            1 = Falls Substring nicht gefunden wurde
#-----------------------------------------------------------------------------------------------------------------------
# ACHTUNG: String und Substring dürfen folgende Zeichen nicht beinhalten: {}/ ... weitere?
# Diese Funktion soll helfen, die Rückgabe von "file" etwas strukturiert zu untersuchen.
# Siehe auch http://www.thegeekstuff.com/2010/07/bash-string-manipulation/
# file liefert Dinge wie z.B.:
#        "ASCII text"
#        "ASCII text, with CRLF line terminators"
#        "ASCII English text"
#        "ASCII English text, with CRLF line terminators"
#        "ASCII text, with no line terminators"
#        "UTF-8 Unicode text"
#        "UTF-8 Unicode text, with CRLF line terminators"
#        "UTF-8 Unicode English text"
#        "UTF-8 Unicode English text, with CRLF line terminators"
#        "ASCII English text, with CRLF, LF line terminators"
#        "ASCII C++ program text, with CRLF, LF line terminators"
#        "Python script, ASCII text executable"   # Hmm, komischerweise wird "Lib/Stm/Stm32F10x_StdPeriph_Lib_V3.5.0/Utilities/STM32_EVAL/Common/fonts.c" als solchiges erkannt
#        "Bourne-Again shell script, UTF-8 Unicode text executable"
#        "UTF-8 Unicode C program text"
#        "UTF-8 Unicode C program text, with CRLF line terminators"
#        "UTF-8 Unicode C++ program text"
#        "ASCII C program text"
#        "ASCII C program text, with CRLF line terminators"
#        "ASCII C++ program text"
#        "ASCII C++ program text, with CRLF line terminators"
#        "C source, ASCII text"   # Offenbar seit Kubuntu 14.04, vorher "ASCII C program text"
#        "C++ source, ASCII text"
#        "ASCII assembler program text"
#        "ASCII make commands text"  # Makefile
#        "UTF-8 Unicode make commands text"
#        "ASCII Java program text"
#        "UTF-8 Unicode Java program text"
#        "C program text (from flex), "  # Thrift/thrift-0.9.1/compiler/cpp/thriftl.cc
#        "XML document text"
#        "TeX document, ASCII text"     # Komischerweise wird ein Makefile aus dem Nordic Sdk 5.2.0 als solches erkannt...
#        "LaTeX document, ASCII text"   #   "  und hier console.h ?!
#        "Blink archive data"           #   "  Examples/NordicSdk/Blinky/README.md ?!?
#        "HTML document"
#        "HTML document, ASCII text"
#        "HTML document, ASCII text, with CRLF line terminators"
#        "HTML document, UTF-8 Unicode text"
#        "HTML document, UTF-8 Unicode text, with CRLF line terminators"
#        "ASCII text, with very long lines"
#        "ASCII English text, with very long lines"
#        "ASCII English text, with very long lines, with CRLF line terminators"
#        "UTF-8 Unicode English text, with very long lines"
#        "ASCII C program text, with very long lines"
#        "ASCII C program text, with very long lines, with CRLF line terminators"
#        "UTF-8 Unicode C program text, with very long lines"
#        "HTML document, Non-ISO extended-ASCII text, with CRLF line terminators")
#        "data"
#        "ISO-8859 English text"
#        "ISO-8859 English text, with CRLF line terminators"
#        "ISO-8859 C program text, with CRLF line terminators"
#        "Non-ISO extended-ASCII text, with CRLF line terminators"
#        "Non-ISO extended-ASCII C program text, with CRLF line terminators"
#        "Non-ISO extended-ASCII English text, with CRLF line terminators"
########################################################################################################################
declare Test_CheckAndRemoveFileTypePart_ReturnAlways_0="false"
function CheckAndRemoveFileTypePart {
    local a
    a="${1/$2}"
    if [ "$a" == "$1" ]; then
        # nix gefunden
        echo "$a"
        [ "$Test_CheckAndRemoveFileTypePart_ReturnAlways_0" == "true" ] && return 0 # Hack für die Tests
        return 1
    fi

    # Treffer!
    # Jetzt noch ggf. entfernen:
    # - Doppelte Komma "C program text, , with CRLF line terminators"
    # - Komma am Anfang und Ende "C program text, "
    a="${a//  / }"    # Doppelte Spaces entfernen
    a="${a//, , /, }" # Doppelte Kommata entfernen
    a="$(Trim "$a")"
    a="${a#"${a%%[!,]*}"}"   # remove leading comma
    a="${a%"${a##*[!,]}"}"   # remove trailing comma
    a="$(Trim "$a")"

    echo "$a"
    return 0
}

function Test_CheckAndRemoveFileTypePart {
    Test_CheckAndRemoveFileTypePart_ReturnAlways_0="true"
    Test_Check "$(CheckAndRemoveFileTypePart  "ASCII text"                                                              "with CRLF line terminators"     )"   "ASCII text"
    Test_Check "$(CheckAndRemoveFileTypePart  "ASCII text, with CRLF line terminators"                                  "with CRLF line terminators"     )"   "ASCII text"
    Test_Check "$(CheckAndRemoveFileTypePart  "ASCII C++ program text, with CRLF, LF line terminators"                  "with CRLF, LF line terminators" )"   "ASCII C++ program text"
    Test_Check "$(CheckAndRemoveFileTypePart  "ASCII text, with very long lines"                                        "with very long lines"           )"   "ASCII text"
    Test_Check "$(CheckAndRemoveFileTypePart  "ASCII English text, with very long lines"                                "with very long lines"           )"   "ASCII English text"
    Test_Check "$(CheckAndRemoveFileTypePart  "ASCII English text, with very long lines, with CRLF line terminators"    "with very long lines"           )"   "ASCII English text, with CRLF line terminators"
    Test_Check "$(CheckAndRemoveFileTypePart  "UTF-8 Unicode English text, with very long lines"                        "UTF-8 Unicode"                  )"   "English text, with very long lines"
    Test_Check "$(CheckAndRemoveFileTypePart  "ASCII C program text, with very long lines"                              "ASCII"                          )"   "C program text, with very long lines"
    Test_Check "$(CheckAndRemoveFileTypePart  "ASCII C program text, with very long lines, with CRLF line terminators"  "ASCII"                          )"   "C program text, with very long lines, with CRLF line terminators"
    Test_Check "$(CheckAndRemoveFileTypePart  "UTF-8 Unicode C program text, with very long lines"                      "with very long lines"           )"   "UTF-8 Unicode C program text"
    Test_Check "$(CheckAndRemoveFileTypePart  "HTML document, Non-ISO extended-ASCII text, with CRLF line terminators"  "HTML document"                  )"   "Non-ISO extended-ASCII text, with CRLF line terminators"
    #Test_Check "$(CheckAndRemoveFileTypePart  "HTML document, Non-ISO extended-ASCII text, with CRLF line terminators"  "Non-ISO extended-ASCII"         )"   "HTML document, with CRLF line terminators"
    Test_Check "$(CheckAndRemoveFileTypePart  "data"                                                                    "irgendwas"                      )"   "data"
    Test_Check "$(CheckAndRemoveFileTypePart  "ISO-8859 English text"                                                   "ISO-8859"                       )"   "English text"
    Test_Check "$(CheckAndRemoveFileTypePart  "ISO-8859 English text, with CRLF line terminators"                       "ISO-8859"                       )"   "English text, with CRLF line terminators"
    Test_Check "$(CheckAndRemoveFileTypePart  "ISO-8859 C program text, with CRLF line terminators"                     "ISO-8859"                       )"   "C program text, with CRLF line terminators"
    Test_Check "$(CheckAndRemoveFileTypePart  "Non-ISO extended-ASCII text, with CRLF line terminators"                 "Non-ISO extended-ASCII"         )"   "text, with CRLF line terminators"
    Test_Check "$(CheckAndRemoveFileTypePart  "Non-ISO extended-ASCII C program text, with CRLF line terminators"        "with CRLF line terminators"    )"   "Non-ISO extended-ASCII C program text"
    Test_CheckAndRemoveFileTypePart_ReturnAlways_0="false"
}
Test_CheckAndRemoveFileTypePart

########################################################################################################################
# Behandlung von genau einer Datei
########################################################################################################################
function DoFile {
    local filename="$1"
    local name="$(basename "$filename")"
    local ext="$(GetFileExt "$filename")"
    #Trace "Preparing ${filename}"
    #return 0
    #if [ "$ext" != "" ]; then
    #    Trace "Fileext = $ext"
    #else
    #    Trace "Name = $name"
    #fi

    # Hier etwas Sicherheitsprüfung, damit ich nicht mal versehentlich eine Binärdatei erwische
    local type="$(file --brief -L "$filename")"
    # Trim, weil z.B. Kubuntu 12.04 "empty" aber Kubuntu 14.04: "empty "
    local strippedType="$(Trim "$type")"
    local htmlDoc="false"
    local crlfAndlf="false"
    local crlfAndcr="false"
    local crlf="false"
    local nolf="false"
    local longLines="false"
    local nonIso="false"
    local iso8859="false"
    local ascii="false"
    local utf8="false"

    #strippedType="$(CheckAndRemoveFileTypePart "$strippedType" "HTML document"                  )"  && htmlDoc="true"    # sollte als erstes bleiben, siehe obige Tests
    strippedType="$(CheckAndRemoveFileTypePart "$strippedType" "with CRLF, LF line terminators" )"  && crlfAndlf="true"
    strippedType="$(CheckAndRemoveFileTypePart "$strippedType" "with CRLF, CR line terminators" )"  && crlfAndcr="true"
    strippedType="$(CheckAndRemoveFileTypePart "$strippedType" "with CRLF line terminators"     )"  && crlf="true"
    strippedType="$(CheckAndRemoveFileTypePart "$strippedType" "with no line terminators"       )"  && nolf="true"
    strippedType="$(CheckAndRemoveFileTypePart "$strippedType" "with very long lines"           )"  && longLines="true"

    strippedType="$(CheckAndRemoveFileTypePart "$strippedType" "Non-ISO extended-ASCII"         )"  && nonIso="true"
    strippedType="$(CheckAndRemoveFileTypePart "$strippedType" "ISO-8859"                       )"  && iso8859="true"
    strippedType="$(CheckAndRemoveFileTypePart "$strippedType" "ASCII"                          )"  && ascii="true"
    strippedType="$(CheckAndRemoveFileTypePart "$strippedType" "UTF-8 Unicode"                  )"  && utf8="true"

    #Trace "$filename: $type / $strippedType"

    if [ "$nonIso" == "true" ] || [ "$iso8859" == "true" ]; then
        # Bei diesen hier immer warnen, auch wenn konvertiert wird. Z.B.:
        #     "ISO-8859 English text"
        #     "ISO-8859 English text, with CRLF line terminators"
        #     "ISO-8859 C program text, with CRLF line terminators"
        #     "Non-ISO extended-ASCII text, with CRLF line terminators"
        #     "Non-ISO extended-ASCII C program text, with CRLF line terminators"
        #     "Non-ISO extended-ASCII English text, with CRLF line terminators"
        Warning "$filename has type \"$type\" /  \"$strippedType\""
        CheckAnsiCodes "$filename"
        # Mit denen jetzt erst mal nichts weiter tun. Tabs etc. erst im nächsten Durchlauf.
        return 0
    fi

    case "$strippedType" in
        "empty");&
        "HIER NUR EIN DUMMY 1")
            # Leere Dateien ignorieren wir hier
            # gefunden in /D/git/N4/Embedded/Thrift/thrift-0.9.1/lib/rb/ext/protocol.h
            Warning "$filename has type \"$type\" /  \"$strippedType\""
            return 0
            ;;

        "text");;
        "English text");;

        "Python script, text executable");;  # Hmm, komischerweise wird "Lib/Stm/Stm32F10x_StdPeriph_Lib_V3.5.0/Utilities/STM32_EVAL/Common/fonts.c" als solchiges erkannt
        "script text executable for python, text");;
        "Bourne-Again shell script, text executable");;
        "POSIX shell script, text executable");;

        "C program text");;
        "C++ program text");;
        "C source, text");;                # Offenbar seit Kubuntu 14.04, vorher "ASCII C program text"
        "C++ source, text");;
        "assembler program text");;
        "assembler source text");;         # Seit Kubuntu 14.04
        "make commands text");;            # Makefile
        "makefile script, text");;
        "automake makefile script, text");; # Z.B. bei Thrift
        "Java program text");;
        "Pascal source, text");;

        "C program text (from flex),");;   # Thrift/thrift-0.9.1/compiler/cpp/thriftl.cc
        "(with BOM) text");;               # Thrift/thrift-0.9.1/sonar-project.properties "UTF-8 Unicode (with BOM) text"
        "BOA archive data");;              # Stm32/Lib/Stm/Stm32F4xx_DSP_StdPeriph_Lib_V1.3.0/Project/STM32F4xx_StdPeriph_Templates/TrueSTUDIO/STM32F401xx/.settings/com.atollic.truestudio.debug.hardware_device.prefs

        "XML document text");;
        "XML 1.0 document, text");;        # Zuweilen bei Eclipse .project?!
        "TeX document, text");;            # Komischerweise wird ein Makefile aus dem Nordic Sdk 5.2.0 als solches erkannt...
        "LaTeX document, text");;          #   "  und hier console.h ?!
        "Blink archive data");;            #   "  Examples/NordicSdk/Blinky/README.md ?!?

        "HTML document");;
        "HTML document, text");;           # Komischerweise werden einige readme.txt als html eingestuft, wohl wegen der enthaltenen "<a href=...>"
        "exported SGML document, text");;  # nRF51/Android/nRF-Toolbox/res/values-sw600dp/dimens.xml

        "Embedded OpenType (EOT)");;       # Kurioses bei: /D/git/N4/Embedded/Lpc43/Common/Lib/Lpcopen/lpcopen_2_12_lpcxpresso_ngx_xplorer_4330/lpc_chip_43xx_m0/inc/lpc_types.h
        "FORTRAN program,");;              # Kurioses bei: "/D/git/N4/Embedded/Lpc43/Common/Dok/Lpc Setup Notes.txt"

        "data");&
        "HIER NUR EIN DUMMY 2")
            # u8g_font_data.c
            Warning "$filename has type \"$type\" /  \"$strippedType\""
            #return 0
            ;;

         *) Error "$filename has unhandled type \"$type\" /  \"$strippedType\""
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

    # Umwandlung der FILE_PATTERNS in einen für find passenden Regular Expression
    local re=""
    for pat in "${FILE_PATTERNS[@]}"; do
      [ "$re" != "" ] && re+='|'
      re+="$pat"
    done
    re="($re)"
    #Trace "Find RE = \"$re\""

    # Regular Expression um diverse Verzeichnisse komplett auszuschliessen
    # Debug & Release sind von Eclipse Managed Make
    # Out ist häuffig von mir
    # build ist wohl Standard bei N4
    local excludeDirsRe="/(Debug|Release|Out|build)/"

    # Etwas Aufwand um auch mit Leerzeichen in Dateinamen umgehen zu können
    local files=()
    local i="0"
    local findopts=""
    [ "$FOLLOW_SYMLINKS" != "" ] && findopts+=" -L"; # follow Symlinks
    # Erst mal alle Files einsammeln
    while IFS= read -r -d $'\0' file; do
        if ! [[ "$file" =~ $excludeDirsRe ]]; then
            files[i++]="$file"
        fi
    done < <(find ${findopts} "${DIRS[@]}" -type f -regextype posix-egrep -regex "${re}" -print0)

    Trace "Found ${#files[@]} Files"

    for file in "${files[@]}"; do
        DoFile "$file"
    done
}


########################################################################################################################
# Auflistung aller Dateitypen
########################################################################################################################
function DoListFileTypes {
    local ext=""
    while IFS= read -r -d $'\0' file; do
        ext="$(GetFileExt "$file")"
        if [ "$ext" != "" ]; then
            echo "*.$ext"
        else
            echo "$(basename "$file")"
        fi
    done < <(find "${DIRS[@]}" -type f -print0) | LC_ALL=C sort -u
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
    echo "${AQUA}Whitespace checker${TEAL}, Joe Merten 2014"
    echo "usage: $0 [options] ..."
    echo "Available options:"
    echo "  --nocolor     - Dont use Ansi VT100 colors"
    echo "  -m            - Modify files"
    echo "  -e            - List file extentions"
    echo "  -L            - Follow Symlinks (like find do)"
    echo "  -t            - Don't denounce tabs if they are not mixed up with space indentation"
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
  elif [ "$1" == "-e" ] || [ "$1" == "--listext" ]; then
    LIST_EXTENTIONS="true"
  elif [ "$1" == "-m" ] || [ "$1" == "--modify" ]; then
    MODIFY="true"
  elif [ "$1" == "-L" ]; then
    FOLLOW_SYMLINKS="true"
  elif [ "$1" == "-t" ]; then
    ALLOW_TABS_CONSEQUENT="true"
  else
    DIRS+=("$1")
    #echo "Unexpected parameter \"$1\"" >&2
    #ShowHelp
    #exit 1
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

# Wenn kein Verzeichnis angegeben, dann defaulten wir auf "."
[ "${#DIRS[@]}" == "0" ] && DIRS+=('.')

if [ "$LIST_EXTENTIONS" == "true" ]; then
    DoListFileTypes
    exit
fi

# Meine FilePatterns sind Regular Expressions (wg. find)
FILE_PATTERNS+=('.*\.h')
FILE_PATTERNS+=('.*\.c')
FILE_PATTERNS+=('.*\.hxx')
FILE_PATTERNS+=('.*\.cxx')
FILE_PATTERNS+=('.*\.hpp')
FILE_PATTERNS+=('.*\.cpp')
FILE_PATTERNS+=('.*\.cc')  # Wg. Thrift
FILE_PATTERNS+=('.*\.s')
FILE_PATTERNS+=('.*\.S')
FILE_PATTERNS+=('.*\.ld')
FILE_PATTERNS+=('.*\.lds')
FILE_PATTERNS+=('.*\.txt')
FILE_PATTERNS+=('.*\.md')
FILE_PATTERNS+=('.*Makefile')
FILE_PATTERNS+=('.*Makefile\..*') # z.B. für "Makefile.posix"
FILE_PATTERNS+=('.*\.mk')
FILE_PATTERNS+=('.*\.sh')
FILE_PATTERNS+=('.*\.bsh')
FILE_PATTERNS+=('.*\.py')

# zus. für Android / Java
FILE_PATTERNS+=('.*\.java')
FILE_PATTERNS+=('.*\.prefs')
FILE_PATTERNS+=('.*\.properties')
FILE_PATTERNS+=('.*\.xml')
FILE_PATTERNS+=('.*\.classpath')
FILE_PATTERNS+=('.*\.project')


#DIRS=("Lib/Stm/Stm32F10x_StdPeriph_Lib_V3.5.0/Libraries")
#FILE_PATTERNS=(".*")
#FILE_PATTERNS="(Lib/Stm/Stm32F10x_StdPeriph_Lib_V3.5.0/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x/startup/gcc_ride7/startup_stm32f10x_ld.s|.*\.md)"
#FILE_PATTERNS="(.*/startup_stm32f10x_ld.s|.*\.md)"
#FILE_PATTERNS="(Lib/Stm/Stm32F10x_StdPeriph_Lib_V3.5.0/Libraries/STM32F10x_StdPeriph_Driver/src/stm32f10x_rcc.c)"

DoAllFiles
