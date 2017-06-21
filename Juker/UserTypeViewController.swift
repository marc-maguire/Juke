//
//  UserTypeViewController.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-20.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class UserTypeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func hostButtonTapped(_ sender: Any) {
        
//        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
////        _ = storyboard.instantiateInitialViewController()
//        let vc = storyboard.instantiateViewController(withIdentifier: "addMusicViewController1") as! UINavigationController
//        self.show(vc, sender: self)
    }


   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "host" {
            let dvc = segue.destination as! TableViewController
            dvc.jukeBox.isPendingHost = true
        }
    }

}
