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
    var panBackground: UIView!
    var panBackgroundWidthAnchor: NSLayoutConstraint!
    var panBackgroundExpandedWidthAnchor: NSLayoutConstraint!
    var slideButtonLeadAnchor: NSLayoutConstraint!
    var slideBtnBackground: UIView!
    var slideBtnBackgroundLeadAnchor: NSLayoutConstraint!
    
    @IBOutlet weak var welcomeWrapper: UIView!
    
    @IBOutlet weak var slideLabel: UILabel!
    
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
        
        slideButtonLeadAnchor = slideButton.leadingAnchor.constraint(equalTo: loginButtonWrapper.leadingAnchor, constant: 0)
        slideButtonLeadAnchor.isActive = true
        
        addCurve(startPoint: p1, endPoint: p2, controlPoint: controlP)
        
        loginButtonWrapper.layer.cornerRadius = 35
        
        slideButton.layer.cornerRadius = 35
        slideButton.tintColor = UIColor(red: 30.0/255, green: 215.0/255, blue: 95.0/255, alpha: 1.0)
        
        loginButtonWrapper.layer.borderColor = UIColor(red: 30.0/255, green: 215.0/255, blue: 96.0/255, alpha: 1.0).cgColor
        loginButtonWrapper.layer.borderWidth = 2
        
        loginButtonWrapper.layer.masksToBounds = true
        slideButton.layer.masksToBounds = true
        panBackgroundSetup()
        setup()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        
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
    
    func panBackgroundSetup() {
        
        slideBtnBackground = UIView()
        slideBtnBackground.translatesAutoresizingMaskIntoConstraints = false
        loginButtonWrapper.insertSubview(slideBtnBackground, belowSubview: slideButton)
        
        
        
        slideBtnBackground.heightAnchor.constraint(equalTo: slideButton.heightAnchor, multiplier: 0.9, constant: 0).isActive = true
        slideBtnBackground.leadingAnchor.constraint(equalTo: slideButton.leadingAnchor).isActive = true
        slideBtnBackground.centerYAnchor.constraint(equalTo: slideButton.centerYAnchor).isActive = true
        slideBtnBackground.widthAnchor.constraint(equalTo: slideButton.widthAnchor, multiplier: 0.9, constant: 0).isActive = true
        slideBtnBackground.backgroundColor = UIColor.white
        slideBtnBackground.layer.borderColor = UIColor(red: 30.0/255, green: 215.0/255, blue: 96.0/255, alpha: 1.0).cgColor
        slideBtnBackground.layer.masksToBounds = true
        slideBtnBackground.layer.cornerRadius = 35
        
        
        
        
        
        panBackground = UIView()
        panBackground.translatesAutoresizingMaskIntoConstraints = false
        loginButtonWrapper.insertSubview(panBackground, belowSubview: slideBtnBackground)
        loginButtonWrapper.insertSubview(slideLabel, aboveSubview: panBackground)
        panBackground.heightAnchor.constraint(equalTo: loginButtonWrapper.heightAnchor, multiplier: 1.0, constant: 0).isActive = true
        panBackground.leadingAnchor.constraint(equalTo: loginButtonWrapper.leadingAnchor).isActive = true
        panBackground.centerYAnchor.constraint(equalTo: loginButtonWrapper.centerYAnchor).isActive = true
        panBackgroundWidthAnchor = panBackground.widthAnchor.constraint(equalToConstant: 70)
        panBackgroundWidthAnchor.isActive = true
        panBackground.backgroundColor = UIColor(red: 31.0/255, green: 231.0/255, blue: 103/255, alpha: 1.0)
        panBackground.layer.masksToBounds = true
        panBackground.layer.cornerRadius = 35

    }

    func setup() {
        auth.clientID = ConfigCreds.clientID
        auth.redirectURL = URL(string: ConfigCreds.redirectURLString)
        
        
        //REMEMBER TO ADD BACK SCOPES
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope,SPTAuthUserFollowReadScope,SPTAuthUserLibraryReadScope,SPTAuthUserReadPrivateScope,SPTAuthUserReadTopScope,SPTAuthUserReadBirthDateScope,SPTAuthUserReadEmailScope, SPTAuthUserLibraryModifyScope]
        
        loginUrl = auth.spotifyWebAuthenticationURL()
        
    }
    
    
    @IBAction func authPan(_ sender: UIPanGestureRecognizer) {
        
        xFromCenter = sender.translation(in: self.view).x
        
        let rightEdge = CGFloat(loginButtonWrapper.bounds.size.width - (slideButton.bounds.size.width / 2))
        
        let xRatio = xFromCenter / (loginButtonWrapper.bounds.size.width / 2)
        
        
        let leftEdge = CGFloat(loginButtonWrapper.bounds.origin.x + (slideButton.bounds.size.width / 2))
        
        
//        let loginMaxX = loginButtonWrapper.bounds.maxX
//        let loginMinX = loginButtonWrapper.bounds.minX
//        
//        let buttonMaxX = slideButton.frame.maxX
//        let buttonMinX = slideButton.frame.minX
        
        switch sender.state {
            
        case .began, .changed:
            
            
            
            print("button max X: \(slideButton.frame.maxX)")
            print(rightEdge)
            print(slideButton.center.x)
            
            //print(sender.view?.center.x)
            
            
//            print("button min X: \(slideButton.frame.minX)")
            
            if (sender.view?.center.x)! >= leftEdge && (sender.view?.center.x)! <= rightEdge {
                slideButtonLeadAnchor.constant = xFromCenter
                panBackgroundWidthAnchor.constant = 70 + xFromCenter
                slideLabel.layer.opacity = Float(1 - xRatio)
            }
            //panBackgroundExpandedWidthAnchor.isActive = true
            self.view.updateConstraints()
            self.view.layoutIfNeeded()
            
            
        case .ended:
            
            if (sender.view?.center.x)! >= rightEdge {
                
                UIApplication.shared.open(loginUrl!, options: [:]) { (didFinish) in
                    if didFinish {
                        if self.auth.canHandle(self.auth.redirectURL) {
                            //build in error handling
                        }
                        
                    }
                }
            } else {
                UIView.animate(withDuration: 0.2, animations: {() -> Void in
                    self.slideButtonLeadAnchor.constant = 0
                    self.slideLabel.layer.opacity = 1.0
                    self.panBackgroundWidthAnchor.constant = 70
                    self.view.updateConstraints()
                    self.view.layoutIfNeeded()
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
