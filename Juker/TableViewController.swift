//
//  TableViewController.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-13.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit
import PlaybackButton

class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
    //MARK: IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    //shows as zero before it is set (need to set it when we are transitioning)
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var songProgressBar: UIProgressView!
    @IBOutlet weak var playbackButton: PlaybackButton!
    
    @IBOutlet weak var albumArtImageView: UIImageView!
    
    
    //MARK: Properties
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession! {
        didSet {
            if (jukeBox?.isPendingHost)! {
            initializePlayer(authSession: session)
            }
        }
    }
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    //var manager = DataManager.shared()
    var jukeBox: JukeBoxManager? {
        didSet{
            jukeBox?.delegate = self
        }
    }
    var playerIsActive: Bool = false
    var isNewUser: Bool = true
    
    var songTimer = SongTimer()
    var trackArray: [Song] = [] {
        didSet {
            tableView.reloadData()
            updateCurrentTrackInfo()
            if (jukeBox?.isHost)! {
                if !playerIsActive {
                    hostPlayNextSong()
                    playerIsActive = true
                }
            }
//            print("\(trackArray[0].isExplicit)")
            //need to fetch album art
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        songTimer.delegate = self
        labelsNeedUpdate()
//        setup()
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
        
    
        //        self.playbackButton.layer.cornerRadius = self.playbackButton.frame.size.height / 2
        //        self.playbackButton.layer.borderWidth = 2.0
        self.playbackButton.adjustMargin = 1
        self.playbackButton.duration = 0.3 // animation duration default 0.24
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
//        jukeBox?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
//        jukeBox?.delegate = self
        if jukeBox?.isPendingHost == true {
            performSegue(withIdentifier: "addMusicSegue", sender: self)
    }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
            if self.isNewUser {
            //this is where the connection issue is, if we sleep, it pauses the app and doesn't connect
            //send event to host to notify them
            let song = Song(withDefaultString: "empty")
            let event = Event(songAction: .newUserSyncRequest, song: song, totalSongTime: 1, timeRemaining: 1, timeElapsed: 1)
            let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
            self.jukeBox?.send(event: newEvent as NSData)
            print("sync request sent")
        }
        })

            }
    

    
    //MARK: Song changing logic
    
    func hostPlayNextSong() {
        
        //on first play, we do not want to remove the first song from the array
        
        if playerIsActive {
            trackArray.removeFirst()
        }
        
        guard let firstSong = trackArray.first else {
            print("No Song")
            //can handle no song in here
            return
        }
        
        //play new song and adjust timers / button state
        self.player?.playSpotifyURI(firstSong.songURI, startingWith: 0, startingWithPosition: 0, callback: nil)
        songTimer.setMaxSongtime(milliseconds: Int(firstSong.duration))
        playbackButton.setButtonState(.playing, animated: false)
        //        view.layoutIfNeeded()
        
        //send new song event to connected peers
        let event = Event(songAction: .startNewSong, song: trackArray[0], totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox?.send(event: newEvent as NSData)
        
        songTimer.startTimer()
        //won't update - is this getting called before the button is instantiated?
  
    }
    
    func nonHostPlayNextSongFrom(_ event: Event) {
        
        //on first play, we do not want to remove the first song from the array
        if playerIsActive {
            trackArray.removeFirst()
        }
        
        songTimer.countDownTimer.invalidate()
        playbackButton.setButtonState(.playing, animated: true)
        updateTimersFrom(event)
        songTimer.startTimer()
        playerIsActive = true
        
        
    }
    @IBAction func didTapPlaybackButton(_ sender: Any) {
        
        toggleHostPlayState()
        
    }
    
    func toggleHostPlayState() {
        
        if (jukeBox?.isHost)! {
            
            if self.playbackButton.buttonState == .playing {
                
                pausePlayback()
                
            } else {
                
                resumePlayback()
                
            }
            //regardless of host state, we send a toggle event to all users to have them change state
            sendTogglePlayEvent()

        }
    }
    
    func pausePlayback() {
        self.player?.setIsPlaying(false, callback: nil)
        self.playbackButton.setButtonState(.pausing, animated: true)
        songTimer.pauseTimer()
        
    }
    
    func resumePlayback() {
        self.player?.setIsPlaying(true, callback: nil)
        self.playbackButton.setButtonState(.playing, animated: true)
        songTimer.pauseTimer()
        
    }
    
    func sendTogglePlayEvent() {
        
        guard let firstSong = trackArray.first else {
            print("No Song")
            //can handle no song in here
            return
        }
        
        let event = Event(songAction: .togglePlay, song: firstSong, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox?.send(event: newEvent as NSData)
        
    }
    
    func sendAddNewSongEvent(song: Song) {
        
        let event = Event(songAction: .addSong, song: song, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox?.send(event: newEvent as NSData)
    }
    
    func updateCurrentTrackInfo() {
        songTitleLabel.text = trackArray[0].title
        artistNameLabel.text = trackArray[0].artist
        //album art =
        //isExplicit =
        
    }
    
    func updateTimersFrom(_ event: Event) {
        self.songTimer.totalSongTime = Float(event.totalSongTime)
        self.songTimer.timeRemaining = event.timeRemaining
        self.songTimer.timeElapsed = event.timeElapsed
    }

    
    func togglePlayButtonState() {
        if self.playbackButton.buttonState == .pausing {
            self.playbackButton.setButtonState(.playing, animated: true)
        } else {
            self.playbackButton.setButtonState(.pausing, animated: true)
        }
    }
    
    // MARK: - Navigation
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue){
        
        if segue.identifier == "first" {
            //wrap both viewcontrollers in a protocol, add the object to a protocol and then cast the segue source to the protocol type. Figure out how ot make it a computed property, make a second selectedSong that reaches into this
            
            let initialVC = segue.source as! SongViewController
            guard let newSong = initialVC.selectedSong else {
                print("no song returned")
                return
            }
            jukeBox?.isHost = true
            trackArray.append(newSong)
            print("adding new song")
            if (jukeBox?.isPendingHost)! {
                jukeBox?.isPendingHost = false
                //PROBLEM SPOT 2
                jukeBox?.serviceBrowser.startBrowsingForPeers()
                print("browsing for peers")
                return
            }
            
            sendAddNewSongEvent(song: newSong)
            
        } else if segue.identifier == "newSearchSong" {
            
            let initialVC = segue.source as! AddMusicViewController
            guard let newSong = initialVC.selectedSong else {
                print("no song returned")
                return
            }
            trackArray.append(newSong)
            if (jukeBox?.isPendingHost)! {
                jukeBox?.isHost = true
                jukeBox?.isPendingHost = false
                //PROBLEM SPOT 2.1
                jukeBox?.serviceBrowser.startBrowsingForPeers()
                return
            }
            sendAddNewSongEvent(song: newSong)
        }
    }
    
    func updateProgressBar(){
        songProgressBar.progressTintColor = UIColor.blue
        songProgressBar.setProgress(Float(songTimer.timeElapsed) / songTimer.totalSongTime, animated: true)
        songProgressBar.layoutIfNeeded()
    }
    
    //MARK: TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! JukeTableViewCell
        cell.textLabel?.text = trackArray[indexPath.row].title
        
        return cell
        
    }
    
    //MARK: Spotify Authentication
    
    func setup() {
        auth.clientID = ConfigCreds.clientID
        auth.redirectURL = URL(string: ConfigCreds.redirectURLString)
        
        
        //REMEMBER TO ADD BACK SCOPES
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope,SPTAuthUserFollowReadScope,SPTAuthUserLibraryReadScope,SPTAuthUserReadPrivateScope,SPTAuthUserReadTopScope,SPTAuthUserReadBirthDateScope,SPTAuthUserReadEmailScope]
        
        loginUrl = auth.spotifyWebAuthenticationURL()
        
    }
    @IBAction func loginPressed(_ sender: UIButton) {
        
        UIApplication.shared.open(loginUrl!, options: [:]) { (didFinish) in
            if didFinish {
                if self.auth.canHandle(self.auth.redirectURL) {
                    //build in error handling
                }
                
            }
        }
    }
    
    func updateAfterFirstLogin () {
        if let sessionObj:Any = UserDefaults.standard.object(forKey: "SpotifySession") as Any? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            initializePlayer(authSession: session)
        }
    }
    
    //MARK: Audio Player Methods
    
    func initializePlayer(authSession:SPTSession){
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player!.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken!)
            
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceive event: SpPlaybackEvent) {
        
    }
    
//    @IBAction func playSong(_ sender: UIButton) {
//        self.player!.playSpotifyURI(self.trackArray.first?.songURI, startingWith: 0, startingWithPosition: 0, callback: { (error) in
//            if (error != nil) {
//                print("playing!")
//            }
//            
//            print(error ?? "no error")
//        })
//        
//    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        print("logged in")
        print("\(session.accessToken)")
        
        print("\(session.encryptedRefreshToken)")
        print("\(auth.clientID)")
    }
    
    func hostSendAllSongs() {
        //send all songs to new users
        for song in trackArray {
            let event = Event(songAction: .newUserSyncResponse, song: song, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
            let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
            jukeBox?.send(event: newEvent as NSData)
        }
    }
    
    func syncTimersForNewUser() {
        let event = Event(songAction: .newUserFinishedSyncing, song: trackArray[0], totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox?.send(event: newEvent as NSData)
    }
    
}

//MARK: JukeboxManagerDelegate Methods

extension TableViewController : JukeBoxManagerDelegate {
    
    func connectedDevicesChanged(manager: JukeBoxManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            print("connect to \(connectedDevices)")
            
            //PROBLEM SPOT ONE
            //if host, send all songs
//            if (self.jukeBox?.isHost)! {
//               self.hostSendAllSongs()
//                self.syncTimersForNewUser()
//                
//            }
            //self.connectionsLabel.text = "Connections: \(connectedDevices)"
        }
    }
    
    func newEvent(manager: JukeBoxManager, event: Event) {
        OperationQueue.main.addOperation {
            switch event.songAction {
            case .addSong:
                print("add song")
                self.trackArray.append(event.song)
            case .removeSong:
                print("remove Song")
            case .togglePlay:
                print("toggle play")
                
                self.updateTimersFrom(event)
                self.songTimer.pauseTimer()
                self.togglePlayButtonState()
                
            case .startNewSong:
                
                self.nonHostPlayNextSongFrom(event)
            case .newUserSyncResponse:
                if self.isNewUser {
                    self.trackArray.append(event.song)
                    
                }
                print("sync data sent by host to new user")
            case .newUserFinishedSyncing:
                if self.isNewUser {
                self.updateTimersFrom(event)
                self.songTimer.startTimer()
                self.togglePlayButtonState()
                    self.playerIsActive = true
//                self.nonHostPlayNextSongFrom(event)
                    print("sync request sync should finish")
//                self.isNewUser = false
//                    self.tableView.reloadData()
                }
            case .newUserSyncRequest:
                if (self.jukeBox?.isHost)! {
                    self.hostSendAllSongs()
                    self.syncTimersForNewUser()
                    print("sync request received")
                    
                }
            }
           
        }
    }
    
}

//MARK: SongtimerProgressBarDelegate Methods

extension TableViewController: SongTimerDelegate {
    
    func progressBarNeedsUpdate() {
        self.updateProgressBar()
    }
    
    func songDidEnd() {
        
        if (jukeBox?.isHost)! {
            hostPlayNextSong()
        }
    }
    
    func labelsNeedUpdate() {
        durationLabel?.text = songTimer.timeString(time: TimeInterval(songTimer.timeRemaining))
        timeElapsedLabel.text = songTimer.timeString(time: TimeInterval(songTimer.timeElapsed))
    }
    func syncResumeTapped(resumeTapped: Bool) {
        self.songTimer.resumeTapped = resumeTapped
    }
}



