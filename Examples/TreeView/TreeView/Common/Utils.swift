//
//  Utils.swift
//  TreeView
//
//  Created by Dzmitry Antonenka on 24/04/21.
//

import Foundation
import SwiftListTreeDataSource

func addItems(_ items: [OutlineItem], to dataSource: ListTreeDataSource<OutlineItem>) {
    addItems(items, itemChildren: { $0.subitems }, to: dataSource)
}
