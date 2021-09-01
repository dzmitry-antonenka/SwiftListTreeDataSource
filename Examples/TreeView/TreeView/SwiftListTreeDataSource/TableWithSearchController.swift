//
//  TableWithSearchController.swift
//  test
//
//  Created by Dzmitry Antonenka on 24/04/21.
//

import UIKit
import SwiftListTreeDataSource

class TableWithSearchController: UIViewController {
    enum DisplayMode {
        case standard
        case filtering(text: String)
    }
    enum Section {
        case main
    }
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    lazy var items: [OutlineItem] = DataManager.shared.mockData.items
    
    var displayMode: DisplayMode = .standard
    var debouncer = Debouncer()
        
    lazy var listTreeDataSource: FilterableListTreeDataSource<OutlineItem> = {
        var dataSource = FilterableListTreeDataSource<OutlineItem>()
        addItems(items, to: dataSource)
        return dataSource
    }()
    
    @available(iOS 13.0, *)
    private(set) lazy var diffableDataSource: UITableViewDiffableDataSource<Section, ListTreeDataSource<OutlineItem>.TreeItemType> = {
        return self.createDiffableDataSource()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupDataSource()
        setupBarButtonItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadUI()
    }
    
    func reloadUI(animating: Bool = true) {
        if isOS13Available {
            var diffableSnaphot = NSDiffableDataSourceSnapshot<Section, ListTreeDataSource<OutlineItem>.TreeItemType>()
            diffableSnaphot.appendSections([.main])
            diffableSnaphot.appendItems(listTreeDataSource.items, toSection: .main)
            self.diffableDataSource.apply(diffableSnaphot, animatingDifferences: animating)
        } else {
            self.tableView.reloadData()
        }
    }
    
    func performSearch(with searchText: String) {
        if !searchText.isEmpty {
            self.searchBar.isLoading = true
            self.displayMode = .filtering(text: searchText)

            self.listTreeDataSource.filterItemsKeepingParents(by: { $0.title.lowercased().contains(searchText.lowercased()) }) { [weak self] in
                guard let self = self else { return }
                self.searchBar.isLoading = false
                self.reloadUI(animating: false)
            }
        } else {
            self.displayMode = .standard
            self.searchBar.isLoading = false
            self.listTreeDataSource.resetFiltering(collapsingAll: true)
            self.reloadUI(animating: false)
        }
    }
}

extension TableWithSearchController: UISearchBarDelegate {
    var isSearching: Bool {
        switch displayMode {
        case .standard:
            return false
        case .filtering(_):
            return true
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        debouncer.debounce { [weak self] in
            guard let self = self else { return }
            self.performSearch(with: searchText)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
}

extension TableWithSearchController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listTreeDataSource.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var searchText: String?
        if case let .filtering(text) = displayMode {
            searchText = text
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! Cell
        let item = listTreeDataSource.items[indexPath.row]
        cell.configure(with: item, searchText: searchText)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = listTreeDataSource.items[indexPath.row]
        listTreeDataSource.toggleExpand(item: item)
        
        if let cell = tableView.cellForRow(at: indexPath) as? Cell {
            // hack for animation to work with diffable data source animation.
            UIView.animate(withDuration: animationDuration) {
                let transform = CGAffineTransform.init(rotationAngle: item.isExpanded ? CGFloat.pi/2.0 : 0)
                cell.disclosureImageView.transform = transform
            }
        }
        
        self.reloadUI(animating: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension TableWithSearchController {
    func setupTableView() {
        tableView.register(UINib(nibName: "Cell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.register(DetailTextCell.self, forCellReuseIdentifier: "TitleDetailCell")
    }
    
    func setupBarButtonItems() {
    }
    
    func setupDataSource() {
        if isOS13Available {
            self.tableView.dataSource = self.diffableDataSource
        } else {
            self.tableView.dataSource = self
        }
    }
}

@available(iOS 13, *)
fileprivate extension TableWithSearchController {
    func createDiffableDataSource() -> UITableViewDiffableDataSource<Section, ListTreeDataSource<OutlineItem>.TreeItemType> {
        let dataSource = UITableViewDiffableDataSource<Section, ListTreeDataSource<OutlineItem>.TreeItemType>(
            tableView: tableView,
            cellProvider: { tableView, indexPath, _ in
                return self.tableView(self.tableView, cellForRowAt: indexPath)
            }
        )
        return dataSource
    }
}
