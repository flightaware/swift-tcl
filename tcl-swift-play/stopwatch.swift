//
//  stopwatch.swift
//  tcl-swift-bridge
//
//  Created by Peter da Silva on 9/16/16.
//  Copyright © 2016 FlightAware. All rights reserved.
//

import Foundation

class stopwatch {
    var start: TimeInterval
    
    init() {
        start = ProcessInfo.processInfo.systemUptime
    }
    
    func reset() {
        start = ProcessInfo.processInfo.systemUptime
    }
    
    func mark() -> TimeInterval {
        return ProcessInfo.processInfo.systemUptime - start
    }
}
    
