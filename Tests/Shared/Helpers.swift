import Foundation
@testable import SwiftListTreeDataSource

public func addItems(_ items: [OutlineItem], to snapshot: ListTreeDataSource<OutlineItem>) {
    addItems(items, itemChildren: { $0.subitems }, to: snapshot)
}
public func addItems(_ items: [NodeTestItem], to snapshot: ListTreeDataSource<NodeTestItem>) {
    addItems(items, itemChildren: { $0.subitems }, to: snapshot)
}
public func depthFirstFlattened(items: [OutlineItem]) -> [OutlineItem] {
    return depthFirstFlattened(items: items, itemChildren: { $0.subitems })
}

public func depthLookupTable<Item>(_ heads: [Item], itemChildren: (Item) -> [Item]) -> [Item: Int] {
    var queue: Queue<(item: Item, level: Int)> = .init()
    var depthTable: [Item: Int] = [:]
    
    let headsWithLevels = zip(heads, Array(repeating: 0, count: heads.count))
    queue.enqueue( Array(headsWithLevels) )
    while let current = queue.dequeue() {
        depthTable[current.item] = current.level
        
        let children = itemChildren(current.item)
        let childrenWithLevels = zip(children, Array(repeating: current.level + 1, count: children.count))
        queue.enqueue( Array(childrenWithLevels) )
    }
    return depthTable
}
