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
            self.delegate?.songDidEnd()
        } else {
            timeRemaining -= 1 //count up by 1 second at a time
            timeElapsed += 1
            self.delegate?.labelsNeedUpdate()

        }
        
    }

    func pauseTimer() {
        if self.resumeTapped == false {
            countDownTimer.invalidate()
            self.resumeTapped = true
        } else {
            startTimer()
            self.resumeTapped = false
        }
    }
    
    func timeString(time:TimeInterval) -> String {
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        return String(format:"%02d:%02d", minutes, seconds)
        
    }


    
}
protocol SongTimerProgressBarDelegate {
    
    func progressBarNeedsUpdate()
    func songDidEnd()
    func labelsNeedUpdate()
}
