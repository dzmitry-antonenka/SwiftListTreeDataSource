import XCTest
import TestsShared
@testable import SwiftListTreeDataSource

class FilterableListTreeDataSourceFilterTests: XCTestCase {
    var expectationTimeout: TimeInterval { 1.0 }
    var data: [OutlineItem] { testDataSet() }

    var dataset: [OutlineItem]!
    var sut: FilterableListTreeDataSource<OutlineItem>!
    
    override func setUp() {
        super.setUp()
        dataset = self.data
        sut = FilterableListTreeDataSource<OutlineItem>()
        addItems(dataset, to: sut)
    }
    
    override func tearDown() {
        dataset = nil
        sut = nil
        super.tearDown()
    }
    
    func test_filter_withCompositionalText_shouldFind1TotalAnd1TargetItems() {
        let searchText = "Compositional"
        executeFilterWithExpectation(searchText)
        
        XCTAssertEqual(self.sut.items.count, 1)
        XCTAssertEqual(self.sut.filteredTargetItems.count, 1)
        for targetItem in self.sut.filteredTargetItems {
            XCTAssertTrue(matchPredicate(searchText)(targetItem.value), "target element should match filter predicate")
        }
    }
    
    func test_filter_withSuppText_shouldFind3TotalAnd1TargetItems() {
        let searchText = "Supp"
        executeFilterWithExpectation(searchText)
        
        XCTAssertEqual(self.sut.items.count, 3)
        XCTAssertEqual(self.sut.filteredTargetItems.count, 1)
        for targetItem in self.sut.filteredTargetItems {
            XCTAssertTrue(matchPredicate(searchText)(targetItem.value), "target element should match filter predicate")
        }
    }
    
    func test_filter_withGrText_shouldFind8TotalAnd5TargetItems() {
        let searchText = "Gr"
        executeFilterWithExpectation(searchText)
        
        XCTAssertEqual(self.sut.items.count, 8)
        XCTAssertEqual(self.sut.filteredTargetItems.count, 5)
        for targetItem in self.sut.filteredTargetItems {
            XCTAssertTrue(matchPredicate(searchText)(targetItem.value), "target element should match filter predicate")
        }
    }
    
    func test_filter_withGridText_shouldFind5TotalAnd3TargetItems() {
        let searchText = "Grid"
        executeFilterWithExpectation(searchText)
        
        XCTAssertEqual(self.sut.items.count, 5)
        XCTAssertEqual(self.sut.filteredTargetItems.count, 3)
        for targetItem in self.sut.filteredTargetItems {
            XCTAssertTrue(matchPredicate(searchText)(targetItem.value), "target element should match filter predicate")
        }
    }
    
    func test_filter_withLiText_shouldFind9TotalAnd8TargetItems() {
        let searchText = "Li"
        executeFilterWithExpectation(searchText)
        
        XCTAssertEqual(self.sut.items.count, 9)
        XCTAssertEqual(self.sut.filteredTargetItems.count, 8)
        for targetItem in self.sut.filteredTargetItems {
            XCTAssertTrue(matchPredicate(searchText)(targetItem.value), "target element should match filter predicate")
        }
    }
    
    func test_filter_withLText_shouldFind23TotalAnd22TargetItems() {
        let searchText = "L"
        executeFilterWithExpectation(searchText)
        
        XCTAssertEqual(self.sut.items.count, 23)
        XCTAssertEqual(self.sut.filteredTargetItems.count, 22)
        for targetItem in self.sut.filteredTargetItems {
            XCTAssertTrue(matchPredicate(searchText)(targetItem.value), "target element should match filter predicate")
        }
    }
    
    func test_filterAndExpandFourthMatchingItem_withLText_shouldIncludeExpandedTargetItem2TotalChildren() throws {
        let searchText = "L"
        executeFilterWithExpectation(searchText)
        
        let fourthItem = try XCTUnwrap(sut.items[safe: 3])
        let fourthItemChildren = fourthItem.subitems
        fourthItem.isExpanded = true
        sut.reload()
        
        XCTAssertEqual(fourthItemChildren.count, 2)
        for childNonMatchingPredicate in fourthItemChildren {
            XCTAssertTrue(sut.items.contains(childNonMatchingPredicate), "expanded target item children must be included")
        }
    }
    
    func test_filterAndExpandFourthAndSixsMatchingItem_withLText_shouldIncludeExpandedTargetItems5TotalChildren() throws {
        let searchText = "L"
        executeFilterWithExpectation(searchText)
        
        // 4rd item
        let fourthItem = try XCTUnwrap(sut.items[safe: 3])
        let fourthItemChildren = fourthItem.subitems
        fourthItem.isExpanded = true
        // 6th item
        let sixsItem = try XCTUnwrap(sut.items[safe: 5])
        let sixsItemChildren = sixsItem.subitems
        sixsItem.isExpanded = true
        // reload
        sut.reload()
        
        let expandedTargetItemChildren = (fourthItemChildren + sixsItemChildren)
        XCTAssertEqual(expandedTargetItemChildren.count, 5)
        for expandedTargetItemChild in expandedTargetItemChildren {
            XCTAssertTrue(sut.items.contains(expandedTargetItemChild), "expanded target item children must be included")
        }
    }
    
    func test_filterAndExpandFourthAndSixsMatchingItem_withLText_shouldInsertExpandedChildrenAtRespectiveParentsPositions() throws {
        let searchText = "L"
        executeFilterWithExpectation(searchText)
        
        // 4rd item
        let fourthItem = try XCTUnwrap(sut.items[safe: 3])
        let fourthItemChildren = fourthItem.subitems
        fourthItem.isExpanded = true
        // 6th item
        let sixsItem = try XCTUnwrap(sut.items[safe: 5])
        let sixsItemChildren = sixsItem.subitems
        sixsItem.isExpanded = true
        // reload
        sut.reload()
        
        let fourthItemIdx = try XCTUnwrap(sut.items.firstIndex(of: fourthItem))
        let sixsItemIdx = try XCTUnwrap(sut.items.firstIndex(of: sixsItem))
        let fourthItemInsertionSlice = sut.items[fourthItemIdx+1..<sut.items.index(fourthItemIdx+1, offsetBy: fourthItemChildren.count)]
        XCTAssertEqual(Array(fourthItemInsertionSlice), fourthItemChildren)
        let sixsItemInsertionSlice = sut.items[sixsItemIdx+1..<sut.items.index(sixsItemIdx+1, offsetBy: sixsItemChildren.count)]
        XCTAssertEqual(Array(sixsItemInsertionSlice), sixsItemChildren)
    }
    
    func test_filter_withCeText_shouldFind8TotalAnd6TargetItems() {
        let searchText = "Ce"
        executeFilterWithExpectation(searchText)
        
        XCTAssertEqual(self.sut.items.count, 8)
        XCTAssertEqual(self.sut.filteredTargetItems.count, 6)
        for targetItem in self.sut.filteredTargetItems {
            XCTAssertTrue(matchPredicate(searchText)(targetItem.value), "target element should match filter predicate")
        }
    }
    
    func test_filter_withCeText_shouldFind2RootsWithoutChildrenMatchingPredicate() {
        let searchText = "Ce"
        executeFilterWithExpectation(searchText)
        
        let rootsWithoutChildrenMatchingPredicate = self.rootsWithoutChildrenMatchingPredicate(searchText: searchText)
        XCTAssertEqual(rootsWithoutChildrenMatchingPredicate.count, 2)
        for item in rootsWithoutChildrenMatchingPredicate {
            XCTAssertTrue(sut.items.contains(item))
        }
    }
    
    func test_filter_withCoText_shouldFind0RootsWithoutChildrenMatchingPredicate() {
        let searchText = "Co"
        executeFilterWithExpectation(searchText)
        
        let rootsWithoutChildrenMatchingPredicate = self.rootsWithoutChildrenMatchingPredicate(searchText: searchText)
        XCTAssertEqual(rootsWithoutChildrenMatchingPredicate.count, 0)
    }
    
    func test_filterAndResetWithCollapsingAll_shouldIncludeOnlyRoots() {
        let searchText = "DUMMY"
        executeFilterWithExpectation(searchText)
        
        sut.resetFiltering(collapsingAll: true)
        XCTAssertEqual(sut.backingStore, sut.items)
    }
    
    func test_filterAndResetWithNOTCollapsingAll_withCoText_shouldKeepFoundTargetItemsAndParents() {
        let searchText = "Co"
        executeFilterWithExpectation(searchText)
                
        sut.resetFiltering(collapsingAll: false)
        
        let targetItemsWithParentsSet = sut.targetItemsTraversedParentSet.union( sut.filteredTargetItems )
        XCTAssertTrue( Set(sut.items).isSuperset(of: targetItemsWithParentsSet) )
    }
    
    func test_filterAndCancel_withCoText_shouldKeepSameElementsBeforeAndAfterSearch() {
        let searchText = "Co"
        let shownItemsBeforeSearch = self.sut.items
        self.sut.filterItemsKeepingParents(by: matchPredicate(searchText), completion: {})
        self.sut.resetFiltering()
        let shownItemsAfterSearch = self.sut.items
        
        XCTAssertEqual(shownItemsBeforeSearch, shownItemsAfterSearch)
    }
    
    func test_filterAndCollapseFirstTopItem_withCeText_shouldExlcudeCollapsedItemChildren() throws {
        let searchText = "Ce"
        executeFilterWithExpectation(searchText)
        
        let firstItem = try XCTUnwrap(sut.items.first)
        let firstItemChildrenMatchingPredicate = firstItem.subitems.filter { matchPredicate(searchText)($0.value) }
        for firstItemChildMatchingPredicate in firstItemChildrenMatchingPredicate {
            XCTAssertTrue(sut.items.contains(firstItemChildMatchingPredicate), "precondition")
        }
        
        firstItem.isExpanded = false
        sut.reload()
        
        for firstItemChildMatchingPredicate in firstItemChildrenMatchingPredicate {
            XCTAssertFalse(sut.items.contains(firstItemChildMatchingPredicate), "should be collapsed and excluded")
        }
    }
    
    func test_filterAndExpand2RootsWithoutChildrenMatchingPredicate_withCeText_shouldIncludeExpandedTargetItem5TotalChildren() throws {
        let searchText = "Ce"
        executeFilterWithExpectation(searchText)
        
        let rootsWithoutChildrenMatchingPredicate = self.rootsWithoutChildrenMatchingPredicate(searchText: searchText)
        let childrenNonMatchingPredicate = rootsWithoutChildrenMatchingPredicate.flatMap(\.subitems)
        XCTAssertEqual(rootsWithoutChildrenMatchingPredicate.count, 2, "precondition")
        for childNonMatchingPredicate in childrenNonMatchingPredicate {
            XCTAssertFalse(sut.items.contains(childNonMatchingPredicate), "precondition")
        }
        
        rootsWithoutChildrenMatchingPredicate.forEach { $0.isExpanded = true }
        sut.reload()
        
        XCTAssertEqual(childrenNonMatchingPredicate.count, 5)
        for childNonMatchingPredicate in childrenNonMatchingPredicate {
            XCTAssertTrue(sut.items.contains(childNonMatchingPredicate), "expanded target item children must be included")
        }
    }
    
    func test_filterAndExpand2RootsWithoutChildrenMatchingPredicate_withCeText_shouldInsertExpandedChildrenAtRespectiveParentsPositions() throws {
        let searchText = "Ce"
        executeFilterWithExpectation(searchText)
        
        let rootsWithoutChildrenMatchingPredicate = self.rootsWithoutChildrenMatchingPredicate(searchText: searchText)
        XCTAssertEqual(rootsWithoutChildrenMatchingPredicate.count, 2, "precondition")

        rootsWithoutChildrenMatchingPredicate.forEach { $0.isExpanded = true }
        sut.reload()
        
        let firstRootWithoutMatchingChildren = try XCTUnwrap(rootsWithoutChildrenMatchingPredicate.first)
        let firstRootWithoutMatchingChildrenIdx = try XCTUnwrap(sut.items.firstIndex(of: firstRootWithoutMatchingChildren))
        let firstRootWithoutMatchingChildrentInsertionSlice = sut.items[firstRootWithoutMatchingChildrenIdx+1..<sut.items.index(firstRootWithoutMatchingChildrenIdx+1, offsetBy: firstRootWithoutMatchingChildren.subitems.count)]
        XCTAssertEqual(Array(firstRootWithoutMatchingChildrentInsertionSlice), firstRootWithoutMatchingChildren.subitems)

        let secondRootWithoutMatchingChildren = try XCTUnwrap(rootsWithoutChildrenMatchingPredicate[safe: 1])
        let secondRootWithoutMatchingChildrenIdx = try XCTUnwrap(sut.items.firstIndex(of: secondRootWithoutMatchingChildren))
        let secondRootWithoutMatchingChildrentInsertionSlice = sut.items[secondRootWithoutMatchingChildrenIdx+1..<sut.items.index(secondRootWithoutMatchingChildrenIdx+1, offsetBy: secondRootWithoutMatchingChildren.subitems.count)]
        XCTAssertEqual(Array(secondRootWithoutMatchingChildrentInsertionSlice), secondRootWithoutMatchingChildren.subitems)
    }
    
    // MARK: - Helpers
    
    func rootsWithoutChildrenMatchingPredicate(searchText: String) -> [TreeItem<OutlineItem>] {
        return self.sut.filteredTargetItems.filter { targetItem in
            guard !sut.targetItemsTraversedParentSet.contains(targetItem) else { return false }
            return targetItem.parent == nil && !targetItem.subitems.contains(where: { matchPredicate(searchText)($0.value) })
        }
    }
    
    func executeFilterWithExpectation(_ searchText: String) {
        let promise = expectation(description: "filter")
        self.sut.filterItemsKeepingParents(by: matchPredicate(searchText)) { [weak promise] in
            promise?.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func matchPredicate(_ searchText: String) -> (_ OutlineItem: OutlineItem) -> Bool {
        return { $0.title.lowercased().contains(searchText.lowercased()) }
    }
}
