#!/usr/bin/env python3
########################################################################################################################
# Log uart rx data to console and logfile
#-----------------------------------------------------------------------------------------------------------------------
# \project    Multithreaded C++ Framework
# \file       Pulog.py
# \creation   2016-11-28, Joe Merten
#-----------------------------------------------------------------------------------------------------------------------
# See also: https://github.com/tbird20d/grabserial
########################################################################################################################

import argparse
import datetime
import time
import serial
import signal
import sys
import re


class SignalCatcher:
    terminateRequested = False
    signum = 0
    def __init__(self):
        signal.signal(signal.SIGINT, self.requestTerminate)
        signal.signal(signal.SIGTERM, self.requestTerminate)
    def requestTerminate(self, signum, frame):
        #print("Signal {} catched!".format(signum))
        self.terminateRequested = True
        self.signum = signum


def timeArg(arg):
    time = arg.strip()
    if not time: raise argparse.ArgumentTypeError("invalid duration")
    time = time.replace(',', '.') # allowing both , and . for decimal separator
    try:
        if time.endswith("ms"):
            time = float(time[:-2]) / 1000
        elif time.endswith("s"):
            time = float(time[:-1])
        elif time.endswith("min"):
            time = float(time[:-3]) * 60
        elif time.endswith("h"):
            time = float(time[:-1]) * 3600
        else:
            time = float(time)
    except:
        raise argparse.ArgumentTypeError("invalid duration '" + arg + "'")
    if time <= 0:
        raise argparse.ArgumentTypeError("invalid duration '" + arg + "'")
    return time


def baudrateArg(arg):
    baud = arg.strip()
    if not baud: raise argparse.ArgumentTypeError("invalid baudrate")
    try:
        if 'k' in baud.lower():
            baud = baud.lower()
            if   baud ==   "9k" or baud ==   "9k6": baud =   9600
            elif baud ==  "14k" or baud ==  "14k4": baud =  14400
            elif baud ==  "19k" or baud ==  "19k2": baud =  19200
            elif baud ==  "38k" or baud ==  "38k4": baud =  38400
            elif baud ==  "57k" or baud ==  "57k6": baud =  57600
            elif baud == "115k" or baud == "115k2": baud = 115200
            elif baud == "230k" or baud == "230k4": baud = 230400
            elif baud == "460k" or baud == "460k8": baud = 460800
            elif baud == "921k" or baud == "921k6": baud = 921600
            else: baud = int(baud[:-1]) * 1000
        elif 'M' in baud.upper():
            baud = baud.upper()
            if   baud == "1M5": baud = 1500000
            elif baud == "2M5": baud = 2500000
            else: baud = int(baud[:-1]) * 1000000
        else:
            baud = int(baud)
    except:
        raise argparse.ArgumentTypeError("invalid baudrate '" + arg + "'")
    if baud <= 0:
        raise argparse.ArgumentTypeError("invalid baudrate '" + arg + "'")
    return baud


def main():
    argsParser = argparse.ArgumentParser(epilog = "All time durations can also be specified with a unit, e.g. \"600ms\" or \"5min\"")
    argsParser.add_argument("port",                                                                                     help="Serial port device name")
    argsParser.add_argument("baudrate",            type = baudrateArg,                                                  help="Serial port baudrate, even e.g. 230k or 1M …")
    argsParser.add_argument("--rtscts",            action="store_true",                                                 help="Use rts/cts hardware handshake")
    argsParser.add_argument("--xonxoff",           action="store_true",                                                 help="Use xon/xoff software handshake")
    argsParser.add_argument("--logfile",                                metavar="<filename>",                           help="Logfile (serial rx data will be appended)")
    argsParser.add_argument("--lower-rts",         action="store_true",                       dest = "lowerRts",        help="Lower rts handshake line after open port")
    argsParser.add_argument("--lower-rts-delayed", type = timeArg,      metavar="<seconds>",  dest = "lowerRtsDelayed", help="Specify delay time for lowering rts handshake line after open port")
    argsParser.add_argument("--quittime",          type = timeArg,      metavar="<seconds>",                            help="Specify time for automatic termination (over all timeout)")
    argsParser.add_argument("--quitnorxtime",      type = timeArg,      metavar="<seconds>",                            help="Specify time for termination in case of no rx data (rx timeout)")
    argsParser.add_argument("--quitpattern",                            metavar="<regex>",                              help="Specify a regular expression pattern to terminate the program, works mid-line")
    argsParser.add_argument("--quitpattime",       type = timeArg,      metavar="<seconds>",                            help="Specify time for delayed termination after pattern match")
    args = argsParser.parse_args()
    #print("port={} baudrate={} logfile={} lowerRts={}".format(args.port, args.baudrate, args.logfile, args.lowerRts))

    signalCatcher = SignalCatcher()

    ser = serial.Serial(port = args.port, baudrate = args.baudrate, rtscts = args.rtscts, xonxoff = args.xonxoff, timeout = 0.2)
    if args.lowerRts: ser.setRTS(False)

    startTimeMonotonic = time.perf_counter()
    norxTime = None
    quitpatternFound = False
    quitpatternTime = 0
    lowerRtsDelayedDone = False

    timestamp = "Started logging at " + datetime.datetime.now().replace(microsecond=0).isoformat(" ")
    console = open("/dev/stdout", "wb")
    console.write(bytes(timestamp + "\n", "utf-8"))
    console.flush()
    if args.logfile is not None:
        # "ab" = append & binary; for open modes see https://docs.python.org/3/library/functions.html#open
        logfile = open(args.logfile, "ab")
        logfile.write(bytes(timestamp + "\n", "utf-8"))
        logfile.flush()
    currentLine = bytearray()
    quitReason = ""
    while True:
        if signalCatcher.terminateRequested:
            quitReason = "signal {}".format(signalCatcher.signum)
            break;

        try:
            data = ser.read(1)
        except IOError:
            # chatch this to silent the "InterruptedError: [Errno 4] Interrupted system call" message when running from within jenkins
            #print("CATCHED IOError")
            quitReason = "catched IOError"
            break

        if data != b'':
            norxTime = time.perf_counter()
            console.write(data)
            console.flush()
            if args.logfile is not None:
                logfile.write(data)
                logfile.flush()

            if data == b'\n':
                #console.write(bytes("RX line = ", "utf-8"))
                #console.write(currentLine)
                #console.write(bytes("\n", "utf-8"))
                #print("TIME = {}".format(time.perf_counter()))
                currentLine.clear()
            else:
                currentLine += data
                #currentLine.append(int(data))

            # Check for termination conditions
            if args.quitpattern is not None and not quitpatternFound:
                lineString = str(currentLine, "utf-8", errors='replace') # replace Utf-8 encoding errors with U+FFFD = '�'
                if re.search(args.quitpattern, lineString):
                    if args.quitpattime is not None:
                        quitpatternFound = True
                        quitpatternTime = time.perf_counter()
                    else:
                        quitReason = "pattern \"{}\" found".format(args.quitpattern)
                        break;

        if args.lowerRtsDelayed is not None and not lowerRtsDelayedDone:
            elapsed = time.perf_counter() - startTimeMonotonic
            if elapsed > args.lowerRtsDelayed:
                ser.setRTS(False)
                lowerRtsDelayedDone = True

        # Check for termination conditions
        if args.quittime is not None:
            elapsed = time.perf_counter() - startTimeMonotonic
            if elapsed > args.quittime:
                quitReason = "{:.2f}s after session started".format(elapsed)
                break;

        if args.quitnorxtime is not None:
            if norxTime is None:
                elapsed = time.perf_counter() - startTimeMonotonic
                if elapsed > args.quitnorxtime:
                    quitReason = "{:.2f}s still no rx data".format(elapsed)
                    break;
            else:
                elapsed = time.perf_counter() - norxTime
                if elapsed > args.quitnorxtime:
                    quitReason = "{:.2f}s without rx data".format(elapsed)
                    break;

        if args.quitpattern is not None and quitpatternFound:
            elapsed = time.perf_counter() - quitpatternTime
            if elapsed > args.quitpattime:
                quitReason = "{:.2f}s after pattern \"{}\" found".format(elapsed, args.quitpattern)
                break;

    ser.close()
    timestamp = "Finished logging at " + datetime.datetime.now().replace(microsecond=0).isoformat(" ") + ", " + quitReason
    if len(currentLine) != 0: console.write(b"\n")
    console.write(bytes(timestamp + "\n", "utf-8"))
    console.close()
    if args.logfile is not None:
        if len(currentLine) != 0: logfile.write(b"\n")
        logfile.write(bytes(timestamp + "\n", "utf-8"))
        logfile.close()

if __name__ == '__main__':
    main()
