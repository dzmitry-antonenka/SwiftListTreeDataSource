//
//  NameCell.swift
//  FileViewer
//
//  Created by Dzmitry Antonenka on 24.04.21.
//  Copyright © 2021 razeware. All rights reserved.
//

import Cocoa

class NameCell: NSTableCellView {
  @IBOutlet weak var disclosureTriangleButton: NSButton!
  @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
  @IBOutlet weak var button: NSButton!

  var onDisclosureButtonPressed: ((_ applyToAllChildren: Bool) -> Void)?
  
  @IBAction func disclosureButtonPressed(_ sender: NSButton) {
    let optionModifierSet = NSEvent.modifierFlags.contains(.option)
    onDisclosureButtonPressed?(optionModifierSet)
  }
}
