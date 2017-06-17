//
//  DraggableView.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-06-16.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//
import Foundation
import UIKit

protocol DraggableViewDelegate {
    func cardSwipedLeft(card: UIView) -> Void
    func cardSwipedRight(card: UIView) -> Void
}

class DraggableView: UIImageView {
    
    
    let ACTION_MARGIN: Float = 120      //%%% distance from center where the action applies. Higher = swipe further in order for the action to be called
    let SCALE_STRENGTH: Float = 4       //%%% how quickly the card shrinks. Higher = slower shrinking
    let SCALE_MAX:Float = 0.93          //%%% upper bar for how much the card shrinks. Higher = shrinks less
    let ROTATION_MAX: Float = 1         //%%% the maximum rotation allowed in radians.  Higher = card can keep rotating longer
    let ROTATION_STRENGTH: Float = 320  //%%% strength of rotation. Higher = weaker rotation
    let ROTATION_ANGLE: Float = 3.14/8  //%%% Higher = stronger rotation angle
    
    var delegate: DraggableViewDelegate!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var originPoint: CGPoint!
    //var overlayView: OverlayView!
    var xFromCenter: Float!
    var yFromCenter: Float!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(beingDragged(gestureRecognizer:)))
        
        
        self.addGestureRecognizer(panGestureRecognizer)
        
        //        overlayView = OverlayView(frame: CGRect(x: self.frame.size.width/2-100, y: 0, width: 100, height: 100))
        //        overlayView.alpha = 0
        //        self.addSubview(overlayView)
        
        self.isUserInteractionEnabled = true
        
        xFromCenter = 0
        yFromCenter = 0
        self.originPoint = self.center
        print("successful init")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //self.setupView()
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(beingDragged(gestureRecognizer:)))
        
        
        self.addGestureRecognizer(panGestureRecognizer)
        
//        overlayView = OverlayView(frame: CGRect(x: self.frame.size.width/2-100, y: 0, width: 100, height: 100))
//        overlayView.alpha = 0
//        self.addSubview(overlayView)
        
        self.isUserInteractionEnabled = true
        
        xFromCenter = 0
        yFromCenter = 0
        
        print("successful init")
    }
    
    func setupView() -> Void {
        self.layer.cornerRadius = 4;
        self.layer.shadowRadius = 3;
        self.layer.shadowOpacity = 0.2;
        //self.layer.shadowOffset = CGSize(1,1);
    }
    
    func beingDragged(gestureRecognizer: UIPanGestureRecognizer) -> Void {
        xFromCenter = Float(gestureRecognizer.translation(in: self).x)
        yFromCenter = Float(gestureRecognizer.translation(in: self).y)
        
        switch gestureRecognizer.state {
        case UIGestureRecognizerState.began:
            
            print("pan began")
        case UIGestureRecognizerState.changed:
            print("pan changed")
            let rotationStrength: Float = min(xFromCenter/ROTATION_STRENGTH, ROTATION_MAX)
            let rotationAngle = ROTATION_ANGLE * rotationStrength
            //let scale = max(1 - fabsf(rotationStrength) / SCALE_STRENGTH, SCALE_MAX)
            self.center = CGPoint(x: self.originPoint.x + CGFloat(xFromCenter), y: self.originPoint.y)
            
            let transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle))
            //let scaleTransform = transform.scaledBy(x: CGFloat(scale), y: CGFloat(scale))
            self.transform = transform
            //self.updateOverlay(distance: CGFloat(xFromCenter))
        case UIGestureRecognizerState.ended:
            
            UIView.animate(withDuration: 0.2, animations: {
                self.center = self.originPoint
                self.transform = CGAffineTransform(rotationAngle: 0)
            }, completion: { (complete) in
                
            })
            
        
            
        
            
        case UIGestureRecognizerState.possible:
            fallthrough
        case UIGestureRecognizerState.cancelled:
            fallthrough
        case UIGestureRecognizerState.failed:
            fallthrough
        default:
            break
        }
    }
    
//    func updateOverlay(distance: CGFloat) -> Void {
//        if distance > 0 {
//            overlayView.setMode(mode: GGOverlayViewMode.GGOverlayViewModeRight)
//        } else {
//            overlayView.setMode(mode: GGOverlayViewMode.GGOverlayViewModeLeft)
//        }
//        overlayView.alpha = CGFloat(min(fabsf(Float(distance))/100, 0.4))
//    }
    
    func afterSwipeAction() -> Void {
        let floatXFromCenter = Float(xFromCenter)
        if floatXFromCenter > ACTION_MARGIN {
            self.rightAction()
        } else if floatXFromCenter < -ACTION_MARGIN {
            self.leftAction()
        } else {
            UIView.animate(withDuration: 0.3, animations: {() -> Void in
                self.center = self.originPoint
                self.transform = CGAffineTransform(rotationAngle: 0)
               // self.overlayView.alpha = 0
            })
        }
    }
    
    func rightAction() -> Void {
        let finishPoint: CGPoint = CGPoint(x: 500, y: 2 * CGFloat(yFromCenter) + self.originPoint.y)
        UIView.animate(withDuration: 0.3,
                                   animations: {
                                    self.center = finishPoint
        }, completion: {
            (value: Bool) in
            self.removeFromSuperview()
        })
        delegate.cardSwipedRight(card: self)
    }
    
    func leftAction() -> Void {
        let finishPoint: CGPoint = CGPoint(x: -500, y: 2 * CGFloat(yFromCenter) + self.originPoint.y)
        UIView.animate(withDuration: 0.3,
                                   animations: {
                                    self.center = finishPoint
        }, completion: {
            (value: Bool) in
            self.removeFromSuperview()
        })
        delegate.cardSwipedLeft(card: self)
    }
    
    func rightClickAction() -> Void {
        let finishPoint = CGPoint(x: 600, y: self.center.y)
        UIView.animate(withDuration: 0.3,
                                   animations: {
                                    self.center = finishPoint
                                    self.transform = CGAffineTransform(rotationAngle: 1)
        }, completion: {
            (value: Bool) in
            self.removeFromSuperview()
        })
        delegate.cardSwipedRight(card: self)
        
    }
    
    func leftClickAction() -> Void {
        let finishPoint: CGPoint = CGPoint(x: -600, y: self.center.y)
        UIView.animate(withDuration: 0.3,
                                   animations: {
                                    self.center = finishPoint
                                    self.transform = CGAffineTransform(rotationAngle: 1)
        }, completion: {
            (value: Bool) in
            self.removeFromSuperview()
        })
        delegate.cardSwipedLeft(card: self)
    }
}