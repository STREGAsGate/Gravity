/**
 * Copyright © 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 * Licensed under MIT License
 *
 * http://stregasgate.com
 */

import GravityC

/// A gravity script class definition.
public class GravityInstance: GravityValueEmitting, GravityInstanceEmitting {
    public let gravity: Gravity
    public let gInstance: UnsafeMutablePointer<gravity_instance_t>

    internal init(gravityClass: GravityClass, gravity: Gravity) {
        self.gravity = gravity
        self.gInstance = gravity_instance_new(gravity.vm, gravityClass.gClass)
    }
    
    internal init(value: GravityValue, gravity: Gravity) {
        assert(value.valueType == .instance)
        self.gravity = gravity
        self.gInstance = unsafeBitCast(value.gValue.p, to: UnsafeMutablePointer<gravity_instance_t>.self)
    }
    
    public var gValue: gravity_value_t {
        return gravity_value_from_object(gInstance)
    }
    
    public var gravityClassName: String {
        return String(cString: gravity_value_name(gValue))
    }
}

extension GravityInstance: GravityGetVarExtendedVMReferencing  {
    @_transparent
    public var _gravity: Gravity {
        return gravity
    }
    
    public func getVar(_ key: String) -> GravityValue {
        guard let htable = gInstance.pointee.objclass?.pointee.htable else {
            //TODO: Add a caching system to return the same instance over and over.
            fatalError("Another instance was created by you invalidating this one.")
        }
        let htableValue = key.withCString { key in
            return gravity_hash_lookup_cstring(htable, key)
        }
        let closure = GravityValue(gValue: htableValue!.pointee).getClosure(gravity: gravity, sender: self)
        if let index = closure.gClosure.pointee.f?.pointee.index {
            return GravityValue(gValue: gInstance.pointee.ivars[Int(index)])
        }else{
            print("Gravity: Failed to obtain var \(key).")
        }
        return .null
    }
}

extension GravityInstance: GravitySetVarExtended {
    public func setVar(_ key: String, to value: GravityValue) {
        guard let htable = gInstance.pointee.objclass?.pointee.htable else {
            //TODO: Add a caching system to return the same instance over and over.
            fatalError("Another instance was created by you invalidating this one.")
        }
        let htableValue = key.withCString { key in
            return gravity_hash_lookup_cstring(htable, key).pointee
        }

        let closure = GravityValue(gValue: htableValue).getClosure(gravity: gravity, sender: self)
        let ivarIndex = UInt32(closure.gClosure.pointee.f.pointee.index)
        gravity_instance_setivar(gInstance, ivarIndex, value.gValue)
    }
}

extension GravityInstance: GravityGetFuncExtended {
    public func getFunc(_ key: String) throws -> GravityClosure {
        guard let gValue: gravity_value_t = key.withCString({ key in
            return gravity_hash_lookup_cstring(gInstance.pointee.objclass.pointee.htable, key)
        })?.pointee else {throw "Gravity Error: Failed to find closure named \(key)."}
        let value = GravityValue(gValue: gValue)
        let valueType = value.valueType
        if valueType != .closure {
            throw "Gravity Error: Expected closure but found \(valueType)."
        }
        return value.getClosure(gravity: gravity, sender: self)
    }
    
    @discardableResult @inline(__always)
    public func runFunc(_ name: String) throws -> GravityValue {
        return try runFunc(name, withArguments: nil)
    }
    
    @discardableResult @inline(__always)
    public func runFunc(_ name: String, withArguments args: [GravityValue]) throws -> GravityValue {
        return try getFunc(name).run(withArguments: args.map({$0.gValue}), sender: self)
    }
    
    @discardableResult @inline(__always)
    public func runFunc(_ name: String, withArguments args: GravityValue...) throws -> GravityValue {
        return try getFunc(name).run(withArguments: args.map({$0.gValue}), sender: self)
    }
}
