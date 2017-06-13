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
    @IBOutlet weak var albumArtImageView: UIImageView!
    var timer = Timer()
    var counter = 0
    var isTimerRunning = false
    var resumeTapped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        setTimer(seconds: 240)
        durationLabel.text = String(counter)
        startTimer()
        
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Timer Methods
    
    func setTimer(seconds: Int) {
        counter = seconds
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(TableViewController.updateCounter)), userInfo: nil, repeats: true)
        
    }
    func updateCounter() {
        counter -= 1 //count up by 1 second at a time
        durationLabel.text = timeString(time: TimeInterval(counter))
    }
    
    func pauseTimer() {
        if self.resumeTapped == false {
            timer.invalidate()
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
    
    
    
    //MARK: TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! JukeTableViewCell
        
        return cell
         
    }
   
}
