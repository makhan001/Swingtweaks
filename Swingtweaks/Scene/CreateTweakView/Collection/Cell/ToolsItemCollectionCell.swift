//
//  ToolsItemCollectionCell.swift
//  Swingtweaks
//
//  Created by Dr.Mac on 07/01/22.
//

import UIKit

class ToolsItemCollectionCell: UICollectionViewCell {
    // MARK: - Outlets
    @IBOutlet weak var imageIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func configure(tools:ToolsItems){
        imageIcon.image = UIImage(named: tools.toolName)
        if tools.isSelected == true {
            imageIcon.tintColor = .red
        } else {
            imageIcon.tintColor = .white
        }
    }
}
