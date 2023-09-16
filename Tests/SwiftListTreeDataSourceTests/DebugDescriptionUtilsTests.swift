import XCTest
import TestsShared
@testable import SwiftListTreeDataSource

class DebugDescriptionUtilsTests: XCTestCase {
    var data: [OutlineItem] { testDataSet() }

    var dataset: [OutlineItem]!
    var sut: ListTreeDataSource<OutlineItem>!
    
    override func setUp() {
        super.setUp()
        dataset = self.data
        setUpSut()
        addItems(dataset, to: sut)
    }
    
    override func tearDown() {
        dataset = nil
        sut = nil
        super.tearDown()
    }

    func setUpSut() {
        sut = ListTreeDataSource<OutlineItem>()
    }
    
    func test_debugDescriptionAllLevels_withBackingStore_shouldMatchDescriptionTopLevelsWithExpandedAllItems() {
        sut.expandAll()
        
        let backingStoreAllLevelsDescription = debugDescriptionAllLevels(sut.backingStore)
        let flattenedItemsTopLevelsDescription = debugDescriptionTopLevel(sut.items)
        XCTAssertEqual(backingStoreAllLevelsDescription, flattenedItemsTopLevelsDescription)
    }
    
    func test_debugDescriptionExpandedLevels_withBackingStoreAndFirstExpanded_shouldMatchDescriptionTopLevelsItems() throws {
        sut.items.first?.isExpanded = true
        sut.reload()
        
        verifyExpandedLevelsDescriptionsMatchesTopLevelForFlattenedItems()
    }
    
    func test_debugDescriptionExpandedLevels_withBackingStoreAndFirstImmediateChildExpanded_shouldMatchDescriptionTopLevelsItems() throws {
        sut.items.first?.subitems.first?.isExpanded = true
        sut.reload()
        
        verifyExpandedLevelsDescriptionsMatchesTopLevelForFlattenedItems()
    }
    
    func test_debugDescriptionExpandedLevels_withBackingStoreAndLastExpanded_shouldMatchDescriptionTopLevelsItems() throws {
        sut.items.last?.isExpanded = true
        sut.reload()
        
        verifyExpandedLevelsDescriptionsMatchesTopLevelForFlattenedItems()
    }
    
    func test_debugDescriptionAllLevels_shouldMatchSpecifiedOutput() {
        sut = ListTreeDataSource<OutlineItem>()
        
        let items = tinyHardcodedDataset()
        addItems(items, to: sut)
        sut.reload()
        
        let output = debugDescriptionAllLevels(sut.backingStore)
        let expected = "Level 0, item1\n  Level 1, item1\n  Level 1, item2\n    Level 2, item1\n    Level 2, item2\nLevel 0, item2"
        
        XCTAssertEqual(output, expected)
    }
    
    func test_debugDescriptionAllLevelsOfFirstItem_shouldMatchSpecifiedOutput() throws {
        sut = ListTreeDataSource<OutlineItem>()
        
        let items = tinyHardcodedDataset()
        addItems(items, to: sut)
        sut.reload()
        
        let output = debugDescriptionAllLevels( try XCTUnwrap(sut.items.first) )
        let expected = "Level 0, item1\n  Level 1, item1\n  Level 1, item2\n    Level 2, item1\n    Level 2, item2"
        
        XCTAssertEqual(output, expected)
    }
    
    func test_debugDescriptionExpandedLevels_shouldMatchSpecifiedOutput() throws {
        sut = ListTreeDataSource<OutlineItem>()
        
        let items = tinyHardcodedDataset()
        addItems(items, to: sut)
        sut.reload()
        
        let output = debugDescriptionExpandedLevels( sut.backingStore )
        let expected = "Level 0, item1\nLevel 0, item2"
        
        XCTAssertEqual(output, expected)
    }
    
    func test_debugDescriptionTopLevels_withBackingStoreAllExpanded_shouldMatchSpecifiedOutput() throws {
        sut = ListTreeDataSource<OutlineItem>()
        
        let items = tinyHardcodedDataset()
        addItems(items, to: sut)
        sut.reload()
        sut.expandAll()
        
        let output = debugDescriptionTopLevel( sut.items )
        let expected = "Level 0, item1\n  Level 1, item1\n  Level 1, item2\n    Level 2, item1\n    Level 2, item2\nLevel 0, item2"
        
        XCTAssertEqual(output, expected)
    }
    
    // MARK: - Helpers
    
    func tinyHardcodedDataset() -> [OutlineItem] {
        DataManager.shared.mockDataTiny.items
    }

    func verifyExpandedLevelsDescriptionsMatchesTopLevelForFlattenedItems() {
        let backingStoreExpandedLevelsDescription = debugDescriptionExpandedLevels(sut.backingStore)
        let flattenedItemsTopLevelsDescription = debugDescriptionTopLevel(sut.items)
        XCTAssertEqual(backingStoreExpandedLevelsDescription, flattenedItemsTopLevelsDescription)
    }
}
