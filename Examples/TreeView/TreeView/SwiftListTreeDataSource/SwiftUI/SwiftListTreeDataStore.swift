//
//  SwiftListTreeDataStore.swift
//  TreeView
//
//  Created by Dzmitry Antonenka on 5/14/24.
//

import SwiftUI
import SwiftListTreeDataSource

class SwiftListTreeDataStore: ObservableObject {
    typealias ItemType = ListTreeDataSource<OutlineItem>.TreeItemType

    enum DisplayMode {
        case standard
        case filtering(text: String)
    }

    private lazy var originalItems: [OutlineItem] = DataManager.shared.mockData.items
    private var debouncer = Debouncer()

    @Published var isLoading: Bool = false
    @Published var displayMode: DisplayMode = .standard
    @Published var items: [ItemType] = []

    private lazy var source: FilterableListTreeDataSource<OutlineItem> = {
        var dataSource = FilterableListTreeDataSource<OutlineItem>()
        addItems(originalItems, to: dataSource)
        return dataSource
    }()

    func performSearch(with searchText: String) {
        if !searchText.isEmpty {
            self.isLoading = true
            self.displayMode = .filtering(text: searchText)

            self.source.filterItemsKeepingParents(by: { $0.title.lowercased().contains(searchText.lowercased()) }) { [weak self] in
                self?.isLoading = false
                self?.items = self?.source.items ?? []
            }
        } else {
            self.displayMode = .standard
            self.isLoading = false
            self.source.resetFiltering(collapsingAll: true)

            self.items = self.source.items
        }
    }

    func toggleExpand(item: ItemType) {
        source.toggleExpand(item: item)
        self.items = self.source.items
    }

    var isSearching: Bool {
        switch displayMode {
        case .standard:
            return false
        case .filtering(_):
            return true
        }
    }

    func searchBar(textDidChange searchText: String) {
        debouncer.debounce { [weak self] in
            guard let self = self else { return }
            self.performSearch(with: searchText)
        }
    }
}
