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

interp.eval("puts {Hey stikny}; return hijinks")

print(interp.resultString())

var xo = TclObj(val: 5)
    var xy = TclObj(val: "hi mom")
    var xz = TclObj(val: 5.5)
    
    

