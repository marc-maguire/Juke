//
//  AddMusicViewController.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-14.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class AddMusicViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var tableView: UITableView!

    var addMusicOptions = ["Playlists", "Recommendation", "Saved Music", "Recently Played"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }

    //check which cell was clicked
    //perform segue
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    }


    
    
//    @IBAction func getSong(_ sender: UIButton) {
//        
//        //        manager.spotifyCurrentUserPlaylists()
//        //
//        //        manager.spotifyPlaylistTracks(ownerID: "jmperezperez", playlistID: "3cEYpjA9oz9GiPac4AsH4n")
//        
//        manager.spotifySearch(searchString: "perez") {(array) in
//            print("YAAAAAAAA")
//            print("Array deets, # of songs: \(array.count) array deets: \(array)")
//            
//            self.trackArray = array
//        }
//    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return addMusicOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = addMusicOptions[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

}
