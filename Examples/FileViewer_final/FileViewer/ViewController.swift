/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Cocoa
import SwiftListTreeDataSource

class ViewController: NSViewController {
  enum DisplayMode {
      case standard
      case filtering(text: String)
  }
  
  @IBOutlet weak var searchBar: ObserverSearchField!
  @IBOutlet weak var statusLabel: NSTextField!
  @IBOutlet weak var tableView: NSTableView!

  var listTreeDataSource: FilterableListTreeDataSource<Metadata>!
  var displayMode: DisplayMode = .standard
  var debouncer = Debouncer()

  let sizeFormatter = ByteCountFormatter()
  var directory: Directory?
  var directoryItems: [Metadata]?
  var sortOrder = Directory.FileOrder.Name
  var sortAscending = true

  override func viewDidLoad() {
    super.viewDidLoad()
    statusLabel.stringValue = ""

    tableView.delegate = self
    tableView.dataSource = self

    tableView.target = self
    tableView.doubleAction = #selector(tableViewDoubleClick(_:))

    searchBar.delegate = self
    searchBar.onTextChange = { [weak self] text in
      self?.textDidChange(text)
    }
    
    let descriptorName = NSSortDescriptor(key: Directory.FileOrder.Name.rawValue, ascending: true)
    let descriptorDate = NSSortDescriptor(key: Directory.FileOrder.Date.rawValue, ascending: true)
    let descriptorSize = NSSortDescriptor(key: Directory.FileOrder.Size.rawValue, ascending: true)

    tableView.tableColumns[0].sortDescriptorPrototype = descriptorName
    tableView.tableColumns[1].sortDescriptorPrototype = descriptorDate
    tableView.tableColumns[2].sortDescriptorPrototype = descriptorSize
  }

  override var representedObject: Any? {
    didSet {
      if let url = representedObject as? URL {
        directory = Directory(folderURL: url)
        reloadFileList()
      }
    }
  }

  func reloadFileList(keepExpandedItemsState: Bool = false) {
    var previouslyShownItemUrlSet: Set<URL> = []
    if keepExpandedItemsState {
      previouslyShownItemUrlSet = Set( self.listTreeDataSource.items.map(\.value.url) )
    }
    
    directoryItems = directory?.contentsOrderedBy(orderedBy: sortOrder, ascending: sortAscending)
    self.listTreeDataSource = FilterableListTreeDataSource<Metadata>()
    addItems(directoryItems ?? [], itemChildren: { $0.subdirectoryDescendants }, to: listTreeDataSource)
    
    let previouslyShownItems = self.listTreeDataSource.allItemSet.filter { previouslyShownItemUrlSet.contains($0.value.url) }
    previouslyShownItems.flatMap(\.allParents).forEach { $0.isExpanded = true }
    self.listTreeDataSource.reload()
    
    tableView.reloadData()
  }

  func updateStatus() {

    let text: String

    let itemsSelected = tableView.selectedRowIndexes.count

    if (directoryItems == nil) {
      text = "No Items"
    }
    else if(itemsSelected == 0) {
      text = "\(directoryItems!.count) items"
    }
    else {
      text = "\(itemsSelected) of \(directoryItems!.count) selected"
    }

    statusLabel.stringValue = text
  }

  @objc func tableViewDoubleClick(_ sender:AnyObject) {
    // 1
    guard tableView.selectedRow >= 0,
      let item = directoryItems?[tableView.selectedRow] else {
        return
    }

    if item.isFolder {
      representedObject = item.url as Any
    } else {
      NSWorkspace.shared.open(item.url as URL)
    }
  }
}

extension ViewController: NSSearchFieldDelegate {
  
  func textDidChange(_ searchText: String) {
    debouncer.debounce { [weak self] in
        guard let self = self else { return }
        self.performSearch(with: searchText)
    }
  }
  
  var isSearching: Bool {
      switch displayMode {
      case .standard:
          return false
      case .filtering(_):
          return true
      }
  }
  
  func searchBarSearchButtonClicked(_ searchBar: NSSearchField) {
      view.resignFirstResponder()
  }
  
  func performSearch(with searchText: String) {
    guard let listTreeDataSource = self.listTreeDataSource else { return }
      if !searchText.isEmpty {
          self.displayMode = .filtering(text: searchText)

        listTreeDataSource.filterItemsKeepingParents(by: { $0.name.lowercased().contains(searchText.lowercased()) }) { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
          }
      } else {
          self.displayMode = .standard
          self.listTreeDataSource.resetFiltering(collapsingAll: true)
          self.tableView.reloadData()
      }
  }
}

extension ViewController: NSTableViewDataSource {

  func numberOfRows(in tableView: NSTableView) -> Int {
    return self.listTreeDataSource?.items.count ?? 0
  }

  func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
    guard let sortDescriptor = tableView.sortDescriptors.first else {
      return
    }

    if let order = Directory.FileOrder(rawValue: sortDescriptor.key!) {
      sortOrder = order
      sortAscending = sortDescriptor.ascending
      reloadFileList(keepExpandedItemsState: true)
    }
  }

}

extension ViewController: NSTableViewDelegate {

  fileprivate enum CellIdentifiers {
    static let NameCell = "NameCellID"
    static let DateCell = "DateCellID"
    static let SizeCell = "SizeCellID"
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

    var image: NSImage?
    var text: String = ""
    var cellIdentifier: String = ""

    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .long

    let treeItem = listTreeDataSource.items[row]
    let item = treeItem.value
    
    if tableColumn == tableView.tableColumns[0] {
      image = item.icon
      text = item.name
      cellIdentifier = CellIdentifiers.NameCell
    } else if tableColumn == tableView.tableColumns[1] {
      text = dateFormatter.string(from: item.date)
      cellIdentifier = CellIdentifiers.DateCell
    } else if tableColumn == tableView.tableColumns[2] {
      text = item.isFolder ? "--" : sizeFormatter.string(fromByteCount: item.size)
      cellIdentifier = CellIdentifiers.SizeCell
    }

    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as! NSTableCellView

    if let cell = cell as? NameCell {
      configureNameCell(item, cell, image, treeItem)
    } else {
      cell.textField?.stringValue = text
      cell.imageView?.image = image ?? nil
    }
    
    return cell
  }
  
  func configureNameCell(_ item: Metadata, _ cell: NameCell, _ image: NSImage?, _ treeItem: TreeItem<Metadata>) {
    let searchText = searchBar.stringValue
    let mattrString = NSMutableAttributedString(string: item.name, attributes: [ .foregroundColor: NSColor.labelColor ])
    if !searchText.isEmpty {
      let defaultFontSize = cell.textField?.font?.pointSize ?? 0
      let range = (item.name.lowercased() as NSString).range(of: searchText.lowercased())
      mattrString.addAttributes([
        .font: NSFont.systemFont(ofSize: defaultFontSize+1.5, weight: .semibold)
      ], range: range)
    }
    cell.textField?.attributedStringValue = mattrString
    cell.imageView?.image = image ?? nil
    
    cell.disclosureTriangleButton.state = treeItem.isExpanded ? .on : .off
    cell.disclosureTriangleButton.alphaValue = treeItem.subitems.isEmpty ? 0 : 1
    
    let left = 11 + 10 * treeItem.level
    cell.leadingConstraint.constant = CGFloat(left)
    
    cell.onDisclosureButtonPressed = { [weak self] applyToAllChildren in
      guard let self = self else { return }
      if applyToAllChildren {
        self.listTreeDataSource.updateAllLevels(of: treeItem, isExpanded: !treeItem.isExpanded)
      } else {
        self.listTreeDataSource.toggleExpand(item: treeItem)
      }
      
      self.tableView.reloadData()
    }
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    updateStatus()
  }
  
}
