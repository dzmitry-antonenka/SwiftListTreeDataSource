import Foundation

public class OutlineItem: Hashable {
    public let identifier: UUID
    public let title: String
    public var subitems: [OutlineItem]

    public init(
        identifier: UUID = UUID(),
        title: String,
        subitems: [OutlineItem] = []
    ) {
        self.identifier = identifier
        self.title = title
        self.subitems = subitems
    }

    public init(
        other: OutlineItem
    ) {
        self.identifier = other.identifier
        self.title = other.title
        self.subitems = other.subitems
    }

    public func hash(into hasher: inout Hasher) {
        // don't add subitems recursively for performance reasons.
        hasher.combine(identifier)
    }
    public static func == (lhs: OutlineItem, rhs: OutlineItem) -> Bool {
        // don't add subitems recursively for performance reasons.
        lhs.identifier == rhs.identifier
    }
}

extension OutlineItem: CustomStringConvertible {
    public var description: String { "\(title)" }
}
extension OutlineItem: CustomDebugStringConvertible {
    public var debugDescription: String { "\(title)" }
}

public struct NodeTestItem: Hashable {
    public let identifier: UUID
    public let title: String
    public var subitems: [NodeTestItem]
    public init(identifier: UUID, title: String, subitems: [NodeTestItem]) {
        self.identifier = identifier
        self.title = title
        self.subitems = subitems
    }
}
extension NodeTestItem {
    public init(_ item: NodeTestItem) {
        self.init(identifier: item.identifier, title: item.title, subitems: item.subitems)
    }
    public init(outline: OutlineItem) {
        identifier = outline.identifier
        title = outline.title
        subitems = outline.subitems.map { NodeTestItem(outline: $0) }
    }
}
