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
    
    public func set(dict: [String : String]) throws {
        try Interp.dictionaryToArray(name, dictionary: dict)
    }
    
    // init - initialize from string
    public convenience init(_ name: String, Interp: TclInterp, namespace: String? = nil, string: String) throws {
        self.init(name, Interp: Interp, namespace: namespace)
        try self.set(Interp.newObject(string).get() as [String: TclObj])
    }

    // init - initialize from dictionary
    public convenience init(_ name: String, Interp: TclInterp, namespace: String? = nil, dict: [String: String]) throws {
        self.init(name, Interp: Interp, namespace: namespace)
        try self.set(dict)
    }
    
    // init - initialize from dictionary
    public convenience init(_ name: String, Interp: TclInterp, namespace: String? = nil, dict: [String: TclObj]) throws {
        self.init(name, Interp: Interp, namespace: namespace)
        try self.set(dict)
    }
    
    public func set(dict: [String : TclObj]) throws {
        try Interp.dictionaryToArray(name, dictionary: dict)
    }
    
    // names - generate a list of names for the keys in the array.
    // This is ugly because there doesn't seem to be a C API for enumerating arrays
    public func names() throws -> [String] {
        let cmd = TclObj("array names", Interp: Interp)
        try cmd.lappend(self.name)
        let res: TclObj = try Interp.eval(cmd.get())
        return try res.get()
    }
    
    // get - return a dict [String: String]
    public func get() throws -> [String: String] {
        let old: [String: TclObj] = self.get()
        var new: [String: String] = [:]
        for (key, obj) in old {
            try new[key] = obj.get()
        }
        return new
    }
    
    // get - return a dict [String: TclObj]
    public func get() -> [String: TclObj] {
        var dict: [String: TclObj] = [:]
        if let names = try? self.names() {
            names.forEach {
                if let val: TclObj = self.getValue($0) {
                    dict[$0] = val
                }
            }
        }
        return dict
    }
    
    public func getValue(key: String) -> TclObj? {
        return Interp.getVar(name, elementName: key)
    }
    
    public func setValue(key: String, obj: TclObj) throws {
        try Interp.setVar(name, elementName: key, obj: obj)
    }
    
    public func setValue(key: String, value: String) throws {
        try Interp.setVar(name, elementName: key, value: value)
    }
    
    public func setValue(key: String, value: Int) throws {
        try Interp.setVar(name, elementName: key, value: value)
    }
    
    public func setValue(key: String, value: Double) throws {
        try Interp.setVar(name, elementName: key, value: value)
    }
    
    public func setValue(key: String, value: Bool) throws {
        try Interp.setVar(name, elementName: key, value: value)
    }

    public subscript (key: String) -> TclObj? {
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
    
    public subscript (key: String) -> String? {
        get {
            do {
                return try getValue(key)?.get()
            } catch {
                return nil
            }
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
    
    public subscript (key: String) -> Int? {
        get {
            do {
                return try getValue(key)?.get()
            } catch {
                return nil
            }
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
    
    public subscript (key: String) -> Double? {
        get {
            do {
                return try getValue(key)?.get()
            } catch {
                return nil
            }
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
    
    public subscript (key: String) -> Bool? {
        get {
            do {
                return try getValue(key)?.get()
            } catch {
                return nil
            }
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
    
    // Generator for maps, forEach, etc... returns a tuple
    public func generate() -> AnyGenerator<(String, TclObj)> {
        guard let nameList = try? self.names() else {
            // Can't initialize the generator, so return a dummy generator that always returns nil
            return AnyGenerator<(String, TclObj)> { return nil }
        }
        
        var next = 0

        return AnyGenerator<(String, TclObj)> {
            var value: TclObj? = nil
            var name: String? = nil
            // looping over name list in case someone unset an array element behind my back
            while value == nil {
                if next >= nameList.count {
                    return nil
                }
                name = nameList[next]
                next += 1
                
                // name can never be nil here necause it's just been assigned from nameList which is a [String]
                value = self.getValue(name!)
            }
            // At this point I believe it is impossible for name to be nil but I'm checking anyway
            if name != nil && value != nil {
                return (name!, value!);
            }
            return nil
        }
    }
}
