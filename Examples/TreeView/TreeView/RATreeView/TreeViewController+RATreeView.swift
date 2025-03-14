//
//  TableController+Pod.swift
//  test
//
//  Created by Dzmitry Antonenka on 24/04/21.
//

import UIKit
import RATreeView

class TreeViewController: UIViewController, RATreeViewDelegate, RATreeViewDataSource {

    var treeView : RATreeView!
    lazy var data : [OutlineItem] = DataManager.shared.mockData.items

    convenience init() {
        self.init(nibName : nil, bundle: nil)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupTreeView()
    }

    func setupTreeView() -> Void {
        treeView = RATreeView(frame: view.bounds)
        treeView.register(UINib(nibName: "Cell", bundle: nil), forCellReuseIdentifier: "Cell")
        treeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        treeView.delegate = self;
        treeView.dataSource = self;
        treeView.treeFooterView = UIView()
        treeView.backgroundColor = .clear
        view.addSubview(treeView)
    }

    //MARK: RATreeView data source

    func treeView(_ treeView: RATreeView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? OutlineItem {
            return item.subitems.count
        } else {
            return self.data.count
        }
    }

    func treeView(_ treeView: RATreeView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? OutlineItem {
            return item.subitems[index]
        } else {
            return data[index] as AnyObject
        }
    }

    func treeView(_ treeView: RATreeView, cellForItem item: Any?) -> UITableViewCell {
        let cell = treeView.dequeueReusableCell(withIdentifier: "Cell") as! Cell
        let item = item as! OutlineItem

        let level = treeView.levelForCell(forItem: item)
        let isExpanded = treeView.isCell(forItemExpanded: item)
        let left = 11 + 10 * level
        cell.lbl?.text = item.title
        cell.lblLeadingConstraint.constant = CGFloat(left)
        cell.disclosureImageView.isHidden = item.subitems.isEmpty
        UIView.animate(withDuration: animationDuration) {
            let transform = CGAffineTransform.init(rotationAngle: isExpanded ? CGFloat.pi/2.0 : 0)
            cell.disclosureImageView.transform = transform
            cell.disclosureImageView.layoutIfNeeded()
        }
        
        return cell
    }
    
    func treeView(_ treeView: RATreeView, willExpandRowForItem item: Any) {
        let item = item as! OutlineItem
        let cell = treeView.cell(forItem: item) as! Cell
        udateCellExpandState(cell, isExpanded: true)
    }

    func treeView(_ treeView: RATreeView, willCollapseRowForItem item: Any) {
        let item = item as! OutlineItem
        let cell = treeView.cell(forItem: item) as! Cell
        udateCellExpandState(cell, isExpanded: false)
    }
    
    func udateCellExpandState(_ cell: Cell, isExpanded: Bool) {
        UIView.animate(withDuration: animationDuration) {
            let transform = CGAffineTransform.init(rotationAngle: isExpanded ? CGFloat.pi/2.0 : 0)
            cell.disclosureImageView.transform = transform
            cell.disclosureImageView.layoutIfNeeded()
        }
    }
}

// MARK: - Actions
fileprivate extension TreeViewController {
    @IBAction func collapseAll(_ sender: UIBarButtonItem) {
        for item in data {
            treeView.collapseRow(forItem: item, collapseChildren: true, with: RATreeViewRowAnimationNone)
        }
        
    }
    @IBAction func expandAll(_ sender: UIBarButtonItem) {
        for item in data {
            treeView.expandRow(forItem: item, expandChildren: true, with: RATreeViewRowAnimationNone)
        }
    }
}
