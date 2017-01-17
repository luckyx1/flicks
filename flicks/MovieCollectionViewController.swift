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

class MovieCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Hold the data locally from the API call
    var movies: [NSDictionary]?

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
       

    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return self.movies?.count ?? 0
    }
    

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
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
