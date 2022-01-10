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
        imageIcon.backgroundColor =  .clear
        imageIcon.borderColor = .clear
        imageIcon.borderWidth = 1
        if tools.isSelected == true {
            imageIcon.tintColor = .red
        } else {
            imageIcon.tintColor = .white
        }
    }
    func colorConfigure(Index:Int){
        imageIcon.tintColor = .clear
        imageIcon.borderColor = .white
        imageIcon.borderWidth = 1
        imageIcon.backgroundColor = Constants.colors[Index]
    }
}
