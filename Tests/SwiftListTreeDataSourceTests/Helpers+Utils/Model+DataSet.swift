import Foundation
import TestsShared

func testDataSet() -> [OutlineItem] {
    let items: [OutlineItem] = [
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
}
