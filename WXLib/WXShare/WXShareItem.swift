//
//  WXShareItem.swift
//  WechatShare
//
//  Created by 王铁山 on 2018/9/11.
//  Copyright © 2018年 wangtieshan. All rights reserved.
//

import Foundation

import UIKit

public class WXShareItem: UIView {
    
    class func itemView() -> WXShareItem {
        guard let itemView = UINib.init(nibName: "WXShareItem", bundle: Bundle.init(for: WXShareItem.classForCoder())).instantiate(withOwner: nil, options: nil).first as? WXShareItem else {
            return WXShareItem()
        }
        itemView.bounds = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 116)
        itemView.imageView.layer.masksToBounds = true
        itemView.imageView.layer.cornerRadius = 2
        
        
        return itemView
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var contentLabel: UILabel!
    
    @IBOutlet weak var iconWidthConstraint: NSLayoutConstraint!
    
    public func hiddenIcon() {
        self.iconWidthConstraint.constant = 0
    }
}

