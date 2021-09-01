//
//  FilterableListTreeDataSource.swift
//  SwiftListTreeDataSource
//
//  Created by Dzmitry Antonenka on 18.04.21.
//

import Foundation

open class FilterableListTreeDataSource<ItemIdentifierType>: ListTreeDataSource<ItemIdentifierType> where ItemIdentifierType: Hashable {
    public override init() { super.init() }
    
    /// hierarchical all items that are flattened, used as source for search.
    private(set) var allFlattenedItemStore: [TreeItemType] = []
                    
    /// The applied filter predicate.
    private(set) var filterPredicate: ((ItemIdentifierType) -> Bool)?
    
    /// Serial dispatch queue for async work.
    private var dispatchQueue = DispatchQueue(label: "FilterableListTreeDataSource")
    
    /// Current working dispatch work item.
    private var dispatchWorkItem: DispatchWorkItem?
        
    /// Target items search elements.
    public private(set) var filteredTargetItems: [TreeItemType] = []
    
    /// Target items search path elements.
    public private(set) var targetItemsTraversedParentSet: Set<TreeItemType> = .init()
        
    /// State helper to avoid rebuilding filtering flattedned item store every time.
    private var needRebuildAllFlattenedItemStore: Bool = true
    
    /// Filter data source by `predicate` and keeping parents search path.
    /// - Parameters:
    ///   - predicate: The filter predicate.
    ///   - completion: The completion handler.
    public func filterItemsKeepingParents(by predicate: @escaping (ItemIdentifierType) -> Bool, completion: @escaping (() -> Void)) {
        self.filterPredicate = predicate
        self.dispatchWorkItem?.cancel()
        
        var workItem: DispatchWorkItem?
        workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if workItem?.isCancelled ?? true { workItem = nil; return }

            // collapse all elements
            self.allFlattenedItemStore.forEach { $0.isExpanded = false }
            
            self.filteredTargetItems = self.allFlattenedItemStore.filter { predicate($0.value) }
            self.targetItemsTraversedParentSet = Set( self.filteredTargetItems.flatMap { $0.allParents } )
            
            // expand all traversed parents for the target items
            self.targetItemsTraversedParentSet.forEach { $0.isExpanded = true }
                                    
            DispatchQueue.main.async {
                if workItem?.isCancelled ?? true { workItem = nil; return }

                self.rebuildShownItemsStore()
                workItem = nil
                completion()
            }
        }
        self.dispatchWorkItem = workItem
        self.dispatchQueue.async(execute: workItem!)
    }
    
    /// Resets filtering state and restores full data source view.
    public func resetFiltering(collapsingAll: Bool = true) {
        resetFilteringState()
        reload()
        
        if collapsingAll {
            collapseAll()
        }
    }
    
    public override func reload() {
        if needRebuildAllFlattenedItemStore {
            rebuildAllFlattenedItemStore()
            needRebuildAllFlattenedItemStore = false
        }
        
        super.reload()
    }
    
    override func rebuildShownItemsStore() {
        // Depth first search + filtering. Tries to open expanded nested items matching `isIncludedInExpand` predicate.
        let outFlatStore = depthFirstFlattened(items: self.backingStore, itemChildren: { $0.isExpanded ? $0.subitems : [] }, filter: isIncludedInExpand)
        self.setShownFlatItems(outFlatStore)
    }
    
    public override func append(_ items: [ItemIdentifierType], to parent: ItemIdentifierType? = nil) {
        super.append(items, to: parent)
        needRebuildAllFlattenedItemStore = true
    }
    public override func insert(_ items: [ItemIdentifierType], after item: ItemIdentifierType) {
        super.insert(items, after: item)
        needRebuildAllFlattenedItemStore = true
    }
    public override func insert(_ items: [ItemIdentifierType], before item: ItemIdentifierType) {
        super.insert(items, before: item)
        needRebuildAllFlattenedItemStore = true
    }
    public override func delete(_ items: [ItemIdentifierType]) {
        super.delete(items)
        needRebuildAllFlattenedItemStore = true
    }
    
    private func isIncludedInExpand(_ item: TreeItemType) -> Bool {
        guard let filterPredicate = filterPredicate else { return true } // allow for all elements when no filtering.
        
        //  Root
        //      RootChild_1
        //          ItemMatching[SearchText]
        //          Item2Matching[SearchText]
        //      RootChild_2
        //          ItemMatching4[SearchText]
        //          ItemMatching5[SearchText]
        //              ItemNoMatchingButMightBeSearchTarget1
        //              ItemNoMatchingButMightBeSearchTarget2
        //  Root2

        switch (item.parent, item) {
        // inluded root elements when matches predicate or contained in traversed parent set (e.g. Root, Root2).
        case let (.none, rootItem):
            return filterPredicate(rootItem.value) || self.targetItemsTraversedParentSet.contains(rootItem)

        // inluded all items contained in traversed parent set, to display full path (e.g. RootChild_1, RootChild_2).
        case let (.some(_), item) where targetItemsTraversedParentSet.contains(item):
            return true
            
        case let (.some(parent), item):
            // inluded items with parent from traversed parent set & matching to `filterPredicate`
            // (e.g. item: ItemMatching4[SearchText], parent: RootChild_2).
            if self.targetItemsTraversedParentSet.contains(parent) {
                return filterPredicate(item.value)
            } else {
                // inluded any additional descendant items (e.g. ItemNoMatchingButMightBeSearchTarget1, ItemNoMatchingButMightBeSearchTarget2)
                return true
            }
        }
    }
    
    private func resetFilteringState() {
        filterPredicate = nil
        dispatchWorkItem?.cancel()
        dispatchWorkItem = nil
    }
    
    private func rebuildAllFlattenedItemStore() {
        self.allFlattenedItemStore = depthFirstFlattened(items: self.backingStore, itemChildren: { $0.subitems })
    }
}
