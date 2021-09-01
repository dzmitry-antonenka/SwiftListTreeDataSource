import XCTest
import TestsShared
import SwiftListTreeDataSource

class ListTreeDataSourcePerformanceTests: XCTestCase {
    var sut: ListTreeDataSource<OutlineItem>!
    var dataset: [OutlineItem]!

    override func setUp() {
        super.setUp()
        sut = ListTreeDataSource<OutlineItem>()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Measure add items
    
    func test_addItemsPerformance_withSmallData() throws {
        dataset = DataManager.shared.mockDataSmall.items
        
        self.measure {
            addItems(dataset, to: sut)
        }
    }
    
    func test_addItemsPerformance_withLarge88KData() throws {
        dataset = DataManager.shared.mockDataLarge88K.items
        
        self.measure {
            addItems(dataset, to: sut)
        }
    }
    
    func test_addItemsPerformance_withLarge350KData() throws {
        dataset = DataManager.shared.mockDataLarge350K.items
        
        self.measure {
            addItems(dataset, to: sut)
        }
    }
    
    func test_addItemsPerformance_withLarge797KData() throws {
        dataset = DataManager.shared.mockDataDoubleLarge797K.items
        
        self.measure {
            addItems(dataset, to: sut)
        }
    }
    
    func test_addItemsPerformance_withExtraLarge7_2MData() throws {
        dataset = DataManager.shared.mockDataExtraLarge7_2M.items
        
        self.measure {
            addItems(dataset, to: sut)
        }
    }
    
    
    // MARK: - Expand all tests
        
    func test_expandAllPerformance_withSmallData() throws {
        dataset = DataManager.shared.mockDataSmall.items
        addItems(dataset, to: sut)
        
        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureExpandAllFromCollapsedState()
        }
    }
    
    func test_expandAllPerformance_withLarge88KData() throws {
        dataset = DataManager.shared.mockDataLarge88K.items
        addItems(dataset, to: sut)
        
        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureExpandAllFromCollapsedState()
        }
    }
    
    func test_expandAllPerformance_withLarge350KData() throws {
        dataset = DataManager.shared.mockDataLarge350K.items
        addItems(dataset, to: sut)
        
        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureExpandAllFromCollapsedState()
        }
    }
    
    func test_expandAllPerformance_withLarge797KData() throws {
        dataset = DataManager.shared.mockDataDoubleLarge797K.items
        addItems(dataset, to: sut)
        
        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureExpandAllFromCollapsedState()
        }
    }
    
    func test_expandAllPerformance_withExtraLarge7_2MData() throws {
        dataset = DataManager.shared.mockDataExtraLarge7_2M.items
        addItems(dataset, to: sut)
        
        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureExpandAllFromCollapsedState()
        }
    }
    
    // MARK: - Collapse all tests

    func test_collapseAllPerformance_withSmallData() throws {
        dataset = DataManager.shared.mockDataSmall.items
        addItems(dataset, to: sut)

        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureCollapseAllFromExpandedState()
        }
    }
    func test_collapseAllPerformance_withLarge88KData() throws {
        dataset = DataManager.shared.mockDataLarge88K.items
        addItems(dataset, to: sut)

        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureCollapseAllFromExpandedState()
        }
    }
    func test_collapseAllPerformance_withLarge350KData() throws {
        dataset = DataManager.shared.mockDataLarge350K.items
        addItems(dataset, to: sut)

        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureCollapseAllFromExpandedState()
        }
    }
    func test_collapseAllPerformance_withLarge797KData() throws {
        dataset = DataManager.shared.mockDataDoubleLarge797K.items
        addItems(dataset, to: sut)

        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureCollapseAllFromExpandedState()
        }
    }
    func test_collapseAllPerformance_withExtraLarge7_2MData() throws {
        dataset = DataManager.shared.mockDataExtraLarge7_2M.items
        addItems(dataset, to: sut)

        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            self.measureCollapseAllFromExpandedState()
        }
    }
    
    // MARK: - Helpers
    
    private func measureExpandAllFromCollapsedState() {
        sut.collapseAll()

        startMeasuring()
        sut.expandAll()
        stopMeasuring()
    }

    private func measureCollapseAllFromExpandedState() {
        sut.expandAll()

        startMeasuring()
        sut.collapseAll()
        stopMeasuring()
    }
}
