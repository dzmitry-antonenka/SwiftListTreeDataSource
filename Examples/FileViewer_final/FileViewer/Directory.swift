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

import AppKit


public struct Metadata: CustomDebugStringConvertible, Hashable {

  let name: String
  let date: Date
  let size: Int64
  let icon: NSImage
  let color: NSColor
  let isFolder: Bool
  var subdirectoryDescendants: [Metadata]
  let url: URL

  init(fileURL: URL, name: String, date: Date, size: Int64, icon: NSImage, isFolder: Bool, subdirectoryDescendants: [Metadata], color: NSColor) {
    self.name = name
    self.date = date
    self.size = size
    self.icon = icon
    self.color = color
    self.isFolder = isFolder
    self.subdirectoryDescendants = subdirectoryDescendants
    self.url = fileURL
  }

  public var debugDescription: String {
    return name + " " + "Folder: \(isFolder)" + " Size: \(size)"
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(url)
    hasher.combine(identifier)
  }
  public static func == (lhs: Metadata, rhs: Metadata) -> Bool {
    return (lhs.url == rhs.url) && lhs.identifier == rhs.identifier
  }
  private let identifier = UUID()
}

public struct Directory  {

  fileprivate(set) var files: [Metadata] = []
  let url: URL

  public enum FileOrder: String {
    case Name
    case Date
    case Size
  }

  let requiredAttributes = [URLResourceKey.localizedNameKey, URLResourceKey.effectiveIconKey,
                            URLResourceKey.typeIdentifierKey, URLResourceKey.contentModificationDateKey,
                            URLResourceKey.fileSizeKey, URLResourceKey.isDirectoryKey,
                            URLResourceKey.isPackageKey]
  
  public init(folderURL: URL) {
    url = folderURL
    files = enumeratedFiles(at: folderURL)
  }

  func enumeratedFiles(at folderURL: URL) -> [Metadata] {
    var files: [Metadata] = []
    if let enumerator = FileManager.default.enumerator(at: folderURL,
                                                       includingPropertiesForKeys: requiredAttributes,
                                                       options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants],
                                                       errorHandler: nil) {

      while let url = enumerator.nextObject() as? URL {
        print("\(url)")

        do {
          let properties = try  (url as NSURL).resourceValues(forKeys: requiredAttributes)
          let isFolder = (properties[URLResourceKey.isDirectoryKey] as? NSNumber)?.boolValue ?? false
          files.append(Metadata(fileURL: url,
                                name: properties[URLResourceKey.localizedNameKey] as? String ?? "",
                                date: properties[URLResourceKey.contentModificationDateKey] as? Date ?? Date.distantPast,
                                size: (properties[URLResourceKey.fileSizeKey] as? NSNumber)?.int64Value ?? 0,
                                icon: properties[URLResourceKey.effectiveIconKey] as? NSImage ?? NSImage(),
                                isFolder: isFolder,
                                subdirectoryDescendants: isFolder ? enumeratedFiles(at: url) : [],
                                color: NSColor()))
        }
        catch {
          print("Error reading file attributes")
        }
      }
    }
    return files
  }

  func contentsOrderedBy(orderedBy: FileOrder, ascending: Bool) -> [Metadata] {
    return allcontentsOrderedBy(files: files, orderedBy: orderedBy, ascending: ascending)
  }
  
  private func allcontentsOrderedBy(files: [Metadata], orderedBy: FileOrder, ascending: Bool) -> [Metadata] {
    func _contentsOrderedBy(files: [Metadata], orderedBy: FileOrder, ascending: Bool) -> [Metadata] {
      let sortedFiles: [Metadata]
      switch orderedBy {
      case .Name:
        sortedFiles = files.sorted {
          return sortMetadata(lhsIsFolder:false, rhsIsFolder: false, ascending: ascending,
                              attributeComparation:itemComparator(lhs:$0.name, rhs: $1.name, ascending:ascending))
        }
      case .Size:
        sortedFiles = files.sorted {
          return sortMetadata(lhsIsFolder:false, rhsIsFolder: false, ascending:ascending,
                              attributeComparation:itemComparator(lhs:$0.size, rhs: $1.size, ascending: ascending))
        }
      case .Date:
        sortedFiles = files.sorted {
          return sortMetadata(lhsIsFolder:false, rhsIsFolder: false, ascending:ascending,
                              attributeComparation:itemComparator(lhs:$0.date, rhs: $1.date, ascending:ascending))
        }
      }
      return sortedFiles
    }
    return _contentsOrderedBy(files: files, orderedBy: orderedBy, ascending: ascending).map { file in
      return Metadata.init(fileURL: file.url, name: file.name, date: file.date,
                           size: file.size, icon: file.icon, isFolder: file.isFolder,
                           subdirectoryDescendants: allcontentsOrderedBy(files: file.subdirectoryDescendants, orderedBy: orderedBy, ascending: ascending),
                           color: file.color)
    }
  }

}

// MARK: - Sorting

func sortMetadata(lhsIsFolder: Bool, rhsIsFolder: Bool,  ascending: Bool,
                  attributeComparation: Bool) -> Bool {
  if(lhsIsFolder && !rhsIsFolder) {
    return ascending ? true : false
  }
  else if (!lhsIsFolder && rhsIsFolder) {
    return ascending ? false : true
  }
  return attributeComparation
}

func itemComparator<T:Comparable>(lhs: T, rhs: T, ascending: Bool) -> Bool {
  return ascending ? (lhs < rhs) : (lhs > rhs)
}


public func ==(lhs: Date, rhs: Date) -> Bool {
  if lhs.compare(rhs) == .orderedSame {
    return true
  }
  return false
}

public func <(lhs: Date, rhs: Date) -> Bool {
  if lhs.compare(rhs) == .orderedAscending {
    return true
  }
  return false
}
