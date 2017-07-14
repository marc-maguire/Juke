//
//  OverlayView.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-06-16.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import Foundation
import UIKit

enum GGOverlayViewMode {
    case GGOverlayViewModeLeft
    case GGOverlayViewModeRight
}

class OverlayView: UIView{
    var _mode: GGOverlayViewMode! = GGOverlayViewMode.GGOverlayViewModeLeft
    var imageView: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
        imageView = UIImageView(image: #imageLiteral(resourceName: "plus"))
        imageView.layer.masksToBounds = true
        self.addSubview(imageView)
        layoutSubviews()
    }
    
    func setMode(mode: GGOverlayViewMode) -> Void {
        if _mode == mode {
            return
        }
        _mode = mode
        
        if _mode == GGOverlayViewMode.GGOverlayViewModeLeft {
            imageView.image = #imageLiteral(resourceName: "dislikeHeart")
        } else {
            imageView.image = #imageLiteral(resourceName: "plus")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = self.frame
    }
}
