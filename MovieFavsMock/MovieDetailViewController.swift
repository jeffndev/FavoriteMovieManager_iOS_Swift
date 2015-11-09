//
//  MovieDetailViewController.swift
//  MovieFavsMock
//
//  Created by Jeff Newell on 10/28/15.
//  Copyright © 2015 Jeff Newell. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    var movie: Movie?
    var favMovies = [Movie]()
    var uid: Int?
    var sessionId: String?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var unFavoriteButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let appDelegateRef = UIApplication.sharedApplication().delegate as? AppDelegate else {
            return
        }
        uid = appDelegateRef.movieDbUserId
        sessionId = appDelegateRef.movieDbSessionId
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        guard let movie = movie else {
            print("movie was nil")
            return
        }
        titleLabel.text = movie.title
        loadFavoritesMovieData()
        if let posterPath = movie.posterPath {
            retreivePosterImageFromAPI(posterPath)
        }
        
    }
    
    
    @IBAction func unFavoriteAction(sender: UIButton) {
        updateFavorites(false)
    }
    
    @IBAction func addFavoriteAction(sender: UIButton) {
        updateFavorites(true)
    }
    
    func updateFavorites(favorite: Bool) {
        // ../account/{id}/favorite
        guard let uid = uid, let sessionId = sessionId, let movie = movie else {
            displayError("movie db session keys are not available")
            return
        }
        let method = "account/\(uid)/favorite"
        let restParms = [ "api_key": MovieDbAccess.API_KEY,
            "session_id": sessionId
        ]
        let requestString =  MovieDbAccess.SECURE_BASE_URL_STRING + method + MovieDbAccess.assembleRestParamaters(restParms)
        let url = NSURL(string: requestString)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = "{\n  \"media_type\": \"movie\",\n  \"media_id\": \(movie.id),\n  \"favorite\": \(favorite)\n}".dataUsingEncoding(NSUTF8StringEncoding)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            guard (error == nil) else {
                self.displayError("There was an error with your request: \(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    self.displayError("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    self.displayError("Your request returned an invalid response! Response: \(response)!")
                } else {
                    self.displayError("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                self.displayError("No data was returned by the request!")
                return
            }
            var parsedJSON: AnyObject!
            do {
                parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            }catch {
                self.displayError("data not parsable")
                return
            }
            guard let status_code = parsedJSON["status_code"] as? Int where MovieDbAccess.statusCodeIsOK(status_code) else {
                self.displayError("Movie was not able to be \(favorite ? "" : "un-")Favorited")
                return
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.favoriteButton.hidden = favorite
                self.unFavoriteButton.hidden = !favorite
            }
        }
        task.resume()
    }
    
    func displayError(msg: String) {
        let alv = UIAlertController()
        alv.title = nil
        alv.message = msg
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alv.addAction(okAction)
        self.presentViewController(alv, animated: true, completion: nil)
    }
    
    
    func retreivePosterImageFromAPI(path: String) {
        let baseURL = NSURL(string: MovieDbAccess.baseImageURLString)!
        let url = baseURL.URLByAppendingPathComponent("w342").URLByAppendingPathComponent(path)
        
        /* 3B. Configure the request */
        let request = NSURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        /* 4B. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                //print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    //print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    //print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    //print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                //print("No data was returned by the request!")
                return
            }
            
            /* 5B. Parse the data */
            // No need, the data is already raw image data.
            
            /* 6B. Use the data! */
            if let image = UIImage(data: data) {
                dispatch_async(dispatch_get_main_queue()) {
                    self.posterImageView!.image = image
                }
            } else {
                //print("Could not create image from \(data)")
            }
        }
        
        /* 7B. Start the request */
        task.resume()
    }
    
    func isMovieInMyFavorites(movieId: Int) -> Bool {
        // ../account/{id}/favorites/movies
        for m in favMovies {
            if m.id == movieId {
                return true
            }
        }
        return false
    }
    
    func loadFavoritesMovieData() {
        
        let method = "account/\(uid)/favorite/movies"
        var restParameters = [String: AnyObject]()
        restParameters["api_key"] = MovieDbAccess.API_KEY
        restParameters["session_id"] = sessionId
        
        let requestString = MovieDbAccess.SECURE_BASE_URL_STRING + method + MovieDbAccess.assembleRestParamaters(restParameters)
        print(requestString)
        guard let requestUrl = NSURL(string: requestString) else {
            //print("could not build a URL from \(requestString)")
            return
        }
        let request = NSMutableURLRequest(URL: requestUrl)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            //{ id: Int, page: Int, total_pages: Int, total_results: Int,
            //    results: [
            //            {backdrop_path: String, id: Int, original_title: String, release_data: String, poster_path: String, title: String, vote_average: Float, vote_count: Int},
            //            ....]
            //        }
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                //print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    //print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                   // print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    //print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                //print("No data was returned by the request!")
                return
            }
            let parsedJSON: AnyObject!
            do {
                parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
               // print("could not parse returned json from new authentication token request")
                return
            }
            let _ = parsedJSON["total_pages"] as? Int
            let _ = parsedJSON["page"] as? Int
            guard let moviesData = parsedJSON["results"] as? [[String: AnyObject]] else {
                //print("could not parse movie results from the JSON response")
                return
            }
            
            self.favMovies.removeAll()
            for m in moviesData {
                self.favMovies.append(Movie(title: m["title"] as! String, id: m["id"] as! Int, posterPath: m["poster_path"] as? String))
            }
            dispatch_async(dispatch_get_main_queue()) {
                let isFavorite = self.isMovieInMyFavorites(self.movie!.id)
                self.favoriteButton.hidden = isFavorite
                self.unFavoriteButton.hidden = !isFavorite
            }
        }
        task.resume()
    }
    
}
