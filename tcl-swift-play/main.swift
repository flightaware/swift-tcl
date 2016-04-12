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
    
    func foo (interp: TclInterp, objv: [TclObj]) -> TclReturn {
        print("foo baby foo baby foo baby foo")
        return TclReturn.OK
    }
    
    func avg (interp: TclInterp, objv: [TclObj]) -> TclReturn {
        var sum = 0.0
        for obj in objv {
            sum += obj.getDouble()!
        }
        interp.setResult(sum / Double(objv.count))
        return TclReturn.OK
    }
    
    interp.create_command("foo", SwiftTclFunction: foo)
    do {
        try interp.eval("foo")
    }
    
    interp.create_command("avg", SwiftTclFunction: avg)
    do {
        try interp.eval("puts \"the average is [avg 1 2 3 4 5 6 7 8 9 10 77]\"")
    }


    