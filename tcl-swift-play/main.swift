    //
//  main.swift
//  tcl-swift-play
//
//  Created by Karl Lehenbauer on 4/6/16.
//  Copyright © 2016 FlightAware. All rights reserved.
//

import Foundation

print("Hello, World!")


let interp = TclInterp()

    do {
        try interp.eval("puts {Hey stikny}; return hijinks")
    }
    catch(TclInterp.InterpErrors.NotString(let str)) {
        print("This isn't a C string \(str)")
    }

    do {
        try interp.eval("invalid command")
    }
    catch(TclInterp.InterpErrors.EvalError(let ret)) {
        print("Invalid command, error code \(ret)")
    }

print(interp.result)

var xo = TclObj(val: 5)
    let xy = TclObj(val: "hi mom")
    print(xy.stringValue)
    xy.stringValue = "hi dad"
    print(xy.stringValue)
    let xz = TclObj(val: 5.5)
    if let xz2 = xz.getInt() {
        print(xz2)
    }
    let x5 = TclObj(val: 5)
    print(x5.getDouble())