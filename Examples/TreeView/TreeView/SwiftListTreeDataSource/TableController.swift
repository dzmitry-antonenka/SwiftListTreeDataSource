//
//  ViewController.swift
//  test
//
//  Created by Dzmitry Antonenka on 24/04/21.
//

import UIKit
import SwiftListTreeDataSource

var isOS13Available: Bool {
    if #available(iOS 13.0, *) {
        return true
    }
    return false
}
var animationDuration: TimeInterval { isOS13Available ? 0.3 : 0.05 }

class TableController: UITableViewController {
    lazy var items: [OutlineItem] = DataManager.shared.mockData.items
    typealias TreeItemType = ListTreeDataSource<OutlineItem>.TreeItemType
    
    lazy var listTreeDataSource: ListTreeDataSource<OutlineItem> = {
        var dataSource = ListTreeDataSource<OutlineItem>()
        addItems(items, to: dataSource)
        return dataSource
    }()
    var dragAndDropController: TableViewDragAndDropSupport<OutlineItem>!

    @available(iOS 13.0, *)
    private(set) lazy var diffableDataSource: UITableViewDiffableDataSource<Section, TreeItemType> = {
        return self.createDiffableDataSource()
    }()
    
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupDataSource()
        configureDragAndDrop()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateUI()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listTreeDataSource.items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! Cell
        
        let item = listTreeDataSource.items[indexPath.row]
        
        let left = 11 + 10 * item.level
        cell.lbl?.text = item.value.title
        cell.lblLeadingConstraint.constant = CGFloat(left)
        cell.disclosureImageView.isHidden = item.subitems.isEmpty
        cell.contentView.backgroundColor = .systemBackground

        let transform = CGAffineTransform.init(rotationAngle: item.isExpanded ? CGFloat.pi/2.0 : 0)
        cell.disclosureImageView.transform = transform
                
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = listTreeDataSource.items[indexPath.row]
        listTreeDataSource.toggleExpand(item: item)
        
        if let cell = tableView.cellForRow(at: indexPath) as? Cell {
            // hack for animation to work with diffable data source animation.
            UIView.animate(withDuration: animationDuration) {
                let transform = CGAffineTransform.init(rotationAngle: item.isExpanded ? CGFloat.pi/2.0 : 0)
                cell.disclosureImageView.transform = transform
            }
        }
        
        self.updateUI(animating: true)
    }

    // MARK: - Row Swipe to Delete
    /// Provide a trailing swipe action for "Delete"
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        
        let node = listTreeDataSource.items[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, complete in
            guard let self = self else { return }
            
            // Deleting a node also removes its entire subtree
            self.listTreeDataSource.delete([node.value])
            self.listTreeDataSource.reload()
            self.updateUI(animating: true)
            
            complete(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension TableController {
    func setupTableView() {
        tableView.register(UINib(nibName: "Cell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.register(DetailTextCell.self, forCellReuseIdentifier: "TitleDetailCell")
    }
    func setupDataSource() {
        if isOS13Available {
            self.tableView.dataSource = self.diffableDataSource
        } else {
            self.tableView.dataSource = self
        }
    }

    func updateUI(animating: Bool = true, reloadIds: [ListTreeDataSource<OutlineItem>.TreeItemType] = []) {
        if isOS13Available {
            var diffableSnaphot = NSDiffableDataSourceSnapshot<Section, ListTreeDataSource<OutlineItem>.TreeItemType>()
            diffableSnaphot.appendSections([.main])
            diffableSnaphot.appendItems(listTreeDataSource.items, toSection: .main)
            diffableSnaphot.reloadItems(reloadIds)
            self.diffableDataSource.apply(diffableSnaphot, animatingDifferences: animating)
        } else {
            self.tableView.reloadData()
        }
    }

    private func configureDragAndDrop() {
        dragAndDropController = TableViewDragAndDropSupport(dataSource: self.listTreeDataSource, tableView: self.tableView, updateUI: { [weak self] animating, reloadIds in
            self?.updateUI(animating:animating, reloadIds:reloadIds)
        })
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = dragAndDropController
        tableView.dropDelegate = dragAndDropController
    }
}

// MARK: - Actions
fileprivate extension TableController {
    @IBAction func collapseAll(_ sender: UIBarButtonItem) {
        listTreeDataSource.collapseAll()
        updateUI(animating: false) // `false` to stay on the safe side for batch update in large data set
    }
    @IBAction func expandAll(_ sender: UIBarButtonItem) {
        listTreeDataSource.expandAll()
        updateUI(animating: false) // `false` to stay on the safe side for batch update in large data set
    }
}

@available(iOS 13, *)
fileprivate extension TableController {
    func createDiffableDataSource() -> UITableViewDiffableDataSource<Section, TreeItemType> {
        let dataSource = UITableViewDiffableDataSource<Section, TreeItemType>(
            tableView: tableView,
            cellProvider: { tableView, indexPath, _ in
                return self.tableView(self.tableView, cellForRowAt: indexPath)
            }
        )
        return dataSource
    }
}
