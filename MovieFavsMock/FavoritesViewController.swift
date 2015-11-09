//
//  FavoritesViewController.swift
//  MovieFavsMock
//
//  Created by Jeff Newell on 10/28/15.
//  Copyright © 2015 Jeff Newell. All rights reserved.
//

import UIKit

class FavoritesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let CELL_IDENTIFIER = "FavoritesCell"
    var movies = [Movie]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Reply, target: self, action: "logOutAction")
    }
    func logOutAction() {
        self.dismissViewControllerAnimated(true, completion: nil)
        //TODO: do we want to negate the sessionId or something deeper?
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //time to call in for the data..
        loadMovieData()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let vc =  self.storyboard?.instantiateViewControllerWithIdentifier("MovieDetailViewController") as! MovieDetailViewController
        vc.movie = movies[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let CELL_IMAGE_SIZE_FORMAT = "w154"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER)!
        cell.textLabel?.text = movies[indexPath.row].title
        cell.imageView!.image = UIImage(named: "Film Icon")
        cell.imageView!.contentMode = .ScaleAspectFit
        //get the image from an api call
        if let posterPath = movies[indexPath.row].posterPath {
            let baseUrl = NSURL(string: MovieDbAccess.baseImageURLString)
            let requestUrl = baseUrl?.URLByAppendingPathComponent(CELL_IMAGE_SIZE_FORMAT).URLByAppendingPathComponent(posterPath)
            let request = NSMutableURLRequest(URL: requestUrl!)
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request) { (data, response, error) in
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
                if let imageFromUrl = UIImage(data: data) {
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView!.image = imageFromUrl
                    }
                }
            }
            task.resume()
        }
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    
    func loadMovieData() {
        guard let appDelegateRef = UIApplication.sharedApplication().delegate as? AppDelegate else {
            //print("could not access the app to save the session id")
            return
        }
        guard let uid = appDelegateRef.movieDbUserId else {
            //print("could not find session user_id")
            return
        }
        let method = "account/\(uid)/favorite/movies"
        var restParameters = [String: AnyObject]()
        restParameters["api_key"] = MovieDbAccess.API_KEY
        restParameters["session_id"] = appDelegateRef.movieDbSessionId
        
        let requestString = MovieDbAccess.SECURE_BASE_URL_STRING + method + MovieDbAccess.assembleRestParamaters(restParameters)
        //print(requestString)
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
            let parsedJSON: AnyObject!
            do {
                parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                //print("could not parse returned json from new authentication token request")
                return
            }
            let _ = parsedJSON["total_pages"] as? Int
            let _ = parsedJSON["page"] as? Int
            guard let moviesData = parsedJSON["results"] as? [[String: AnyObject]] else {
                //print("could not parse movie results from the JSON response")
                return
            }
            
            self.movies.removeAll()
            for m in moviesData {
                self.movies.append(Movie(title: m["title"] as! String, id: m["id"] as! Int, posterPath: m["poster_path"] as? String))
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
        //print("count of favorites: \(movies.count)")
        task.resume()
    }
    
}