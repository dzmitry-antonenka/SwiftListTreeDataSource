# SwiftListTreeDataSource

[![Swift](https://github.com/dzmitry-antonenka/SwiftListTreeDataSource/actions/workflows/swift.yml/badge.svg)](https://github.com/dzmitry-antonenka/SwiftListTreeDataSource/actions/workflows/swift.yml)

List tree data souce to display hierachical data structures in lists-like way. It's UI agnostic, just like view-model, so can be used with UITableView/UICollectionView/NSTableView/SwiftUI or in console application.

## Demo:

TreeView (iOS):        | FileViewer (macOS): 
:-------------------------:|:-------------------------:
<img src="https://user-images.githubusercontent.com/11133998/131714349-03ec8259-9975-4835-9e79-e2f2a3c5cf54.mp4" width="300" height="534"> | <img src="https://user-images.githubusercontent.com/11133998/131739773-9528b112-e068-46ef-9f1c-fea0e746d14f.mp4" width="540" height="350">

Note: `FileViewer` is a modification for [RW tutorial](https://www.raywenderlich.com/830-macos-nstableview-tutorial)

## Installation:

[CocoaPods](http://www.cocoapods.org):

Add additional entry to your Podfile.
```
pod "SwiftListTreeDataSource", "1.0.0"
```

[Swift Package Manager](https://swift.org/package-manager/):

Works along with CocoaPods and others!
You can add it directly in Xcode. File -> Swift Packages -> Add Package Dependency -> ..

## Requirements:
Swift 5.3 & Dispatch framework. Support for apple platforms starting:
* iOS '8.0'
* macOS '10.10'
* tvOS '9.0'
* watchOS '2.0'

## Usage:
#### Please see example projects for more!
Create data source:
```
var listTreeDataSource = ListTreeDataSource<OutlineItem>()

// create data source with filtering support.
var filterableListTreeDataSource = FilterableListTreeDataSource<OutlineItem>()
```

Add/Insert/Delete - quick helper methods:
```   
// Helper to traverse items with all nested children to include to data source.
addItems(items, itemChildren: { $0.subitems }, to: listTreeDataSource)
```

Fold (inorder traversal + map into final result):
Use case: changes were made and we need final tree. FO 
```
let folded = listTreeDataSource.fold(NodeTestItem.init) { item, subitems in
    NodeTestItem(identifier: item.identifier, title: item.title, subitems: subitems)
}

Or Fold with Identity (when element already hierarchical item):
let folded = sut.fold({ $0 }) { root, _ in root }
```

Add/Insert/Delete/Move - More grannular control:
```
// Append:
listTreeDataSource.append(currentToAdd, to: referenceParent)

// Insert:
listTreeDataSource.insert([insertionBeforeItem], before: existingItem)
listTreeDataSource.insert([insertionAfterItem], after: existingItem)

// Delete:
listTreeDataSource.delete([itemToDelete])

// Move:
// E.g. user drags `existingNode` into `newParent` subitems with 0 index.
// existingNode = listTreeDataSource.items[sourceIdx];
// newParent = listTreeDataSource.items[dropParentIdx];
// toIndex = drop index in newParent;
listTreeDataSource.move(existingNode, toIndex: 0, inParent: newParent)

// NOTE: Reload data source at the end of changes.
listTreeDataSource.reload()
```    

UI related logic:
``` 
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

    let transform = CGAffineTransform.init(rotationAngle: item.isExpanded ? CGFloat.pi/2.0 : 0)
    cell.disclosureImageView.transform = transform

    return cell
}

// MARK: - Example with fitering

func performSearch(with searchText: String) {
    if !searchText.isEmpty {
        self.searchBar.isLoading = true
        self.displayMode = .filtering(text: searchText)

        self.filterableTreeDataSource.filterItemsKeepingParents(by: { $0.title.lowercased().contains(searchText.lowercased()) }) { [weak self] in
            guard let self = self else { return }
            self.searchBar.isLoading = false
            self.reloadUI(animating: false)
        }
    } else {
        self.displayMode = .standard
        self.searchBar.isLoading = false
        self.filterableTreeDataSource.resetFiltering(collapsingAll: true)
        self.reloadUI(animating: false)
    }
}

func reloadUI(animating: Bool = true) {
    if isOS13Available {
        var diffableSnaphot = NSDiffableDataSourceSnapshot<Section, ListTreeDataSource<OutlineItem>.TreeItemType>()
        diffableSnaphot.appendSections([.main])
        diffableSnaphot.appendItems(filterableTreeDataSource.items, toSection: .main)
        self.diffableDataSource.apply(diffableSnaphot, animatingDifferences: animating)
    } else {
        self.tableView.reloadData()
    }
}
```

More advanced formula to try to fit `indentation` into available space, helped colleagues with data science background:
```
/// https://en.wikipedia.org/wiki/Exponential_decay
let isPad = UIDevice.current.userInterfaceIdiom == .pad
let decayCoefficient: Double = isPad ? 150 : 40
let lvl = Double(item.level)
let left = 11 + 10 * lvl * ( exp( -lvl / max(decayCoefficient, lvl)) )
let leftOffset: CGFloat = min( CGFloat(left) , UIScreen.main.bounds.width - 120.0)
cell.lblLeadingConstraint.constant = leftOffset
```

## Why yet another library? When we have quite a few:
- Apple's NSDiffableDataSourceSectionSnapshot introduces this feature starting iOS14+ 
- [RATreeView](https://github.com/Augustyniak/RATreeView)
- [LNZTreeView](https://github.com/gringoireDM/LNZTreeView)
- Related question on [Stack Overflow](https://stackoverflow.com/questions/40626357/achieve-tree-view-like-structure-in-iphone-app)

## Key differences:
- Support for older OS versions that can work with Swift 5.3 & Dispatch (GCD) framework.
- This solution is UI agnostic and doesn't depend on any UI components or frameworks. You can use for UITableView, NSTableView (macOS), UICollectionView or use other custom frameworks.
- Included support for filtering.

## Implementation details summary:
The key algorithm used is depth first traversal (also called DFS) to build flattened store of nodes and expose it to consumer. Essentially what we need is flat list, node nesting level is used to add identation decoration. Component that supports filtering uses same strategy, but with small modifications: DSF with filtering. Implemented in iterative style to achieve maximum performance. Please see source code for details.

## Performance
The performance of underlying components is quite decent and achieved with iterative style implementation. For large data set performance issues migth be caused by consumer UI frameworks, e.g. long diffing by `NSDiffableDataSourceSectionSnapshot` when processing lots of data. In this case please disable animation when appying differences or fall back to `reloadData`.

### Testing version 1.0.0 on MacBook Pro 2019:
Expand All Levels (worst case since requires to traverse all nodes, method `expandAll()`):
* ~88_000 nodes: 0.133 sec.
* ~350_000 nodes: 0.479 sec.
* ~797_000 nodes: 1.149 sec.
* ~7_200_000 nodes: 10.474 sec.

Add items to data source (method `addItems(_:to:)`):
* ~88_000 nodes: 0.483 sec.
* ~350_000 nodes: 1.848 sec.
* ~797_000 nodes: 4.910 sec.
* ~7_200_000 nodes: 46.816 sec.

## Unit testing:
All functional items are under test, but there might be some room for improvement (e.g. covering additional corner cases).  

## Debugging

```
// to get `testable` access to internal stuff, including to `backingStore`.
@testable import SwiftListTreeDataSource

// Make conform to `CustomDebugStringConvertible`.
extension OutlineItem: CustomDebugStringConvertible {
    public var debugDescription: String { "\(title)" }
}

// Correct usage:
let output1 = debugDescriptionTopLevel(listTreeDataSource.items) // ✅ Description for top level since `items` already flattened (one-level perspective) and include expanded children.
let output2 = debugDescriptionAllLevels(listTreeDataSource.backingStore) // ✅ Description for all levels, asked with hierarchical store as input.
let output3 = debugDescriptionExpandedLevels(listTreeDataSource.backingStore) // ✅ Description for expanded levels, asked with hierarchical store as input.
print(output3) // print output to console for example.  

// Wrong usage:
// ❌ `listTreeDataSource.items` are already flattened (one-level perspetive) and include expanded items, so methods below will return nonsense.
debugDescriptionAllLevels(listTreeDataSource.items) // ❌
debugDescriptionExpandedLevels(listTreeDataSource.items) // ❌
```
