//
//  ListTreeDataSource.swift
//  SwiftListTreeDataSource
//
//  Created by Dzmitry Antonenka on 18.04.21.
//

import Foundation

open class TreeItem<Item: Hashable>: Hashable, Identifiable {
    public let id = UUID()
    public fileprivate(set) var value: Item
    public fileprivate(set) var subitems: [TreeItem]
    public fileprivate(set) weak var parent: TreeItem?
    
    /// Indicates whether or not item expanded. Setting the value won't trigger state update, please see examples of usage
    public var isExpanded: Bool = false
    
    /// Indicates the nest level.
    public fileprivate(set) var level: Int = 0
    
    init(value: Item, parent: TreeItem?, items: [TreeItem] = []) {
        self.value = value
        self.parent = parent
        self.subitems = items
        self.level = level(of: self)
    }
    
    public func level(of item: TreeItem<Item>) -> Int {
        // Traverse up to next parent to find level. root element has `0` level.
        var counter: Int = 0
        var currentItem: TreeItem<Item> = item
        while let parent = currentItem.parent {
            counter += 1
            currentItem = parent
        }
        return counter
    }
    
    public func allParents(of item: TreeItem<Item>) -> [TreeItem<Item>] {
        var parents: [TreeItem<Item>] = []
        var currentItem: TreeItem<Item> = item
        while let parent = currentItem.parent {
            parents.append(parent)
            currentItem = parent
        }
        return parents
    }
    
    public var allParents: [TreeItem<Item>] { allParents(of: self) }
    
    public static func == (lhs: TreeItem<Item>, rhs: TreeItem<Item>) -> Bool {
        return lhs.id == rhs.id && lhs.value == rhs.value
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(value)
    }
}

open class ListTreeDataSource<ItemIdentifierType> where ItemIdentifierType : Hashable {
    public typealias TreeItemType = TreeItem<ItemIdentifierType>
        
    public init() {}
    
    /// The hierarchical backing store. Shouldn't be used directly, unless for advanced scenarios or for debugging purposes.
    private(set) var backingStore: [TreeItemType] = []
    
    /// The set of all tree items in data source.
    public var allItemSet: Set<TreeItemType> { Set(self.lookupTable.map(\.value)) }
    
    /// The display items, should be used by consumer UI framework.
    /// Discussion: Basically this is one-level perspective on hierarchical structure.
    public var items: [TreeItemType] { shownFlatItems }
    
    /// The map to quickly find needed tree item.
    private var lookupTable: [ItemIdentifierType: TreeItemType] = [:]
    
    /// The hierarchical items that are flattened. Note: not expanded items not included.
    private(set) var shownFlatItems: [TreeItemType] = []
    
    /// Sets shown flat items. Shoudn't be used diretly unless special filter logic involved.
    func setShownFlatItems(_ items: [TreeItemType]) {
        self.shownFlatItems = items
    }
        
    /// Adds the array of `items` to specified `parent`.
    /// - Parameters:
    ///   - items: The array of items to add.
    ///   - parent: The optional parent.
    public func append(_ items: [ItemIdentifierType], to parent: ItemIdentifierType? = nil) {
        func append(items: [ItemIdentifierType], into insertionArray: inout [TreeItemType], parentBackingItem: TreeItemType?) {
            let treeItems = items.map { item in TreeItem(value: item, parent: parentBackingItem) }
            cacheTreeItems(treeItems)
            insertionArray.append(contentsOf: treeItems)
        }

        if let parent = parent, let parentBackingItem = self.lookupTable[parent] {
            append(items: items, into: &parentBackingItem.subitems, parentBackingItem: parentBackingItem)
        } else {
            append(items: items, into: &backingStore, parentBackingItem: nil)
        }
    }
    
    /// Inserts the array of`items` after specified `item`.
    /// - Parameters:
    ///   - items: The array of items to insert.
    ///   - item: The item `after` insertion items should appear.
    public func insert(_ items: [ItemIdentifierType], after item: ItemIdentifierType) {
        insert(items, item: item, after: true)
    }
    
    /// Inserts the array of`items` before specified `item`.
    /// - Parameters:
    ///   - items: The array of items to insert.
    ///   - item: The item `before` insertion items should appear.
    public func insert(_ items: [ItemIdentifierType], before item: ItemIdentifierType) {
        insert(items, item: item, after: false)
    }
    
    /// Deletes the array of`items`.
    /// - Parameter items: The array of items to delete.
    public func delete(_ items: [ItemIdentifierType]) {
        let deleteItemSet = Set(items)
        let filterPredicate: (TreeItem<ItemIdentifierType>) -> Bool = { !deleteItemSet.contains($0.value) }

        // filter backing store and all subitems
        backingStore = backingStore.filter(filterPredicate)
        let theDepthFirstFlattened = depthFirstFlattened(items: backingStore)
        for item in theDepthFirstFlattened {
            item.subitems = item.subitems.filter(filterPredicate)
        }
        
        // delete from lookupTable
        deleteItemSet.forEach { lookupTable[$0] = nil }
    }
    
    /// Reloads data source with current state.
    /// Note: should be used after state modification to take effect. E.g. add/delete/insert, item.isExpanded = `newValue` etc.
    public func reload() {
        rebuildShownItemsStore()
    }
    
    /// Depth first search. Tries to open all expanded nested items for the first item before proceed to others.
    func rebuildShownItemsStore() {
        self.shownFlatItems = depthFirstFlattened(items: self.backingStore, itemChildren: { $0.isExpanded ? $0.subitems : [] })
    }

    /// Lookup for `item` tree node.
    func lookup(_ item: ItemIdentifierType) -> TreeItemType? {
        return self.lookupTable[item]
    }
    
    // MARK: - Helpers
    
    private func cacheTreeItems(_ treeItems: [TreeItemType]) {
        treeItems.forEach { lookupTable[$0.value] = $0 }
    }
    
    private func insert(_ items: [ItemIdentifierType], item: ItemIdentifierType, after: Bool) {
        func insert(items: [ItemIdentifierType], into insertionArray: inout [TreeItemType],
                    existingItem: TreeItemType, after: Bool, existingItemParent: TreeItemType?) {
            let treeItems = items.map { item in TreeItem(value: item, parent: existingItemParent) }
            cacheTreeItems(treeItems)
            
            guard let existingItemIdx = insertionArray.firstIndex(of: existingItem) else { return; }
            let insertionIdx = after ? insertionArray.index(after: existingItemIdx)
                                     : existingItemIdx
            insertionArray.insert(contentsOf: treeItems, at: insertionIdx)
        }

        guard let existingItem = self.lookupTable[item] else { return; }
        if let existingItemParent = existingItem.parent {
            insert(items: items, into: &existingItemParent.subitems,
                   existingItem: existingItem, after: after, existingItemParent: existingItemParent)
        } else {
            insert(items: items, into: &backingStore,
                   existingItem: existingItem, after: after, existingItemParent: nil)
        }
    }
}

// MARK: - Utils
extension ListTreeDataSource {
    public func toggleExpand(item: TreeItemType) {
        item.isExpanded = !item.isExpanded
        reload()
    }
    
    public func updateAllLevels(of item: TreeItemType, isExpanded: Bool) {
        let theDepthFirstFlattened = depthFirstFlattened(items: [item], itemChildren: { $0.subitems })
        theDepthFirstFlattened.forEach { $0.isExpanded = isExpanded }
        reload()
    }
    
    public func expandAll() {
        lookupTable.values.forEach { $0.isExpanded = true }
        reload()
    }
    
    public func collapseAll() {
        lookupTable.values.forEach { $0.isExpanded = false }
        reload()
    }
}
