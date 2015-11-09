//
//  ViewController.swift
//  MovieFavsMock
//
//  Created by Jeff Newell on 10/22/15.
//  Copyright © 2015 Jeff Newell. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var userNameText: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    var tapRecognizer: UITapGestureRecognizer?
    var keyboardAdjusted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        tapRecognizer?.numberOfTapsRequired = 1
        
        //some UI tweaks..
        let paddingLeftFrame = CGRectMake(0.0,0.0, 8.0,0.0)
        userNameText.leftView = UIView(frame: paddingLeftFrame)
        userNameText.leftViewMode = .Always
        passwordText.leftView = UIView(frame: paddingLeftFrame)
        passwordText.leftViewMode = .Always
        loginButton.layer.cornerRadius = CGFloat(4.0)
        
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        view.addGestureRecognizer(tapRecognizer!)
        registerForKeyboardNotifications()
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        view.removeGestureRecognizer(tapRecognizer!)
        unregisterForKeyboardNotifications()
    }
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    
    @IBAction func loginAction(sender: UIButton) {
        
        guard let uname = userNameText.text where uname.characters.count > 1 else {
            userNameText.placeholder = "YOU MUST ENTER A USER NAME"
            return
        }
        guard let pword = passwordText.text where pword.characters.count > 1 else {
            passwordText.placeholder = "YOU MUST ENTER A PASSWORD"
            return
        }
        
        let method = "authentication/token/new"
        var restParameters = [String: AnyObject]()
        restParameters["api_key"] = MovieDbAccess.API_KEY
        
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
            //TODO: all the usual checks...
            
            
            guard let data = data else {
                //print("empty data object returned")
                return
            }
            let parsedJSON: AnyObject!
            do {
                parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                //print("could not parse returned json from new authentication token request")
                return
            }
            guard let success = parsedJSON["success"] as? Bool where success == true else {
                //print("auth token request was not successful")
                return
            }
            guard let requestToken = parsedJSON["request_token"] as? String else {
                //print("request token came up empty")
                return
            }
            
            self.loginFinalizeWithRequestToken(requestToken, uname: uname, pword: pword)
        }
        task.resume()
    }
    func loginFinalizeWithRequestToken(authRequestToken: String, uname: String, pword: String) {
        let method = "authentication/token/validate_with_login"
        var restParameters = [String: AnyObject]()
        restParameters["api_key"] = MovieDbAccess.API_KEY
        restParameters["request_token"] = authRequestToken
        restParameters["username"] = uname //"jefenew"
        restParameters["password"] = pword //"Z0r8nSuxB8lls"
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
            //TODO: all the usual checks...
            
            
            guard let data = data else {
                //print("empty data object returned")
                return
            }
            let parsedJSON: AnyObject!
            do {
                parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                //print("could not parse returned json from new authentication token request")
                return
            }
            guard let success = parsedJSON["success"] as? Bool where success == true else {
                //print("auth token request was not successful")
                return
            }
            guard let requestToken = parsedJSON["request_token"] as? String else {
                //print("request token came up empty")
                return
            }
            guard requestToken == authRequestToken else {
                //print("returned token from login validation not the same as submitted")
                return
            }
            self.loginRequestSession(requestToken)
        }
        task.resume()
    }
    func loginRequestSession(authRequestToken: String) {
        
        let method = "authentication/session/new"
        var restParameters = [String: AnyObject]()
        restParameters["api_key"] = MovieDbAccess.API_KEY
        restParameters["request_token"] = authRequestToken
        
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
            //TODO: all the usual checks...
            
            
            guard let data = data else {
                //print("empty data object returned")
                return
            }
            let parsedJSON: AnyObject!
            do {
                parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                //print("could not parse returned json from new authentication token request")
                return
            }
            guard let success = parsedJSON["success"] as? Bool where success == true else {
                //print("auth token request was not successful")
                return
            }
            guard let sessionId = parsedJSON["session_id"] as? String else {
                //print("session id came up empty")
                return
            }
            guard let appDelegateRef = UIApplication.sharedApplication().delegate as? AppDelegate else {
                //print("could not access the app to save the session id")
                return
            }
            appDelegateRef.movieDbSessionId = sessionId
            
            dispatch_async(dispatch_get_main_queue()) {
                let tabController = self.storyboard?.instantiateViewControllerWithIdentifier("GenresTabBarController") as! UITabBarController
                self.presentViewController(tabController, animated: true, completion: nil)
            }
            self.getUserID(sessionId)
        }
        task.resume()
        
        
    }
    func getUserID(session_id : String) {
        
        let method = "account"
        var restParameters = [String: AnyObject]()
        restParameters["api_key"] = MovieDbAccess.API_KEY
        restParameters["session_id"] = session_id
        
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
            //TODO: all the usual checks...
            
            
            guard let data = data else {
                //print("empty data object returned")
                return
            }
            let parsedJSON: AnyObject!
            do {
                parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                //print("could not parse returned json from new authentication token request")
                return
            }
            guard let userId = parsedJSON["id"] as? Int else {
                //print("user id came up empty")
                return
            }
            guard let appDelegateRef = UIApplication.sharedApplication().delegate as? AppDelegate else {
                //print("could not access the app to save the session id")
                return
            }
            appDelegateRef.movieDbUserId = userId
            
//            dispatch_async(dispatch_get_main_queue()) {
//                self.debugTextLabel.text = "User Id: \(userId)"
//            }
        }
        task.resume()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if !keyboardAdjusted {
            self.view.superview?.frame.origin.y -= getKeyboardHeight(notification)/2
            keyboardAdjusted = true
        }
    }
    func keyboardWillHide(notification: NSNotification) {
        if keyboardAdjusted {
            self.view.superview?.frame.origin.y += getKeyboardHeight(notification)/2
            keyboardAdjusted = false
        }
    }
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    func registerForKeyboardNotifications(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    func unregisterForKeyboardNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    
}

