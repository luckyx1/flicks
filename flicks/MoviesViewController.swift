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


class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkErrorView: UIView!
    var movies: [NSDictionary]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize a UIRefreshControl
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
        
        // Setup the UITable
        tableView.dataSource = self
        tableView.delegate = self
        
        
        // add refresh control to table view
        tableView.insertSubview(refreshControl, at: 0)
        
        self.networkErrorView.isHidden = false
        
        //Do the gets from the API
        self.getNowFeaturing(refreshControl: refreshControl)

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if let movies = movies {
            return movies.count
        }else{
            return 0
        }
    }
    

    func fadeInImage(url: NSURL, poster: UIImageView){
        let imageRequest = NSURLRequest(url: url as URL)
        
        poster.setImageWith(imageRequest as URLRequest, placeholderImage: nil, success: { (imageRequest, imageResponse, image) -> Void in
            // imageResponse will be nil if the image is cached
            if imageResponse != nil {
                print("Image was NOT cached, fade in image")
                poster.alpha = 0.0
                poster.image = image
                UIView.animate(withDuration: 1.0, animations: { () -> Void in
                    poster.alpha = 3.0
                })
            } else {
                print("Image was cached so just update the image")
                poster.image = image
            }
        }, failure:  { (imageRequest, imageResponse, error) -> Void in
            // do something for the failure condition
        })
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        
        let movie = self.movies![indexPath.row]
        
        let title = movie["title"] as! String
        cell.titleLabel.text = title
        
        let overview = movie["overview"] as! String
        cell.overviewLabel.text = overview
        
        if let posterPath = movie["poster_path"] as? String{
            let baseUrl = "https://image.tmdb.org/t/p/w500/"
            let imageUrl = NSURL(string: baseUrl + posterPath)
            self.fadeInImage(url: imageUrl!, poster: cell.imageView!)
        }
        
        
        return cell
    }
    
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
            }
        }
        task.resume()
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl) {
        self.getNowFeaturing(refreshControl: refreshControl)
    }
    


}
