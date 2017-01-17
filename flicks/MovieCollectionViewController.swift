//
//  MovieCollectionViewController.swift
//  flicks
//
//  Created by Rob Hernandez on 1/16/17.
//  Copyright © 2017 Robert Hernandez. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MovieCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Initialize a UIRefreshControl
    let refreshControl = UIRefreshControl()
    
    // Hold the data locally from the API call
    var movies: [NSDictionary]?

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self

        // Do any additional setup after loading the view.
        refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
        
        //Do the GET from the "The movies" API
        self.getNowFeaturing(refreshControl: refreshControl)
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return 3
    }
    

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "movieCollectCell", for: indexPath) as! MovieCollectionCell
        let movie = self.movies![indexPath.row]
        
        let title = movie["title"] as! String
        cell.titleLabel.text = title
        
        // Attempt to get the poster_path and set into the cell
        if let posterPath = movie["poster_path"] as? String{
            let baseUrl = "https://image.tmdb.org/t/p/w500/"
            let imageUrl = NSURL(string: baseUrl + posterPath)
            self.fadeInImage(url: imageUrl!, poster: cell.movieImage)
        }
        
        
        return cell
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl) {
        self.getNowFeaturing(refreshControl: refreshControl)
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
                    print("found data in collection")
                    self.movies = dataDictionary["results"] as! [NSDictionary]
                    
                    // Hide HUD once the network request comes back (must be done on main UI thread)
                    MBProgressHUD.hide(for: self.view, animated: true)
                    
                    self.collectionView.reloadData()
                    refreshControl.endRefreshing()
                    
                }
            }else{
                print("didnt find data")
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



}
