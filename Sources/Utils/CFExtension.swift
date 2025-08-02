import Foundation

extension CFArray {
    public func getValue<T>(_ index: CFIndex) -> T {
        return unsafeBitCast(CFArrayGetValueAtIndex(self, index), to: T.self)
    }

    public func getCount() -> CFIndex {
        return CFArrayGetCount(self)
    }
}

extension CFDictionary {
    public func getValue<T>(_ key: CFString) -> T {
        return unsafeBitCast(
            CFDictionaryGetValue(self, unsafeBitCast(key, to: UnsafeRawPointer.self)), to: T.self)
    }
}
