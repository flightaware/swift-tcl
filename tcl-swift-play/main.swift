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
    
    func latlongs_to_distance (interp: TclInterp, objv: [TclObj]) -> TclReturn {
        if (objv.count != 4) {
            
        }
        return TclReturn.OK
    }
    
    let EARTH_RADIUS_MILES = 3963.0
    
    func fa_degrees_radians (degrees: Double) -> Double {
        return (degrees * M_PI / 180);
    }

    func fa_latlongs_to_distance (lat1: Double, lon1: Double, lat2: Double, lon2:Double) -> Double {
        let dLat = fa_degrees_radians (lat2 - lat1)
        let dLon = fa_degrees_radians (lon2 - lon1)

        
        let lat1 = fa_degrees_radians (lat1)
        let lat2 = fa_degrees_radians (lat2)
        
        let a = sin (dLat / 2) * sin (dLat / 2) + sin (dLon / 2) * sin (dLon / 2) * cos (lat1) * cos (lat2)
        let c = 2 * atan2 (sqrt (a), sqrt (1 - a))
        var distance = EARTH_RADIUS_MILES * c
        
        // if result was not a number
        if (isnan(distance)) {
            distance = 0
        }
        
        return distance
    }
    
    func fa_latlongs_to_distance_cmd (interp: TclInterp, objv: [TclObj]) throws -> TclReturn {
        
        if (objv.count != 4) {
            throw TclError.WrongNumArgs(nLeadingArguments: 0, message: "lat0 lon0 lat1 lon1")
        }
        
        let lat1, lon1, lat2, lon2: Double
        
        do {
            lat1 = try objv[0].getDouble(interp)
        }
        
        do {
            lon1 = try objv[1].getDouble(interp)
        }
        
        do {
            lat2 = try objv[2].getDouble(interp)
        }
        
        do {
            lon2 = try objv[3].getDouble(interp)
        }
        
        let distance = fa_latlongs_to_distance(lat1, lon1: lon1, lat2: lat2, lon2: lon2)
        interp.setResult(distance)
        return TclReturn.OK
    }
    
    interp.create_command("fa_latlongs_to_distance", SwiftTclFunction: fa_latlongs_to_distance_cmd)

    
    do {
        try interp.eval("puts \"distance from KIAH to KSEA is [fa_latlongs_to_distance  29.9844444 -95.3414444 47.4498889 -122.3117778]\"")
    }
    
    