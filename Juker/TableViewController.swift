//
//  TableViewController.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-13.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
   
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var ArtistNameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    //shows as zero before it is set (need to set it when we are transitioning)
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var songProgressBar: UIProgressView!

    
    @IBOutlet weak var albumArtImageView: UIImageView!
    var countDownTimer = Timer()
    var countUpTimer = Timer()
    var timeRemaining = 0
    var timeElapsed = 0 {
        didSet {
            updateProgressBar()
        }
    }
    var resumeTapped = false
    var songLength = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        durationLabel.text = String(timeRemaining)
        setMaxSongtime(seconds: 240) //use to set new song length
        timeElapsedLabel.text = String(timeElapsed)
        
        startTimer()
        
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Timer Methods
    
    func setMaxSongtime(seconds: Int) {
        timeRemaining = seconds
    }
    
    func startTimer() {
        countDownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(TableViewController.updateCounter)), userInfo: nil, repeats: true)
        countUpTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(TableViewController.updateCountUpTimer)), userInfo: nil, repeats: true)
        
    }
    func updateCounter() {
        if timeRemaining == 0 {
            countDownTimer.invalidate()
            countUpTimer.invalidate()
            //notify everyone that the song is finished
            let notificationName = Notification.Name("songDidFinishPlaying")
            NotificationCenter.default.post(name: notificationName, object: nil, userInfo:  ["nextSong" : "testNextSong", "finishedSong": "testFinishedSong"])
        } else {
            timeRemaining -= 1 //count up by 1 second at a time
            durationLabel.text = timeString(time: TimeInterval(timeRemaining))
        }
        
    }
    
    func updateCountUpTimer() {
        
            timeElapsed += 1 //count up by 1 second at a time
            timeElapsedLabel.text = timeString(time: TimeInterval(timeElapsed))
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

    func updateProgressBar(){
        songProgressBar.progressTintColor = UIColor.blue
        songProgressBar.setProgress(Float(timeElapsed) / Float(timeRemaining), animated: true)
        songProgressBar.layoutIfNeeded()
    }

    
    
    //MARK: TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! JukeTableViewCell
        
        return cell
         
    }
   
}
