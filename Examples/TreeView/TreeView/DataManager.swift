//
//  DataManager.swift
//  TreeView
//
//  Created by Dzmitry Antonenka on 24/04/21.
//

import Foundation

enum MockData {
    case small
    case large88K
    case large350K
    case doubleLarge797K
    case extraLarge7_2M
    
    var items: [OutlineItem] {
        switch self {
        case .small: return OutlineItemDataSet.mockDataSmall
        case .large88K: return OutlineItemDataSet.mockData88K
        case .large350K: return OutlineItemDataSet.mockData350K
        case .doubleLarge797K: return OutlineItemDataSet.mockData797K
        case .extraLarge7_2M: return OutlineItemDataSet.mockData7_2M
        }
    }
}

class DataManager {
    static let shared = DataManager()
        
    var mockData: MockData { self.mockDataSmall }
    
    // specialized data sets
    lazy var mockDataSmall: MockData = .small
    lazy var mockDataLarge88K: MockData = .large88K
    lazy var mockDataLarge350K: MockData = .large350K
    lazy var mockDataDoubleLarge797K: MockData = .doubleLarge797K
    lazy var mockDataExtraLarge7_2M: MockData = .extraLarge7_2M
}
