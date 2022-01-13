//
//  ToolItemCollectionView.swift
//  Swingtweaks
//
//  Created by Dr.Mac on 07/01/22.
//

import Foundation
import UIKit
struct ToolsItems {
    var toolName: String
    var isSelected: Bool
}

class ToolItemCollectionView: UICollectionView {
    
    var toolsItems = [ToolsItems( toolName: "ST_Pencil", isSelected: false),
                      ToolsItems( toolName: "ST_Line", isSelected: false),
                      ToolsItems( toolName: "ST_Circle", isSelected: false),
                      ToolsItems( toolName: "ST_Square", isSelected: false),
                      ToolsItems( toolName: "ST_Hand", isSelected: false),
                      ToolsItems( toolName: "ST_Search", isSelected: false),
                      ToolsItems( toolName: "ST_Paintpalette", isSelected: false)]
    
                   //   ToolsItems( toolName: "ST_Eraser", isSelected: false)]
    var isStrokeColor:Bool = false
    var didSelectToolsAtIndex:((Int) -> Void)?
    var didSelectColorAtIndex:((Int) -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(strokeColor:Bool) {
        self.register(UINib(nibName: "ToolsItemCollectionCell", bundle: nil), forCellWithReuseIdentifier: "ToolsItemCollectionCell")
        isStrokeColor = strokeColor
        self.delegate = self
        self.dataSource = self
        layoutIfNeeded()
        reloadData()
    }
}

extension ToolItemCollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isStrokeColor {
            return Constants.colors.count
        }
        else{
        return toolsItems.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: "ToolsItemCollectionCell", for: indexPath) as? ToolsItemCollectionCell else {
            return UICollectionViewCell()
        }
        if isStrokeColor{
            cell.colorConfigure(Index: indexPath.row)
        }
        else{
            cell.configure(tools: toolsItems[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        CGSize(width: 25  , height: 25)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isStrokeColor {
            self.didSelectColorAtIndex?(indexPath.item)
        }
        else{
        self.didSelectToolsAtIndex?(indexPath.item)
        for index in 0..<toolsItems.count{
            if indexPath.row == index{
//                if toolsItems[index].isSelected == true{
//                    toolsItems[index].isSelected = false
//                } else {
//                    toolsItems[index].isSelected = true
//                }
                toolsItems[index].isSelected = true
            } else {
                toolsItems[index].isSelected = false
            }
        }
        collectionView.reloadData()
        }
    }
}

