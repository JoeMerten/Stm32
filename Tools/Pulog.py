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

def main():
    argsParser = argparse.ArgumentParser()
    argsParser.add_argument("port",                                                  help="Serial port device name")
    argsParser.add_argument("baudrate",      type = int,                             help="Serial port baudrate")
    argsParser.add_argument("--rtscts",      action="store_true",                    help="Use rts/cts hardware handshake")
    argsParser.add_argument("--xonxoff",     action="store_true",                    help="Use xon/xoff software handshake")
    argsParser.add_argument("--logfile",                                             help="Logfile (serial rx data will be appended)")
    argsParser.add_argument("--lower-rts",   action="store_true", dest = "lowerRts", help="Lower rts handshake line after open port")
    argsParser.add_argument("--quittime",    type = int,                             help="Specify time in seconds for automatic termination (over all timeout).")
    argsParser.add_argument("--quitpattern",                                         help="Specify a regular expression pattern to terminate the program. Works mid-line.")
    argsParser.add_argument("--quitpattime", type = int,                             help="Specify time in seconds for delayed termination after pattern match.")
    args = argsParser.parse_args()
    #print("port={} baudrate={} logfile={} lowerRts={}".format(args.port, args.baudrate, args.logfile, args.lowerRts))

    signalCatcher = SignalCatcher()

    ser = serial.Serial(port = args.port, baudrate = args.baudrate, rtscts = args.rtscts, xonxoff = args.xonxoff, timeout = 0.2)
    if args.lowerRts: ser.setRTS(False)

    startTimeMonotonic = time.perf_counter()
    quitpatternFound = False
    quitpatternTime = 0

    timestamp = "Started logging at " + datetime.datetime.now().isoformat(" ")
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
                try:
                    lineString = str(currentLine, "utf-8")
                    if re.search(args.quitpattern, lineString):
                        if args.quitpattime is not None:
                            quitpatternFound = True
                            quitpatternTime = time.perf_counter()
                        else:
                            quitReason = "pattern \"{}\" found".format(args.quitpattern)
                            break;
                except UnicodeDecodeError:
                    # Nothing to do
                    pass

        if args.quittime is not None:
            elapsed = time.perf_counter() - startTimeMonotonic
            if elapsed > args.quittime:
                quitPattern = "{:.2f}s".format(elapsed)
                break;

        if args.quitpattern is not None and quitpatternFound:
            elapsed = time.perf_counter() - quitpatternTime
            if elapsed > args.quitpattime:
                quitReason = "{:.2f}s after pattern \"{}\" found".format(elapsed, args.quitpattern)
                break;

    ser.close()
    timestamp = "Finished logging at " + datetime.datetime.now().isoformat(" ") + ", " + quitReason
    if len(currentLine) != 0: console.write(b"\n")
    console.write(bytes(timestamp + "\n", "utf-8"))
    console.close()
    if args.logfile is not None:
        if len(currentLine) != 0: logfile.write(b"\n")
        logfile.write(bytes(timestamp + "\n", "utf-8"))
        logfile.close()

if __name__ == '__main__':
    main()
