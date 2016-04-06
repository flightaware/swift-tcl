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
    var interp: UnsafeMutablePointer<Tcl_Interp>;
    
    init() {
        interp = Tcl_CreateInterp()
        Tcl_Init(interp)
    }
    
    func eval(code: String) {
        let ret = Tcl_Eval(interp, code.cStringUsingEncoding(NSUTF8StringEncoding)!)
        
        print("eval return code is \(ret)")
    }
}


let interp = TclInterp()

interp.eval("puts {Hey stikny}")

