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
//    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    
    var beginPointX: CGFloat!
    var endPointX: CGFloat!
    var originPoint: CGPoint!
    var xFromCenter: CGFloat!
    
    @IBOutlet weak var welcomeWrapper: UIView!
    
    @IBOutlet weak var loginButtonWrapper: UIView!

    @IBOutlet weak var slideButton: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("login max X: \(loginButtonWrapper.bounds.maxX)")
        print("login minX: \(loginButtonWrapper.bounds.minX)")
        
        
        print("button max X: \(slideButton.frame.maxX)")
        print("button min X: \(slideButton.frame.minX)")
        
        originPoint = slideButton.center
        beginPointX = loginButtonWrapper.bounds.origin.x
        endPointX = loginButtonWrapper.bounds.size.width
        
        
        let p1 = CGPoint(x: welcomeWrapper.bounds.origin.x, y: welcomeWrapper.bounds.origin.y + 2)
        let p2 = CGPoint(x: welcomeWrapper.bounds.width, y: welcomeWrapper.bounds.origin.y + 2)
        let controlP = CGPoint(x: welcomeWrapper.bounds.width / 2, y: welcomeWrapper.bounds.origin.y - 120)
        
        addCurve(startPoint: p1, endPoint: p2, controlPoint: controlP)
        
        loginButtonWrapper.layer.cornerRadius = 35
        slideButton.layer.cornerRadius = 35
        loginButtonWrapper.layer.borderColor = UIColor(red: 30.0/255, green: 215.0/255, blue: 96.0/255, alpha: 1.0).cgColor
        loginButtonWrapper.layer.borderWidth = 2
        loginButtonWrapper.layer.masksToBounds = true
        slideButton.layer.masksToBounds = true
        setup()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
        // Do any additional setup after loading the view.
    }
    
    func addCurve(startPoint: CGPoint, endPoint: CGPoint, controlPoint: CGPoint) {
        
        let layer = CAShapeLayer()
        
        welcomeWrapper.layer.addSublayer(layer)
        layer.strokeColor = welcomeWrapper.layer.backgroundColor
        layer.fillColor = welcomeWrapper.layer.backgroundColor
        layer.lineWidth = 1
        
        let path = UIBezierPath()
        
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, controlPoint: controlPoint)
        layer.path = path.cgPath
        path.stroke()
        
    }

    func setup() {
        auth.clientID = ConfigCreds.clientID
        auth.redirectURL = URL(string: ConfigCreds.redirectURLString)
        
        
        //REMEMBER TO ADD BACK SCOPES
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope,SPTAuthUserFollowReadScope,SPTAuthUserLibraryReadScope,SPTAuthUserReadPrivateScope,SPTAuthUserReadTopScope,SPTAuthUserReadBirthDateScope,SPTAuthUserReadEmailScope]
        
        loginUrl = auth.spotifyWebAuthenticationURL()
        
    }
    
    
    @IBAction func authPan(_ sender: UIPanGestureRecognizer) {
        
        xFromCenter = sender.translation(in: loginButtonWrapper).x
        
        let loginMaxX = loginButtonWrapper.bounds.maxX
        let loginMinX = loginButtonWrapper.bounds.minX
        
        let buttonMaxX = slideButton.frame.maxX
        let buttonMinX = slideButton.frame.minX
        
        switch sender.state {
            
        case .began, .changed:
            
            print("button max X: \(slideButton.frame.maxX)")
//            print("button min X: \(slideButton.frame.minX)")
            
            if buttonMinX >= loginMinX && buttonMaxX <= loginMaxX {
                slideButton.center = CGPoint(x: originPoint.x + xFromCenter, y: originPoint.y)
            }

        case .ended:
            
            if buttonMaxX >= loginMaxX {
                UIApplication.shared.open(loginUrl!, options: [:]) { (didFinish) in
                    if didFinish {
                        if self.auth.canHandle(self.auth.redirectURL) {
                            //build in error handling
                        }
                        
                    }
                }
            } else {
                
                UIView.animate(withDuration: 0.2, animations: {() -> Void in
                    self.slideButton.center = self.originPoint
                    
                })
                
            }

        default:
            break
        }
        
    }

    
    func updateAfterFirstLogin () {
        if let sessionObj:Any = UserDefaults.standard.object(forKey: "SpotifySession") as Any? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
//            initializePlayer(authSession: session)
            performSegue(withIdentifier: "userType", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "userType" {
            let dvc = segue.destination as! UserTypeViewController
            dvc.session = session
        }
    }
    //MARK: Audio Player Methods
    
//    func initializePlayer(authSession:SPTSession){
//        if self.player == nil {
//            self.player = SPTAudioStreamingController.sharedInstance()
//            self.player!.playbackDelegate = self
//            self.player!.delegate = self
//            try! player!.start(withClientId: auth.clientID)
//            self.player!.login(withAccessToken: authSession.accessToken!)
//            
//        }
//    }
    
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
