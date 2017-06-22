//
//  UserTypeViewController.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-20.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class UserTypeViewController: UIViewController {
    
    
    @IBOutlet weak var inviteButton: UIButton!
    //when we load, if there are no invites, this should be invisible by default
    

    var session:SPTSession!
    var jukeBox: JukeBoxManager = JukeBoxManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//       NotificationCenter.default.addObserver(self, selector: #selector(UserTypeViewController.updateInviteButtonWith(notification:)), name: NSNotification.Name(rawValue: "receivedInvite"), object: nil)
       NotificationCenter.default.addObserver(self, selector: #selector(UserTypeViewController.beginSegue), name: NSNotification.Name(rawValue: "receivedInvite"), object: nil)
        //how to get the value out of the dictionary?

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//    @objc func updateInviteButtonWith(notification: NSNotification) {
//        if let info = notification.userInfo as? Dictionary<String,String> {
//            // Check if value present before using it
//            if let hostName = info["hostName"] {
//                print(hostName)
//                
//                inviteButton.isHidden = false
//                inviteButton.titleLabel?.textColor = UIColor.black
//                inviteButton.titleLabel?.text = hostName
//                //update button state here with name of host, make it visible
//            }
//            else {
//                print("no value for key\n")
//            }
//        }
//        else {
//            print("wrong userInfo type")
//        }
//        
//    }
 
        @objc func beginSegue() {
            performSegue(withIdentifier: "guest", sender: self)
            }
   
    @IBAction func hostButtonTapped(_ sender: Any) {
        jukeBox.isPendingHost = true
        
//        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
////        _ = storyboard.instantiateInitialViewController()
//        let vc = storyboard.instantiateViewController(withIdentifier: "addMusicViewController1") as! UINavigationController
//        self.show(vc, sender: self)
    }


    @IBAction func acceptInviteButtonTapped(_ sender: Any) {
//        jukeBox.isAcceptingInvites = true
        //go to the tableViewController
        
    }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "host" {
            let dvc = segue.destination as! TableViewController
            dvc.isNewUser = false
            jukeBox.isHost = true
            dvc.jukeBox = jukeBox
            dvc.session = session
            
            
        }
        if segue.identifier == "guest" {
            let dvc = segue.destination as! TableViewController
            dvc.jukeBox = jukeBox
            dvc.session = session
            //session is not set because no playing
            //might need session if playing loner than an hour
            
        }

    }

}
