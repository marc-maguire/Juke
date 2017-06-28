//
//  TestViewController.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-06-16.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit
import MGSwipeTableCell
import PlaybackButton


class TestViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, MGSwipeTableCellDelegate, UITextFieldDelegate, DraggableViewDelegate {
    
    //MARK: - Properties
    
    var imageCache = [String:UIImage]() {
        willSet {
            if imageCache.count >= 100 {
                self.imageCache.removeAll()
            }
        }
    }
    var playlistImageCache = [String: UIImage]()
    
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession! {
        didSet {
            if  jukeBox.isPendingHost {
                initializePlayer(authSession: session)
            }
        }
    }
    var shouldShowCategories = true
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    var jukeBox: JukeBoxManager! {
        didSet{
            jukeBox.delegate = self
        }
    }
    var playerIsActive: Bool = false
    var isNewUser: Bool = true
    
    var songTimer = SongTimer()
    var manager = DataManager.shared()
    var playListTable: UITableView!
    
    //MARK: - Data Model Properties
    
    var currentlyPlayingSong: Song! {
        didSet {
            updateCurrentTrackInfo()
            albumImage.image = playlistImageCache[(currentlyPlayingSong.images[0]["url"]) as! String]
        }
    }
    var trackArray: [Song] = [] {
        didSet {
            playListTable.reloadData()
            if jukeBox.isHost {
                if !playerIsActive {
                    hostPlayNextSong()
                    playerIsActive = true
                }
            }
        }
    }
    var likedSongs: [Song] = []
    var filteredSongs = [Song]()
    var addMusicOptions = ["Playlists", "Recommendation", "Saved Music", "Recently Played"]
    var selectedSong: Song?
    
    
    //MARK: - Album Main View Image Properties
    @IBOutlet weak var jukeView: UIView!
    @IBOutlet weak var albumImage: DraggableView!
    @IBOutlet weak var jukeHeight: NSLayoutConstraint!
    var originalHeight: CGFloat!
    var expandedHeight: Bool!
    
    //MARK: - Currently Playing Song Views
    
    @IBOutlet weak var currentInfoWrapper: UIView!
    
    @IBOutlet weak var currentTrackLabel: UILabel!
    
    @IBOutlet weak var currentArtistLabel: UILabel!
    
    @IBOutlet weak var trackProgressView: UIProgressView!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var timeElapsedLabel: UILabel!
    
    @IBOutlet weak var playbackButton: PlaybackButton!
    
    //MARK: - Search View Wrapper and Results Table Properties
    
    var searchWrapper: UIView!
    var searchField: UITextField!
    var searchFieldWidth: NSLayoutConstraint!
    var searchFieldExpandedWidth: NSLayoutConstraint!
    var searchWrapperHeight: NSLayoutConstraint!
    var searchWrapperExpandedBottomAnchor: NSLayoutConstraint!
    var resultsTable: UITableView!
    var tapView: UIView!
    
    
    
    
    //MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupQuadCurve()
        
        
        originalHeight = jukeHeight.constant
        albumImage.layer.cornerRadius = 10
        songTimer.delegate = self
        albumImage.delegate = self
        labelsNeedUpdate()
        
        trackProgressView.progressTintColor = UIColor(red: 245.0/255, green: 255.0/255, blue: 141.0/255, alpha: 1.0)
        trackProgressView.layer.cornerRadius = 0
        trackProgressView.backgroundColor = UIColor.lightGray
        
        
        playlistTableSetup()
        searchWrapperSetup()
        
        
        
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if jukeBox.isPendingHost == true {
            
            
            self.showSearch()
            
        }
    }
    
    //MARK: - User Voting Methods
    
    func cardSwipedRight(card: UIView) {
        //don't need the card parameter if we can remove it
        //am I the host and if so have I already voted on the current song?
        if self.jukeBox.isHost {
            if currentlyPlayingSong.hasBeenVotedOnBy(peer: jukeBox.myPeerId.displayName) {
                return
            } else {
                currentlyPlayingSong.voters.append(jukeBox.myPeerId.displayName)
                //network call to add to hosts personal spotify
                manager.spotifySaveSongForCurrentUser(songURI: currentlyPlayingSong.songURI)
            }
        } else {
            if currentlyPlayingSong.hasBeenVotedOnBy(peer: jukeBox.myPeerId.displayName) {
            return

            } else {
                //network call to add to non hosts personal spotify
                manager.spotifySaveSongForCurrentUser(songURI: currentlyPlayingSong.songURI)
            }
        
        }
        print("upvoted")
        incrementCurrentSongLikes()
    }
    
    func cardSwipedLeft(card: UIView) {
        //don't need the card parameter if we can remove it
        
        if self.jukeBox.isHost {
            if currentlyPlayingSong.hasBeenVotedOnBy(peer: jukeBox.myPeerId.displayName) {
                return
            } else {
                currentlyPlayingSong.voters.append(jukeBox.myPeerId.displayName)
                
               
            }
        }
        print("downvoted")
        incrementCurrentSongDislikes()
    }
    
    func incrementCurrentSongLikes() {
        if  !jukeBox.isHost {
//            currentlyPlayingSong.likes += 1
////            need to check if song should be added to liked array
//            if currentlyPlayingSong.likes >= 2 {
//                //append to likedSongs as long as likedSongs does not already contain it
//                if !likedSongs.contains(currentlyPlayingSong) {
//                    likedSongs.append(currentlyPlayingSong)
//                    print("Adding \(currentlyPlayingSong.title) to liked songs")
//                    print("\(likedSongs)")
//                }
//            }
//            print("song likes up 1")
//        } else {
            //send increase song likes event and host calls this method
            let event = Event(songAction: .currentSongLiked, song: currentlyPlayingSong, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed, index: 0, playbackState: "Play", sender: jukeBox.myPeerId.displayName)
            let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
            jukeBox.send(event: newEvent as NSData)
            
        }
        
    }
    
    func incrementCurrentSongDislikes() {
        if  jukeBox.isHost {
            currentlyPlayingSong.dislikes += 1
            print("song dislikes up 1")
            songNeedsChanging()
        } else {
            //send increase song likes event and host calls this method
            let event = Event(songAction: .currentSongDisliked, song: currentlyPlayingSong, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed, index: 0, playbackState: "Play", sender: jukeBox.myPeerId.displayName)
            let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
            jukeBox.send(event: newEvent as NSData)
            
        }
    }
    
    func incrementLikesForSongAtIndex(index: Int) {
        if jukeBox.isHost {
            let song = trackArray[index]
            manager.spotifySaveSongForCurrentUser(songURI: song.songURI)
            
//            song.likes += 1
//            if song.likes >= 2 {
//                //append to likedSongs as long as likedSongs does not already contain it
//                if !likedSongs.contains(song) {
//                    likedSongs.append(song)
//                    print("Adding \(song.title) to liked songs")
//                    print("\(likedSongs)")
//                }
//            }
        } else {
            let song = trackArray[index]

        //network call for non host to add song to spotify saved songs
        manager.spotifySaveSongForCurrentUser(songURI: song.songURI)
        let event = Event(songAction: .queuedSongLiked, song: currentlyPlayingSong, totalSongTime: 0, timeRemaining: 0, timeElapsed: 0, index: index, playbackState: "Play", sender: jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox.send(event: newEvent as NSData)
        }
        
        
    }
    func incrementDislikesForSongAtIndex(index: Int) {
        if jukeBox.isHost {
            let song = trackArray[index]
            song.dislikes += 1
            if song.dislikes >= 2 {
                trackArray.remove(at: index)
                let event = Event(songAction: .removeQueuedSong, song: song, totalSongTime: 1, timeRemaining: 1, timeElapsed: 1, index: index, playbackState: "Play", sender: jukeBox.myPeerId.displayName)
                let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
                self.jukeBox.send(event: newEvent as NSData)
                
            }
        } else {
        let event = Event(songAction: .queuedSongDisliked, song: currentlyPlayingSong, totalSongTime: 0, timeRemaining: 0, timeElapsed: 0, index: index, playbackState: "Play", sender: jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox.send(event: newEvent as NSData)
        }
    }
    
    //MARK: - Song Player State Handling
    
    func songNeedsChanging() {
        if currentlyPlayingSong.dislikes >= 2 {
            hostPlayNextSong()
        }
    }
    
    
    func hostPlayNextSong() {
        
        //on first play, we do not want to remove the first song from the array
        
        guard let firstSong = trackArray.first else {
            print("No Song")
            //can handle no song in here
            return
        }
        
        songTimer.countDownTimer.invalidate()
        //ToDo - currentlyPlayingSong should only ever be fired once per user
        //look up dispatch once
        currentlyPlayingSong = firstSong
        trackArray.removeFirst()
        
        
        if trackArray.count == 0 {
            loadCurrentlyPlayingSongImage()
        }
        playListTable.reloadData()
        //play new song and adjust timers / button state
        self.player?.playSpotifyURI(currentlyPlayingSong.songURI, startingWith: 0, startingWithPosition: 0, callback: nil)
        songTimer.setMaxSongtime(milliseconds: Int(currentlyPlayingSong.duration))
        playbackButton.setButtonState(.playing, animated: false)
        //        view.layoutIfNeeded()
        
        //send new song event to connected peers
        let event = Event(songAction: .startNewSong, song: currentlyPlayingSong, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed, index: 0, playbackState: "Play", sender: jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox.send(event: newEvent as NSData)
        
        songTimer.startTimer()
        //won't update - is this getting called before the button is instantiated?
        
    }
    
    func nonHostPlayNextSongFrom(_ event: Event) {
        
        
        currentlyPlayingSong = event.song
        trackArray.removeFirst()
        
        playListTable.reloadData()
        
        
        songTimer.countDownTimer.invalidate()
        playbackButton.setButtonState(.playing, animated: true)
        updateTimersFrom(event)
        songTimer.startTimer()
        playerIsActive = true
        
        
    }
    
    func loadCurrentlyPlayingSongImage() {
        let song: Song = currentlyPlayingSong
        
        let imageURL = song.images[0]["url"] as! String
        
        // If this image is already cached, don't re-download
        if let img = playlistImageCache[imageURL] {
            albumImage.image = img
        }
        else {
            // The image isn't cached, download the img data on a background thread
            
            let url = URL(string: imageURL)
            let session = URLSession.shared
            let task = session.dataTask(with: url!, completionHandler: { (data, response, error) in
                if error == nil {
                    
                    let image = UIImage(data: data!)
                    // Store the image in our cache
                    self.playlistImageCache[imageURL] = image
                    // Update the cell
                    DispatchQueue.main.async(execute: {
                        self.albumImage.image = image
                    })
                }
                else {
                    print("Uh Oh")
                    
                }
                
            })
            task.resume()
        }
        
    }
    @IBAction func didTapPlaybackButton(_ sender: Any) {
        
        toggleHostPlayState()
        
    }
    
    func toggleHostPlayState() {
        
        if  jukeBox.isHost {
            
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
        
        guard let firstSong = currentlyPlayingSong else {
            print("No Song")
            //can handle no song in here
            return
        }
        
        let event = Event(songAction: .togglePlay, song: firstSong, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed, index: 0, playbackState: "Play", sender: jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox.send(event: newEvent as NSData)
        
    }
    
    func sendAddNewSongEvent(song: Song) {
        
        let event = Event(songAction: .addSong, song: song, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed, index: 0, playbackState: "Play", sender: jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox.send(event: newEvent as NSData)
    }
    
    func updateCurrentTrackInfo() {
        
        currentTrackLabel.text = currentlyPlayingSong.title
        currentArtistLabel.text = currentlyPlayingSong.artist
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
        
        
        //wrap all endpoint viewcontrollers where a song is selected in a protocol, add the object to a protocol and then cast the segue source to the protocol type.
        
        let unwindVC = segue.source as! Unwindable
        let unwindSong = unwindVC.unwindSong
        
        trackArray.append(unwindSong)
        print("adding new song")
        if  jukeBox.isPendingHost {
            jukeBox.isPendingHost = false
            jukeBox.isHost = true
            jukeBox.serviceBrowser.startBrowsingForPeers()
            print("browsing for peers")
            hideSearch()
            return
        }
        
        sendAddNewSongEvent(song: unwindSong)
        hideSearch()
    }
    
    func updateProgressBar(){
        trackProgressView.setProgress(Float(songTimer.timeElapsed) / songTimer.totalSongTime, animated: true)
    }
    
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
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        print("logged in")
        print("\(session.accessToken)")
        print("\(session.encryptedRefreshToken)")
        print("\(auth.clientID)")
    }
    
    //MARK: - MultiPeer Event Handling Methods
    
    func hostSendAllSongs() {
        //send all songs to new users
        for song in trackArray {
            let event = Event(songAction: .newUserSyncResponse, song: song, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed, index: 0, playbackState: "Play", sender: jukeBox.myPeerId.displayName)
            let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
            jukeBox.send(event: newEvent as NSData)
        }
    }
    
    func syncTimersForNewUser() {
        
        let currentState = playbackButton.buttonState
        var playbackState: String!
        
        if currentState == .playing {
            playbackState = "Play"
        } else if currentState == .pausing {
            playbackState = "Pause"
        } else {
            playbackState = "Play"
        }
        let event = Event(songAction: .newUserFinishedSyncing, song: currentlyPlayingSong, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed, index: 0, playbackState: playbackState, sender: jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox.send(event: newEvent as NSData)
        
    }
    
    func hostSendNewConnectionEvent() {
        
        let event = Event(songAction: .newConnectionDetected, song: currentlyPlayingSong, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed, index: 0, playbackState: "Play", sender: jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox.send(event: newEvent as NSData)
        
    }
    
    
    // MARK: - TextField Delegate Methods
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let txt = textField.text else { return true }
        let text = (txt as NSString).replacingCharacters(in: range, with: string) as String
        
        
        if text == "" {
            shouldShowCategories = true
            resultsTable.reloadData()
        } else {
            shouldShowCategories = false
            
            manager.spotifySearch(searchString: text) { (songs) in
                DispatchQueue.main.async {
                    self.filteredSongs = songs
                    self.resultsTable.reloadData()
                }
            }
        }
        
        return true
    }
    
    //MARK: - Programmatic View Setup and Methods
    
    func playlistTableSetup() {
        
        playListTable = UITableView()
        
        playListTable.dataSource = self
        playListTable.delegate = self
        
        let nib = UINib(nibName: "PlaylistTableCell", bundle: nil)
        playListTable.register(nib, forCellReuseIdentifier: "PlaylistCell")
        
        
        jukeView.addSubview(playListTable)
        
        playListTable.backgroundColor = jukeView.backgroundColor
        
        playListTable.translatesAutoresizingMaskIntoConstraints = false
        playListTable.widthAnchor.constraint(equalTo: jukeView.widthAnchor, multiplier: 1).isActive = true
        playListTable.centerXAnchor.constraint(equalTo: jukeView.centerXAnchor).isActive = true
        playListTable.bottomAnchor.constraint(equalTo: jukeView.bottomAnchor).isActive = true
        
        playListTable.topAnchor.constraint(equalTo: currentInfoWrapper.bottomAnchor).isActive = true
        
        playListTable.isHidden = true
        
    }
    
    func searchWrapperSetup() {
        searchWrapper = UIView()
        view.addSubview(searchWrapper)
        searchWrapper.backgroundColor = view.backgroundColor
        
        searchWrapper.translatesAutoresizingMaskIntoConstraints = false
        searchWrapper.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0, constant: 0).isActive = true
        searchWrapper.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        searchWrapper.topAnchor.constraint(equalTo: view.topAnchor, constant: 60).isActive = true
        searchWrapperHeight = searchWrapper.heightAnchor.constraint(equalToConstant: 40)
        searchWrapperHeight.isActive = true
        
        searchWrapperExpandedBottomAnchor = searchWrapper.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
        searchWrapperExpandedBottomAnchor.isActive = false
        
        searchField = UITextField()
        searchField.delegate = self
        searchWrapper.addSubview(searchField)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchFieldWidth = searchField.widthAnchor.constraint(equalTo: searchWrapper.widthAnchor, multiplier: 0.67, constant: 0)
        searchFieldWidth.isActive = true
        searchFieldExpandedWidth = searchField.widthAnchor.constraint(equalTo: self.searchWrapper.widthAnchor, multiplier: 0.90, constant: 0)
        searchFieldExpandedWidth.isActive = false
        
        let font = UIFont.systemFont(ofSize: 30, weight: UIFontWeightLight)
        
        searchField.textAlignment = .center
        searchField.adjustsFontSizeToFitWidth = true
        
        searchField.font = font
        searchField.textColor = UIColor(red: 50.0/255, green: 50.0/255, blue: 50.0/255, alpha: 1.0)
        searchField.tintColor = UIColor(red: 50.0/255, green: 50.0/255, blue: 50.0/255, alpha: 1.0)
        searchField.centerXAnchor.constraint(equalTo: searchWrapper.centerXAnchor).isActive = true
        searchField.topAnchor.constraint(equalTo: searchWrapper.topAnchor, constant: 0).isActive = true
        searchField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        searchField.attributedPlaceholder = NSAttributedString(string: "Search for a track")
        
        tapView = UIView()
        searchWrapper.addSubview(tapView)
        tapView.translatesAutoresizingMaskIntoConstraints = false
        tapView.widthAnchor.constraint(equalTo: searchField.widthAnchor, multiplier: 1.0, constant: 0).isActive = true
        tapView.centerXAnchor.constraint(equalTo: searchWrapper.centerXAnchor, constant: 0).isActive = true
        tapView.heightAnchor.constraint(equalTo: searchField.heightAnchor, multiplier: 1.0, constant: 0).isActive = true
        tapView.topAnchor.constraint(equalTo: searchField.topAnchor, constant: 0).isActive = true
        searchWrapper.bringSubview(toFront: tapView)
        let search = UITapGestureRecognizer(target: self, action: #selector(showSearch))
        tapView.addGestureRecognizer(search)
        
        
        //set up results TableView
        resultsTable = UITableView()
        resultsTable.dataSource = self
        resultsTable.delegate = self
        resultsTable.translatesAutoresizingMaskIntoConstraints = false
        resultsTable.isHidden = true
        
        
        
        let categoryNib = UINib(nibName: "SearchCategoryCell", bundle: nil)
        let trackNib = UINib(nibName: "SearchTrackCell", bundle: nil)
        
        resultsTable.register(categoryNib, forCellReuseIdentifier: "CategoryCell")
        
        resultsTable.register(trackNib, forCellReuseIdentifier: "TrackCell")
        
        searchWrapper.addSubview(resultsTable)
        resultsTable.backgroundColor = searchWrapper.backgroundColor
        
        resultsTable.widthAnchor.constraint(equalTo: searchWrapper.widthAnchor, multiplier: 1.0, constant: 0).isActive = true
        
        resultsTable.centerXAnchor.constraint(equalTo: searchWrapper.centerXAnchor).isActive = true
        resultsTable.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 0).isActive = true
        resultsTable.bottomAnchor.constraint(equalTo: searchWrapper.bottomAnchor, constant: 0).isActive = true
        
    }
    
    func showSearch() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear, animations: {
            //self.view.removeGestureRecognizer(self.keyboardDismiss)
            self.shouldShowCategories = true
            self.view.bringSubview(toFront: self.searchWrapper)
            self.searchWrapper.sendSubview(toBack: self.tapView)
            self.tapView.isUserInteractionEnabled = false
            self.searchFieldWidth.isActive = false
            self.searchFieldExpandedWidth.isActive = true
            self.searchField.textAlignment = .left
            
            self.searchWrapperHeight.isActive = false
            self.searchWrapperExpandedBottomAnchor.isActive = true
            
            self.resultsTable.isHidden = false
            self.updateViewConstraints()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func hideSearch() {
        
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear, animations: {
            self.view.sendSubview(toBack: self.searchWrapper)
            self.searchWrapper.bringSubview(toFront: self.tapView)
            self.tapView.isUserInteractionEnabled = true
            self.searchFieldExpandedWidth.isActive = false
            self.searchFieldWidth.isActive = true
            self.searchField.textAlignment = .center
            
            self.searchWrapperExpandedBottomAnchor.isActive = false
            self.searchWrapperHeight.isActive = true
            self.shouldShowCategories = true
            self.searchField.text = ""
            self.resultsTable.reloadData()
            self.resultsTable.isHidden = true
            self.updateViewConstraints()
            self.view.endEditing(true)
            self.view.layoutIfNeeded()
        }, completion: { (true) in
            self.filteredSongs = []
            self.selectedSong = nil
        })
        
    }
    
    
    
    
    
    //MARK: - TableView DataSource and Delegate Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch tableView {
        case resultsTable:
            if shouldShowCategories {
                return addMusicOptions.count
            } else {
                return filteredSongs.count
            }
        case playListTable:
            return trackArray.count
        default:
            break
        }
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch tableView {
        case resultsTable:
            
            
            if shouldShowCategories {
                resultsTable.isScrollEnabled = false
                let cell = resultsTable.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! SearchCategoryCell
                
                cell.categoryNameLabel.text = addMusicOptions[indexPath.row]
                cell.backgroundColor = resultsTable.backgroundColor
                
                
                return cell
            } else {
                resultsTable.isScrollEnabled = true
                //put it in here
                //watch out for cache size
                let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! SearchTrackCell
                let song: Song = filteredSongs[indexPath.row]
                
                cell.trackNameLabel.text = filteredSongs[indexPath.row].title
                cell.trackArtistLabel.text = filteredSongs[indexPath.row].artist
                if filteredSongs[indexPath.row].isExplicit {
                    cell.explicitMarkerImage.image = #imageLiteral(resourceName: "explicit-grey")
                } else {
                    cell.explicitMarkerImage.image = #imageLiteral(resourceName: "placeholder-rect")
                }
                cell.trackAlbumImage.image = #imageLiteral(resourceName: "placeholder-rect")
                cell.backgroundColor = resultsTable.backgroundColor
                let imageURL = song.images[1]["url"] as! String
                
                // If this image is already cached, don't re-download
                if let img = imageCache[imageURL] {
                    cell.trackAlbumImage.image = img
                }
                else {
                    // The image isn't cached, download the img data
                    // We should perform this in a background thread
                    let url = URL(string: imageURL)
                    //let request = NSURLRequest(url: url!)
                    let session = URLSession.shared
                    
                    
                    let task = session.dataTask(with: url!, completionHandler: { (data, response, error) in
                        if error == nil {
                            
                            let image = UIImage(data: data!)
                            // Store the image in to our cache
                            self.imageCache[imageURL] = image
                            // Update the cell
                            DispatchQueue.main.async(execute: {
                                cell.trackAlbumImage.image = image
                            })
                        }
                        else {
                            print("Uh Oh")
                            
                        }
                        
                    })
                    task.resume()
                }
                return cell
                
            }
        case playListTable:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as! PlaylistTableCell
            let song: Song = trackArray[indexPath.row]
            
            cell.delegate = self
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            
            cell.trackNameLabel.text = song.title
            cell.trackArtistLabel.text = song.artist
            //put it in here
            //watch out for cache size
            
            if song.isExplicit {
                cell.explicitMarkerImage.image = #imageLiteral(resourceName: "explicit-grey")
            } else {
                cell.explicitMarkerImage.image = #imageLiteral(resourceName: "placeholder-rect")
            }
            cell.trackAlbumImage.image = #imageLiteral(resourceName: "placeholder-rect")
            cell.backgroundColor = playListTable.backgroundColor
            let imageURL = song.images[0]["url"] as! String
            
            // If this image is already cached, don't re-download
            if let img = playlistImageCache[imageURL] {
                cell.trackAlbumImage.image = img
            }
            else {
                // The image isn't cached, download the img data
                // We should perform this in a background thread
                let url = URL(string: imageURL)
                //let request = NSURLRequest(url: url!)
                let session = URLSession.shared
                
                
                let task = session.dataTask(with: url!, completionHandler: { (data, response, error) in
                    if error == nil {
                        
                        let image = UIImage(data: data!)
                        // Store the image in to our cache
                        self.playlistImageCache[imageURL] = image
                        // Update the cell
                        DispatchQueue.main.async(execute: {
                            cell.trackAlbumImage.image = image
                        })
                    }
                    else {
                        print("Uh Oh")
                        
                    }
                    
                })
                task.resume()
            }
            return cell
            
        default:
            break
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        switch tableView {
        case resultsTable:
            
            if shouldShowCategories {
                
                switch indexPath.row {
                case 0:
                    performSegue(withIdentifier: "playlist", sender: self)
                case 1:
                    performSegue(withIdentifier: "playlist", sender: self) //update this to recommendation
                case 2:
                    performSegue(withIdentifier: "playlist", sender: self) //update this to saved music
                case 3:
                    performSegue(withIdentifier: "playlist", sender: self) //Recently Played
                default:
                    return
                }
                
            } else {
                
                selectedSong = filteredSongs[indexPath.row]
                
                guard let selectedTrack = selectedSong else {
                    print("error, no track")
                    return
                }
                
                trackArray.append(selectedTrack)
                
                if  jukeBox.isPendingHost {
                    jukeBox.isPendingHost = false
                    jukeBox.isHost = true
                    jukeBox.serviceBrowser.startBrowsingForPeers()
                    hideSearch()
                    return
                }
                
                sendAddNewSongEvent(song: selectedTrack)
                hideSearch()
                
                
            }
            
        case playListTable:
            return
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        
        switch tableView {
        
        case resultsTable:
            
            if shouldShowCategories {
                return 90
            } else {
                return 70
            }
            
        case playListTable:

            return 90
            
        default:
            return 90
        }
    }
    
    //MARK: - MGSwipeTableCell Methods
    
    func swipeTableCell(_ cell: MGSwipeTableCell, swipeButtonsFor direction: MGSwipeDirection, swipeSettings: MGSwipeSettings, expansionSettings: MGSwipeExpansionSettings) -> [UIView]? {
        swipeSettings.transition = MGSwipeTransition.clipCenter
        swipeSettings.keepButtonsSwiped = false
        expansionSettings.buttonIndex = 0
        expansionSettings.threshold = 1.0
        expansionSettings.expansionLayout = MGSwipeExpansionLayout.center
        expansionSettings.triggerAnimation.easingFunction = MGSwipeEasingFunction.cubicOut
        expansionSettings.fillOnTrigger = false
        
        //let color = UIColor(red: 47/255.0, green: 47/255.0, blue: 49/255.0, alpha: 1.0)
        let font = UIFont(name: "HelveticaNeue-Light", size: 14)
        
        if direction == MGSwipeDirection.leftToRight {
            
            // reported issue of possible retain cycle in MGSwipeButton callback. Use [unowned self] if problem arises
            
            let upvote = MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "heart2"), backgroundColor: UIColor.init(red: 254.0/255, green: 46.0/255, blue: 83.0/255, alpha: 0), padding: 15, callback: { (sender) -> Bool in
                guard let index = self.playListTable.indexPath(for: cell) else {
                    print("could not get indexduring upvote")
                    return true
                }
                //send upvoted event
                if self.jukeBox.isHost {
                    let song: Song = self.trackArray[Int(index.row)]
                    if song.hasBeenVotedOnBy(peer: self.jukeBox.myPeerId.displayName) {
                        
                    } else {
                        song.voters.append(self.jukeBox.myPeerId.displayName)
                        self.incrementLikesForSongAtIndex(index: Int(index.row))
                    }
                } else {
                    self.incrementLikesForSongAtIndex(index: Int(index.row))
                }
                
                print("upvoted")
                
                return true
            })
            
            if cell.swipeState == .swipingLeftToRight {
                upvote.iconTintColor(UIColor.white)
            }
            
            //upvote.titleLabel?.font = font
            //expansionSettings.expansionColor = UIColor.init(red: 254.0/255, green: 46.0/255, blue: 83.0/255, alpha: 1.0)
            
            
            return [upvote]
        } else {
            let downvote = MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "dislikeHeart"), backgroundColor: UIColor(red: 47/255.0, green: 47/255.0, blue: 49/255.0, alpha: 0), padding: 15, callback: { (sender) -> Bool in
                
                guard let index = self.playListTable.indexPath(for: cell) else {
                    print("could not get index during downvote")
                    return true
                }
                //send downvotequeuedSong event
                if self.jukeBox.isHost {
                    let song: Song = self.trackArray[Int(index.row)]
                    if song.hasBeenVotedOnBy(peer: self.jukeBox.myPeerId.displayName) {
                        return true
                    } else {
                        song.voters.append(self.jukeBox.myPeerId.displayName)
//                        self.incrementDislikesForSongAtIndex(index: Int(index.row))
                    }
                }

                
                self.incrementDislikesForSongAtIndex(index: Int(index.row))
                
                print("downvoted")
                return true
            })
            downvote.titleLabel?.font = font
            //expansionSettings.expansionColor = UIColor(red: 47/255.0, green: 47/255.0, blue: 49/255.0, alpha: 0)
            return [downvote]
        }
        
        return nil
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == resultsTable {
            searchField.resignFirstResponder()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == resultsTable {
            searchField.resignFirstResponder()
        }
    }
    
    //MARK: - Quad Curve Methods
    
    func setupQuadCurve() {
        // At some point, will make jukeView a custom UIView Class that will initialize a quadcurve upon setup and attach gesture capabilties
        
        let p1 = CGPoint(x: jukeView.bounds.origin.x, y: jukeView.bounds.origin.y + 2)
        let p2 = CGPoint(x: jukeView.bounds.width, y: jukeView.bounds.origin.y + 2)
        let controlP = CGPoint(x: jukeView.bounds.width / 2, y: jukeView.bounds.origin.y - 120)
        addCurve(startPoint: p1, endPoint: p2, controlPoint: controlP)
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
            
            self.view.bringSubview(toFront: self.jukeView)
            
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

//MARK: - Extensions

extension UIViewController {
    //still needed?
    func hideKeyboard() {
        self.view.endEditing(true)
    }
}

extension TestViewController : JukeBoxManagerDelegate {
    
    func connectedDevicesChanged(manager: JukeBoxManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            //this is called once a new connection has been established
            //now we should send the event
            if  self.jukeBox.isHost{
                self.hostSendNewConnectionEvent()
                print("connect to \(connectedDevices)")
            }
            
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
                    self.currentlyPlayingSong = event.song
                    self.playListTable.reloadData()
                    self.updateTimersFrom(event)
                    //need to know play state
                    if event.playbackState == "Play" {
                        self.songTimer.startTimer()
                        self.playbackButton.setButtonState(.playing, animated: true)
                    } else {
                        self.playbackButton.setButtonState(.pausing, animated: true)
                        self.songTimer.startTimer()
                        self.labelsNeedUpdate()
                        self.songTimer.pauseTimer()
                    }
                    //                    self.togglePlayButtonState()
                    self.playerIsActive = true
                    print("sync request sync should finish")
                    self.isNewUser = false
                    self.loadCurrentlyPlayingSongImage()
                    
                }
                
            case .newUserSyncRequest:
                if  self.jukeBox.isHost {
                    self.hostSendAllSongs()
                    self.syncTimersForNewUser()
                    print("sync request received")
                }
                
            case .newConnectionDetected:
                if self.isNewUser {
                    let song = Song(withDefaultString: "empty")
                    let event = Event(songAction: .newUserSyncRequest, song: song, totalSongTime: 1, timeRemaining: 1, timeElapsed: 1, index: 0, playbackState: "Play", sender: self.jukeBox.myPeerId.displayName)
                    let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
                    self.jukeBox.send(event: newEvent as NSData)
                    print("sync request sent")
                    
                }
            case .currentSongLiked:
                if  self.jukeBox.isHost {
                    if self.currentlyPlayingSong.hasBeenVotedOnBy(peer: event.sender) {
                        print("you only get one vote")
                        return
                    } else {
                      self.currentlyPlayingSong.voters.append(event.sender)
                      self.incrementCurrentSongLikes()
                    }
                    
                }
                
            case .currentSongDisliked:
                if  self.jukeBox.isHost {
                    if self.self.currentlyPlayingSong.hasBeenVotedOnBy(peer: event.sender) {
                        print("you only get one vote")
                        return
                    } else {
                    self.currentlyPlayingSong.voters.append(event.sender)
                    self.incrementCurrentSongDislikes()
                    }
                }
            case .queuedSongLiked:
                let song: Song = self.trackArray[event.index]
                if song.hasBeenVotedOnBy(peer: event.sender) {
                    print("you only get one vote")
                    return
                } else {
                song.voters.append(event.sender)
                self.incrementLikesForSongAtIndex(index: event.index)
                }
            case .queuedSongDisliked:
                let song: Song = self.trackArray[event.index]
                if song.hasBeenVotedOnBy(peer: event.sender) {
                    print("you only get one vote")
                    return
                } else {
                song.voters.append(event.sender)
                self.incrementDislikesForSongAtIndex(index: event.index)
                }
                //                if self.jukeBox.isHost {
                //                    let song: Song = self.trackArray[event.index]
                //                    song.dislikes += 1
                //                    //check if song should be removed
                //                    if song.dislikes == 2 {
                //                        //host removes from array
                //                        self.trackArray.remove(at: event.index)
                //                        //if removed, send remove song event to guests
                //                        let event = Event(songAction: .removeQueuedSong, song: song, totalSongTime: 1, timeRemaining: 1, timeElapsed: 1, index: event.index, playbackState: "Play")
                //                        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
                //                        self.jukeBox.send(event: newEvent as NSData)
                //
                //                    }
            //                }
            case .removeQueuedSong:
                //host removes song before sending event, only non hosts should remove song here
                if !self.jukeBox.isHost {
                    self.trackArray.remove(at: event.index)
                }
            }
            
        }
    }
    
}

extension TestViewController: SongTimerDelegate {
    
    func progressBarNeedsUpdate() {
        self.updateProgressBar()
    }
    
    func songDidEnd() {
        if  jukeBox.isHost {
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
