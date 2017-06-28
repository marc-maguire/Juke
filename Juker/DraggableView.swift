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
    
    
    let ACTION_MARGIN: CGFloat = 120      //%%% distance from center where the action applies. Higher = swipe further in order for the action to be called
    let SCALE_STRENGTH: CGFloat = 4       //%%% how quickly the card shrinks. Higher = slower shrinking
    let SCALE_MAX:CGFloat = 0.93          //%%% upper bar for how much the card shrinks. Higher = shrinks less
    let ROTATION_MAX: CGFloat = 1         //%%% the maximum rotation allowed in radians.  Higher = card can keep rotating longer
    let ROTATION_STRENGTH: CGFloat = 320  //%%% strength of rotation. Higher = weaker rotation
    let ROTATION_ANGLE: CGFloat = 3.14/8  //%%% Higher = stronger rotation angle
    
    var delegate: DraggableViewDelegate!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var originPoint: CGPoint!
    var overlayView: OverlayView!
    var xFromCenter: CGFloat!
    var yFromCenter: CGFloat!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(beingDragged(gestureRecognizer:)))
        
        
        self.addGestureRecognizer(panGestureRecognizer)
        
//                overlayView = OverlayView(frame: self.frame)
//                overlayView.alpha = 0
//                overlayView.layer.masksToBounds = true
//                self.addSubview(overlayView)
//        
//        self.bounds = super.frame
//        self.frame = self.bounds
//        self.layer.masksToBounds = true
        
        self.isUserInteractionEnabled = true
        
        
//        xFromCenter = 0
//        yFromCenter = 0
        self.originPoint = self.center
        print("successful init")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
    }
    
    func setupView() -> Void {
        self.layer.cornerRadius = 4;
        self.layer.shadowRadius = 3;
        self.layer.shadowOpacity = 0.2;
        //self.layer.shadowOffset = CGSize(1,1);
    }
    
    func beingDragged(gestureRecognizer: UIPanGestureRecognizer) -> Void {
        xFromCenter = gestureRecognizer.translation(in: self).x
        yFromCenter = gestureRecognizer.translation(in: self).y
        
        switch gestureRecognizer.state {
        case UIGestureRecognizerState.began:
            print("pan began")
        case UIGestureRecognizerState.changed:
            print("pan changed")
            print(xFromCenter)
            let rotationStrength: CGFloat = min(xFromCenter/ROTATION_STRENGTH, ROTATION_MAX)
            let rotationAngle = ROTATION_ANGLE * rotationStrength
            //let scale = max(1 - fabsf(rotationStrength) / SCALE_STRENGTH, SCALE_MAX)
            
            
            let transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle))
            //let scaleTransform = transform.scaledBy(x: CGFloat(scale), y: CGFloat(scale))
            self.transform = transform
            self.center.x = originPoint.x + xFromCenter
            //self.updateOverlay(distance: xFromCenter)
        case UIGestureRecognizerState.ended:
            
            UIView.animate(withDuration: 0.2, animations: {() -> Void in
                self.center = self.originPoint
                self.transform = CGAffineTransform(rotationAngle: 0)
                //self.overlayView.alpha = 0
            })

            afterSwipeAction(offsetX: xFromCenter)
 
        case UIGestureRecognizerState.possible:
            print("possible")
            fallthrough
        case UIGestureRecognizerState.cancelled:
            print("cancelled")
            fallthrough
        case UIGestureRecognizerState.failed:
            print("failed")
            fallthrough
        default:
            print("default")
            break
        }
    }
    
    func updateOverlay(distance: CGFloat) -> Void {
        if distance > 0 {
            overlayView.setMode(mode: GGOverlayViewMode.GGOverlayViewModeRight)
        } else {
            overlayView.setMode(mode: GGOverlayViewMode.GGOverlayViewModeLeft)
        }
        overlayView.alpha = CGFloat(min(fabsf(Float(distance))/100, 0.4))
    }
    
    func afterSwipeAction(offsetX: CGFloat) -> Void {
        
        if offsetX > ACTION_MARGIN {
            self.rightAction()
        } else if offsetX < -ACTION_MARGIN {
            self.leftAction()
        }
    }
    
    func rightAction() -> Void {
        //print("upvoted")
        delegate.cardSwipedRight(card: self)
    }
    
    func leftAction() -> Void {
        //print("downvoted")
        delegate.cardSwipedLeft(card: self)
    }
    
}
