import Foundation
import Gravity

let scriptURL = Bundle.module.resourceURL!.appendingPathComponent("File.gravity")
let gravity = Gravity()

// Set Int
gravity.setVar("itsTen", to: 10)

// Assign a Swift func to an existing `extern func` in the gravity script
func doSomething(gravity: Gravity, args: [GravityValue]) -> GravityValue {
    print("Did in fact do something!")
    // Gets printed from the gravity script
    return gravity.createValue("Hello!")
}
gravity.setFunc("doSomething", to: doSomething)

// Assign a Swift closure to an existing `extern func` in the gravity script
gravity.setFunc("doSomethingElse") { gravity, args in
    print("Did something else!", args)
}


// Create a new class for editing
let gravityClass = gravity.createClass(named: "MyClass")

// Give the class an instance variable
gravityClass.addVar("iVar1")

// Give the class a function with a Swift callback
gravityClass.addFunc("iFunc1") { gravity, sender, args in
    return 7 ... 14
}

// Set the class to an existing `extern class`
gravity.setClass("MyClass", to: gravityClass)


// Create an instance of the class
let instance = gravityClass.createInstance()

// Set the instance variable of the instance
instance.setVar("iVar1", to: 17)

// Assign the instance to an existing `extern var` in the gravity script
gravity.setVar("externalInstance", to: instance)

do {
    // Compile the script
    try gravity.compile(scriptURL)
    
    
    // Run the main function of the gravity script
    let result = try gravity.runMain()
    
    // print the result returned from `func main()`
    print("Result:", result)
    
    
    // Get a var by name and print it's value
    print(gravity.getVar("itsTen"))
    
    // Run an existing `func` in the gravity script
    try gravity.runFunc("doSomethingShared")
    
    // Run an existing `func` in the gravity script and print it's result
    print("Func itsNine():", try gravity.runFunc("itsNine"))
    
    
    // Get an instance from a `var` in the gravity script
    let instance = try gravity.getInstance("internalInstance")
    
    // Assign a value to a `var` in the `Instance`
    instance.setVar("iVar1", to: ["Yes" : 66])
    
    // Get a `var` from an `Instance` and print it's result
    print("internalInstance.iVar1:", instance.getVar("iVar1"))
    
    // Run the func we set on the class of the instance on the instance
    print("internalInstance.iFunc1:", try instance.runFunc("iFunc1"))
}catch{
    print(error)
    fatalError()
}
