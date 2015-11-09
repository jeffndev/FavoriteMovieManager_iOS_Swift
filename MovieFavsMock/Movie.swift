//
//  Movie.swift
//  MovieFavsMock
//
//  Created by Jeff Newell on 10/28/15.
//  Copyright © 2015 Jeff Newell. All rights reserved.
//

import UIKit

struct Movie {
    private static let TITLE_KEY = "title"
    private static let ID_KEY = "id"
    private static let POSTER_PATH_KEY = "poster_path"
    
    var title = ""
    var id = 0
    var posterPath: String? = nil
    
    static func fromJSON(jsonObject: [String: AnyObject]) -> Movie? {
        guard let movieTitle = jsonObject[TITLE_KEY] as? String, let movieId = jsonObject[ID_KEY] as? Int, let moviePosterPath = jsonObject[POSTER_PATH_KEY] as? String else {
            return nil
        }
        return Movie(title: movieTitle, id: movieId, posterPath: moviePosterPath)
    }
}
