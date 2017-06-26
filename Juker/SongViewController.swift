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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = tracksArray[indexPath.row].title
        cell.detailTextLabel?.text = tracksArray[indexPath.row].artist
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSong = tracksArray[indexPath.row]
        performSegue(withIdentifier: "first", sender: self)
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

