//
//  TestViewController.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-06-16.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit


class TestViewController: UIViewController {
    
    //w: 253 h: 305
    
    @IBOutlet weak var jukeView: UIView!
    

    @IBOutlet weak var albumImage: DraggableView!

    @IBOutlet weak var upNextImage: UIImageView!

    @IBOutlet weak var jukeHeight: NSLayoutConstraint!
    var originalHeight: CGFloat!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initial Quadcurve setup

        let p1 = CGPoint(x: jukeView.bounds.origin.x, y: jukeView.bounds.origin.y)
        
        let p2 = CGPoint(x: jukeView.bounds.width, y: jukeView.bounds.origin.y)
        
        let controlP = CGPoint(x: jukeView.bounds.width / 2, y: jukeView.bounds.origin.y - 120)

        addCurve(startPoint: p1, endPoint: p2, controlPoint: controlP, color: UIColor.blue)
        
        originalHeight = jukeHeight.constant

        
        albumImage.layer.cornerRadius = 10
        
        upNextImage.layer.cornerRadius = 10

        
    }
    
    func addCurve(startPoint: CGPoint, endPoint: CGPoint, controlPoint: CGPoint, color: UIColor) {
        
        let layer = CAShapeLayer()
        
        jukeView.layer.addSublayer(layer)
        layer.strokeColor = jukeView.layer.backgroundColor
        layer.fillColor = jukeView.layer.backgroundColor
        layer.lineWidth = 1

        let path = UIBezierPath()
        
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, controlPoint: controlPoint)
        layer.path = path.cgPath
        path.stroke()
   
    }
    
    
    @IBAction func swipeForTable(_ sender: UIPanGestureRecognizer) {
        
        let direction = CGFloat(sender.velocity(in: self.view.window).y)
        
        let yChange = CGFloat(sender.translation(in: self.view.window).y)
        
        
        if direction <= 0 && yChange < 0 {
            jukeHeight.constant = originalHeight + (-yChange)
            
            
            sender.view?.setNeedsLayout()
            self.view.layoutIfNeeded()
            
        }
        
        if direction >= 0 && yChange > 0 {
            jukeHeight.constant = originalHeight - yChange
            
            sender.view?.setNeedsLayout()
            self.view.layoutIfNeeded()
            
        }
        
        originalHeight = jukeHeight.constant
        sender.setTranslation(CGPoint.zero, in: self.view)
        
        
        

    }
    
    
        
        
    
    
}

