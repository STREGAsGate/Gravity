/**
 * Copyright © 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 * Licensed under MIT License
 *
 * http://stregasgate.com
 */

import GravityC
#if canImport(Foundation) && !os(WASI)
import struct Foundation.URL
#endif

extension Gravity {
    static var version: String {
        return GRAVITY_VERSION
    }
    static var versionNumber: Int {
        return Int(GRAVITY_VERSION_NUMBER)
    }
}

internal class GravityCompilerUserData {
    unowned let gravity: Gravity
    #if canImport(Foundation) && !os(WASI)
    var baseURL: URL? = nil
    #endif
    init(gravity: Gravity) {
        self.gravity = gravity
    }
}

internal var gravityDelegate: gravity_delegate_t = {
    var delegate: gravity_delegate_t = gravity_delegate_t()
    delegate.error_callback = errorCallback(vm:errorType:description:errorDesc:xdata:)
    #if canImport(Foundation) && !os(WASI)
    delegate.filename_callback = filenameCallback(fileID:xData:)
    delegate.loadfile_callback = loadFileCallback(file:size:fileID:xData:isStatic:)
    #endif
    #if DEBUG
    delegate.unittest_callback = unittestCallback(vm:errorType:desc:note:value:row:column:xdata:)
    #endif
    delegate.bridge_execute = gravityCFuncBridged(vm:xdata:ctx:args:nargs:rindex:)
    return delegate
}()

public class Gravity {
    let vm: OpaquePointer
    var isManaged: Bool
    var mainClosure: UnsafeMutablePointer<gravity_closure_t>? = nil
    var didRunMain: Bool = false
    var recentError: Error? = nil
    #if DEBUG
    var unitTestExpected: Testing? = nil
    #endif
    
    var loadedFilenames: [UInt32:String] = [:]
    
    /// Returns true if the compiled script included the additional sourece
    public func compiledSourceIncluded(fileName: String) -> Bool {
        return loadedFilenames.values.contains(where: {$0 == fileName})
    }
    
    internal lazy var compilerUserData: GravityCompilerUserData = GravityCompilerUserData(gravity: self)
    internal func compilerUserDataReference() -> UnsafeMutableRawPointer {
        return Unmanaged.passUnretained(compilerUserData).toOpaque()
    }
    
    @inline(__always)
    internal func setGrabageCollectionEnabled(_ enabled: Bool) {
        gravity_gc_setenabled(vm, enabled)
    }
    
    // These references are used in various xdata areas and should
    // stay alive while this gravity instance is alive.
    struct UserDataReference: Hashable {
        let reference: AnyObject
        @inlinable
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(reference))
        }
        static func ==(lhs: Self, rhs: Self) -> Bool {
            return lhs.reference === rhs.reference
        }
    }
    internal var userDataReferences: Set<UserDataReference> = []
    internal func retainedUserDataPointer(from reference: AnyObject) -> UnsafeMutableRawPointer {
        let userDataP = Unmanaged.passUnretained(reference).toOpaque()
        userDataReferences.insert(UserDataReference(reference: reference))
        return userDataP
    }
    
    /// Create a new gravity instance.
    public init() {
        self.vm = gravity_vm_new(&gravityDelegate)
        self.isManaged = true
    }
    
    internal init(vm: OpaquePointer) {
        self.vm = vm
        self.isManaged = false
    }
    
    /**
     Compile a gravity script.
     - parameter sourceCode: The gravity script as a `String`.
     - parameter addDebug: `true` to add debug. nil to add debug only in DEBUG configurations.
     - throws: Gravity compilation errors such as syntax problems.
     */
    public func compile(_ sourceCode: String, addDebug: Bool? = nil) throws {
        self.mainClosure = nil
        self.didRunMain = false
        try sourceCode.withCString { cString in
            #if DEBUG
            let isDebug = true
            #else
            let isDebug = false
            #endif
            
            gravityDelegate.xdata = compilerUserDataReference()
            
            let compiler: OpaquePointer = gravity_compiler_create(&gravityDelegate)
            if let closure = gravity_compiler_run(compiler, cString, sourceCode.count, 0, true, addDebug ?? isDebug) {
                self.mainClosure = closure
                gravity_compiler_transfer(compiler, vm)
                gravity_compiler_free(compiler)
            }else if let error = recentError {
                defer {
                    gravity_compiler_free(compiler)
                    recentError = nil
                }
                throw error
            }else{
                gravity_compiler_free(compiler)
                throw "Gravity Error: Failed to compile."
            }
        }
        #if canImport(Foundation) && !os(WASI)
        compilerUserData.baseURL = nil
        #endif
    }
    
    /// Runs the  `func main()` of the gravity script.
    @discardableResult
    public func runMain() throws -> GravityValue {
        guard let mainClosure = mainClosure else {throw "No main closure found. Did you forget to compile?"}
        gravity_vm_runmain(vm, mainClosure)
        if let error = recentError {throw error}
        self.didRunMain = true
        return GravityValue(gValue: gravity_vm_result(vm))
    }
    
    @inline(__always)
    public func setClass(_ key: String, to value: GravityClass) {
        setVar(key, to: value)
    }
    
    /**
     References an object instance from within the gravity script.
     - parameter key: The name of the `var` as written in the gravity script.
     - returns: A `GravityInstance` which references the script closure/function for `key`.
    */
    @inline(__always)
    public func getInstance(_ key: String) throws -> GravityInstance {
        let value = getVar(key)
        if value == .null {
            throw "Gravity Error: Failed to find Instance named \(key)."
        }
        let valueType = value.valueType
        if valueType != .instance {
            throw "Gravity Error: Expected Instance for key \(key). Found \(valueType)."
        }
        return value.getInstance(gravity: self)
    }
    
    /**
     Make a new gravity value from a Swift value.
     - parameter value: The Swift value to store in the `GravityValue`.
     - returns: A `GravityValue` representing the provided Swift vlaue.
     */
    public func createValue(_ value: any BinaryInteger) -> GravityValue {
        return GravityValue(value)
    }
    /**
     Make a new gravity value from a Swift value.
     - parameter value: The Swift value to store in the `GravityValue`.
     - returns: A `GravityValue` representing the provided Swift vlaue.
     */
    public func createValue(_ value: any BinaryFloatingPoint) -> GravityValue {
        return GravityValue(value)
    }
    
    /**
     Make a new gravity value from a Swift value.
     - parameter value: The Swift value to store in the `GravityValue`.
     - returns: A `GravityValue` representing the provided Swift vlaue.
     */
    public func createValue(_ value: Bool) -> GravityValue {
        return GravityValue(value)
    }
    
    /**
     Make a new gravity value from a Swift value.
     - parameter value: The Swift value to store in the `GravityValue`.
     - returns: A `GravityValue` representing the provided Swift vlaue.
     */
    public func createValue(_ value: String) -> GravityValue {
        return GravityValue(value, self)
    }
    
    /**
     Make a new gravity value from a Swift value.
     - parameter value: The Swift value to store in the `GravityValue`.
     - returns: A `GravityValue` representing the provided Swift vlaue.
     */
    public func createValue(_ value: StaticString) -> GravityValue {
        return GravityValue(value, self)
    }
    
    /**
     Make a new gravity value from a Swift value.
     - parameter value: The Swift value to store in the `GravityValue`.
     - returns: A `GravityValue` representing the provided Swift vlaue.
     */
    public func createValue(_ values: [GravityValue]) -> GravityValue {
        return GravityValue(values, self)
    }
    
    /**
     Make a new gravity value from a Swift value.
     - parameter value: The Swift value to store in the `GravityValue`.
     - returns: A `GravityValue` representing the provided Swift vlaue.
     */
    public func createValue(_ values: [GravityValue:GravityValue]) -> GravityValue {
        return GravityValue(values, self)
    }
    
    /**
     Make a new gravity class definition.
     - parameter name: The class name as written in a gravity script.
     - parameter superClass: An optional super class for the gravity class.
     - returns: A `GravityClass` representing a gravity class.
     */
    public func createClass(named name: String, superClass: GravityClass? = nil) -> GravityClass {
        let theClass = GravityClass(name: name, superClass: superClass, gravity: self)
        name.withCString { cString in
            gravity_vm_setvalue(vm, cString, theClass.gValue)
        }
        return theClass
    }
    
    deinit {
        guard isManaged else {return}
        self.cleanupCInternalFunctions()
        self.cleanupCBridgedFunctions()
        gravity_vm_free(vm)
        gravity_core_free()
    }
}

// This is only called for global closures. Instance methods use the seperate bridge delegate callback.
internal func gravityCFuncInternal(vm: OpaquePointer!, args: UnsafeMutablePointer<gravity_value_t>!, nargs: UInt16, rindex: UInt32) -> Bool {
    let functionName: String = {
        let gClosure = unsafeBitCast(args!.pointee.p, to: UnsafeMutablePointer<gravity_closure_t>.self)
        let cName = gClosure.pointee.f.pointee.identifier!
        return String(cString: cName)
    }()
    
    guard let function = Gravity.cInternalFunctionMap[vm]?[functionName] else {fatalError()}
    var args = UnsafeBufferPointer(start: args, count: Int(nargs)).map({GravityValue(gValue: $0)})
    args.removeFirst()// The first is always the closure being called
    let result = function(Gravity(vm: vm), args)
    return _gravityHandleCFuncReturn(vm: vm, returnValue: result, returnSlot: rindex)
}

@inline(__always)
internal func _gravityHandleCFuncReturn(vm: OpaquePointer, returnValue: GravityValue, returnSlot: UInt32) -> Bool {
    switch returnValue.valueType {
    case .closure:
        gravity_vm_setslot(vm, returnValue.gValue, returnSlot)
        return false
    case .fiber:
        return false
    default:
        gravity_vm_setslot(vm, returnValue.gValue, returnSlot)
        return true
    }
}

extension Gravity {
    internal static var cInternalFunctionMap: [OpaquePointer:[String:GravitySwiftFunctionReturns]] = [:]
    @inline(__always) fileprivate func cleanupCInternalFunctions() {
        Gravity.cInternalFunctionMap.removeValue(forKey: vm)
    }
    
    /**
     Assign a Swift function/closure to be called from the gravity script
     - parameter key: The name of the `extern func` as wirrten in the gravity script.
     - parameter function: The swift function to call
     */
    public func setFunc(_ key: String, to function: @escaping GravitySwiftFunctionReturns) {
        key.withCString { cKey in
            let gFunc = gravity_function_new_internal(vm, cKey, gravityCFuncInternal, 0)
            let gClosure = gravity_closure_new(vm, gFunc)
            
            var gValue = gravity_value_t()
            gValue.p = unsafeBitCast(gClosure, to: UnsafeMutablePointer<gravity_object_t>.self)
            gValue.isa = gravity_class_closure
            
            gravity_vm_setvalue(vm, cKey, gValue)
        }
        
        var funcDatabase = Self.cInternalFunctionMap[vm] ?? [:]
        funcDatabase[key] = function
        Self.cInternalFunctionMap[vm] = funcDatabase
    }
    
    /**
     Assign a Swift function/closure to be called from the gravity script
     - parameter key: The name of the `extern func` as wirrten in the gravity script.
     - parameter function: The swift function to call
     */
    @inlinable
    public func setFunc(_ key: String, to function: @escaping GravitySwiftFunction) {
        let rFunc: GravitySwiftFunctionReturns = {gravity, args -> GravityValue in
            function(gravity, args)
            return .null
        }
        setFunc(key, to: rFunc)
    }
}

/// A function called from gravity that has no ownership, such as a global function.
public typealias GravitySwiftFunctionReturns = (_ gravity: Gravity, _ args: [GravityValue]) -> GravityValue
public typealias GravitySwiftFunction = (_ gravity: Gravity, _ args: [GravityValue]) -> Void

extension Gravity: GravityVMReferencing {
    @_transparent
    public var _gravity: Gravity {
        return self
    }
}

extension Gravity: GravityGetVarExtendedVMReferencing {
    /**
     Obtain a value from gravity.
     - parameter key: The name of the `var` as written in the gravity script.
     */
    public func getVar(_ key: String) -> GravityValue {
        guard didRunMain else {fatalError("Gravity Error: `runMain()` must be called before you can do this.")}
        return key.withCString { cString in
            let value: gravity_value_t = gravity_vm_getvalue(vm, cString, UInt32(key.utf8.count))
            return GravityValue(gValue: value)
        }
    }
}

extension Gravity: GravitySetVarExtended {
    /**
     Assign a value to a `var` in the gravity script.
     - parameter value: The swift value to assign
     - parameter key: The name of the `extern var` as written in the gravity script.
     */
    public func setVar(_ key: String, to value: GravityValue) {
        key.withCString { cString in
            gravity_vm_setvalue(vm, cString, value.gValue)
        }
    }
}

extension Gravity: GravityGetFuncExtended {
    /**
     References a closure/function from within the gravity script.
     - parameter key: The name of the closure as written in the gravity script.
     - returns: A `GravityClosure` which references the script closure/function for `key`.
                You can call `run()` on the `GravityClosure` to execute the reference script closure.
    */
    public func getFunc(_ key: String) throws -> GravityClosure {
        let value = getVar(key)
        if value == .null {
            throw "Gravity Error: Failed to find Closure named \(key)."
        }
        let valueType = value.valueType
        if valueType != .closure {
            throw "Gravity Error: Expected Closure for key \(key). Found \(valueType)."
        }
        return value.getClosure(gravity: self, sender: nil)
    }
    
    @discardableResult @inline(__always)
    public func runFunc(_ name: String) throws -> GravityValue {
        return try runFunc(name, withArguments: nil)
    }
    
    @discardableResult @inline(__always)
    public func runFunc(_ name: String, withArguments args: [GravityValue]) throws -> GravityValue {
        return try getFunc(name).run(withArguments: args.map({$0.gValue}))
    }
    
    @discardableResult @inline(__always)
    public func runFunc(_ name: String, withArguments args: GravityValue...) throws -> GravityValue {
        return try getFunc(name).run(withArguments: args.map({$0.gValue}))
    }
}

extension Gravity: Equatable {
    public static func ==(lhs: Gravity, rhs: Gravity) -> Bool {
        return lhs.vm == rhs.vm
    }
}
