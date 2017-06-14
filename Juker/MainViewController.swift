//
//  ViewController.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-06-10.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit
//import Alamofire

class MainViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    var manager = DataManager.shared()
    
    var track: String?
    
    
    let jukeBox = JukeBoxManager()
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var artistLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    var trackArray: [Song] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
        
        
        jukeBox.delegate = self
    }
    
    
    
    func updateAfterFirstLogin () {
        if let sessionObj:Any = UserDefaults.standard.object(forKey: "SpotifySession") as Any? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            initializePlayer(authSession: session)
        }
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
    func setup() {
        auth.clientID = ConfigCreds.clientID
        auth.redirectURL = URL(string: ConfigCreds.redirectURLString)
        
        
        //REMEMBER TO ADD BACK SCOPES
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope,SPTAuthUserFollowReadScope,SPTAuthUserLibraryReadScope,SPTAuthUserReadPrivateScope,SPTAuthUserReadTopScope,SPTAuthUserReadBirthDateScope,SPTAuthUserReadEmailScope]
        
        loginUrl = auth.spotifyWebAuthenticationURL()
        
        //loginUrl = auth.spotifyAppAuthenticationURL()
        
        
        
    }
    
    
    @IBAction func loginPressed(_ sender: UIButton) {
        
        if UIApplication.shared.openURL(loginUrl!) {
            if auth.canHandle(auth.redirectURL) {
                // To do - build in error handling
            }
        }
        
//        UIApplication.shared.open(loginUrl!, options: [:]) { (bool) in
//            
//        }
    }
    
    func updateLabels(song: Song) {
        titleLabel.text = song.title
        artistLabel.text = song.artist
        //        durationLabel.text = "\(song.duration)"
        
    }
    
    @IBAction func sendSong1Tapped(_ sender: UIButton) {
        let savedSong = NSKeyedArchiver.archivedData(withRootObject: trackArray[0])
        jukeBox.send(song: savedSong as NSData)
        updateLabels(song: trackArray[0])
        
    }
    
    @IBAction func sendSong2Tapped(_ sender: UIButton) {
        let savedSong = NSKeyedArchiver.archivedData(withRootObject: trackArray[1])
        jukeBox.send(song: savedSong as NSData)
        updateLabels(song: trackArray[1])
        
    }

    
    func jsonParser(completion: @escaping (String?) -> ()) {
        let urlPath = "https://api.spotify.com/v1/tracks?ids=11dFghVXANMlKmJXsNCbNl,2takcwOaAZWiXQijPHIx7B"
        guard let endpoint = URL(string: urlPath) else {
            print("Error creating endpoint")
            return
        }
        
        guard let token = session.accessToken else {
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        // Set headers
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            do {
                guard let data = data else {
                    return
                }
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {
                    return
                }
                
                guard let strongSelf = self else {
                    return
                }
                
                print(json)
                
                guard let tracks = json["tracks"] as? [[String:AnyObject]] else {
                    return
                }
                
                
                for track in tracks {
                    
                    let song = Song(singleTrackDict: track)
                    
                    strongSelf.trackArray.append(song!)
                    
                }
               
                let trackString = strongSelf.trackArray.first?.songURI
                print(trackString!)
                
                completion(trackString)
                
                
    
            }
            catch {
                
            }
 
        }.resume()
        
    }
    
    @IBAction func getSong(_ sender: UIButton) {
        
        manager.getCurrentUserPlaylists()
        
        
        jsonParser { (uri) in
            self.track = uri!
            
            print("got here baby")
            
        }
        
    }
    
    
    @IBAction func playSong(_ sender: UIButton) {
        self.player!.playSpotifyURI(self.track!, startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("playing!")
            }
            
            print(error ?? "no error")
        })
        
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        print("logged in")
        print("\(session.accessToken)")
    
        print("\(session.encryptedRefreshToken)")
        print("\(auth.clientID)")
    }

}

extension MainViewController : ColorServiceManagerDelegate {
    
    func connectedDevicesChanged(manager: JukeBoxManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            //self.connectionsLabel.text = "Connections: \(connectedDevices)"
        }
    }
    
    //MARK: NEW-----------
    func songChanged(manager: JukeBoxManager, song: Song) {
        OperationQueue.main.addOperation {
            self.updateLabels(song: song)
        }
    }
    
}
