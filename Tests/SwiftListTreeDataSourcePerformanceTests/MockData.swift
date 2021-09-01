//
//  File.swift
//  
//
//  Created by Dzmitry Antonenka on 18.04.21.
//

import TestsShared
import Foundation

struct DataSet {
    static var mockData88K: [OutlineItem] = {
        // Total elements in tree: (Int) $R0 = 88_572, creation time ~0.201 sec on MBP 2019, core i7
        return menuItems(targetNestLevel: 10, currentLevel: 0, itemsInSection: 3)
    }()
    static var mockData350K: [OutlineItem] = {
        // Total elements in tree: (Int) $R0 = 349_524, creation time ~0.94 sec on MBP 2019, core i7
        return menuItems(targetNestLevel: 9, currentLevel: 0, itemsInSection: 4)
    }()
    static var mockData797K: [OutlineItem] = {
        // Total elements in tree: (Int) $R0 = 797_160, creation time ~1.86 sec on MBP 2019, core i7
        return menuItems(targetNestLevel: 12, currentLevel: 0, itemsInSection: 3)
    }()
    static var mockData7_2M: [OutlineItem] = {
        // Total elements in tree: (Int) $R0 = 7_174_452, creation time ~17.5 sec on MBP 2019, core i7
        return menuItems(targetNestLevel: 14, currentLevel: 0, itemsInSection: 3)
    }()
    
    static var mockDataSmall: [OutlineItem] = {
        var items: [OutlineItem] = [
                OutlineItem(title: "Compositional Layout", subitems: [
                    OutlineItem(title: "Getting Started", subitems: [
                        OutlineItem(title: "Grid"),
                        OutlineItem(title: "Inset Items Grid"),
                        OutlineItem(title: "Two-Column Grid"),
                        OutlineItem(title: "Per-Section Layout", subitems: [
                            OutlineItem(title: "Distinct Sections"),
                            OutlineItem(title: "Adaptive Sections")
                            ])
                        ]),
                    OutlineItem(title: "Advanced Layouts", subitems: [
                        OutlineItem(title: "Supplementary Views", subitems: [
                            OutlineItem(title: "Item Badges"),
                            OutlineItem(title: "Section Headers/Footers"),
                            OutlineItem(title: "Pinned Section Headers")
                            ]),
                        OutlineItem(title: "Section Background Decoration"),
                        OutlineItem(title: "Nested Groups"),
                        OutlineItem(title: "Orthogonal Sections", subitems: [
                            OutlineItem(title: "Orthogonal Sections"),
                            OutlineItem(title: "Orthogonal Section Behaviors")
                            ])
                        ]),
                    OutlineItem(title: "Conference App", subitems: [
                        OutlineItem(title: "Videos"),
                        OutlineItem(title: "News")
                        ])
                ]),
                OutlineItem(title: "Diffable Data Source", subitems: [
                    OutlineItem(title: "Mountains Search"),
                    OutlineItem(title: "Settings: Wi-Fi"),
                    OutlineItem(title: "Insertion Sort Visualization"),
                    OutlineItem(title: "UITableView: Editing", subitems: [
                        OutlineItem(title: "UITableView: Editing v1"),
                        OutlineItem(title: "UITableView: Editing v2.x")
                    ])
                    ]),
                OutlineItem(title: "Lists", subitems: [
                    OutlineItem(title: "Simple List"),
                    OutlineItem(title: "Reorderable List"),
                    OutlineItem(title: "List Appearances"),
                    OutlineItem(title: "List with Custom Cells")
                ]),
                OutlineItem(title: "Outlines", subitems: [
                    OutlineItem(title: "Emoji Explorer"),
                    OutlineItem(title: "Emoji Explorer - List")
                ]),
                OutlineItem(title: "Cell Configurations", subitems: [
                    OutlineItem(title: "Custom Configurations")
                ])
            ]
        return items
    }()
    
    static func menuItems(targetNestLevel: Int, currentLevel: Int, itemsInSection: Int = 3) -> [OutlineItem] {
        return (1...itemsInSection).compactMap { (index) in
            guard currentLevel < targetNestLevel else { return nil }
            return OutlineItem(title: "Level \(currentLevel), item: \(index)", subitems: menuItems(targetNestLevel: targetNestLevel,
                                                                                                    currentLevel: currentLevel + 1, itemsInSection: itemsInSection) )
            
        }
    }
}


enum MockData {
    case small
    case large88K
    case large350K
    case doubleLarge797K
    case extraLarge7_2M
    
    var items: [OutlineItem] {
        switch self {
        case .small: return DataSet.mockDataSmall
        case .large88K: return DataSet.mockData88K
        case .large350K: return DataSet.mockData350K
        case .doubleLarge797K: return DataSet.mockData797K
        case .extraLarge7_2M: return DataSet.mockData7_2M
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
