    //
//  main.swift
//  tcl-swift-play
//
//  Created by Karl Lehenbauer on 4/6/16.
//  Copyright © 2016 FlightAware. All rights reserved.
//

import Foundation

print("Hello, World!")

class TclInterp {
    var interp: UnsafeMutablePointer<Tcl_Interp>
    
    init() {
        interp = Tcl_CreateInterp()
        Tcl_Init(interp)
    }
    
    deinit {
        Tcl_DeleteInterp (interp)
    }
    
    func eval(code: String) {
        let ret = Tcl_Eval(interp, code.cStringUsingEncoding(NSUTF8StringEncoding)!)
        
        print("eval return code is \(ret)")
    }
    
    func resultString() -> String {
        return(String.fromCString(Tcl_GetString(Tcl_GetObjResult(interp))))!
    }
}

class TclObj {
    var obj: UnsafeMutablePointer<Tcl_Obj>
    
    init() {
        obj = Tcl_NewObj()
    }
    
    init(val: Int) {
        obj = Tcl_NewLongObj(val)
    }
    
    init(val: String) {
        obj = Tcl_NewStringObj (val.cStringUsingEncoding(NSUTF8StringEncoding)!, -1)
    }
    
    init(val: Double) {
        obj = Tcl_NewDoubleObj (val)
    }
    
    deinit {
        Tcl_DecrRefCount(obj)
    }
    
    func string() -> String {
        return(String.fromCString(Tcl_GetString(obj)))!
    }
    
    func int() -> Int? {
        var longVal: CLong = 0
        let result = Tcl_GetLongFromObj (nil, obj, &longVal)
        if (result == TCL_ERROR) {
            return nil
        }
        return longVal
    }
}

let interp = TclInterp()

interp.eval("puts {Hey stikny}; return hijinks")

print(interp.resultString())

var xo = TclObj(val: 5)
    var xy = TclObj(val: "hi mom")
    var xz = TclObj(val: 5.5)
    
    

