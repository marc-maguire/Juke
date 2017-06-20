//
//  TestViewController.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-06-16.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit
import MGSwipeTableCell


class TestViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, MGSwipeTableCellDelegate {

    @IBOutlet weak var jukeView: UIView!
    
    @IBOutlet weak var albumImage: DraggableView!

    @IBOutlet weak var jukeHeight: NSLayoutConstraint!
    var originalHeight: CGFloat!
    var expandedHeight: Bool!
    
    // Currently Playing Info
    
    @IBOutlet weak var currentInfoWrapper: UIView!
    
    @IBOutlet weak var currentTrackLabel: UILabel!
    
    @IBOutlet weak var currentArtistLabel: UILabel!
    
    @IBOutlet weak var trackProgressView: UIProgressView!
    
    //playlist Table
    
    var playListTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        //Initial Quadcurve setup
        // At some point, will make jukeView a custom UIView Class that will initialize a quadcurve upon setup and attach gesture capabilties

        let p1 = CGPoint(x: jukeView.bounds.origin.x, y: jukeView.bounds.origin.y + 2)
        let p2 = CGPoint(x: jukeView.bounds.width, y: jukeView.bounds.origin.y + 2)
        let controlP = CGPoint(x: jukeView.bounds.width / 2, y: jukeView.bounds.origin.y - 120)

        addCurve(startPoint: p1, endPoint: p2, controlPoint: controlP)
        
        originalHeight = jukeHeight.constant
        albumImage.layer.cornerRadius = 10
        

        playlistTableSetup()
        
    }
    
    func playlistTableSetup() {
        
        playListTable = UITableView()
        
        playListTable.dataSource = self
        playListTable.delegate = self
//        playListTable.register(PlaylistTableCell.self, forCellReuseIdentifier: "Cell")
        
        let nib = UINib(nibName: "PlaylistTableCell", bundle: nil)
        
        playListTable.register(nib, forCellReuseIdentifier: "Cell")
        
        //playListTable.bounces = false
        

        jukeView.addSubview(playListTable)
        
        playListTable.backgroundColor = jukeView.backgroundColor
        
        playListTable.translatesAutoresizingMaskIntoConstraints = false
        playListTable.widthAnchor.constraint(equalTo: jukeView.widthAnchor, multiplier: 1).isActive = true
        playListTable.centerXAnchor.constraint(equalTo: jukeView.centerXAnchor).isActive = true
        playListTable.bottomAnchor.constraint(equalTo: jukeView.bottomAnchor).isActive = true
        
        playListTable.topAnchor.constraint(equalTo: currentInfoWrapper.bottomAnchor).isActive = true
        
        playListTable.isHidden = true
        
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell, swipeButtonsFor direction: MGSwipeDirection, swipeSettings: MGSwipeSettings, expansionSettings: MGSwipeExpansionSettings) -> [UIView]? {
        swipeSettings.transition = MGSwipeTransition.clipCenter
        swipeSettings.keepButtonsSwiped = false
        expansionSettings.buttonIndex = 0
        expansionSettings.threshold = 1.0
        expansionSettings.expansionLayout = MGSwipeExpansionLayout.center
        expansionSettings.triggerAnimation.easingFunction = MGSwipeEasingFunction.cubicOut
        expansionSettings.fillOnTrigger = false
        
        let color = UIColor(red: 47/255.0, green: 47/255.0, blue: 49/255.0, alpha: 1.0)
        let font = UIFont(name: "HelveticaNeue-Light", size: 14.0)
        
        if direction == MGSwipeDirection.leftToRight {
            let upvote = MGSwipeButton(title: "upvote", backgroundColor: UIColor.lightGray, padding: 15, callback: { (sender) -> Bool in
                print("upvoted")
                return true
            })
            upvote.titleLabel?.font = font
            expansionSettings.expansionColor = UIColor(red: 47/255.0, green: 47/255.0, blue: 49/255.0, alpha: 1.0)
            
            return [upvote]
        } else {
            let downvote = MGSwipeButton(title: "downvote", backgroundColor: UIColor.lightGray, padding: 15, callback: { (sender) -> Bool in
                print("downvoted")
                return true
            })
            downvote.titleLabel?.font = font
            expansionSettings.expansionColor = UIColor.red
            return [downvote]
        }
        
        return nil
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = playListTable.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PlaylistTableCell
        cell.delegate = self
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        
        

    
        return cell
    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        
        
        
        
        
        
        
        return true
    }
    
    
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 120
    }
    
    
    
    func addCurve(startPoint: CGPoint, endPoint: CGPoint, controlPoint: CGPoint) {
        
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
    
    @IBAction func showPlaylist(_ sender: UISwipeGestureRecognizer) {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            
            self.jukeHeight.constant = self.view.bounds.size.height - 100
            
            self.playListTable.isHidden = false
            
            self.playListTable.heightAnchor.constraint(equalToConstant: 0).isActive = false

            self.view.layoutIfNeeded()
            
        }, completion: nil)
        
    }
    
    @IBAction func hidePlaylist(_ sender: UISwipeGestureRecognizer) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            
            self.jukeHeight.constant = self.originalHeight
            
            self.playListTable.isHidden = true

            self.view.layoutIfNeeded()
            
        }, completion: nil)
    }

}

//extension TableViewController : JukeBoxManagerDelegate {
//    
//    func connectedDevicesChanged(manager: JukeBoxManager, connectedDevices: [String]) {
//        OperationQueue.main.addOperation {
//            //self.connectionsLabel.text = "Connections: \(connectedDevices)"
//        }
//    }
//    
//    //MARK: NEW-----------
//    func newSong(manager: JukeBoxManager, song: Song) {
//        OperationQueue.main.addOperation {
//            self.trackArray.append(song)
//            //            self.player!.queueSpotifyURI(song.songURI, callback: nil)
//            
//        }
//    }
//}
//
//extension TableViewController: SongTimerProgressBarDelegate {
//    
//    func progressBarNeedsUpdate() {
//        self.updateProgressBar()
//    }
//    
//    func songDidEnd() {
//        playerIsActive = false
//        playbackButton.setButtonState(.pausing, animated: true)
//        trackArray.remove(at: 0)
//        songTitleLabel.text = trackArray[0].title
//        artistNameLabel.text = trackArray[0].artist
//        didTapPlaybackButton(self)
//    }
//    
//    func labelsNeedUpdate() {
//        durationLabel?.text = songTimer.timeString(time: TimeInterval(songTimer.timeRemaining))
//        timeElapsedLabel.text = songTimer.timeString(time: TimeInterval(songTimer.timeElapsed))
//    }
//}


