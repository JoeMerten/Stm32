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
# │ Gnome terminal  │      │       │        │        │       │         │         │        │        │         │         │     │  -   │   -   │   -    │   -    │       │
# ├─────────────────┼──────┼───────┼────────┼────────┼───────┼─────────┼─────────┼────────┼────────┼─────────┼─────────┼─────┼──────┼───────┼────────┼────────┼───────┤
# │ macOS console   │  ok  │  ok   │   -    │   ok   │ slow  │   ok    │   ok    │   -    │   -    │   ok    │   ok    │  -  │  -   │   -   │   -    │   -    │  ok   │
# ├─────────────────┼──────┼───────┼────────┼────────┼───────┼─────────┼─────────┼────────┼────────┼─────────┼─────────┼─────┼──────┼───────┼────────┼────────┼───────┤
# │ Kubuntu xterm   │  ok  │  ok   │   ok   │   ok   │ slow  │   ok    │   ok    │ single │   ok   │   ok    │   ok    │ ok* │  -   │   -   │   -    │   -    │  ok   │
# ├─────────────────┼──────┼───────┼────────┼────────┼───────┼─────────┼─────────┼────────┼────────┼─────────┼─────────┼─────┼──────┼───────┼────────┼────────┼───────┤
# │ Win Teraterm    │  ok  │   -   │   -    │   ok   │   -   │   ok    │    -    │   -    │   -    │   ok    │   ok    │ ok  │  -   │   -   │   -    │   -    │  ok   │
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
# ⚫ xterm testet version 322 in Kubuntu 16.04
#   • xterm stops blinking when window loose focus
#   • double underline just underlines single (might depend on font size?)
#   • rgb colors were parsed, but displayed incorrect; e.g. dark magenta became gray and even no smooth gradient rendering
# ⚫ Win Teraterm 4.9
#   • [1m changes foreground color to yellow (if default color)
#   • [5m changes foreground color to red (if default color) and also brighten background color (if not default background color)
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
#   • version 0.4.4 will got much more ansi attribute and color functionality (work in progress)
# ⚫ Mac XcodeColors
#   • Still no Ansi support, see https://github.com/robbiehanson/XcodeColors/issues/66
# ⚫ My mission
#   • Jenkins AnsiColor: add italic, inverse, strike, color90, palette, rgb - and maybe fix conceal issues
#     - homepage: https://wiki.jenkins-ci.org/display/JENKINS/AnsiColor+Plugin
#     - My issue report: https://github.com/dblock/jenkins-ansicolor-plugin/issues/89
#     - For inverse: http://stackoverflow.com/questions/42585913/how-to-display-inverse-text-in-html
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
        print("\x1B[{}mon\x1B[{}moff\x1B[m  ".format(styles[s]["on"], styles[s]["off"]), end='')
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
# As read in https://en.wikipedia.org/wiki/ANSI_escape_code, the basic colors might be a bit different from the 16 first
# entries of the 256 color palette.
########################################################################################################################
def standardVersusPaletteColors():
    print("┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐")
    print("│ Comparing standard colors esc[40m, esc[100m, ... versus first 16 palette colors esc[48;5;0m ... esc[48;5;15m │")
    print("└──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘")

    print("Standard: ", end='')
    for i in range(40, 48): print("\x1B[{}m {:3d} \x1B[m".format(i, i), end='')
    for i in range(100, 108): print("\x1B[{}m {:3d} \x1B[m".format(i, i), end='')
    print("")
    print("Palette:  ", end='')
    for i in range(0, 16): print("\x1B[48;5;{}m {:3d} \x1B[m".format(i, i), end='')
    print("")


########################################################################################################################
# Combinations with inverse attribute
########################################################################################################################
def inverseCombinations():
    print("┌───────────────────────────────┐")
    print("│ Some combinations with esc[7m │")
    print("└───────────────────────────────┘")

    print("\x1B[33;41m" + "yellow on red, " +
          "\x1B[7m" + "now inverse, " +
          "\x1B[7m" + "one more [7m should change nothing, " +
          "\x1B[27m" + "turned back to non inverse" + "\x1B[m")

    print("\x1B[33;41m" + "yellow on red, " +
          "\x1B[7m" + "now inverse, " +
          "\x1B[30m" + "[30m → red on black, " +
          "\x1B[103m" + "[103m  → yellow on black, " +
          "\x1B[27m" + "[27m → black on yellow" + "\x1B[m")


########################################################################################################################
# Hmm won't work this way?
########################################################################################################################
def xtermDefaultColors():
    print("┌──────────────────────┐")
    print("│ xterm default colors │")
    print("└──────────────────────┘")

    print("\x1B]10;1\x07" + "foreground 31")
    print("\x1B]10;3\x07" + "background 33")
    print("\x1B[mafter[m")


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
   standardVersusPaletteColors()
   inverseCombinations()
   #xtermDefaultColors()


########################################################################################################################
# Entry
########################################################################################################################
if __name__ == '__main__':
    main()
