//
//  SongTimer.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-18.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import Foundation



class SongTimer {
    
    var delegate: SongTimerProgressBarDelegate?
    var countDownTimer = Timer()
    var countUpTimer = Timer()
    var totalSongTime: Float = 0.0
    var timeRemaining = 0
    var timeElapsed = 0 {
        didSet {
            self.delegate?.progressBarNeedsUpdate()
        }
    }
    var resumeTapped = false
   
    //MARK: ProgressBar Delegate Method
    
    func ProgressBarNeedsUpdate() {
        
        self.delegate?.progressBarNeedsUpdate()
    }
    
    func setMaxSongtime(milliseconds: Int) {
        timeRemaining = milliseconds/1000
        totalSongTime = Float(milliseconds/1000)
        timeElapsed = 0
    }
    
    func startTimer() {
        countDownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(SongTimer.updateCounter)), userInfo: nil, repeats: true)
    }
    
  @objc  func updateCounter() {
        if timeRemaining == 0 {
            countDownTimer.invalidate()
            countUpTimer.invalidate()
            self.delegate?.songDidEnd()
        } else {
            timeRemaining -= 1 //count up by 1 second at a time
            timeElapsed += 1

        }
        
    }



    
}
protocol SongTimerProgressBarDelegate {
    
    func progressBarNeedsUpdate()
    func songDidEnd()
    func labelsNeedUpdate()
}
