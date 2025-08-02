import Foundation

extension Sequence {
    public func uniqueMap<T>(_ transform: (Element) -> T) -> [T] where T: Hashable {
        var set = Set<T>()
        var array = [T]()
        for element in self {
            let element = transform(element)
            if set.insert(element).inserted {
                array.append(element)
            }
        }
        return array
    }
}
