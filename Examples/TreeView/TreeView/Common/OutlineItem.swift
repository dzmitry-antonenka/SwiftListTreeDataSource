//
//  OutlineItem.swift
//  test
//
//  Created by Dzmitry Antonenka on 24/04/21.
//

import Foundation

class OutlineItem: Identifiable, Hashable, Codable {
    let title: String
    var subitems: [OutlineItem]

    init(title: String,
         subitems: [OutlineItem] = []) {
        self.title = title
        self.subitems = subitems
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    static func == (lhs: OutlineItem, rhs: OutlineItem) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    private var identifier = UUID()
    var id: UUID { identifier }
}

extension OutlineItem: CustomStringConvertible {
    var description: String {
        return "\(title)"
    }
}
