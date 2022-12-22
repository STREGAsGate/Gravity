<b>⚠️ Under Heavy Development! Expect sweeping changes followed by a squash.</b>

# Gravity for Swift

<p align="left" >
<a href="http://gravity-lang.org"><img src="https://raw.githubusercontent.com/stregasgate/gravity/master/.github/docs/assets/images/logo-gravity.png" height="74px" alt="Gravity Programming Language" title="Gravity Programming Language"></a>
<a href="https://swift.org"><img src="https://raw.githubusercontent.com/stregasgate/gravity/master/.github/docs/assets/images/logo-swift.png" height="74px" alt="Swift Programming Language" title="Swift Programming Language"></a>
</p>

[![Windows](https://github.com/STREGAsGate/Gravity/actions/workflows/Windows.yml/badge.svg)](https://github.com/STREGAsGate/Gravity/actions/workflows/Windows.yml) [![macOS](https://github.com/STREGAsGate/Gravity/actions/workflows/macOS.yml/badge.svg)](https://github.com/STREGAsGate/Gravity/actions/workflows/macOS.yml) [![Linux](https://github.com/STREGAsGate/Gravity/actions/workflows/Linux.yml/badge.svg)](https://github.com/STREGAsGate/Gravity/actions/workflows/Linux.yml) [![WebAssembly](https://github.com/STREGAsGate/Gravity/actions/workflows/SwiftWasm.yml/badge.svg)](https://github.com/STREGAsGate/Gravity/actions/workflows/SwiftWasm.yml)

# What is Gravity for Swift?
<b>Gravity</b> is a powerful, dynamically typed, lightweight, embeddable programming language. It is a class-based concurrent scripting language with a modern Swift like syntax.

<b>Gravity for Swift</b> is a Swift Package that allows you to use the Gravity language with your Swift projects.

# Getting Started
<i>This README does not cover the Gravity language. </br>
Before jumping in you should familiarize yourself with [Gravity's documentation](http://gravity-lang.org).</i>

## Adding Gravity for Swift to your Project
You can add <b>Gravity for Swift</b> to a package:
```swift
let package = Package(
    name: "MyThing",
    dependencies: [
        // Add Gravity as a package dependency so it's available to your target
        .package(url: "https://github.com/STREGAsGate/Gravity.git", branch: "master"),
    ],
    targets: [
        // Add Gravity to your target dependencies
        // This will make Gravity available to `import Gravity`
        .executableTarget(name: "MyThing", dependencies: ["Gravity"]),
    ]
)
```
<sub>If you are using an ***Xcode Project*** you can add gravity by selecting your project in the navigator, your project at the top of the targets list, and finally the ***Package Dependencies*** tab.</sub></br>

## Running a Gravity script
```swift
import Gravity

// The Gravity object handles everything.
let gravity = Gravity()

// Compile script from a URL
let bundleURL = Bundle.module.resourceURL!
let scriptURL = bundleURL.appendingPathComponent("File.gravity")
try gravity.compile(scriptURL)
  
// Execute the script's func main()
try gravity.runMain()
```

A Gravity script can also be compiled from a string.
```swift
try gravity.compile("func main() {}")
```

Some actions must be done in a specific order. </br>
For example, you cannot call `runMain()` before calling `compile(script)`.
</br></br>
# Obtaining Values
You can retrieve a value from the script in various ways.

### Global Variables
A global variable is any variable in the root of a script.
```swift
/* --- Gravity Script --- */
var myVar = 10 // <- This is a global variable
func main() {}
```
You can obtain the value of a global variable using `gravity.getVar("myVar")`.
```swift
// The GravityValue type is the universal return type for Gravity
let myVarGravity: GravityValue = gravity.getVar("myVar")
// Make sure it's an Int
assert(myVarGravity.valueType == .int)
// Ask for the Int
let myVar: Int = myVarGravity.getInt()

// The Int can also be obtained directly by declarting myVar as an Int
let myVar: Int = gravity.getVar("myVar")
```

### Return Values
All Closures in Gravity return a value, but you can ignore the value if you know it's empty
```swift
// Ignoring the return value
try gravity.runMain()
// Storing the return value
let result = try gravity.runMain()
```

# C99 Access
You can access the unmodifed c99 Gravity source directly via the Swift module GravityC.
```swift
import GravityC
```
<sub>Note: Using the GravityC module requires significant knowledge of Swift's Unsafe API and is not recommended.</sub>

# Strega's Gate
[![Twitter](https://img.shields.io/twitter/follow/stregasgate?style=social)](https://twitter.com/stregasgate) [![YouTube](https://img.shields.io/youtube/channel/subscribers/UCBXFkK2B4w9856wBJfCGufg?label=Subscribe&style=social)](https://youtube.com/stregasgate) [![Reddit](https://img.shields.io/reddit/subreddit-subscribers/stregasgate?style=social)](https://www.reddit.com/r/stregasgate/) [![Discord](https://img.shields.io/discord/641809158051725322?label=Hang%20Out&logo=Discord&style=social)](https://discord.gg/5JdRJhD)

Check out what I'm working on at various places or come say hi on discord!
