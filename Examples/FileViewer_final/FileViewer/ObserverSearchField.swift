//
//  ObserverSearchField.swift
//  FileViewer
//
//  Created by Dzmitry Antonenka on 24.04.21.
//  Copyright © 2021 razeware. All rights reserved.
//

import Cocoa

class ObserverSearchField: NSSearchField {
    var onTextChange: ((String) -> Void)?
  
    override func textDidChange(_ notification: Notification) {
      onTextChange?(self.stringValue)
    }
}
