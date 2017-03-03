#!/usr/bin/env python3
########################################################################################################################
# Testing Ansi Capabilities of Terminals
#-----------------------------------------------------------------------------------------------------------------------
# \project    Multithreaded C++ Framework
# \file       AnsiColors.py
# \creation   2017-03-02, Joe Merten
#-----------------------------------------------------------------------------------------------------------------------
# See also: https://en.wikipedia.org/wiki/ANSI_escape_code
########################################################################################################################


########################################################################################################################
# Test results, capabilities of tested terminals / parsers
#-----------------------------------------------------------------------------------------------------------------------
#                   ╭──────┬───────┬────────┬────────┬───────┬─────────┬─────────┬────────┬────────┬─────────┬─────────┬─────┬──────┬───────┬────────┬────────┬───────╮
#                   │ bold │ faint │ italic │ underl │ blink │ inverse │ conceal │ dbundl │ strike │ color90 │ palette │ rgb │ font │ frame │ encirc │ overln │ reset │
# ╭─────────────────┼──────┼───────┼────────┼────────┼───────┼─────────┼─────────┼────────┼────────┼─────────┼─────────┼─────┼──────┼───────┼────────┼────────┼───────┤
# │ Kubuntu konsole │bright│   -   │   ok   │   ok   │ slow  │   ok    │    -    │   -    │   -    │   ok    │   ok    │ ok  │  -   │   -   │   -    │   -    │  ok   │
# ├─────────────────┼──────┼───────┼────────┼────────┼───────┼─────────┼─────────┼────────┼────────┼─────────┼─────────┼─────┼──────┼───────┼────────┼────────┼───────┤
# │ Gnome termonal  │      │       │        │        │       │         │         │        │        │         │         │     │  -   │   -   │   -    │   -    │       │
# ├─────────────────┼──────┼───────┼────────┼────────┼───────┼─────────┼─────────┼────────┼────────┼─────────┼─────────┼─────┼──────┼───────┼────────┼────────┼───────┤
# │ macOS console   │  ok  │  ok   │   -    │   -    │ slow  │   ok    │   ok    │   -    │   -    │   ok    │   ok    │  -  │  -   │   -   │   -    │   -    │  ok   │
# ├─────────────────┼──────┼───────┼────────┼────────┼───────┼─────────┼─────────┼────────┼────────┼─────────┼─────────┼─────┼──────┼───────┼────────┼────────┼───────┤
# │ Win Teraterm    │  ok  │   -   │   -    │   ok   │   -   │   ok    │    -    │   -    │   -    │   ok    │   ok    │ ok  │  -   │   -   │   -    │   -    │       │
# ├─────────────────┼──────┼───────┼────────┼────────┼───────┼─────────┼─────────┼────────┼────────┼─────────┼─────────┼─────┼──────┼───────┼────────┼────────┼───────┤
# │ Eclipse         │  ok  │   -   │   ok   │   ok   │   -   │   ok    │   ok    │   ok   │   ok   │   ok    │   ok    │ ok  │  -   │  ok   │   -    │   -    │  ok   │
# ├─────────────────┼──────┼───────┼────────┼────────┼───────┼─────────┼─────────┼────────┼────────┼─────────┼─────────┼─────┼──────┼───────┼────────┼────────┼───────┤
# │ Jenkins         │  ok  │   -   │   -    │   ok   │   -   │    -    │   ok*   │   ok   │   -    │    -    │    -    │  -  │  -   │   -   │   -    │   -    │partial│
# ╰─────────────────┴──────┴───────┴────────┴────────┴───────┴─────────┴─────────┴────────┴────────┴─────────┴─────────┴─────┴──────┴───────┴────────┴────────┴───────╯
# Notes / Issues:
# ⚫ Kubuntu 16.04 konsole
#   • applies bright colors for [1m instead of bold
#   • needs [22m to return to low brightness, [21m won't to this
#   • blink slow [5m works, but blink fast [6m not
# ⚫ macOS console
#   • reset single attributes don't works with foreground [39m and background color [49m
# ⚫ Eclipse Neon, Ansi Console
#   • Mihai Nita, net.mihai-nita.ansicon.feature.group, version 1.3.5.201612301822
#   • homepage: https://mihai-nita.net/java/ or https://mihai-nita.net/2013/06/03/eclipse-plugin-ansi-in-console/
#   • behaviour of [1m is customizable (bold versus bright colors)
#   • conceal text became visible when selected
#   • for rgb colors, need at least version 1.3.5
# ⚫ Jenkins AnsiColor
#   • version 0.4.3
#   • conceal suppresses output completely, there is no placeholder (e.g. whitespace) output
#   • reset single attributes don't works with conceal
# ⚫ Mac XcodeColors
#   • Still no Ansi support, see https://github.com/robbiehanson/XcodeColors/issues/66
# ⚫ My mission
#   • Jenkins AnsiColor: add italic, inverse, strike, color90, palette, rgb - and maybe fix conceal issues
#     - homepage: https://wiki.jenkins-ci.org/display/JENKINS/AnsiColor+Plugin
#     - inverse: https://github.com/dblock/jenkins-ansicolor-plugin/issues/64
#     - color90: https://github.com/dblock/jenkins-ansicolor-plugin/issues/16
#     - palette and rgb are addressed here: https://issues.jenkins-ci.org/browse/JENKINS-24378
#     - palette: https://github.com/dblock/jenkins-ansicolor-plugin/issues/44
########################################################################################################################


########################################################################################################################
#
########################################################################################################################
styles = [
    { "name": "normal"   , "on": 0, "off":  0 },
    { "name": "bold"     , "on": 1, "off": 22 },  # 21 = Bold: off or Underline: Double, but: Bold off not widely supported; double underline hardly ever supported.
    { "name": "faint"    , "on": 2, "off": 22 },  # 22 = Normal color or intensity / Neither bold nor faint
    { "name": "italic"   , "on": 3, "off": 23 },  # 23 = not italic, not fractur
    { "name": "underline", "on": 4, "off": 24 },
    { "name": "blinkslow", "on": 5, "off": 25 },  # 25 = blink off, 26 = reserved
    { "name": "blinkfast", "on": 6, "off": 25 },
    { "name": "inverse"  , "on": 7, "off": 27 },
    { "name": "conceal"  , "on": 8, "off": 28 },
    { "name": "strikeout", "on": 9, "off": 29 },
    { "name": "dblunderl", "on":21, "off": 24 },  # 21 = double underline in Eclipse Ansi Console and on Jenkins
    { "name": "framed"   , "on":51, "off": 54 },
    { "name": "encircled", "on":52, "off": 54 },
    { "name": "overlined", "on":53, "off": 55 },
]

########################################################################################################################
#
########################################################################################################################
def standardColors():
    print("┌─────────────────────────────────────────────────────────────────────────────────┐")
    print("│ Standard Colors like esc[31m, esc[41m, esc[91m and even things like bold esc[1m │")
    print("└─────────────────────────────────────────────────────────────────────────────────┘")

    myRange = list(range(30, 38)) + list(range(90, 98)) + list(range(40, 48)) + list(range(100, 108))
    for s in range(len(styles)):
        print("{:9}: ".format(styles[s]["name"]), end='')
        print("\x1B[{}mdef\x1B[m".format(styles[s]["on"]), end='')
        for i in myRange: print("\x1B[{};{}m{:3d}\x1B[m".format(styles[s]["on"], i, i), end='')
        print("")


########################################################################################################################
#
########################################################################################################################
def paletteColors():
    print("┌───────────────────────────────────┐")
    print("│ Palette Colors like esc[38;5;123m │")
    print("└───────────────────────────────────┘")

    for fgbg in list([38, 48]):
        # 16 standard colors
        for i in range(0, 16): print("\x1B[{};5;{}m   {:3d}   \x1B[m".format(fgbg, i, i), end='')
        print("")
        # 216 rgb colors
        for j in range(16, 232, 36):
            for i in range(j, j+36): print("\x1B[{};5;{}m {:3d}\x1B[m".format(fgbg, i, i), end='')
            print("")
        # 24 shades of gray (note, that 232 is not black and 255 seems not to be white)
        for i in range(232, 256): print("\x1B[{};5;{}m  {:3d} \x1B[m".format(fgbg, i, i), end='')
        print("")


########################################################################################################################
#
########################################################################################################################
def rgbColors():
    print("┌────────────────────────────────────┐")
    print("│ Rgb Colors like esc[38;2;10;20:30m │")
    print("└────────────────────────────────────┘")

    colors = [
        { "name": "red"  , "r": 1, "g": 0, "b": 0 },
        { "name": "green", "r": 0, "g": 1, "b": 0 },
        { "name": "blue" , "r": 0, "g": 0, "b": 1 },
        { "name": "cyan" , "r": 0, "g": 1, "b": 1 },
        { "name": "magnt", "r": 1, "g": 0, "b": 1 },
        { "name": "yello", "r": 1, "g": 1, "b": 0 },
        { "name": "gray" , "r": 1, "g": 1, "b": 1 },
    ]

    for fgbg in list([38, 48]):
        for c in range(len(colors)):
            r = colors[c]["r"]
            g = colors[c]["g"]
            b = colors[c]["b"]
            print("{:5}: ".format(colors[c]["name"]), end='')
            if fgbg == 38: bullet = "⚫"
            else: bullet = "•"
            for i in range(0, 256, 2): print("\x1B[{};2;{};{};{}m{}\x1B[m".format(fgbg, r*i, g*i, b*i, bullet), end='')
            print("")


########################################################################################################################
#
########################################################################################################################
def font():
    print("┌──────────────────────────────────────────────────────┐")
    print("│ Switching fonts, like esc[10m, esc[11m, ... esc[20m  │")
    print("└──────────────────────────────────────────────────────┘")

    for i in range (10, 20):
        print("font {}: \x1B[{}mexample in font {}\x1B[m".format(i, i, i))
    print("fractur: \x1B[20mexample in fractur\x1B[m")


########################################################################################################################
#
########################################################################################################################
def resetAttributes():
    print("┌───────────────────────────────────────────────────┐")
    print("│ Reset single attributes, like esc[39m and esc[22m │")
    print("└───────────────────────────────────────────────────┘")

    print("foreground: \x1B[33;1;41myellow bold on red\x1B[39m just bold on red\x1B[m")
    print("background: \x1B[33;1;41myellow bold on red\x1B[49m just yellow bold\x1B[m")

    for s in range(1, len(styles)):
        print("{:10}: ".format(styles[s]["name"]), end='')
        print("\x1B[33;41m\x1B[{}mon\x1B[{}moff\x1B[m".format(styles[s]["on"], styles[s]["off"]), end='')
        print("")


########################################################################################################################
#
########################################################################################################################
def frames():
    print("┌───────────────────────┐")
    print("│ Framing, like esc[51m │")
    print("└───────────────────────┘")

    print("framed: \x1B[51minside\x1B[54moutside")
    print("encircled: \x1B[52minside\x1B[54moutside")
    print("overlined: \x1B[53minside\x1B[55moutside")


########################################################################################################################
#   __  __       _
#  |  \/  | __ _(_)_ __
#  | |\/| |/ _` | | '_ \
#  | |  | | (_| | | | | |
#  |_|  |_|\__,_|_|_| |_|
########################################################################################################################
def main():
   standardColors()
   paletteColors()
   rgbColors()
   font()
   resetAttributes()
   frames()


########################################################################################################################
# Entry
########################################################################################################################
if __name__ == '__main__':
    main()
