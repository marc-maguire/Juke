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
    
    var imageCache = [String:UIImage]() {
        willSet {
            if imageCache.count >= 100 {
                self.imageCache.removeAll()
            }
        }
    }
    var manager = DataManager.shared()
    
    var playlistArray: [Playlist] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableSetup()
        manager.spotifyCurrentUserPlaylists { (playlist) in
            self.playlistArray = playlist
            self.tableView.reloadData()
        }
        
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    func tableSetup() {
        let nib = UINib(nibName: "SearchPlaylistCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "SearchPlaylist")
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return playlistArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchPlaylist", for: indexPath) as! SearchPlaylistCell
     
        let playlist = playlistArray[indexPath.row]
        
        cell.backgroundColor = tableView.backgroundColor
        
        cell.playlistNameLabel?.text = playlist.name
        
        cell.playlistImageView.image = #imageLiteral(resourceName: "placeholder-rect")
        
        let imageURL = playlist.image
        
        // If this image is already cached, don't re-download
        if let img = imageCache[imageURL] {
            cell.playlistImageView.image = img
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
                        cell.playlistImageView.image = image
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "song", sender: self)
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
