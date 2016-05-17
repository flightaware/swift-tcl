//
//  tcl-array.swift
//  tcl-swift-bridge
//
//  Created by Peter da Silva on 5/17/16.
//  Copyright © 2016 FlightAware. All rights reserved.
//
// Free under the Berkeley license.
//

import Foundation


// TclArray - Tcl object class

public class TclArray {
    let name: String
    let Interp: TclInterp?
    let interp: UnsafeMutablePointer<Tcl_Interp>
    
    // init - initialize from interpreter and name
    public init(_ name: String, Interp: TclInterp? = nil, namespace: String? = nil) {
        self.Interp = Interp;
        self.interp = Interp?.interp ?? nil
        if namespace == nil {
            self.name = name;
        } else {
            self.name = namespace! + "::" + name;
        }
    }
    
    func fromDict(dict: [String : String]) throws {
        try Interp?.dictionaryToArray(name, dictionary: dict)
    }
    
    func getValue(key: String) -> TclObj? {
        return Interp?.getVar(name, elementName: key)
    }
    
    func setValue(key: String, obj: TclObj) throws {
        try Interp?.setVar(name, elementName: key, obj: obj)
    }
    
    func setValue(key: String, value: String) throws {
        try Interp?.setVar(name, elementName: key, value: value)
    }
    
    subscript (key: String) -> TclObj? {
        get {
            return getValue(key)
        }
        set (obj) {
            if obj != nil {
                do {
                    try setValue(key, obj: obj!)
                } catch {
                }
            }
        }
    }
}