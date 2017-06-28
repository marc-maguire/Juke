//
//  SongViewController.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-15.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class SongViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, Unwindable {

    @IBOutlet weak var tableView: UITableView!
    var imageCache = [String:UIImage]() {
        willSet {
            if imageCache.count >= 100 {
                self.imageCache.removeAll()
            }
        }
    }
    var tracksArray: [Song] = []
    var selectedSong: Song?
    var unwindSong: Song {
        get {
            return selectedSong!
        }
    }
    var manager = DataManager.shared()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "SearchTrackCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "TrackCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tableView.reloadData()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tracksArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! SearchTrackCell
      

        
        let song: Song = tracksArray[indexPath.row]
        
        cell.trackNameLabel.text = tracksArray[indexPath.row].title
        cell.trackArtistLabel.text = tracksArray[indexPath.row].artist
        if tracksArray[indexPath.row].isExplicit {
            cell.explicitMarkerImage.image = #imageLiteral(resourceName: "explicit-grey")
        } else {
            cell.explicitMarkerImage.image = #imageLiteral(resourceName: "placeholder-rect")
        }
        cell.trackAlbumImage.image = #imageLiteral(resourceName: "placeholder-rect")
        cell.backgroundColor = tableView.backgroundColor
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSong = tracksArray[indexPath.row]
        performSegue(withIdentifier: "first", sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
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

