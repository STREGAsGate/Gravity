/**
 * Copyright © 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 * Licensed under MIT License
 *
 * http://stregasgate.com
 */

import GravityC

//MARK: - Emitters
public protocol GravityValueEmitting {
    var gValue: gravity_value_t {get}
}
public protocol GravityClassEmitting {
    var gClass: UnsafeMutablePointer<gravity_class_t>! {get}
}
public protocol GravityInstanceEmitting {
    var gInstance: UnsafeMutablePointer<gravity_instance_t> {get}
}
public protocol GravityClosureEmitting {
    var gClosure: UnsafeMutablePointer<gravity_closure_t>! {get}
}

// MARK: - GravityVMReferencing
public protocol GravityVMReferencing {
    var _gravity: Gravity {get}
}

// MARK: - GravityGetValueExtended
public protocol GravityGetVarExtended {
    func getVar(_ key: String) -> GravityValue
}
extension GravityGetVarExtended {
    /**
     Obtain a value from gravity.
     - parameter key: The name of the `var` as written in the gravity script.
     */
    @inline(__always)
    public func getVar(_ key: String) -> Bool {
        return getVar(key).getBool()
    }
    
    /**
     Obtain a value from gravity.
     - parameter key: The name of the `var` as written in the gravity script.
     */
    @inline(__always)
    public func getVar<T: BinaryInteger>(_ key: String) -> T {
        return getVar(key).getInt()
    }
    
    /**
     Obtain a value from gravity.
     - parameter key: The name of the `var` as written in the gravity script.
     */
    @inline(__always)
    public func getVar(_ key: String) -> Float {
        return getVar(key).asFloat()
    }
    
    /**
     Obtain a value from gravity.
     - parameter key: The name of the `var` as written in the gravity script.
     */
    @inline(__always)
    public func getVar(_ key: String) -> Double {
        return getVar(key).asDouble()
    }
    
    /**
     Obtain a value from gravity.
     - parameter key: The name of the `var` as written in the gravity script.
     */
    @inline(__always)
    public func getVar(_ key: String) -> String {
        return getVar(key).getString()
    }
}

// MARK: - GravityGetValueExtendedVMReferencing
public protocol GravityGetVarExtendedVMReferencing: GravityGetVarExtended, GravityVMReferencing {}
extension GravityGetVarExtendedVMReferencing {
    @inline(__always)
    public func getVar(_ key: String) -> GravityClosure {
        return getVar(key).getClosure(gravity: _gravity, sender: self as? GravityValueEmitting)
    }
    
    @inlinable
    public func getVar(_ key: String) throws -> GravityInstance {
        let value = getVar(key)
        if value == .null {
            throw "Gravity Error: Failed to find Instance named \(key)."
        }
        let valueType = value.valueType
        if valueType != .instance {
            throw "Gravity Error: Expected Instance for key \(key). Found \(valueType)."
        }
        return value.getInstance(gravity: _gravity)
    }
}

// MARK: - GravitySetValueExtended
public protocol GravitySetVarExtended {
    func setVar(_ key: String, to value: GravityValue)
}
extension GravitySetVarExtended {
    /**
     Assign a value to a `var` in the gravity script.
     - parameter value: The swift value to assign
     - parameter key: The name of the `extern var` as written in the gravity script.
     */
    @inline(__always)
    public func setVar(_ key: String, to value: any BinaryInteger) {
        self.setVar(key, to: GravityValue(value))
    }
    
    /**
     Assign a value to a `var` in the gravity script.
     - parameter value: The swift value to assign
     - parameter key: The name of the `extern var` as written in the gravity script.
     */
    @inline(__always)
    public func setVar(_ key: String, to value: any BinaryFloatingPoint) {
        self.setVar(key, to: GravityValue(value))
    }

    /**
     Assign a value to a `var` in the gravity script.
     - parameter value: The swift value to assign
     - parameter key: The name of the `extern var` as written in the gravity script.
     */
    @inline(__always)
    public func setVar(_ key: String, to value: String) {
        self.setVar(key, to: GravityValue(value))
    }
    
    /**
     Assign a value to a `var` in the gravity script.
     - parameter value: The swift value to assign
     - parameter key: The name of the `extern var` as written in the gravity script.
     */
    @inline(__always)
    public func setVar(_ key: String, to value: GravityValueEmitting) {
        self.setVar(key, to: GravityValue(value))
    }
}

// MARK: - GravityGetClosureExtended
public protocol GravityGetFuncExtended {
    func getFunc(_ key: String) throws -> GravityClosure
}
