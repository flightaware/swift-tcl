//
//  tcl-object.swift
//  tcl-swift-bridge
//
//  Created by Peter da Silva on 5/17/16.
//  Copyright © 2016 FlightAware. All rights reserved.
//
// Free under the Berkeley license.
//

import Foundation


// TclObj - Tcl object class

public class TclObj {
    let obj: UnsafeMutablePointer<Tcl_Obj>
    let Interp: TclInterp?
    let interp: UnsafeMutablePointer<Tcl_Interp>
    
    // various initializers to create a Tcl object from nothing, an int,
    // double, string, Tcl_Obj *, etc
    
    // init - Initialize from a Tcl_Obj *
    init(_ val: UnsafeMutablePointer<Tcl_Obj>, Interp: TclInterp? = nil) {
        self.Interp = Interp; self.interp = Interp?.interp ?? nil
        obj = val
        IncrRefCount(val)
    }
    
    // init - initialize from nothing, get an empty Tcl object
    public convenience init(Interp: TclInterp? = nil) {
        self.init(Tcl_NewObj(), Interp: Interp)
    }
    
    // init - initialize from a Swift Int
    public convenience init(_ val: Int, Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.intValue = val;
    }
    
    // init - initialize from a Swift String
    public convenience init(_ val: String, Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.stringValue = val;
    }
    
    // init - initialize from a Swift Double
    public convenience init(_ val: Double, Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.doubleValue = val;
    }
    
    // init - initialize from a Swift Bool
    public convenience init(_ val: Bool, Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.boolValue = val;
    }
    
    // init - init from a set of Strings to a list
    public convenience init(_ set: Set<String>, Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.set(set)
    }
    
    func set(set: Set<String>) {
        for element in set {
            let string = element.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (interp, obj, Tcl_NewStringObj (string, -1))
        }
    }
    
    // init from a set of Ints to a list
    public convenience init(_ set: Set<Int>, Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.set(set)
    }
    
    func set(set: Set<Int>) {
        for element in set {
            Tcl_ListObjAppendElement (interp, obj, Tcl_NewLongObj (element))
        }
    }
    
    // init from a Set of doubles to a list
    public convenience init(_ set: Set<Double>, Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.set(set)
    }
    
    func set(set: Set<Double>) {
        for element in set {
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewDoubleObj (element))
        }
    }
    
    // init from an Array of Strings to a Tcl list
    public convenience init(_ array: [String], Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.set(array)
    }
    
    func set(array: [String]) {
        for element in array {
            let string = element.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewStringObj (string, -1))
        }
    }
    
    // Init from an Array of Int to a Tcl list
    public convenience init (_ array: [Int], Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.set(array)
    }
    
    func set(array: [Int]) {
        array.forEach {
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewLongObj($0))
        }
    }
    
    // Init from an Array of Double to a Tcl list
    public convenience init (_ array: [Double], Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.set(array)
    }
    
    func set(array: [Double]) {
        array.forEach {
            Tcl_ListObjAppendElement(nil, obj, Tcl_NewDoubleObj($0))
        }
    }
    
    // init from a String/String dictionary to a list
    public convenience init (_ dictionary: [String: String], Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.set(dictionary)
    }
    
    func set(dictionary: [String: String]) {
        dictionary.forEach {
            let keyString = $0.0.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewStringObj (keyString, -1))
            let valueString = $0.1.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewStringObj (valueString, -1))
        }
    }
    
    // init from a String/Int dictionary to a list
    public convenience init (_ dictionary: [String: Int], Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.set(dictionary)
    }

    func set(dictionary: [String: Int]) {
        dictionary.forEach {
            let keyString = $0.0.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewStringObj (keyString, -1))
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewLongObj ($0.1))
        }
    }
    
    // init from a String/Double dictionary to a list
    public convenience init (_ dictionary: [String: Double], Interp: TclInterp? = nil) {
        self.init(Interp: Interp)
        self.set(dictionary)
    }
    
    func set(dictionary: [String: Double]) {
        dictionary.forEach {
            let keyString = $0.0.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewStringObj (keyString, -1))
            Tcl_ListObjAppendElement (nil, obj, Tcl_NewDoubleObj ($0.1))
        }
    }
    
    // deinit - decrement the object's reference count.  if it goes below one
    // the object will be freed.  if not then something else has it and it will
    // be freed after the last use
    deinit {
        DecrRefCount(obj)
    }
    
    // various set functions to set the Tcl object from a string, Int, Double, etc
    public var stringValue: String? {
        get {
            return try? get()
        }
        set {
            guard let val = newValue else {return}
            set(val)
        }
    }
    
    func get() throws -> String {
        return try tclobjp_to_String(obj)
    }
    
    func set(value: String) {
        Tcl_SetStringObj (obj, value.cStringUsingEncoding(NSUTF8StringEncoding) ?? [], -1)
    }
    
    // getInt - return the Tcl object as an Int or nil
    // if in-object Tcl type conversion fails
    public var intValue: Int? {
        get {
            return try? get()
        }
        set {
            guard let val = newValue else {return}
            set(val)
        }
    }

    func get() throws -> Int {
        return try tclobjp_to_Int(obj)
    }

    func set(val: Int) {
        Tcl_SetLongObj (obj, val)
    }

    // getDouble - return the Tcl object as a Double or nil
    // if in-object Tcl type conversion fails
    public var doubleValue: Double? {
        get {
            return try? get()
        }
        set {
            guard let val = newValue else {return}
            set(val)
        }
    }
    
    func get() throws -> Double {
        return try tclobjp_to_Double(obj)
    }
    
    func set(val: Double) {
        Tcl_SetDoubleObj (obj, val)
    }
    
    // getBool - return the Tcl object as a Bool or nil
    public var boolValue: Bool? {
        get {
            return try? get()
        }
        set {
            guard let val = newValue else {return}
            set(val)
        }
    }

    func get() throws -> Bool {
        return try tclobjp_to_Bool(obj)
    }

    func set(val: Bool) {
        Tcl_SetBooleanObj (obj, val ? 1 : 0)
    }

    // getObj - return the Tcl object pointer (Tcl_Obj *)
    func get() -> UnsafeMutablePointer<Tcl_Obj> {
        return obj
    }
    
    func getArg(varName: String) throws -> Int {
        do {
            return try tclobjp_to_Int(obj, interp: interp)
        } catch {
            Interp?.addErrorInfo(" while converting \"\(varName)\" argument")
            throw TclError.Error
        }
    }
    
    func getArg(varName: String) throws -> Double {
        do {
            return try tclobjp_to_Double(obj, interp: interp)
        } catch {
            Interp?.addErrorInfo(" while converting \"\(varName)\" argument")
            throw TclError.Error
        }
    }
    
    func getArg(varName: String) throws -> Bool {
        do {
            return try tclobjp_to_Bool(obj, interp: interp)
        } catch {
            Interp?.addErrorInfo(" while converting \"\(varName)\" argument")
            throw TclError.Error
        }
    }
    
    func getArg(varName: String) throws -> String {
        do {
            return try tclobjp_to_String(obj)
        } catch {
            Interp?.addErrorInfo(" while converting \"\(varName)\" argument")
            throw TclError.Error
        }
    }

    // lappend - append a Tcl_Obj * to the Tcl object list
    func lappend (value: UnsafeMutablePointer<Tcl_Obj>) throws {
        guard (Tcl_ListObjAppendElement (interp, obj, value) != TCL_ERROR) else {throw TclError.Error}
    }
    
    // lappend - append an Int to the Tcl object list
    public func lappend (value: Int) throws {
        try self.lappend (Tcl_NewLongObj (value))
    }
    
    // lappend - append a Double to the Tcl object list
    public func lappend (value: Double) throws {
        try self.lappend (Tcl_NewDoubleObj (value))
    }
    
    // lappend - append a String to the Tcl object list
    public func lappend (value: String) throws {
        let cString = value.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
        try self.lappend(Tcl_NewStringObj (cString, -1))
    }
    
    // lappend - append a Bool to the Tcl object list
    public func lappend (value: Bool) throws {
        try self.lappend (Tcl_NewBooleanObj (value ? 1 : 0))
    }
    
    // lappend - append a tclObj to the Tcl object list
    public func lappend (value: TclObj) throws {
        try self.lappend(value)
    }
    
    // lappend - append an array of Int to the Tcl object list
    // (flattens them out)
    public func lappend (array: [Int]) throws {
        try array.forEach {
            try self.lappend($0)
        }
    }
    
    // lappend - append an array of Double to the Tcl object list
    // (flattens them out)
    public func lappend (array: [Double]) throws {
        try array.forEach {
            try self.lappend($0)
        }
    }
    
    // lappend - append an array of String to the Tcl object list
    // (flattens them out)
    public func lappend (array: [String]) throws {
        try array.forEach {
            try self.lappend($0)
        }
    }
    
    // llength - return the number of elements in the list if the contents of our obj can be interpreted as a list
    public func llength () throws -> Int {
        var count: Int32 = 0
        if (Tcl_ListObjLength(interp, obj, &count) == TCL_ERROR) {
            throw TclError.Error
        }
        return Int(count)
    }
    
    // lindex - return the nth element treating obj as a list, if possible, and return a Tcl_Obj *
    func lindex (index: Int) throws -> UnsafeMutablePointer<Tcl_Obj>? {
        var tmpObj: UnsafeMutablePointer<Tcl_Obj> = nil
        var index = index;
        if(index < 0) {
            if let count = try? self.llength() {
                index += count
            }
        }
        if Tcl_ListObjIndex(interp, obj, Int32(index), &tmpObj) == TCL_ERROR {
            throw TclError.Error
        }
        return tmpObj
    }
    
    // lindex returning a TclObj object or nil
    public func lindex (index: Int) throws -> TclObj? {
        let tmpObj: UnsafeMutablePointer<Tcl_Obj>? = try self.lindex(index)
        return TclObj(tmpObj!, Interp: Interp)
    }
    
    // lindex returning an Int or nil
    func lindex (index: Int) throws -> Int {
        let tmpObj: UnsafeMutablePointer<Tcl_Obj>? = try self.lindex(index)
        
        return try tclobjp_to_Int(tmpObj, interp: interp)
    }
    
    // lindex returning a Double or nil
    public func lindex (index: Int) throws -> Double {
        let tmpObj: UnsafeMutablePointer<Tcl_Obj>? = try self.lindex(index)
        
        return try tclobjp_to_Double(tmpObj, interp: interp)
    }
    
    // lindex returning a String or nil
    public func lindex (index: Int) throws -> String {
        let tmpObj: UnsafeMutablePointer<Tcl_Obj>? = try self.lindex(index)
        
        return try tclobjp_to_String(tmpObj)
    }
    
    // lindex returning a Bool or nil
    public func lindex (index: Int) throws -> Bool {
        let tmpObj: UnsafeMutablePointer<Tcl_Obj>? = try self.lindex(index)
        
        return try tclobjp_to_Bool(tmpObj, interp: interp)
    }
    
    // toDictionary - copy the tcl object as a list into a String/TclObj dictionary
    public func get() throws -> [String: TclObj] {
        var dictionary: [String: TclObj] = [:]
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0.stride(to: objc-1, by: 2) {
            let keyString = try tclobjp_to_String(objv[i])
            dictionary[keyString] = TclObj(objv[i+1], Interp: Interp)
        }
        return dictionary
    }
    
    // toArray - create a String array from the tcl object as a list
    public func get() throws -> [String] {
        var array: [String] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0..<Int(objc) {
            try array.append(tclobjp_to_String(objv[i]))
        }
        
        return array
    }
    
    // toArray - create an Int array from the tcl object as a list
    public func get() throws -> [Int] {
        var array: [Int] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0..<Int(objc) {
            let longVal = try tclobjp_to_Int(objv[i], interp: interp)
            array.append(longVal)
        }
        
        return array
    }
    
    // toArray - create a Double array from the tcl object as a list
    public func get() throws ->  [Double] {
        var array: [Double] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0..<Int(objc) {
            let doubleVal = try tclobjp_to_Double(objv[i], interp: interp)
            array.append(doubleVal)
            
        }
        
        return array
    }
    
    // toArray - create a TclObj array from the tcl object as a list,
    // each element becomes its own TclObj
    
    public func get() throws -> [TclObj] {
        var array: [TclObj] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0..<Int(objc) {
            array.append(TclObj(objv[i]))
        }
        
        return array
    }
    
    // Utility function for lrange
    private func normalize_range(first: Int, _ last: Int, _ count: Int) -> ( Int, Int) {
        var start: Int = first
        var end: Int = last
        
        if start < 0 { start = max(0, count + start) }
        else if start >= count { start = count - 1 }
        
        if end < 0 { end = max(0, count + end) }
        else if end >= count { end = count  - 1}
        
        if end < start { end = start }
        
        return (start, end)
    }
    
    // lrange returning a TclObj array
    public func lrange (first: Int, _ last: Int) throws -> [TclObj] {
        var array: [TclObj] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        let (start, end) = normalize_range(first, last, Int(objc))
        
        for i in start...end {
            array.append(TclObj(objv[i], Interp: Interp))
        }
        
        return array
    }
    
    public func lrange(range: Range<Int>) throws -> [TclObj] {
        return try self.lrange(range.startIndex, range.endIndex)
    }
    
    // lrange returning a string array
    public func lrange (first: Int, _ last: Int) throws -> [String] {
        var array: [String] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        let (start, end) = normalize_range(first, last, Int(objc))
        
        for i in start...end {
            try array.append(tclobjp_to_String(objv[i]))
        }
        
        return array
    }
    
    public func lrange(range: Range<Int>) throws -> [String] {
        return try self.lrange(range.startIndex, range.endIndex-1)
    }
    
    // lrange returning an integer array
    public func lrange (first: Int, _ last: Int) throws -> [Int] {
        var array: [Int] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        let (start, end) = normalize_range(first, last, Int(objc))
        
        for i in start...end {
            let longVal = try tclobjp_to_Int(objv[i], interp: interp)
            array.append(longVal)
        }
        
        return array
    }
    
    public func lrange(range: Range<Int>) throws -> [Int] {
        return try self.lrange(range.startIndex, range.endIndex)
    }
    
    // lrange returning a float array
    public func lrange (first: Int, _ last: Int) throws -> [Double] {
        var array: [Double] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        let (start, end) = normalize_range(first, last, Int(objc))
        
        for i in start...end {
            let doubleVal = try tclobjp_to_Double(objv[i], interp: interp)
            array.append(doubleVal)
        }
    
        return array
    }
    
    public func lrange(range: Range<Int>) throws -> [Double] {
        return try self.lrange(range.startIndex, range.endIndex)
    }
    
    // lrange returning a boolean array
    public func lrange (first: Int, _ last: Int) throws -> [Bool] {
        var array: [Bool] = []
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        let (start, end) = normalize_range(first, last, Int(objc))
        
        for i in start...end {
            let boolVal = try tclobjp_to_Bool(objv[i], interp: interp)
            array.append(boolVal)
        }
        
        return array
    }
    
    public func lrange(range: Range<Int>) throws -> [Bool] {
        return try self.lrange(range.startIndex, range.endIndex)
    }

    // get - copy the tcl object as a list into a String/String dictionary
    public func get() throws -> [String: String] {
        var dictionary: [String: String] = [:]
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0.stride(to: Int(objc-1), by: 2) {
            let keyString = try tclobjp_to_String(objv[i])
            let valueString = try tclobjp_to_String(objv[i+1])
            
            dictionary[keyString] = valueString
        }
        return dictionary
    }
    
    // get - copy the tcl object as a list into a String/String dictionary
    public func get() throws -> [String: Int] {
        var dictionary: [String: Int] = [:]
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0.stride(to: Int(objc-1), by: 2) {
            let keyString = try tclobjp_to_String(objv[i])
            let val = try tclobjp_to_Int(objv[i+1])
            dictionary[keyString] = val
        }
        return dictionary
    }
    
    // get - copy the tcl object as a list into a String/String dictionary
    public func get() throws -> [String: Double] {
        var dictionary: [String: Double] = [:]
        
        var objc: Int32 = 0
        var objv: UnsafeMutablePointer<UnsafeMutablePointer<Tcl_Obj>> = nil
        
        if Tcl_ListObjGetElements(interp, obj, &objc, &objv) == TCL_ERROR {throw TclError.Error}
        
        for i in 0.stride(to: Int(objc-1), by: 2) {
            let keyString = try tclobjp_to_String(objv[i])
            let val = try tclobjp_to_Double(objv[i+1])
            
            dictionary[keyString] = val
        }
        return dictionary
    }
    
    subscript(index: Int) -> TclObj? {
        get {
            if let result : TclObj? = try? self.lindex(index) {
                return result
            } else {
                return nil
            }
        }
        set {
            let list = newValue != nil ? [newValue!] : []
            do { try lreplace(index...index, list: list) } catch { }
        }
    }
    
    subscript(range: Range<Int>) -> [TclObj]? {
        get {
            if let result : [TclObj] = try? self.lrange(range) {
                return result
            } else {
                return nil
            }
        }
        set {
            let list = newValue != nil ? newValue! : []
            do { try lreplace(range, list: list) } catch { }
        }
    }
    
    subscript(index: Int) -> String? {
        get {
            if let result : String = try? self.lindex(index) {
                return result
            } else {
                return nil
            }
        }
        set {
            let list = newValue != nil ? [newValue!] : []
            do { try lreplace(index...index, list: list) } catch { }
        }
    }
  
    subscript(range: Range<Int>) -> [String]? {
        get {
            if let result : [String] = try? self.lrange(range) {
                return result
            } else {
                return nil
            }
        }
        set {
            let list = newValue != nil ? newValue! : []
            do { try lreplace(range, list: list) } catch { }
        }
    }
    
    subscript(index: Int) -> Double? {
        get {
            if let result : Double = try? self.lindex(index) {
                return result
            } else {
                return nil
            }
        }
        set {
            let list = newValue != nil ? [newValue!] : []
            do { try lreplace(index...index, list: list) } catch { }
        }
    }
    
    subscript(range: Range<Int>) -> [Double]? {
        get {
            if let result : [Double] = try? self.lrange(range) {
                return result
            } else {
                return nil
            }
        }
        set {
            let list = newValue != nil ? newValue! : []
            do { try lreplace(range, list: list) } catch { }
        }
    }
    
    subscript(index: Int) -> Int? {
        get {
            if let result : Int = try? self.lindex(index) {
                return result
            } else {
                return nil
            }
        }
        set {
            let list = newValue != nil ? [newValue!] : []
            do { try lreplace(index...index, list: list) } catch { }
        }
    }
    
    subscript(range: Range<Int>) -> [Int]? {
        get {
            if let result : [Int] = try? self.lrange(range) {
                return result
            } else {
                return nil
            }
        }
        set {
            let list = newValue != nil ? newValue! : []
            do { try lreplace(range, list: list) } catch { }
        }
    }

    subscript(index: Int) -> Bool? {
        get {
            if let result : Bool = try? self.lindex(index) {
                return result
            } else {
                return nil
            }
        }
        set {
            let list = newValue != nil ? [newValue!] : []
            do { try lreplace(index...index, list: list) } catch { }
        }
    }
    
    subscript(range: Range<Int>) -> [Bool]? {
        get {
            if let result : [Bool] = try? self.lrange(range) {
                return result
            } else {
                return nil
            }
        }
        set {
            let list = newValue != nil ? newValue! : []
            do { try lreplace(range, list: list) } catch { }
        }
    }
    
    // lreplace(range, list) and variants
    func lreplace (range: Range<Int>, objv: [UnsafeMutablePointer<Tcl_Obj>]) throws {
        guard (Tcl_ListObjReplace (interp, obj, Int32(range.startIndex), Int32(range.endIndex-range.startIndex), Int32(objv.count), objv) != TCL_ERROR) else {throw TclError.Error}
    }
    
    func lreplace (range: Range<Int>, list: [TclObj]) throws {
        try self.lreplace(range, objv: list.map { $0.obj })
    }
    
    // IMPORTANT NOTE
    // Orginally used self.lreplace(range, objv: list.map { TclObj($0).map } )
    // This allocated and deallocated the TclObj for each step of the map, so passing freed memory to Tcl_ListObjReplace above
    // Creating a [ TclObj ] meant that none of the TclObjs are deallocated until lreplace returns.
    func lreplace (range: Range<Int>, list: [String]) throws {
        try self.lreplace(range, list: list.map { TclObj($0) })
    }
    
    func lreplace (range: Range<Int>, list: [Int]) throws {
        try self.lreplace(range, list: list.map { TclObj($0) })
    }
    
    func lreplace (range: Range<Int>, list: [Double]) throws {
        try self.lreplace(range, list: list.map { TclObj($0) })
    }
    
    func lreplace (range: Range<Int>, list: [Bool]) throws {
        try self.lreplace(range, list: list.map { TclObj($0) })
    }
    
    func linsert (index: Int, objv: [UnsafeMutablePointer<Tcl_Obj>]) throws {
        guard (Tcl_ListObjReplace (interp, obj, Int32(index), Int32(0), Int32(objv.count), objv) != TCL_ERROR) else {throw TclError.Error}
    }
    
    func linsert (index: Int, list: [TclObj]) throws {
        try self.linsert(index, objv: list.map { $0.obj })
    }
    
    func linsert (index: Int, list: [String]) throws {
        try self.linsert(index, list: list.map { TclObj($0) })
    }
    
    func linsert (index: Int, list: [Int]) throws {
        try self.linsert(index, list: list.map { TclObj($0) })
    }
    
    func linsert (index: Int, list: [Double]) throws {
        try self.linsert(index, list: list.map { TclObj($0) })
    }
    
    func linsert (index: Int, list: [Bool]) throws {
        try self.linsert(index, list: list.map { TclObj($0) })
    }
}


