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

    if let result: String = try? interp.eval("puts {Hey stinky}; return hijinks") {
        print("interpreter returned '\(result)'")
    } else {
        print("interpreter failed")
    }

print(interp.result)
    
    if let result: Int = try? interp.eval("expr 1 + 4") {
        print("interpreter returned '\(result)'")
    } else {
        print("interpreter failed")
    }

    var xo = interp.newObject(5)
    let xy = interp.newObject("hi mom")
    print(xy.stringValue)
    xy.stringValue = "hi dad"
    print(xy.stringValue)
    let xz = interp.newObject(5.5)
    if let xz2 = xz.intValue {
        print(xz2)
    }
    let x5 = interp.newObject(5)
    print(x5.doubleValue)
    
    // List test
    try interp.rawEval(["set", "a", "{illegal {string"])
    try interp.rawEval("puts [list a = $a]")
    
    func foo (interp: TclInterp, objv: [TclObj]) -> String {
        print("foo baby foo baby foo baby foo")
        return ""
    }
    
    func avg (interp: TclInterp, objv: [TclObj]) -> Double {
        var sum = 0.0
        for obj in objv {
            guard let val = obj.doubleValue else {continue}
            sum += val
        }
        return(sum / Double(objv.count))
    }
    
    interp.create_command("foo", foo)
    
    do {
        try interp.rawEval("foo")
    }
    
    interp.create_command("avg", avg)
    do {
        try interp.rawEval("puts \"the average is [avg 1 2 3 4 5 6 7 8 9 10 77]\"")
    }
    
    try interp.rawEval("puts \"the average is [avg 1 2 3 4 5 foo 7 8 9 10 77]\"")
    
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
    
    func fa_latlongs_to_distance_cmd (interp: TclInterp, objv: [TclObj]) throws -> Double {
        if (objv.count != 4) {
            throw TclError.WrongNumArgs(nLeadingArguments: 0, message: "lat0 lon0 lat1 lon1")
        }

        let lat1: Double = try objv[0].getArg("lat1")
        let lon1: Double = try objv[1].getArg("lon1")
        let lat2: Double = try objv[2].getArg("lat2")
        let lon2: Double = try objv[3].getArg("lon2")
            
        let distance = fa_latlongs_to_distance(lat1, lon1: lon1, lat2: lat2, lon2: lon2)
        return distance
    }
    
    interp.create_command("fa_latlongs_to_distance", fa_latlongs_to_distance_cmd)

    
    do {
        try interp.rawEval("puts \"distance from KIAH to KSEA is [fa_latlongs_to_distance  29.9844444 -95.3414444 47.4498889 -122.3117778]\"")
    }
    
    print("importing a swift array")
    var ints: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 9, 8, 10]
    var intListObj = interp.newObject(ints)
    print(ints)
    print(intListObj.stringValue)
    print("")

    let sarray = ["zero","one","two","three","four"]
    print("Testing ranges and indexes on \(sarray)")
    let xarray = interp.newObject(sarray)
    print(" xarray.lrange(1...3) = \(try? xarray.lrange(1...3) as [String])")
    print(" xarray.lrange(-3 ... -1) = \(try? xarray.lrange(-3 ... -1) as [String])")
    print(" xarray.lindex(1) = \(try? xarray.lindex(1) as String)")
    print(" xarray.lindex(-1) = \(try? xarray.lindex(-1) as String)")
    print("Testing subscripts")
    print(" xarray[0].stringValue = \(xarray[0]?.stringValue)")
    print(" xarray[0...2] = \(xarray[0...2] as [String]?)")
    print(" xarray as String = \(try xarray.get() as String)")
    try xarray.linsert(5, list: ["five"])
    print(" after insert at end: xarray as String = \(try xarray.get() as String)")
    try xarray.lreplace(0...2, list: ["0", "uno", "II"])
    print(" after replace at beginning: xarray as String = \(try xarray.get() as String)")
    xarray[0...2] = ["ZERO", "ONE", "TWO"]
    xarray[3] = "(3)"
    print(" after subscript assignment: xarray as String = \(try xarray.get() as String)")
    xarray[4...4] = ["4", "four", "IV", "[d]"]
    print(" after subscript assignment changing length: xarray as String = \(try xarray.get() as String)")
    xarray[5...7] = [] as [String]
    print(" after subscript assignment deleting elements: xarray as String = \(try xarray.get() as String)")
    xarray[0] = false
    xarray[1...4] = [1, 2, 3, 4]
    xarray[5] = 5.0
    print(" after subscript assignment of typed values: xarray as String = \(try xarray.get() as String)")
    print("\nTesting generator")
    var list = ""
    var sum = 0.0
    var count = 0
    for obj in xarray {
        if let v: Double = try? obj.get() {
            if list == "" {
                list = "{" + String(v)
            } else {
                list = list + ", " + String(v)
            }
            sum += v
            count += 1
        }
    }
    list += "}"
    print("sum of \(list) is \(sum), average is \(sum / Double(count))")

    let testdict = ["name": "Nick", "age": "32", "role": "hustler"]
    print("\nTesting array type on \(testdict)")
    if let character = try? interp.newArray("character", dict: testdict) {
        print("character[\"name\"]?.stringValue = \(character["name"]?.stringValue)")
        print("character[\"name\"] as String = \(character["name"] as String?)")
        print("character.names() = \(try character.names())")
        print("character.get() = \(try character.get() as [String: String])")

        print("\nModifying character")
        character["name"] = "Nick Wilde"
        character["animal"] = "fox"
        character["role"] = "cop"
        character["movie"] = "Zootopia"
        print("character[\"name\"]?.stringValue = \(character["name"]?.stringValue)")
        print("character.names() = \(try character.names())")
        print("character.get() = \(try character.get() as [String: String])")

        print("\nsubst test")
        print(try interp.subst("character(name) = $character(name)"))
        
        print("\ngenerator test")
        for (key, value) in character {
            try print("character[\"\(key)\"] = \(value.get() as String)")
        }
    } else {
        print("Could not initialize array from dictionary.")
    }

    print("\ndigging variables out of the Tcl interpreter")
    var autoPath: String = try! interp.getVar("auto_path")
    print("auto_path is '\(autoPath)'")

    let tclVersion: Double = try! interp.getVar("tcl_version")
    print("Tcl version is \(tclVersion)")
    print("")

    print("sticking something extra into the tcl_platform array")
    try! interp.setVar("tcl_platform", elementName: "swift", value: "enabled")

    do {try interp.rawEval("array get tcl_platform")}
    var dict: [String:String] = try! interp.resultObj.get()
    print(dict)
    var version = dict["osVersion"]!
    print("Your OS is \(dict["os"]!), running version \(version)")

    var machine: String = interp.getVar("tcl_platform", elementName: "machine")!
    var byteOrder: String = interp.getVar("tcl_platform", elementName: "byteOrder")!
    print("Your machine is \(machine) and your byte order is \(byteOrder)")
    print("")

    print("intentionally calling a swift extension with a bad argument")
    let _ = try? interp.rawEval("puts \"distance from KIAH to KSEA is [fa_latlongs_to_distance  29.9844444 -95.3414444 crash -122.3117778]\"")
    let _ = try? interp.rawEval("puts \"distance from KIAH to KSEA is [fa_latlongs_to_distance  29.9844444 -95.3414444]\"")