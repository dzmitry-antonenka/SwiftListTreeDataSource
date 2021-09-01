//
//  Cell.swift
//  test
//
//  Created by Dzmitry Antonenka on 24/04/21.
//

import UIKit
import SwiftListTreeDataSource

class Cell: UITableViewCell {
    @IBOutlet weak var lbl: UILabel!
    @IBOutlet weak var lblLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var disclosureImageView: UIImageView!
    
    func configure(with item: ListTreeDataSource<OutlineItem>.TreeItemType, searchText: String? = nil) {
        let left = 11 + 10 * item.level
        
        let mattrString = NSMutableAttributedString(string: item.value.title, attributes: [ .foregroundColor: UIColor.black ])
        if let searchText = searchText, !searchText.isEmpty {
            let range = (item.value.title.lowercased() as NSString).range(of: searchText.lowercased())
            mattrString.addAttributes([
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ], range: range)
        }

        lbl?.attributedText = mattrString
        lblLeadingConstraint.constant = CGFloat(left)
        
        let transform = CGAffineTransform.init(rotationAngle: (item.isExpanded) ? CGFloat.pi/2.0 : 0)
        disclosureImageView.transform = transform
        disclosureImageView.isHidden = item.subitems.isEmpty
    }
}

class DetailTextCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
