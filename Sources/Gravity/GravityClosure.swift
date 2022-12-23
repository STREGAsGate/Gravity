/**
 * Copyright © 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 * Licensed under MIT License
 *
 * http://stregasgate.com
 */

import GravityC

public class GravityClosure: GravityValueEmitting, GravityClosureEmitting {
    let gravity: Gravity
    public let gClosure: UnsafeMutablePointer<gravity_closure_t>!
    let sender: GravityValueEmitting?

    internal init(gravity: Gravity, closure: UnsafeMutablePointer<gravity_closure_t>, sender: GravityValueEmitting?) {
        self.gravity = gravity
        self.gClosure = closure
        self.sender = sender
    }
    
    public var gValue: gravity_value_t {
        var gValue = gravity_value_t()
        gValue.p = unsafeBitCast(gClosure, to: UnsafeMutablePointer<gravity_object_t>.self)
        gValue.isa = gravity_class_closure
        return gValue
    }
    
    @discardableResult @inline(__always)
    public func run(withArguments args: [gravity_value_t], sender: GravityValueEmitting? = nil) throws -> GravityValue {
        var args = args
        gravity_vm_runclosure(gravity.vm, gClosure, sender?.gValue ?? gravity_value_from_null(), &args, UInt16(args.count))

        if let error = gravity.recentError {throw error}

        return GravityValue(gValue: gravity_vm_result(gravity.vm))
    }
}
