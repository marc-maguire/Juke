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
    

    override func viewDidLoad() {
        super.viewDidLoad()

        let p1 = CGPoint(x: jukeView.bounds.origin.x, y: jukeView.bounds.origin.y)
        
        let p2 = CGPoint(x: jukeView.bounds.width, y: jukeView.bounds.origin.y)
        
        let controlP = CGPoint(x: jukeView.bounds.width / 2, y: jukeView.bounds.origin.y - 120)

        addCurve(startPoint: p1, endPoint: p2, controlPoint: controlP, color: UIColor.blue)
        
        //albumImage.sendSubview(toBack: jukeView)
        
        albumImage.layer.cornerRadius = 10
        
        upNextImage.layer.cornerRadius = 10

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addCurve(startPoint: CGPoint, endPoint: CGPoint, controlPoint: CGPoint, color: UIColor) {
        
        let layer = CAShapeLayer()
        jukeView.layer.addSublayer(layer)
        
        
        layer.strokeColor = jukeView.layer.backgroundColor
        
        //slightly darker stroke color
        
            //UIColor(red: 220.0/255, green: 220.0/255, blue: 220.0/255, alpha: 1.0).cgColor
        
        layer.fillColor = jukeView.layer.backgroundColor
        
        
           // UIColor(red: 237.0/255, green: 237.0/255, blue: 237.0/255, alpha: 1.0).cgColor
        
        //layer.fillColor = UIColor(red: 237.0/255, green: 237.0/255, blue: 237.0/255, alpha: 1.0).cgColor
        layer.lineWidth = 1
        
        
        
        
        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, controlPoint: controlPoint)
        
        layer.path = path.cgPath
        
        
        
        path.stroke()
   
    }

}

