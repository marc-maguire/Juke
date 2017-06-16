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
    let searchController = UISearchController(searchResultsController: nil)
    var songs = [Song]()
    var filteredSongs = [Song]()
    var manager = DataManager.shared()
    
    var addMusicOptions = ["Playlists", "Recommendation", "Saved Music", "Recently Played"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        // Do any additional setup after loading the view.
    }
    //This filters the candies array based based on searchText and will put the results in the filteredCandies array you just added. Don’t worry about the scope parameter for now, you’ll use that in a later section of this tutorial. 
    //NEED TO UPDATE
    

    func filterContentForSearchText(searchText: String, scope: String = "All") {
        //do network call here
        if searchText.characters.count >= 1 {
        manager.spotifySearch(searchString: searchText.lowercased()) { (songs) in
            DispatchQueue.main.async {
                self.filteredSongs = []
                self.filteredSongs = songs
            }
        }
        }
//        filteredSongs = songs.filter { song in
//            return song.title.lowercased().contains(searchText.lowercased())
    
        
        tableView.reloadData()
    }
    
    //check which cell was clicked
    //perform segue
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return
        }

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
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredSongs.count
        }
        return addMusicOptions.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if searchController.isActive && searchController.searchBar.text != "" {
            
            cell.textLabel?.text = filteredSongs[indexPath.row].title
            cell.detailTextLabel?.text = filteredSongs[indexPath.row].artist

        }else {
            cell.textLabel?.text = addMusicOptions[indexPath.row]
            cell.accessoryType = .disclosureIndicator
        
        }
        return cell
    }

}
extension AddMusicViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
