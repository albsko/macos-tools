// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import AppKit
import ArgumentParser

@main
struct swift_tools: ParsableCommand {
    mutating func run() throws {
        let greeter = Greeter()
        print(greeter.getGreeting())
    }
}

struct Greeter {
    func getGreeting() -> String {
        return "Hello!"
    }
}
