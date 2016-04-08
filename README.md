## Overview

This is an experiment in creating a bridge between Tcl and Swift

It defines a TclInterp class in Swift that provides methods for eval'ing Tcl code from Swift and for digging results out of the interpreter.

It also defines a TclObj class that can convert between Swift data types such as Int, Double, String and Tcl object representations of equivalent types.

## Building

Right now this is on the Mac and requires Xcode and the included Xcode project looks to Tcl as installed by macports (https://www.macports.org/) with the include file in /opt/local/include and the tcl dylib in /opt/local/lib.

To go this way make sure Xcode and macports are installed and install Tcl with "sudo port install tcl".

The code can also be built against the Tcl that gets installed in /usr/include, /usr/lib, etc, as installed by the Xcode command line tools if you change the targets in the project.

## Running it

I'm currently just running it from within Xcode.  The TclInterp and TclObj classes are defined in tcl.swift while main.swift defines a TclInterp and messes around with it a bit.

## Stuff it needs

* Someone who really understands Swift to bring it in line with best practices, etc
* A way to create new Tcl commands that invoke Swift functions (I envision the Swift function that is directly invoked from Tcl will receive an array of TclObj objects that it can dig its arguments out of)
* Methods to convert between Swift Lists, Sets and Dictionaries and Tcl lists, arrays and dicts
* Additional methods of the TclInterp class to get and set Tcl variables (including array elements) and additional ways to interact with the Tcl interpreter that are useful

## Stuff that would be nice eventually

* Support for safe interpreters
* Support for setting resource limits on interpreters using Tcl_Limit*

## Stuff that would be cool if it's even possible

* The ability to introspect Swift from Tcl to find objects and invoke methods on them (Swift seems to be moving away from even providing a way to do that.  I still think bridging is useful even if it can't do this.)

## Stuff that might be interesting to try

* linking Tcl variables to Swift variables using Tcl_LinkVar


