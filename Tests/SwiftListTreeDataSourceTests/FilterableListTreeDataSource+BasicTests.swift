import XCTest
import TestsShared
@testable import SwiftListTreeDataSource

// Subclass of `ListTreeDataSourceTests`. Test base methods to make sure it's not broken in specified subclass.
class FilterableListTreeDataSourceBasicTests: ListTreeDataSourceTests {
    override func setUpSut() {
        sut = FilterableListTreeDataSource<OutlineItem>()
    }
}
