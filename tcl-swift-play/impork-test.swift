//
//  impork-test.swift
//  tcl-swift-bridge
//
//  Created by Peter da Silva on 5/25/16.
//  Copyright © 2016 FlightAware. All rights reserved.
//

import Foundation

func import_impork(Interp: TclInterp, file: String) throws {
    try Interp.rawEval(["source", file])
}

func impork(Interp: TclInterp) {
    let file: String = "/Users/peter.dasilva/git/swift-tcl/package/impork.tcl" // *cries*
    do {
        try import_impork(Interp, file: file)
        
        let array = try Interp.newArray("imporked", string: tcl_impork(Interp, file: file))
        for (num, line) in array {
            print("\(num)\t\(try line.get() as String)")
        }
    } catch {
        print(error)
    }
}

// tcl_impork
// Wrapper for impork
func tcl_impork (springboardInterp: TclInterp, file: String, first: Int = 1, step: Int = 1) throws -> String {
    let vec = springboardInterp.newObject()
    try vec.lappend("impork")
    try vec.lappend(file)
    try vec.lappend(first)
    try vec.lappend(step)
    Tcl_EvalObjEx(springboardInterp.interp, vec.get(), 0)
    return try springboardInterp.getResult()
}
