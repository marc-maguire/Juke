//
//  LoginViewController.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-20.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController,SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {

    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
        // Do any additional setup after loading the view.
    }

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
            performSegue(withIdentifier: "userType", sender: self)
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
    
       
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        print("logged in")
        print("\(session.accessToken)")
        
        print("\(session.encryptedRefreshToken)")
        print("\(auth.clientID)")
    }
    

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
