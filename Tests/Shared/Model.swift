import Foundation

public class OutlineItem: Hashable {
    public let title: String
    public var subitems: [OutlineItem]

    public init(title: String,
         subitems: [OutlineItem] = []) {
        self.title = title
        self.subitems = subitems
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    public static func == (lhs: OutlineItem, rhs: OutlineItem) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    private let identifier = UUID()
}

extension OutlineItem: CustomStringConvertible {
    public var description: String { "\(title)" }
}
extension OutlineItem: CustomDebugStringConvertible {
    public var debugDescription: String { "\(title)" }
}
