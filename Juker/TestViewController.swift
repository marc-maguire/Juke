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
    
    private var imageCache = [String:UIImage]() {
        willSet {
            if imageCache.count >= 100 {
                self.imageCache.removeAll()
            }
        }
    }
    private var playlistImageCache = [String: UIImage]()
    
    private var auth = SPTAuth.defaultInstance()!
    var session:SPTSession! {
        didSet {
            if  jukeBox.isPendingHost {
                initializePlayer(authSession: session)
            }
        }
    }
    var shouldShowCategories = true
    private var player: SPTAudioStreamingController?
    private var loginUrl: URL?
    var jukeBox: JukeBoxManager! {
        didSet{
            jukeBox.delegate = self
        }
    }
//    fileprivate var playerIsActive: Bool = false
	var isNewUser: Bool = true
    
    fileprivate var songTimer = SongTimer()
    private var manager = DataManager.shared()
	fileprivate var playListTable: UITableView! {
		didSet {
			self.playListTable.dataSource = self
			self.playListTable.delegate = self
		}
	}
    
    //MARK: - Data Model Properties
    
    fileprivate var currentlyPlayingSong: Song! {
        didSet {
            updateCurrentTrackInfo()
			self.loadCurrentlyPlayingSongImage()
        }
    }
    fileprivate var trackArray: [Song] = [] {
        didSet {
            playListTable.reloadData()
			let _ = self.startParty
        }
    }
	private lazy var startParty = {
		if self.jukeBox.isHost {
			self.playNextSong()
		}
	}()
    private var likedSongs: [Song] = []
    private var filteredSongs = [Song]()
    private var addMusicOptions = ["Playlists", "Recommendation", "Saved Music", "Recently Played"]
    private var selectedSong: Song?
    
    
    //MARK: - Album Main View Image Properties
    @IBOutlet weak private var jukeView: UIView!
    @IBOutlet weak private var albumImage: DraggableView!
    @IBOutlet weak private var jukeHeight: NSLayoutConstraint!
    private var originalHeight: CGFloat!
    private var expandedHeight: Bool!
    
    //MARK: - Currently Playing Song Views
    
    @IBOutlet weak private var currentInfoWrapper: UIView!
    @IBOutlet weak private var currentTrackLabel: UILabel!
    @IBOutlet weak private var currentArtistLabel: UILabel!
    @IBOutlet weak private var trackProgressView: UIProgressView!
    @IBOutlet weak fileprivate var durationLabel: UILabel!
    @IBOutlet weak fileprivate var timeElapsedLabel: UILabel!
    @IBOutlet weak fileprivate var playbackButton: PlaybackButton!
    
    //MARK: - Search View Wrapper and Results Table Properties
    
    private var searchWrapper: UIView!
    private var searchField: UITextField!
    private var searchFieldWidth: NSLayoutConstraint!
    private var searchFieldExpandedWidth: NSLayoutConstraint!
    private var searchWrapperHeight: NSLayoutConstraint!
    private var searchWrapperExpandedBottomAnchor: NSLayoutConstraint!
    private var resultsTable: UITableView!
    private var tapView: UIView!
    
    
    
    
    //MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
        self.setupQuadCurve()
        self.originalHeight = jukeHeight.constant
        self.albumImage.layer.cornerRadius = 10
        self.songTimer.delegate = self
        self.albumImage.delegate = self
        self.labelsNeedUpdate()
        
        self.trackProgressView.progressTintColor = UIColor(red: 245.0/255, green: 255.0/255, blue: 141.0/255, alpha: 1.0)
        self.trackProgressView.layer.cornerRadius = 0
        self.trackProgressView.backgroundColor = UIColor.lightGray
		
        self.playlistTableSetup()
        self.searchWrapperSetup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
		//move this to view did load?
        if self.jukeBox.isPendingHost == true {
            self.showSearch()
        }
    }
    
    //MARK: - User Voting Methods
	
	func cardSwipedRight(card: UIView) {
		self.handleLikeAction()
	}
	
	private func handleLikeAction() {
		guard !self.currentlyPlayingSong.hasBeenVotedOnBy(peer: jukeBox.myPeerId.displayName) else { return }
		
		self.currentlyPlayingSong.voters.append(jukeBox.myPeerId.displayName)
		//network call to add to hosts personal spotify
		self.manager.spotifySaveSongForCurrentUser(songURI: currentlyPlayingSong.songURI)
		let event = Event(songAction: .currentSongLiked, song: self.currentlyPlayingSong, totalSongTime: Int(self.songTimer.totalSongTime), timeRemaining: self.songTimer.timeRemaining, timeElapsed: self.songTimer.timeElapsed, index: 0, playbackState: "Play", sender: self.jukeBox.myPeerId.displayName)
		let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
		self.jukeBox.send(event: newEvent as NSData)
	}
	
	fileprivate func handleLikeEvent() {
		self.currentlyPlayingSong.likes += 1
	}
	

    
    func cardSwipedLeft(card: UIView) {
		self.handleDislikeAction()
	}
	
	private func handleDislikeAction() {
		guard !currentlyPlayingSong.hasBeenVotedOnBy(peer: jukeBox.myPeerId.displayName) else { return }
		
		self.currentlyPlayingSong.voters.append(jukeBox.myPeerId.displayName)
		
		print("downvoted")
		self.incrementCurrentSongDislikes()
		if !self.songNeedsChanging() {
			let event = Event(songAction: .currentSongDisliked, song: self.currentlyPlayingSong, totalSongTime: Int(self.songTimer.totalSongTime), timeRemaining: self.songTimer.timeRemaining, timeElapsed: self.songTimer.timeElapsed, index: 0, playbackState: "Play", sender: self.jukeBox.myPeerId.displayName)
			let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
			self.jukeBox.send(event: newEvent as NSData)
		}
	}
	
	fileprivate func handleDislikeEvent() {
		self.incrementCurrentSongDislikes()
	}
	
	private func incrementCurrentSongDislikes() {
		self.currentlyPlayingSong.dislikes += 1
	}
	
	fileprivate func handleIncrementLikesForSongAtIndexEvent(index: Int) {
		
		let song = trackArray[index]
		song.voters.append(self.jukeBox.myPeerId.displayName)
		song.likes += 1
		self.manager.spotifySaveSongForCurrentUser(songURI: song.songURI)
	}
	
	private func sendIncrementSongLikesAtIndexEvent(index: Int) {
		let event = Event(songAction: .queuedSongLiked, song: self.currentlyPlayingSong, totalSongTime: 0, timeRemaining: 0, timeElapsed: 0, index: index, playbackState: "Play", sender: self.jukeBox.myPeerId.displayName)
		let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
		self.jukeBox.send(event: newEvent as NSData)
	}
	
	fileprivate func handleIncrementDislikesForSongAtIndexEvent(index: Int) {
		let song = self.trackArray[index]
		song.dislikes += 1
	}
	
	private func sendDecrementOrRemoveAtIndexEvent(index: Int) {
		
		let song = trackArray[index]
		//this will eventually be set to 51% of participants but is at 2 for testing
		if song.dislikes >= 2 {
			self.trackArray.remove(at: index)
			let event = Event(songAction: .removeQueuedSong, song: song, totalSongTime: 1, timeRemaining: 1, timeElapsed: 1, index: index, playbackState: "Play", sender: self.jukeBox.myPeerId.displayName)
			let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
			self.jukeBox.send(event: newEvent as NSData)
		} else {
			let event = Event(songAction: .queuedSongDisliked, song: self.currentlyPlayingSong, totalSongTime: 0, timeRemaining: 0, timeElapsed: 0, index: index, playbackState: "Play", sender: self.jukeBox.myPeerId.displayName)
			let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
			self.jukeBox.send(event: newEvent as NSData)
		}
	}
	
	fileprivate func handleRemoveQueuedSongAtIndexEvent(index: Int) {
		self.trackArray.remove(at: index)
	}
	
    //MARK: - Song Player State Handling
    
    private func songNeedsChanging() -> Bool {
		if self.currentlyPlayingSong.dislikes >= 2 {
			self.playNextSong()
			return true
		} else {
			return false
		}
	}
    
    //Only hosts can playNextSong
    func playNextSong() {
        
        //on first play, we do not want to remove the first song from the array
        guard let firstSong = self.trackArray.first else {
            print("No Song")
            //can handle no song in here
            return
        }
        
        self.songTimer.countDownTimer.invalidate()
        //ToDo - currentlyPlayingSong should only ever be fired once per user
		self.currentlyPlayingSong = firstSong
		self.trackArray.removeFirst()
		self.playListTable.reloadData()
		//play new song and adjust timers / button state
		self.player?.playSpotifyURI(currentlyPlayingSong.songURI, startingWith: 0, startingWithPosition: 0, callback: nil)
		self.songTimer.setMaxSongtime(milliseconds: Int(currentlyPlayingSong.duration))
		self.playbackButton.setButtonState(.playing, animated: false)
        
        //send new song event to connected peers
        let event = Event(songAction: .startNewSong, song: self.currentlyPlayingSong, totalSongTime: Int(self.songTimer.totalSongTime), timeRemaining: self.songTimer.timeRemaining, timeElapsed: self.songTimer.timeElapsed, index: 0, playbackState: "Play", sender: self.jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        self.jukeBox.send(event: newEvent as NSData)
        self.songTimer.startTimer()
    }
	
    fileprivate func handlePlayNextSongEvent(_ event: Event) {
		
        self.currentlyPlayingSong = event.song
        self.trackArray.removeFirst()
        self.playListTable.reloadData()
        self.songTimer.countDownTimer.invalidate()
        self.playbackButton.setButtonState(.playing, animated: true)
        self.updateTimersFrom(event)
        self.songTimer.startTimer()
    }
    
    fileprivate func loadCurrentlyPlayingSongImage() {
		
		let song: Song = currentlyPlayingSong
		let imageURL = song.images[0]["url"] as! String
		// If this image is already cached, don't re-download
		if let img = playlistImageCache[imageURL] {
			albumImage.image = img
		} else {
			// The image isn't cached, download the img data on a background thread
			
			let url = URL(string: imageURL)
			let session = URLSession.shared
			let task = session.dataTask(with: url!) { (data, response, error) in
				if error == nil {
					let image = UIImage(data: data!)
					// Store the image in our cache
					self.playlistImageCache[imageURL] = image
					// Update the cell
					DispatchQueue.main.async {
						self.albumImage.image = image
					}
				}
				else {
					print("Uh Oh")
				}
			}
			task.resume()
		}
		
	}
	
    @IBAction private func didTapPlaybackButton(_ sender: Any) {
		//only the host can toggle play
		guard self.jukeBox.isHost else { return }
		self.togglePlay()
    }
	
	private func togglePlay() {
		let playState: Bool = self.playbackButton.buttonState == .pausing ? true : false
		self.player?.setIsPlaying(playState, callback: nil)
		self.playbackButton.setButtonState(playState ? .playing : .pausing, animated: true)
		self.songTimer.toggleTimer()
		self.sendTogglePlayEvent()
	}
	
    private func sendTogglePlayEvent() {
        
        guard let firstSong = currentlyPlayingSong else {
            print("No Song")
            //can handle no song in here
            return
        }
        let event = Event(songAction: .togglePlay, song: firstSong, totalSongTime: Int(self.songTimer.totalSongTime), timeRemaining: self.songTimer.timeRemaining, timeElapsed: self.songTimer.timeElapsed, index: 0, playbackState: "Play", sender: self.jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        self.jukeBox.send(event: newEvent as NSData)
    }
    
    private func sendAddNewSongEvent(song: Song) {
        
        let event = Event(songAction: .addSong, song: song, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed, index: 0, playbackState: "Play", sender: jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox.send(event: newEvent as NSData)
    }
    
    private func updateCurrentTrackInfo() {
        
        currentTrackLabel.text = currentlyPlayingSong.title
        currentArtistLabel.text = currentlyPlayingSong.artist
        //eventually handle explicit tag
    }
    
    fileprivate func updateTimersFrom(_ event: Event) {
        self.songTimer.totalSongTime = Float(event.totalSongTime)
        self.songTimer.timeRemaining = event.timeRemaining
        self.songTimer.timeElapsed = event.timeElapsed
    }
	
	fileprivate func handleTogglePlayEvent(_ event: Event) {
		print("toggle play")
		self.updateTimersFrom(event)
		self.songTimer.toggleTimer()
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
        
        self.trackArray.append(unwindSong)
        print("adding new song")
        if  self.jukeBox.isPendingHost {
            self.jukeBox.isPendingHost = false
            self.jukeBox.isHost = true
            self.jukeBox.serviceBrowser.startBrowsingForPeers()
            print("browsing for peers")
            self.hideSearch()
            return
        }
        self.sendAddNewSongEvent(song: unwindSong)
        self.hideSearch()
    }
    
   fileprivate func updateProgressBar(){
        self.trackProgressView.setProgress(Float(songTimer.timeElapsed) / songTimer.totalSongTime, animated: true)
    }
    
    func initializePlayer(authSession:SPTSession){
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player?.playbackDelegate = self
            self.player?.delegate = self
			//should do do / try here and catch the error
            try! player?.start(withClientId: auth.clientID)
            self.player?.login(withAccessToken: authSession.accessToken!)
            
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
            let event = Event(songAction: .newUserSyncResponse, song: song, totalSongTime: Int(self.songTimer.totalSongTime), timeRemaining: self.songTimer.timeRemaining, timeElapsed: self.songTimer.timeElapsed, index: 0, playbackState: "Play", sender: self.jukeBox.myPeerId.displayName)
            let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
            self.jukeBox.send(event: newEvent as NSData)
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
        let event = Event(songAction: .newUserFinishedSyncing, song: self.currentlyPlayingSong, totalSongTime: Int(self.songTimer.totalSongTime), timeRemaining: self.songTimer.timeRemaining, timeElapsed: self.songTimer.timeElapsed, index: 0, playbackState: playbackState, sender: self.jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        self.jukeBox.send(event: newEvent as NSData)
        
    }
    
    func hostSendNewConnectionEvent() {
        
        let event = Event(songAction: .newConnectionDetected, song: self.currentlyPlayingSong, totalSongTime: Int(self.songTimer.totalSongTime), timeRemaining: self.songTimer.timeRemaining, timeElapsed: self.songTimer.timeElapsed, index: 0, playbackState: "Play", sender: self.jukeBox.myPeerId.displayName)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        self.jukeBox.send(event: newEvent as NSData)
        
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
    
   private func playlistTableSetup() {
        
        self.playListTable = UITableView()
        
        let nib = UINib(nibName: "PlaylistTableCell", bundle: nil)
        self.playListTable.register(nib, forCellReuseIdentifier: "PlaylistCell")
        self.jukeView.addSubview(playListTable)
        
        self.playListTable.backgroundColor = jukeView.backgroundColor
        
        self.playListTable.translatesAutoresizingMaskIntoConstraints = false
        self.playListTable.widthAnchor.constraint(equalTo: self.jukeView.widthAnchor, multiplier: 1).isActive = true
        self.playListTable.centerXAnchor.constraint(equalTo: self.jukeView.centerXAnchor).isActive = true
        self.playListTable.bottomAnchor.constraint(equalTo: self.jukeView.bottomAnchor).isActive = true
        
        self.playListTable.topAnchor.constraint(equalTo: currentInfoWrapper.bottomAnchor).isActive = true
        
        self.playListTable.isHidden = true
        
    }
    
	private func searchWrapperSetup() {
		self.searchWrapper = UIView()
		view.addSubview(searchWrapper)
		self.searchWrapper.backgroundColor = view.backgroundColor
		
		self.searchWrapper.translatesAutoresizingMaskIntoConstraints = false
		self.searchWrapper.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0, constant: 0).isActive = true
		self.searchWrapper.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		self.searchWrapper.topAnchor.constraint(equalTo: view.topAnchor, constant: 60).isActive = true
		self.searchWrapperHeight = searchWrapper.heightAnchor.constraint(equalToConstant: 40)
		self.searchWrapperHeight.isActive = true
		
		self.searchWrapperExpandedBottomAnchor = searchWrapper.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
		self.searchWrapperExpandedBottomAnchor.isActive = false
		
		self.searchField = UITextField()
		self.searchField.delegate = self
		self.searchWrapper.addSubview(searchField)
		self.searchField.translatesAutoresizingMaskIntoConstraints = false
		self.searchFieldWidth = searchField.widthAnchor.constraint(equalTo: searchWrapper.widthAnchor, multiplier: 0.67, constant: 0)
		self.searchFieldWidth.isActive = true
		self.searchFieldExpandedWidth = searchField.widthAnchor.constraint(equalTo: self.searchWrapper.widthAnchor, multiplier: 0.90, constant: 0)
		self.searchFieldExpandedWidth.isActive = false
		
		let font = UIFont.systemFont(ofSize: 30, weight: UIFontWeightLight)
		
		self.searchField.textAlignment = .center
		self.searchField.adjustsFontSizeToFitWidth = true
		
		self.searchField.font = font
		self.searchField.textColor = UIColor(red: 50.0/255, green: 50.0/255, blue: 50.0/255, alpha: 1.0)
		self.searchField.tintColor = UIColor(red: 50.0/255, green: 50.0/255, blue: 50.0/255, alpha: 1.0)
		self.searchField.centerXAnchor.constraint(equalTo: self.searchWrapper.centerXAnchor).isActive = true
		self.searchField.topAnchor.constraint(equalTo: self.searchWrapper.topAnchor, constant: 0).isActive = true
		self.searchField.heightAnchor.constraint(equalToConstant: 40).isActive = true
		self.searchField.attributedPlaceholder = NSAttributedString(string: "Search for a track")
		
		self.tapView = UIView()
		self.searchWrapper.addSubview(tapView)
		self.tapView.translatesAutoresizingMaskIntoConstraints = false
		self.tapView.widthAnchor.constraint(equalTo: self.searchField.widthAnchor, multiplier: 1.0, constant: 0).isActive = true
		self.tapView.centerXAnchor.constraint(equalTo: self.searchWrapper.centerXAnchor, constant: 0).isActive = true
		self.tapView.heightAnchor.constraint(equalTo: self.searchField.heightAnchor, multiplier: 1.0, constant: 0).isActive = true
		self.tapView.topAnchor.constraint(equalTo: self.searchField.topAnchor, constant: 0).isActive = true
		self.searchWrapper.bringSubview(toFront: self.tapView)
		let search = UITapGestureRecognizer(target: self, action: #selector(showSearch))
		self.tapView.addGestureRecognizer(search)
		
		
		//set up results TableView
		self.resultsTable = UITableView()
		self.resultsTable.dataSource = self
		self.resultsTable.delegate = self
		self.resultsTable.translatesAutoresizingMaskIntoConstraints = false
		self.resultsTable.isHidden = true
		
		
		
		let categoryNib = UINib(nibName: "SearchCategoryCell", bundle: nil)
		let trackNib = UINib(nibName: "SearchTrackCell", bundle: nil)
		
		self.resultsTable.register(categoryNib, forCellReuseIdentifier: "CategoryCell")
		
		self.resultsTable.register(trackNib, forCellReuseIdentifier: "TrackCell")
		
		self.searchWrapper.addSubview(resultsTable)
		self.resultsTable.backgroundColor = searchWrapper.backgroundColor
		
		self.resultsTable.widthAnchor.constraint(equalTo: searchWrapper.widthAnchor, multiplier: 1.0, constant: 0).isActive = true
		
		self.resultsTable.centerXAnchor.constraint(equalTo: searchWrapper.centerXAnchor).isActive = true
		self.resultsTable.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 0).isActive = true
		self.resultsTable.bottomAnchor.constraint(equalTo: searchWrapper.bottomAnchor, constant: 0).isActive = true
		
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
    
   private func hideSearch() {
        
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
            if self.shouldShowCategories {
                return self.addMusicOptions.count
            } else {
                return self.filteredSongs.count
            }
        case playListTable:
            return self.trackArray.count
        default:
            break
        }
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch tableView {
        case resultsTable:
            
            
            if self.shouldShowCategories {
                self.resultsTable.isScrollEnabled = false
                let cell = self.resultsTable.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! SearchCategoryCell
                
                cell.categoryNameLabel.text = addMusicOptions[indexPath.row]
                cell.backgroundColor = resultsTable.backgroundColor
                
                
                return cell
            } else {
                self.resultsTable.isScrollEnabled = true
                //put it in here
                //watch out for cache size
                let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! SearchTrackCell
                let song: Song = self.filteredSongs[indexPath.row]
                
                cell.trackNameLabel.text = self.filteredSongs[indexPath.row].title
                cell.trackArtistLabel.text = self.filteredSongs[indexPath.row].artist
                if self.filteredSongs[indexPath.row].isExplicit {
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
            
            if self.shouldShowCategories {
                
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
                
                self.selectedSong = self.filteredSongs[indexPath.row]
                
                guard let selectedTrack = selectedSong else {
                    print("error, no track")
                    return
                }
                
                self.trackArray.append(selectedTrack)
                
				if  self.jukeBox.isPendingHost {
					self.jukeBox.isPendingHost = false
					self.jukeBox.isHost = true
					self.jukeBox.serviceBrowser.startBrowsingForPeers()
					self.hideSearch()
					return
				}
                
                self.sendAddNewSongEvent(song: selectedTrack)
                self.hideSearch()
                
                
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

            if self.shouldShowCategories {
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
            
            let upvote = MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "plus3"), backgroundColor: UIColor.init(red: 10.0/255, green: 197.0/255, blue: 2.0/255, alpha: 1.0), padding: 15) { [weak self] (sender) -> Bool in
                guard let index = self?.playListTable.indexPath(for: cell) else {
                    print("could not get indexduring upvote")
					return true
				}
				//send upvoted event
				guard let song: Song = self?.trackArray[Int(index.row)], let displayName = self?.jukeBox.myPeerId.displayName, !song.hasBeenVotedOnBy(peer: displayName) else { return true }
				song.voters.append(displayName)
				song.likes += 1
				self?.manager.spotifySaveSongForCurrentUser(songURI: song.songURI)
				self?.sendIncrementSongLikesAtIndexEvent(index: Int(index.row))
				print("upvoted")
				return true
			}
            return [upvote]
        } else {
            let downvote = MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "x2"), backgroundColor: UIColor(red: 255/255.0, green: 0/255.0, blue: 58/255.0, alpha: 1.0), padding: 15) { [weak self] (sender) -> Bool in
                
                guard let index = self?.playListTable.indexPath(for: cell) else {
                    print("could not get index during downvote")
                    return true
                }
                //send downvotequeuedSong event
				guard let song: Song = self?.trackArray[Int(index.row)], let displayName = self?.jukeBox.myPeerId.displayName, !song.hasBeenVotedOnBy(peer: displayName) else { return true }
				song.voters.append(displayName)
				song.dislikes += 1
				self?.sendDecrementOrRemoveAtIndexEvent(index: Int(index.row))
                print("downvoted")
                return true
            }
            downvote.titleLabel?.font = font
            //expansionSettings.expansionColor = UIColor(red: 47/255.0, green: 47/255.0, blue: 49/255.0, alpha: 0)
            return [downvote]
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == self.resultsTable {
            self.searchField.resignFirstResponder()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.resultsTable {
            self.searchField.resignFirstResponder()
        }
    }
    
    //MARK: - Quad Curve Methods
    
    func setupQuadCurve() {
        // At some point, will make jukeView a custom UIView Class that will initialize a quadcurve upon setup and attach gesture capabilties
        
        let p1 = CGPoint(x: 0, y: self.jukeView.bounds.origin.y)
        let p2 = CGPoint(x: self.view.frame.width, y: self.jukeView.bounds.origin.y)
        let controlP = CGPoint(x: self.view.frame.width / 2, y: self.jukeView.bounds.origin.y - 120)
        addCurve(startPoint: p1, endPoint: p2, controlPoint: controlP)
    }
    
    func addCurve(startPoint: CGPoint, endPoint: CGPoint, controlPoint: CGPoint) {
        
        let layer = CAShapeLayer()
        
        self.jukeView.layer.addSublayer(layer)
        layer.strokeColor = self.jukeView.layer.backgroundColor
        layer.fillColor = self.jukeView.layer.backgroundColor
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
				self.handleTogglePlayEvent(event)
                
            case .startNewSong:
                self.handlePlayNextSongEvent(event)
                
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
                        self.songTimer.toggleTimer()
                    }
                    //                    self.togglePlayButtonState()
//                    self.playerIsActive = true
                    print("sync request sync should finish")
                    self.isNewUser = false
//                    self.loadCurrentlyPlayingSongImage()
					
                }
                
            case .newUserSyncRequest:
				//this should have different implementations
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
				self.handleLikeEvent()
				
			case .currentSongDisliked:
				self.handleDislikeEvent()
				
			case .queuedSongLiked:
				self.handleIncrementLikesForSongAtIndexEvent(index: event.index)
				
			case .queuedSongDisliked:
				self.handleIncrementDislikesForSongAtIndexEvent(index: event.index)
				
			case .removeQueuedSong:
				//host removes song before sending event, only non hosts should remove song here
				self.handleRemoveQueuedSongAtIndexEvent(index: event.index)
				
			}
            
        }
    }
}

extension TestViewController: SongTimerDelegate {
    
    func progressBarNeedsUpdate() {
        self.updateProgressBar()
    }
    
    func songDidEnd() {
        if  self.jukeBox.isHost {
            self.playNextSong()
        }
    }
    
    func labelsNeedUpdate() {
        self.durationLabel?.text = self.songTimer.timeString(time: TimeInterval(songTimer.timeRemaining))
        self.timeElapsedLabel.text = self.songTimer.timeString(time: TimeInterval(songTimer.timeElapsed))
    }
    func syncResumeTapped(resumeTapped: Bool) {
        self.songTimer.resumeTapped = resumeTapped
    }
}
