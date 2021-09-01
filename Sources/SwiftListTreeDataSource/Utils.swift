//
//  ListTreeDataSource+Utils.swift
//  SwiftListTreeDataSource
//
//  Created by Dzmitry Antonenka on 18.04.21.
//

import Foundation

public func addItems<Item>(_ items: [Item], itemChildren: (Item) -> [Item], to dataSource: ListTreeDataSource<Item>) {
    dataSource.append(items, to: nil)
    
    var queue: Queue<Item> = .init()
    queue.enqueue(items)
    
    while let current = queue.dequeue() {
        dataSource.append(itemChildren(current), to: current)
        queue.enqueue(itemChildren(current))
    }
    
    dataSource.reload()
}

func depthFirstFlattened<Item: Hashable>(items: [TreeItem<Item>]) -> [TreeItem<Item>] {
    return depthFirstFlattened(items: items, itemChildren: { $0.subitems })
}

func depthFirstFlattened<Item>(items: [Item], itemChildren: (Item) -> [Item], filter: (Item) -> Bool = { _ in true }) -> [Item] {
    var outFlatStore: Array< Item > = []
    
    var stack: Array< Item > = items.reversed().filter(filter)
    while let current = stack.last {
        stack.removeLast()
        
        outFlatStore.append(current)
        stack.append(contentsOf: itemChildren(current).reversed().filter(filter))
    }
    return outFlatStore
}

public func debugDescriptionTopLevel<Item: Hashable & CustomDebugStringConvertible>(_ flattened: [TreeItem<Item>]) -> String {
    return flattened.map(debugDescriptionTopLevel).joined(separator: "\n")
}
public func debugDescriptionAllLevels<Item: Hashable & CustomDebugStringConvertible>(_ heads: [TreeItem<Item>]) -> String {
    return heads.map(debugDescriptionAllLevels).joined(separator: "\n")
}
public func debugDescriptionExpandedLevels<Item: Hashable & CustomDebugStringConvertible>(_ heads: [TreeItem<Item>]) -> String {
    return heads.map(debugDescriptionExpandedLevels).joined(separator: "\n")
}

public func debugDescriptionAllLevels<Item: Hashable & CustomDebugStringConvertible>(_ item: TreeItem<Item>) -> String {
    let theFlattened = depthFirstFlattened(items: [item], itemChildren: { $0.subitems })
    return theFlattened.compactMap(debugDescriptionTopLevel).joined(separator: "\n")
}
public func debugDescriptionExpandedLevels<Item: Hashable & CustomDebugStringConvertible>(_ item: TreeItem<Item>) -> String {
    let theFlattened = depthFirstFlattened(items: [item], itemChildren: { $0.isExpanded ? $0.subitems : [] })
    return theFlattened.compactMap(debugDescriptionTopLevel).joined(separator: "\n")
}
public func debugDescriptionTopLevel<Item: Hashable & CustomDebugStringConvertible>(_ item: TreeItem<Item>) -> String {
    let indent = String.init(repeating: " ", count: item.level*2)
    return "\(indent)" + "\(item.value)"
}
