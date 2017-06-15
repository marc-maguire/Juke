//
//  PlaylistViewController.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-15.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var manager = DataManager.shared()
    
    var playlistArray: [Playlist] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        manager.spotifyCurrentUserPlaylists { (playlist) in
            self.playlistArray = playlist
            self.tableView.reloadData()
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
//        tableView.reloadData()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return playlistArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = playlistArray[indexPath.row].name
        
        return cell
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "song" {
            let svc = segue.destination as! SongViewController
            //get index path
            guard let indexPath = tableView.indexPathForSelectedRow else {
                return
            }
            let playlist = playlistArray[indexPath.row]
            manager.spotifyPlaylistTracks(ownerID: playlist.ownerID, playlistID: playlist.playlistID, completionArray: { (songs) in
                svc.tracksArray = songs
                svc.tableView.reloadData()
            })
            //search for song based on index path
            
            
            
        }
        
    }


}
