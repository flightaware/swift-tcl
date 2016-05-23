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

public class TclArray: SequenceType {
    let name: String
    let Interp: TclInterp
    let interp: UnsafeMutablePointer<Tcl_Interp>
    
    // init - initialize from empty or existing array
    public init(_ name: String, Interp: TclInterp, namespace: String? = nil) {
        self.Interp = Interp;
        self.interp = Interp.interp
        if namespace == nil {
            self.name = name;
        } else {
            self.name = namespace! + "::" + name;
        }
    }
    
    func set(dict: [String : String]) throws {
        try Interp.dictionaryToArray(name, dictionary: dict)
    }
    
    // init - initialize from string
    public convenience init(_ name: String, Interp: TclInterp, namespace: String? = nil, string: String) throws {
        self.init(name, Interp: Interp, namespace: namespace)
        try self.set(Interp.object(string).get())
    }

    // init - initialize from dictionary
    public convenience init(_ name: String, Interp: TclInterp, namespace: String? = nil, dict: [String: String]) throws {
        self.init(name, Interp: Interp, namespace: namespace)
        try self.set(dict)
    }
    
    // names - generate a list of names for the keys in the array.
    // This is ugly because there doesn't seem to be a C API for enumerating arrays
    func names() throws -> [String]? {
        let cmd = TclObj("array names", Interp: Interp)
        do { try cmd.lappend(self.name) } catch { return nil }
        let res: TclObj = try Interp.eval(cmd.get())
        return try res.get()
    }
    
    // get - return a dict
    func get() throws -> [String: String] {
        var dict: [String: String] = [:]
        try self.names()?.forEach {
            if let val: String = try self.getValue($0)?.get() {
                dict[$0] = val
            }
        }
        return dict
    }
    
    func getValue(key: String) -> TclObj? {
        return Interp.getVar(name, elementName: key)
    }
    
    func setValue(key: String, obj: TclObj) throws {
        try Interp.setVar(name, elementName: key, obj: obj)
    }
    
    func setValue(key: String, value: String) throws {
        try Interp.setVar(name, elementName: key, value: value)
    }
    
    func setValue(key: String, value: Int) throws {
        try Interp.setVar(name, elementName: key, value: value)
    }
    
    func setValue(key: String, value: Double) throws {
        try Interp.setVar(name, elementName: key, value: value)
    }
    
    func setValue(key: String, value: Bool) throws {
        try Interp.setVar(name, elementName: key, value: value)
    }

    subscript (key: String) -> TclObj? {
        get {
            return getValue(key)
        }
        set {
            if let obj = newValue {
                do {
                    try setValue(key, obj: obj)
                } catch {
                }
            }
        }
    }
    
    subscript (key: String) -> String? {
        get {
            return getValue(key)?.stringValue
        }
        set {
            if let string = newValue {
                do {
                    try setValue(key, value: string)
                } catch {
                }
            }
        }
    }
    
    subscript (key: String) -> Int? {
        get {
            return getValue(key)?.intValue
        }
        set {
            if let int = newValue {
                do {
                    try setValue(key, value: int)
                } catch {
                }
            }
        }
    }
    
    subscript (key: String) -> Double? {
        get {
            return getValue(key)?.doubleValue
        }
        set {
            if let double = newValue {
                do {
                    try setValue(key, value: double)
                } catch {
                }
            }
        }
    }
    
    subscript (key: String) -> Bool? {
        get {
            return getValue(key)?.boolValue
        }
        set {
            if let bool = newValue {
                do {
                    try setValue(key, value: bool)
                } catch {
                }
            }
        }
    }
    
    // Generator for maps, forEach, etc... returns a tuple, so $0.0 is the key, $0.1 is the value
    public func generate() -> AnyGenerator<(String, String)> {
        var nameList: [String]
        // A bit of Optional parkour because it's a little to complex for a guard, I think
        if let tmp = try? self.names() {
            nameList = tmp!
        } else {
            // Can't initialize the generator, so return a dummy generator that always returns nil
            return AnyGenerator<(String, String)> { return nil }
        }
        var next = 0

        return AnyGenerator<(String, String)> {
            let length = nameList.count
            if next >= length {
                return nil
            }
            let name = nameList[next]
            guard let value: String? = try? self.getValue(name)?.get() else {
                return nil
            }
            if value == nil {
                return nil
            }
            next += 1
            return (name, value!);
        }
    }

}