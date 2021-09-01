//
//  AppleTreeDataSourcePerformanceTests.swift
//  
//
//  Created by Dzmitry Antonenka on 22.04.21.
//

#if canImport(UIKit)

import XCTest
import TestsShared
import UIKit
@testable import SwiftListTreeDataSource

@available(iOS 14.0, *)
class AppleTreeDataSourcePerformanceTests: XCTestCase {
    var dataset: [OutlineItem]!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        dataset = nil
        super.tearDown()
    }
    
    // MARK: - Measure add items
    
    func test_addItemsPerformance_withSmallData() throws {
        dataset = DataManager.shared.mockDataSmall.items
        
        self.measure {
            let _ = initialSnapshot()
        }
    }
    
    func test_addItemsPerformance_withLarge88KData() throws {
        dataset = DataManager.shared.mockDataLarge88K.items
        
        self.measure {
            let _ = initialSnapshot()
        }
    }
    
    func test_expandAllPerformance_withSmallData() throws {
        dataset = DataManager.shared.mockDataSmall.items
        

        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureExpandAllFromCollapsedState()
        }
    }

    func test_expandAllPerformance_withLarge88KData() throws {
        dataset = DataManager.shared.mockDataLarge88K.items

        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureExpandAllFromCollapsedState()
        }
    }

    // MARK: - Helpers
    
    private func measureExpandAllFromCollapsedState() {
        var sut = initialSnapshot()
        let flattened = depthFirstFlattened(items: dataset)
        sut.collapse(flattened)

        startMeasuring()
        sut.expand(flattened)
        stopMeasuring()
    }

    private func measureCollapseAllFromExpandedState() {
        var sut = initialSnapshot()
        let flattened = depthFirstFlattened(items: dataset)
        sut.expand(flattened)

        startMeasuring()
        sut.collapse(flattened)
        stopMeasuring()
    }
    
    func initialSnapshot() -> NSDiffableDataSourceSectionSnapshot<OutlineItem> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<OutlineItem>()

        func addItems2(_ menuItems: [OutlineItem]) {
            snapshot.append(menuItems, to: nil)
            
            var queue: Queue<OutlineItem> = .init()
            queue.enqueue(menuItems)
            while let current = queue.dequeue() {
                
                snapshot.append(current.subitems, to: current)
                queue.enqueue(current.subitems)
            }
        }
        
        addItems2(self.dataset)
        return snapshot
    }
}

#endif
