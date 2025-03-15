//
//  TableViewDragAndDropSupport.swift
//  TreeView
//
//  Created by Dzmitry Antonenka on 3/14/25.
//

import UIKit
import SwiftListTreeDataSource

class TableViewDragAndDropSupport<Item: Hashable>: NSObject, UITableViewDragDelegate, UITableViewDropDelegate {
    var dataSource: ListTreeDataSource<Item>
    var tableView: UITableView
    var updateUI: (_ animating: Bool, _ reloadIds: [ListTreeDataSource<Item>.TreeItemType]) -> Void

    var autoExpandTimer: Timer?
    var hoveredNode: TreeItem<Item>?
    var draggedNode: (TreeItem<Item>, Bool)?

    init(dataSource: ListTreeDataSource<Item>, tableView: UITableView, updateUI: @escaping (_ animating: Bool, _ reloadIds: [ListTreeDataSource<Item>.TreeItemType]) -> Void) {
        self.tableView = tableView
        self.dataSource = dataSource
        self.updateUI = updateUI
    }

    // MARK: - Drag Delegate
    func tableView(_ tableView: UITableView,
                   itemsForBeginning session: UIDragSession,
                   at indexPath: IndexPath) -> [UIDragItem] {
        // We'll attach the warehouse item as an NSItemProvider, or just an empty provider
        let node = self.dataSource.items[indexPath.row]
        
        startDraggingNode(node)
        
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = node // local reference to our node
        return [dragItem]
    }

    // MARK: - UITableViewDropDelegate
    
    func tableView(_ tableView: UITableView,
                   canHandle session: UIDropSession) -> Bool {
        return session.localDragSession != nil
    }
    
    /// **Live expand** logic happens here: we track the hovered node and start a timer if it’s collapsed.
    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?)
    -> UITableViewDropProposal {
        guard
            let dragSession = session.localDragSession,
            let sourceItem = dragSession.items.first,
            let sourceNode = sourceItem.localObject as?  TreeItem<Item>
        else {
            setHoveredNode(nil)
            return UITableViewDropProposal(operation: .cancel)
        }
        
        // If no valid index path, just allow a move to the end
        guard let destinationIndexPath = destinationIndexPath,
              destinationIndexPath.row < dataSource.items.count else {
            resetAutoExpand()
            setHoveredNode(nil)
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        
        let hoveredCandidate = dataSource.items[destinationIndexPath.row]
        
        // *** Here’s the key check: If hoveredCandidate is in sourceNode’s subtree => .forbidden
        if allDescendants(of: sourceNode).contains(hoveredCandidate) {
            setHoveredNode(nil)
            return UITableViewDropProposal(operation: .forbidden)
        }
        
        // If new hovered node => reset the auto-expand timer
        if hoveredCandidate != hoveredNode {
            setHoveredNode(hoveredCandidate)
            resetAutoExpand()
            
            // If node is collapsed but has children => schedule expand
            if !hoveredCandidate.isExpanded && !hoveredCandidate.subitems.isEmpty {
                autoExpandTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    self.dataSource.toggleExpand(item: hoveredCandidate)
                    self.updateUI(true, [])
                }
            }
        }
        
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    /// Called when the user moves the drag away from the table or finishes the drop
    func tableView(_ tableView: UITableView, dropSessionDidEnd session: any UIDropSession) {
        resetAutoExpand()
        setHoveredNode(nil)
        finishDraggingNode()
    }
    
    func tableView(_ tableView: UITableView,
                   performDropWith coordinator: UITableViewDropCoordinator) {
        
        guard coordinator.proposal.operation == .move,
              let item = coordinator.items.first,
              let sourceNode = item.dragItem.localObject as? TreeItem<Item> else { return }
        
        // destinationIndexPath might be nil if user drops outside any rows, so we handle that scenario too
        let destIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: dataSource.items.count, section: 0)
        
        // We want to re-parent or reorder the sourceNode based on the drop location.
        moveNode(sourceNode, to: destIndexPath)
        
        updateUI(true, [sourceNode])
    }
    
    /// Moves `node` so that it appears at the position indicated by `destinationIndexPath`.
    /// We must figure out which parent is relevant at that path, etc.
    private func moveNode(_ sourceNode: TreeItem<Item>,
                          to destinationIndexPath: IndexPath) {
        
        // If the user drops below all items, we can re-parent at the top-level
        if destinationIndexPath.row >= dataSource.items.count {
            // Move the item to top-level at the end
            // We'll do an index = backingStore.count, but the library expects a numeric index, parent, etc.
            dataSource.move(sourceNode.value, toIndex: dataSource.items.count, inParent: nil)
            dataSource.reload()
            return
        }
        
        // Else, find the node that is currently at the destination
        let destinationNode = dataSource.items[destinationIndexPath.row]
        
        // We could choose to place `sourceNode` at the same level as `destNode` or as a child.
        // Let’s do: “drop on row” => re-parent to its parent if it has one, inserted just after it.
        
        if let parentNode = destinationNode.parent {
            // Move under the same parent as destNode
            // We'll find parent's subitems, figure out the index for insertion
            let subitems = parentNode.subitems
            if let insertIndex = subitems.firstIndex(of: destinationNode) {
                dataSource.move(sourceNode.value, toIndex: insertIndex, inParent: parentNode.value)
            }
        } else {
            // destNode is top-level; insert it at top-level
            let topLevel = dataSource.items.filter({ $0.parent == nil })
            if let insertIndex = topLevel.firstIndex(of: destinationNode) {
                dataSource.move(sourceNode.value, toIndex: insertIndex, inParent: nil)
            }
        }
        
        dataSource.reload()
    }
    
    // MARK: - Helpers for auto-expand
    private func resetAutoExpand() {
        autoExpandTimer?.invalidate()
        autoExpandTimer = nil
    }
    
    private func startDraggingNode(_ node: TreeItem<Item>) {
        draggedNode = (node, node.isExpanded)
        
        node.isExpanded = false
        dataSource.reload()
        
        updateUI(true, [node])
    }
    
    // MARK: - Restore expansions once drag ends
    private func finishDraggingNode() {
        guard let (node, isExpanded) = draggedNode else { return }
        draggedNode = nil
        
        node.isExpanded = isExpanded
        dataSource.reload()
        
        updateUI(true, [node])
    }
    
    // MARK: - Hover Helpers
    private func setHoveredNode(_ newNode: TreeItem<Item>?) {
        // 1. Unhighlight the old node's row
        if let oldNode = hoveredNode {
            if let oldIndex = dataSource.items.firstIndex(of: oldNode) {
                updateCell(at: IndexPath(row: oldIndex, section: 0), color: .systemBackground)
            }
        }
        
        // 2. Update hoveredNode
        hoveredNode = newNode
        
        // 3. Highlight the new node's row
        if let newNode = newNode {
            if let newIndex = dataSource.items.firstIndex(of: newNode) {
                updateCell(at: IndexPath(row: newIndex, section: 0), color: .quaternarySystemFill)
            }
        }
    }

     private func updateCell(at indexPath: IndexPath, color: UIColor) {
         guard let cell = tableView.cellForRow(at: indexPath) else { return }
         cell.contentView.backgroundColor = color
     }
}
