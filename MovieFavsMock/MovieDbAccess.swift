//
//  MovieDbAccess.swift
//  MovieFavsMock
//
//  Created by Jeff Newell on 10/26/15.
//  Copyright © 2015 Jeff Newell. All rights reserved.
//

import Foundation

class MovieDbAccess {
    
    static let API_KEY: String = "21ac243915da272c3c6b92a9958a3650"
    static let BASE_URL_STRING: String = "http://api.themoviedb.org/3/"
    static let SECURE_BASE_URL_STRING: String = "https://api.themoviedb.org/3/"
    
    static let baseImageURLString = "http://image.tmdb.org/t/p/"
    static let secureBaseImageURLString =  "https://image.tmdb.org/t/p/"
    static let posterSizes = ["w92", "w154", "w185", "w342", "w500", "w780", "original"]
    static let profileSizes = ["w45", "w185", "h632", "original"]

    
    static func urlEncode(text: String?) -> String? {
        if let strToEncode = text {
            return strToEncode.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        } else {
            return text
        }
    }
    static func assembleRestParamaters(parameters: [String: AnyObject]) -> String {
        var encodedParametersChunks = [String]()
        for (key, val) in parameters {
            let value = "\(val)"
            if let encodedVal = MovieDbAccess.urlEncode(value) {
                encodedParametersChunks.append("\(key)=\(encodedVal)")
            }
        }
        return encodedParametersChunks.count == 0 ? "" : "?\(encodedParametersChunks.joinWithSeparator("&"))"
    }
    static func statusCodeIsOK(statusCode: Int) -> Bool {
        let goodStatus: Set<Int> = [ 1, 12, 13 ]
        return goodStatus.contains(statusCode)
    }
}

/* Movie Db status_codes (as of 10/28/2015
 https://www.themoviedb.org/documentation/api/status-codes
1	200	Success.
2	501	Invalid service: this service does not exist.
3	401	Authentication failed: You do not have permissions to access the service.
4	405	Invalid format: This service doesn't exist in that format.
5	422	Invalid parameters: Your request parameters are incorrect.
6	404	Invalid id: The pre-requisite id is invalid or not found.
7	401	Invalid API key: You must be granted a valid key.
8	403	Duplicate entry: The data you tried to submit already exists.
9	503	Service offline: This service is temporarily offline, try again later.
10	401	Suspended API key: Access to your account has been suspended, contact TMDb.
11	500	Internal error: Something went wrong, contact TMDb.
12	201	The item/record was updated successfully.
13	200	The item/record was deleted successfully.
14	401	Authentication failed.
15	500	Failed.
16	401	Device denied.
17	401	Session denied.
18	400	Validation failed.
19	406	Invalid accept header.
20	422	Invalid date range: Should be a range no longer than 14 days.
21	200	Entry not found: The item you are trying to edit cannot be found.
22	400	Invalid page: Pages start at 1 and max at 1000. They are expected to be an integer.
23	400	Invalid date: Format needs to be YYYY-MM-DD.
24	504	Your request to the backend server timed out. Try again.
25	429	Your request count (#) is over the allowed limit of (40).
26	400	You must provide a username and password.
27	400	Too many append to response objects: The maximum number of remote calls is 20.
28	400	Invalid timezone: Please consult the documentation for a valid timezone.
29	400	You must confirm this action: Please provide a confirm=true parameter.
30	401	Invalid username and/or password: You did not provide a valid login.
31	401	Account disabled: Your account is no longer active. Contact TMDb if this is an error.
32	401	Email not verified: Your email address has not been verified.
33	401	Invalid request token: The request token is either expired or invalid.
34	401	The resource you requested could not be found.
*/