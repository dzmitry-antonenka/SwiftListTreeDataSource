import XCTest
import TestsShared
@testable import SwiftListTreeDataSource

class ListTreeDataSourceTests: XCTestCase {
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

    func test_foldRecreate_withTinyDataSet_shouldMatchIdentity() {
        let sut = ListTreeDataSource<NodeTestItem>()

        let dataSet = DataManager.shared.mockDataTiny.items.map(NodeTestItem.init(outline:))
        addItems(dataSet, to: sut)
        sut.reload()

        let folded = sut.fold(NodeTestItem.init(leaf:)) { item, subitems in
            NodeTestItem(identifier: item.identifier, title: item.title, subitems: subitems)
        }
        XCTAssertEqual(dataSet, folded)
    }

    func test_foldId_withTinyDataSet_shouldMatchIdentity() {
        let sut = ListTreeDataSource<NodeTestItem>()

        let dataSet = DataManager.shared.mockDataTiny.items.map(NodeTestItem.init(outline:))
        addItems(dataSet, to: sut)
        sut.reload()

        let folded = sut.fold(id(_:)) { root, _ in root }
        XCTAssertEqual(dataSet, folded)
    }

    // MARK: - Append/Insert/Delete/Move tests
    
    func test_append_withOneElementToNilParent_shouldAppendAsHead() throws {
        sut = ListTreeDataSource<OutlineItem>() // start from clean state

        let root = OutlineItem(title: "Root")
        sut.append([root], to: nil)
        sut.reload()
        
        XCTAssertEqual((try XCTUnwrap(sut.backingStore.first)).value, root)
    }

    func test_append_withTwoElementsToNilParent_shouldAppendAsHeads() throws {
        sut = ListTreeDataSource<OutlineItem>() // start from clean state

        let root = OutlineItem(title: "Root")
        let root2 = OutlineItem(title: "Root")
        sut.append([root, root2], to: nil)
        sut.reload()

        XCTAssertEqual(sut.backingStore.map(\.value), [root, root2])
    }

    func test_move_withOneElementToNilParent_Identity() throws {
        sut = ListTreeDataSource<OutlineItem>() // start from clean state

        let root = OutlineItem(title: "Root")
        sut.append([root], to: nil)
        sut.move(root, toIndex: 0, inParent: nil)
        sut.reload()

        XCTAssertEqual(sut.backingStore.map(\.parent), [nil])
        XCTAssertEqual(sut.backingStore.map(\.value), [root])
        XCTAssertEqual(sut.backingStore.map(\.level), [0])
    }

    func test_move_withTwoElementsToNilParent_shouldSecondBecomeFirst() throws {
        let sut = ListTreeDataSource<NodeTestItem>() // start from clean state

        let dummyId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let dataSet: [NodeTestItem] = [
            OutlineItem(identifier: dummyId, title: "Root"),
            OutlineItem(identifier: dummyId, title: "Root2")
        ].map(NodeTestItem.init)

        let root = dataSet[0]; let root2 = dataSet[1]

        addItems(dataSet, to: sut)
        sut.reload()

        sut.move(root2, toIndex: 0, inParent: nil)

        XCTAssertEqual(sut.backingStore.map(\.parent), [nil, nil])
        XCTAssertEqual(sut.backingStore.map(\.value), [root2, root])
        XCTAssertEqual(sut.backingStore.map(\.level), [0, 0])

        // Verify folded result
        let folded = sut.fold(NodeTestItem.init(leaf:), cons: NodeTestItem.init)
        XCTAssertEqual(
            folded, [
                NodeTestItem(identifier: dummyId, title: "Root2"),
                NodeTestItem(identifier: dummyId, title: "Root")
            ]
        )
    }

    func test_move_withTwoElementsToNilParent_shouldSecondBecomeChildOfFirst() throws {
        let sut = ListTreeDataSource<NodeTestItem>() // start from clean state

        let dummyId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let dataSet: [NodeTestItem] = [
            OutlineItem(identifier: dummyId, title: "Root"),
            OutlineItem(identifier: dummyId, title: "Root2")
        ].map(NodeTestItem.init)

        let root = dataSet[0]; let root2 = dataSet[1]

        addItems(dataSet, to: sut)
        sut.reload()

        sut.move(root2, toIndex: 0, inParent: root)

        XCTAssertEqual(sut.backingStore.map(\.parent), [nil])
        XCTAssertEqual(sut.backingStore.map(\.value), [root])
        XCTAssertEqual(sut.backingStore.map(\.level), [0])

        XCTAssertEqual(sut.backingStore.count, 1)
        let head = try (XCTUnwrap(sut.backingStore.first))
        XCTAssertEqual(head.subitems.map(\.parent), [head])
        XCTAssertEqual(head.subitems.map(\.value), [root2])
        XCTAssertEqual(head.subitems.map(\.level), [1])

        // Verify folded result
        let folded = sut.fold(NodeTestItem.init(leaf:), cons: NodeTestItem.init)
        XCTAssertEqual(
            folded, [
                NodeTestItem(identifier: dummyId, title: "Root", subitems: [
                    NodeTestItem(identifier: dummyId, title: "Root2")
                ])
            ]
        )
    }

    func test_move_withOneElementToParent_shouldChildBecomeSecondRoot() throws {
        let sut = ListTreeDataSource<NodeTestItem>() // start from clean state
        let dummyId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let dataSet: [NodeTestItem] = [
            OutlineItem(identifier: dummyId, title: "Root", subitems: [
                OutlineItem(identifier: dummyId, title: "Child")
            ])
        ].map(NodeTestItem.init)

        let root = dataSet[0]; let child = root.subitems[0]

        addItems(dataSet, to: sut)
        sut.reload()

        XCTAssertEqual(try XCTUnwrap(sut.lookup(root)?.level), 0)
        XCTAssertEqual(try XCTUnwrap(sut.lookup(child)?.level), 1)

        sut.move(child, toIndex: 1, inParent: nil)

        XCTAssertEqual(sut.backingStore.map(\.parent), [nil, nil])
        XCTAssertEqual(sut.backingStore.map(\.value), [root, child])
        XCTAssertEqual(sut.backingStore.map(\.level), [0, 0])
        XCTAssertEqual(sut.backingStore.flatMap(\.subitems), [])

        // Verify folded result
        let folded = sut.fold(NodeTestItem.init(leaf:), cons: NodeTestItem.init)
        XCTAssertEqual(
            folded, [
                NodeTestItem(identifier: dummyId, title: "Root"),
                NodeTestItem(identifier: dummyId, title: "Child")
            ]
        )
    }

    func test_move_withRootElementAndChildren_shouldRoot2Child2MoveToRoot1Child1() throws {
        let sut = ListTreeDataSource<NodeTestItem>() // start from clean state
        let dummyId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let dataSet: [NodeTestItem] = [
            OutlineItem(identifier: dummyId, title: "Root1", subitems: [
                OutlineItem(identifier: dummyId, title: "Root1.Child1")
            ]),
            OutlineItem(identifier: dummyId, title: "Root2", subitems: [
                OutlineItem(identifier: dummyId, title: "Root2.Child1"),
                OutlineItem(identifier: dummyId, title: "Root2.Child2", subitems: [
                    OutlineItem(identifier: dummyId, title: "Root2.Child2.Child1")
                ])
            ])
        ].map(NodeTestItem.init(outline:))

        let root1 = dataSet[0]; let root1Child1 = root1.subitems[0]
        let root2 = dataSet[1]; let root2Child2 = root2.subitems[1]

        addItems(dataSet, to: sut)
        sut.reload()

        let root2Node = try XCTUnwrap(sut.lookup(root2))
        let root1Child1Node = try XCTUnwrap(sut.lookup(root1Child1))
        let root2Child2Node = try XCTUnwrap(sut.lookup(root2Child2))
        let root2Child2NodeChildren_BeforeMove = root2Child2Node.subitems
        let root2Child2NodeChildren_BeforeMoveFlattened = depthFirstFlattened(items: root2Child2NodeChildren_BeforeMove)
            .map { (parent: $0.parent?.value, level: $0.level, value: $0.value) }
        let root2Child2NodeOldParent = try XCTUnwrap(root2Child2Node.parent)
        let root2Child2NodeOldParentParent = try XCTUnwrap(root2Child2Node.parent).parent
        sut.move(root2Child2, toIndex: 0, inParent: root1Child1)

        XCTAssertEqual(sut.backingStore.map(\.parent), [nil, nil])
        XCTAssertEqual(sut.backingStore.map(\.value), [root1, root2])
        XCTAssertEqual(sut.backingStore.map(\.level), [0, 0])

        let root1Node = try XCTUnwrap(sut.lookup(root1))
        XCTAssertEqual(root1Node.level, 0)

        // Verify `root2Child2Node` moved to `root1Child1Node`
        // root1Node
        //      | root1Child1Node
        //            | <- root2Child2Node.parent
        XCTAssertEqual(root2Child2Node.parent, root1Child1Node)
        XCTAssertEqual(root2Child2Node.level, 2)

        // Verify `root1Child1Node` has inserted `root2Child2Node`
        // root1Node
        //      | root1Child1Node
        //            | [root2Child2Node]
        XCTAssertEqual(root1Child1Node.subitems, [root2Child2Node])

        // Verify old parent of `root2Child2Node` doesn't reference `root2Child2`
        // root2Node
        //       ..
        //     | root2Child2NodeOldParent
        //              |-- ..... children not include `root2Child2`
        XCTAssertFalse(root2Child2NodeOldParent.subitems.map(\.value).contains(root2Child2))
        XCTAssertEqual(root2Child2NodeOldParent.level, 0)
        XCTAssertEqual(root2Child2NodeOldParent, root2Node)
        XCTAssertNil(root2Child2NodeOldParentParent)

        // Verify `root2Child2Node` children keeped
        let root2Child2NodeChildren_AfterMove = root2Child2Node.subitems
        let root2Child2NodeChildren_AfterMoveFlattened = depthFirstFlattened(items: root2Child2NodeChildren_AfterMove)
            .map { (parent: $0.parent?.value, level: $0.level, value: $0.value) }

        XCTAssertEqual(root2Child2NodeChildren_AfterMoveFlattened.count, root2Child2NodeChildren_BeforeMoveFlattened.count)
        for (subchildBefore, subchildAfter) in zip(root2Child2NodeChildren_BeforeMoveFlattened, root2Child2NodeChildren_AfterMoveFlattened) {
            XCTAssertEqual(subchildAfter.parent, subchildBefore.parent)
            XCTAssertEqual(subchildAfter.level, subchildBefore.level + 1) // moved +1 level deeper
            XCTAssertEqual(subchildAfter.value, subchildBefore.value)
        }

        // Verify folded result
        let folded = sut.fold(NodeTestItem.init(leaf:), cons: NodeTestItem.init)
        XCTAssertEqual(
            folded, [
                NodeTestItem(identifier: dummyId, title: "Root1", subitems: [
                    NodeTestItem(identifier: dummyId, title: "Root1.Child1", subitems: [
                        NodeTestItem(identifier: dummyId, title: "Root2.Child2", subitems: [
                            NodeTestItem(identifier: dummyId, title: "Root2.Child2.Child1")
                        ])
                    ])
                ]),
                NodeTestItem(identifier: dummyId, title: "Root2", subitems: [
                    NodeTestItem(identifier: dummyId, title: "Root2.Child1")
                ])
            ]
        )
    }

    func test_append_withOneElementToParent_shouldAppendElementToParent() throws {
        let root = OutlineItem(title: "Root")
        let child = OutlineItem(title: "Child")
        sut.append([root], to: nil)
        sut.append([child], to: root)
        sut.reload()
                
        let rootItem = try XCTUnwrap(sut.backingStore.last)
        XCTAssertEqual(rootItem.value, root)
        XCTAssertEqual( try XCTUnwrap(rootItem.subitems.last).value , child)
    }
    
    func test_append_withRootElementAndChildren_shouldAppendElementsToParents() throws {
        let root1 = OutlineItem(title: "Root1")
        let root1Child1 = OutlineItem(title: "Root1.Child1")
        sut.append([root1], to: nil)
        sut.append([root1Child1], to: root1)

        let root2 = OutlineItem(title: "Root2")
        let root2Child1 = OutlineItem(title: "Root2.Child1")
        let root2Child2 = OutlineItem(title: "Root2.Child2")
        sut.append([root2], to: nil)
        sut.append([root2Child1, root2Child2], to: root2)
        
        sut.reload()
                
        let rootItem1 = try XCTUnwrap(sut.backingStore[safe: sut.backingStore.endIndex-2])
        XCTAssertEqual(rootItem1.value, root1)
        XCTAssertEqual( try XCTUnwrap(rootItem1.subitems.last).value , root1Child1)
        
        let rootItem2 = try XCTUnwrap(sut.backingStore.last)
        XCTAssertEqual(rootItem2.value, root2)
        XCTAssertEqual( try XCTUnwrap(rootItem2.subitems).map(\.value) , [root2Child1, root2Child2])
    }
    
    func test_insertAfterAndBefore_withUITableViewEditingItem_shouldInsertAtCorrectPosition() throws {
        try verifyInsertionAfterAndBeforeItem(title: "UITableView: Editing")
    }
    
    func test_insertAfterAndBefore_withEditingV1Item_shouldInsertAtCorrectPosition() throws {
        try verifyInsertionAfterAndBeforeItem(title: "Editing v1")
    }

    func test_insertAfterAndBefore_withCompositionalItem_shouldInsertAtCorrectPosition() throws {
        try verifyInsertionAfterAndBeforeItem(title: "Compositional")
    }
    
    func test_insertAfterAndBefore_withEditingv2xItem_shouldInsertAtCorrectPosition() throws {
        try verifyInsertionAfterAndBeforeItem(title: "Editing v2.x")
    }

    func test_delete_withFirstItem_shouldRemoveFirstItemAndAllChildren() throws {
        let firstItem = try XCTUnwrap( data.first )
        verifyDeleteItemAndAllChildren(firstItem)
    }
    
    func test_delete_withLastItem_shouldRemoveFirstItemAndAllChildren() throws {
        let firstItem = try XCTUnwrap( data.last )
        verifyDeleteItemAndAllChildren(firstItem)
    }
    
    func test_delete_withLastItemFirstImmediateChild_shouldRemoveLastItemFirstImmediateChildAndAllChildren() throws {
        let firstItem = try XCTUnwrap( data.last?.subitems.first )
        verifyDeleteItemAndAllChildren(firstItem)
    }
    
    func test_delete_withFirstItemFirstImmediateChild_shouldRemoveFirstItemFirstImmediateChildAndAllChildren() throws {
        let firstItem = try XCTUnwrap( data.first?.subitems.first )
        verifyDeleteItemAndAllChildren(firstItem)
    }
    
    // MARK: - Expand/Collapse tests
    
    func test_expandAll_shouldIncludeAllItems() {
        sut.expandAll()
        
        let flattenedDataSet = depthFirstFlattened(items: dataset)
        let shownItemValues = sut.items.map(\.value)
        XCTAssertEqual(flattenedDataSet, shownItemValues)
    }
    
    func test_collapseAll_withAllExpanded_shouldIncludeOnlyRoots() {
        sut.expandAll()
        sut.reload()

        sut.collapseAll()
        
        let datasetRoots = dataset
        let shownItemValues = sut.items.map(\.value)
        XCTAssertEqual(datasetRoots, shownItemValues)
    }
    
    func test_toggleExpandFirstItem_withAllCollapsed_shouldExpandFirstItemChildren() throws {
        sut.collapseAll()
        
        let firstItem = try XCTUnwrap(sut.items.first)
        sut.toggleExpand(item: firstItem)
        
        let shownItemValues = Set( sut.items.map(\.value) )
        for item in firstItem.subitems {
            XCTAssertTrue( shownItemValues.contains(where: { $0 == item.value }) )
        }
    }
    
    func test_expandAllLevelsOfFirstItem_withAllCollapsed_shouldExpandFirstItemAllChildren() throws {
        sut.collapseAll()
     
        let firstItem = try XCTUnwrap(sut.items.first)
        sut.updateAllLevels(of: firstItem, isExpanded: true)
        
        let firstItemWithAllChildren = depthFirstFlattened(items: [firstItem])
        let shownItemValues = Set( sut.items.map(\.value) )
        for item in firstItemWithAllChildren {
            XCTAssertTrue( shownItemValues.contains(where: { $0 == item.value }) )
        }
    }
    
    func test_collapseAllLevelsOfFirstItem_withAllExpanded_shouldCollapseFirstItemAllChildren() throws {
        sut.expandAll()
     
        let firstItem = try XCTUnwrap(sut.items.first)
        sut.updateAllLevels(of: firstItem, isExpanded: false)
        
        let firstItemAllChildren = depthFirstFlattened(items: [firstItem]).dropFirst()
        let shownItemValues = Set( sut.items.map(\.value) )
        for item in firstItemAllChildren {
            XCTAssertFalse( shownItemValues.contains(where: { $0 == item.value }) )
        }
    }
    
    func test_toggleExpandFirstItem_withAllExpanded_shouldCollapseFirstItemChildren() throws {
        sut.expandAll()
        
        let firstItem = try XCTUnwrap(sut.items.first)
        sut.toggleExpand(item: firstItem)
        
        let shownItemValues = Set( sut.items.map(\.value) )
        for item in firstItem.subitems {
            XCTAssertFalse( shownItemValues.contains(where: { $0 == item.value }) )
        }
    }
    
    func test_expandFirstItem_shouldInsertItemsAfterFirst() throws {
        sut.items.first?.isExpanded = true
        sut.reload()
        
        let shownItemValues = sut.items.map(\.value)
        var expectedData = Array(dataset[...])
        expectedData.insert(contentsOf: try XCTUnwrap(expectedData.first?.subitems), at: 1)
        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    func test_expandLastItem_shouldInsertItemsAfterLast() throws {
        sut.items.last?.isExpanded = true
        sut.reload()
        
        let shownItemValues = sut.items.map(\.value)
        var expectedData = Array(dataset[...])
        expectedData.append(contentsOf: try XCTUnwrap(expectedData.last?.subitems))
        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    func test_expandFirstItemAndItsFirstImmediateChild_shouldInsertItemsAfterFirstAndItsFirstImmediateChild() throws {
        sut.items.first?.isExpanded = true
        sut.items.first?.subitems.first?.isExpanded = true
        sut.reload()
        
        let shownItemValues = sut.items.map(\.value)
        var expectedData = Array(dataset[...])
        expectedData.insert(contentsOf: try XCTUnwrap(expectedData.first?.subitems), at: 1)
        expectedData.insert(contentsOf: try XCTUnwrap(expectedData.first?.subitems.first?.subitems), at: 2)
        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    func test_expandFirstAndItsSecondImmediateChild_shouldInsertItemsAfterFirstAndItsSecondImmediateChild() throws {
        sut.items.first?.isExpanded = true
        sut.items.first?.subitems[safe: 1]?.isExpanded = true
        sut.reload()
        
        let shownItemValues = sut.items.map(\.value)
        var expectedData = Array(dataset[...])
        expectedData.insert(contentsOf: try XCTUnwrap(expectedData.first?.subitems), at: 1)
        expectedData.insert(contentsOf: try XCTUnwrap(expectedData.first?.subitems[safe: 1]?.subitems), at: 3)
        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    func test_expandFirstItemAllLevels_shouldInsertFirstItemAllChildrenAfterFirst() throws {
        let firstItemFlattened = depthFirstFlattened(items: [try XCTUnwrap(sut.items.first)])
        firstItemFlattened.forEach { $0.isExpanded = true }
        sut.reload()

        let shownItemValues = sut.items.map(\.value)
        
        let firstItemAllChildren = depthFirstFlattened(items: [try XCTUnwrap(dataset.first)]).dropFirst()
        var expectedData = Array(dataset[...])
        expectedData.insert(contentsOf: firstItemAllChildren, at: 1)
        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    func test_expandFirstAndSecondItemsAllLevels_shouldInsertAllChildrenForFirstAndForSecondRespectively() throws {
        let firstTreeItemWithAllChildren = depthFirstFlattened(items: [try XCTUnwrap(sut.items.first)])
        firstTreeItemWithAllChildren.forEach { $0.isExpanded = true }
        let secondTreeItemWithAllChidrenFlattened = depthFirstFlattened(items: [try XCTUnwrap(sut.items[safe: 1])])
        secondTreeItemWithAllChidrenFlattened.forEach { $0.isExpanded = true }
        sut.reload()

        let shownItemValues = sut.items.map(\.value)
        var expectedData = Array(dataset[...])
        
        let firstOutlineItem = dataset.first
        let secondOutlineItem = try XCTUnwrap(dataset[safe: 1])
        
        let theFirstOutlineItemAllChildren = depthFirstFlattened(items: [try XCTUnwrap(firstOutlineItem)]).dropFirst()
        expectedData.insert(contentsOf: theFirstOutlineItemAllChildren, at: 1)
        
        let secondOutlineItemIdx = try XCTUnwrap(expectedData.firstIndex(of: secondOutlineItem))
        let theSecondOutlineItemAllChildren = depthFirstFlattened(items: [secondOutlineItem]).dropFirst()
        expectedData.insert(contentsOf: theSecondOutlineItemAllChildren, at: expectedData.index(after: secondOutlineItemIdx))

        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    // MARK: - Level (Depth) tests
    
    func test_level_withAllExpanded_shouldMatchToCreatedDepthTable() {
        let theDepthLookupTable = depthLookupTable(dataset, itemChildren: { $0.subitems })

        sut.expandAll()
        
        for treeItem in sut.items {
            XCTAssertEqual(treeItem.level, theDepthLookupTable[treeItem.value])
        }
    }
    
    // MARK: - Helpers
    
    func verifyDeleteItemAndAllChildren(_ item: OutlineItem) {
        let firstItemWithAllChildren = depthFirstFlattened(items: [item])
        
        sut.delete([item])
        sut.reload()
        
        let allItemsFlattened = depthFirstFlattened(items: sut.backingStore)
        let allItemSet = Set( allItemsFlattened.map(\.value) )
        for deletedItem in firstItemWithAllChildren {
            XCTAssertFalse( allItemSet.contains(deletedItem) )
        }
    }
    
    func verifyInsertionAfterAndBeforeItem(title: String) throws {
        let existingItem = try XCTUnwrap( depthFirstFlattened(items: self.dataset).first(where: { $0.title.contains(title) }) )
        let existingTreeItem = try XCTUnwrap( sut.lookup(existingItem) )
        
        let insertionAfterItemTitle = "Inserted after \(title)"
        let insertionAfterItem = OutlineItem(title: insertionAfterItemTitle)
        sut.insert([insertionAfterItem], after: existingItem)
        
        let insertionBeforeItemTitle = "Inserted before \(title)"
        let insertionBeforeItem = OutlineItem(title: insertionBeforeItemTitle)
        sut.insert([insertionBeforeItem], before: existingItem)
        sut.reload()
        
        let targerArrayForInsertion = existingTreeItem.parent?.subitems ?? sut.backingStore
        
        let existingItemIdx = try XCTUnwrap(targerArrayForInsertion.firstIndex(where: { $0.value == existingItem }))
        let insertionAfterItemIdx = try XCTUnwrap(targerArrayForInsertion.firstIndex(where: { $0.value == insertionAfterItem }))
        let insertionBeforeItemIdx = try XCTUnwrap(targerArrayForInsertion.firstIndex(where: { $0.value == insertionBeforeItem }))
        
        XCTAssertEqual(insertionAfterItemIdx, targerArrayForInsertion.index(after: existingItemIdx))
        XCTAssertEqual(insertionBeforeItemIdx, targerArrayForInsertion.index(before: existingItemIdx))
    }
}

func id<A>(_ a: A) -> A { a }
