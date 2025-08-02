import Foundation

extension DispatchTime {
    public var uptimeMilliseconds: UInt64 { uptimeNanoseconds / 1_000_000 }
}
