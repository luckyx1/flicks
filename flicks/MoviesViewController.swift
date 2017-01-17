//
//  MoviesViewController.swift
//  flicks
//
//  Created by Rob Hernandez on 1/15/17.
//  Copyright © 2017 Robert Hernandez. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD


class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    // Reference to the tableView
    @IBOutlet weak var tableView: UITableView!
    // Reference to the searchBar
    @IBOutlet weak var searchBar: UISearchBar!
    // Reference to the networkError View
    @IBOutlet weak var networkErrorView: UIView!
    // Hold the data locally from the API call
    var movies: [NSDictionary]?
    
    // Initialize a UIRefreshControl
    let refreshControl = UIRefreshControl()
    
    // View Controller code
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
        
        // Setup the UITable
        tableView.dataSource = self
        tableView.delegate = self
        
        // Setup the searchBar
        searchBar.delegate = self
        
        
        // add refresh control to table view
        tableView.insertSubview(refreshControl, at: 0)
        
        // By default, don't show error
        self.networkErrorView.isHidden = false
        
        //Do the GET from the "The movies" API
        self.getNowFeaturing(refreshControl: refreshControl)

    }
    
    // TableView code
    
    // How many rows available on the phone
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if let movies = movies {
            return movies.count
        }else{
            return 0
        }
    }
    
    // What to put into the cell for the tableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        // Pull a cell off from the table view
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        // Pull the equivalent record from local data
        let movie = self.movies![indexPath.row]
        
        // Get the title from that record
        let title = movie["title"] as! String
        // Set the cell's title
        cell.titleLabel.text = title
        
        // Get the overview from that record
        let overview = movie["overview"] as! String
        // Set the cell's overview
        cell.overviewLabel.text = overview
        
        // Attempt to get the poster_path and set into the cell
        if let posterPath = movie["poster_path"] as? String{
            let baseUrl = "https://image.tmdb.org/t/p/w500/"
            let imageUrl = NSURL(string: baseUrl + posterPath)
            self.fadeInImage(url: imageUrl!, poster: cell.posterView)
        }
        
        return cell
    }
    
    // API Get
    
    func getNowFeaturing(refreshControl: UIRefreshControl){
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        // Display HUD right before the request is made
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    self.networkErrorView.isHidden = true
                    
                    self.movies = dataDictionary["results"] as! [NSDictionary]
                    
                    // Hide HUD once the network request comes back (must be done on main UI thread)
                    MBProgressHUD.hide(for: self.view, animated: true)
                    
                    self.tableView.reloadData()
                    refreshControl.endRefreshing()

                }
            }else{
                // Network issue, show proper msg and attempt connection again
                self.networkErrorView.isHidden = false
                
                // Attempt API call again
                self.getNowFeaturing(refreshControl: refreshControl)
            }
        }
        task.resume()
    }
    
    // Fade in code
    
    func fadeInImage(url: NSURL, poster: UIImageView){
        let imageRequest = NSURLRequest(url: url as URL)
        
        poster.setImageWith(imageRequest as URLRequest, placeholderImage: nil, success: { (imageRequest, imageResponse, image) -> Void in
            // imageResponse will be nil if the image is cached
            if imageResponse != nil {
                print("Image was NOT cached, fade in image")
                poster.alpha = 0.0
                poster.image = image
                UIView.animate(withDuration: 0.4, animations: { () -> Void in
                    poster.alpha = 2.0
                })
            } else {
                print("Image was cached so just update the image")
                poster.image = image
            }
        }, failure:  { (imageRequest, imageResponse, error) -> Void in
            // do something for the failure condition
            poster.image = nil
        })
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl) {
        self.getNowFeaturing(refreshControl: refreshControl)
    }
    
    // Search code
    
    // This method updates movies based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, movies is the same as the original data
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the movies array
        // For each item, return true if the item should be included and false if the
        // item should NOT be included
        self.movies = searchText.isEmpty ? movies : movies?.filter({(movie: NSDictionary) -> Bool in
            // If dataItem matches the searchText, return true to include it
            return (movie["title"] as! String).range(of: searchText, options: .caseInsensitive) != nil
        })
        
        tableView.reloadData()
    }
    
    // Allows Search Bar to have cancel button
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    // Clears out search focus and pulls data when cancel is clicked
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        self.getNowFeaturing(refreshControl: refreshControl)
    }
    


}
