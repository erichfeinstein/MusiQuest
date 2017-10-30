//
//  ViewController.swift
//  Musiquest
//
//  Created by Eric Feinstein on 4/3/16.
//  Copyright © 2016 Eric Feinstein. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, AVAudioPlayerDelegate, UITextFieldDelegate, UIViewControllerTransitioningDelegate {
    @IBOutlet weak var artistLabel: MarqueeLabel!
    @IBOutlet weak var songLabel: MarqueeLabel!
    @IBOutlet weak var artistPicture: UIImageView!
    @IBOutlet weak var backgroundPicture: UIImageView!
    @IBOutlet weak var searchBox: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    @IBOutlet weak var nowPlaying: UILabel!
    @IBOutlet weak var musiquestLabel: UILabel!
    @IBOutlet weak var restartSearchButton: UIButton!
    @IBOutlet weak var spotifyButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var rewindButton: UIButton!
    
    static var currentSongName: String!
    static var currentArtistID: String!
    static var currentArtistsName: String!
    static var currentArtistURL: String!
    static var visitedArtists = [""]
    static var nextArtist: AnyObject!
    static var initialSearch: Bool = true
    static var blockedArtists = [""]
    var playing = false
    var songPlaying: AVAudioPlayer!
    
    override func viewDidLoad() {
        ViewController.currentSongName = "Loading..."
        searchBox.delegate = self
        artistPicture.image = UIImage(named: "spotify-logo500.png")
        likeButton.enabled = false
        dislikeButton.enabled = false
        okButton.enabled = false
        likeButton.alpha = 0
        dislikeButton.alpha = 0
        okButton.alpha = 0
        spotifyButton.enabled = false
        spotifyButton.alpha = 0
        nowPlaying.alpha = 0
        restartSearchButton.alpha = 0
        restartSearchButton.enabled = false
        pauseButton.alpha = 0
        rewindButton.alpha = 0
        pauseButton.enabled = false
        rewindButton.enabled = false
        searchBox.attributedPlaceholder = NSAttributedString(string:"ex: The Beatles", attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
    
    func updateLabels(){
        artistPicture.backgroundColor = UIColor.blackColor()
        dispatch_async(dispatch_get_main_queue()) {
            self.artistLabel.text = "You found \(ViewController.currentArtistsName)!     "
            self.songLabel.text = "\(ViewController.currentSongName)     "
        }
    }
    
    @IBAction func openInSpotify(sender: UIButton) {
        UIApplication.sharedApplication().openURL(NSURL(string: ViewController.currentArtistURL)!)
    }
    
    @IBAction func findDifferentArtist(sender: UIButton) {
        ViewController.currentArtistID = ViewController.visitedArtists[ViewController.visitedArtists.count-2]
        findRelatedArtist(dislikeButton)
    }
    @IBAction func findRelatedArtist(sender: UIButton) {
        if (ViewController.initialSearch) {
            likeButton.enabled = true
            dislikeButton.enabled = true
            likeButton.alpha = 1
            dislikeButton.alpha = 1
            okButton.enabled = false
            okButton.alpha = 0
            ViewController.initialSearch = false
        }
        if pauseButton.currentImage == UIImage(named: "play.png") {
            if let image = UIImage(named: "pause.png") {
                pauseButton.setImage(image, forState: .Normal)
            }
        }
        rewindButton.enabled = true
        let url = "https://api.spotify.com/v1/artists/\(ViewController.currentArtistID)/related-artists"
        let requestURL = NSURL(string: url)
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL!)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(urlRequest) { (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                do{
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                    if let artists = json["artists"] as! NSArray? {
                        if (artists.count == 0) {
                            let alert = UIAlertController(title: "Uh oh!", message: "Looks like your quest has ended. Hit the search button to start a new Musiquest!", preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
                            self.presentViewController(alert, animated: true, completion: nil)
                            //Out of artists, must start new search
                            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                                self.likeButton.enabled = false
                                self.likeButton.alpha = 0.5
                                self.dislikeButton.enabled = false
                                self.dislikeButton.alpha = 0.5
                                self.rewindButton.enabled = false
                            }
                            return
                        }
                        for i in 0 ..< artists.count {
                            if (!ViewController.visitedArtists.contains(artists[i]["id"] as! String)){
                                ViewController.nextArtist = artists[i]
                                break
                            }
                        }
                        if let name = ViewController.nextArtist["name"] {
                            ViewController.currentArtistsName = name as! String
                            self.updateLabels()
                        }
                        if let urls = ViewController.nextArtist["external_urls"] {
                            if let spotify_url = urls!["spotify"] {
                                ViewController.currentArtistURL = spotify_url as! String
                            }
                        }
                        if let id = ViewController.nextArtist["id"] {
                            ViewController.currentArtistID = id as! String
                            ViewController.visitedArtists.append(id as! String)
                            self.findTopSong(0)
                        }
                        if let images = ViewController.nextArtist["images"] {
                            let urlString = images![0]["url"] as! String
                            let imageUrl = NSURL(string: urlString)
                            self.downloadImage(imageUrl!, view: self.artistPicture)
                        }
                    }
                }catch {
                    print("Error: \(error)")
                }
            }
        }
        task.resume()
    }
    
    //Returns the id of the artist searched
    @IBAction func searchArtist(sender: UIButton) {
        if searchBox.text == "" {
            let alert = UIAlertController(title: "Error!", message: "You need to enter an artist to search!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            searchSpotifyForArtist(searchBox.text!)
        }
    }
    
    func updateUI() {
        if (ViewController.currentArtistID != nil){
            restartSearchButton.alpha = 1
            restartSearchButton.enabled = true
            musiquestLabel.alpha = 0
            searchBox.enabled = false
            searchBox.alpha = 0
            okButton.enabled = true
            okButton.alpha = 1
            spotifyButton.enabled = true
            spotifyButton.alpha = 1
            searchButton.enabled = false
            searchButton.alpha = 0
            nowPlaying.alpha = 1
            pauseButton.enabled = true
            pauseButton.alpha = 1
            rewindButton.enabled = false
            rewindButton.alpha = 1
            
            likeButton.enabled = false
            likeButton.alpha = 0
            dislikeButton.enabled = false
            dislikeButton.alpha = 0
        }
    }
    
    @IBAction func pause(sender: UIButton) {
        if pauseButton.currentImage == UIImage(named: "play.png") {
            songPlaying.play()
            if let image = UIImage(named: "pause.png") {
                pauseButton.setImage(image, forState: .Normal)
            }
        } else {
            songPlaying.pause()
            if let image = UIImage(named: "play.png") {
                pauseButton.setImage(image, forState: .Normal)
            }
        }
    }
    @IBAction func rewind(sender: UIButton) {
        //Skips over any "blocked" artists, which are artists who have Spotify pages, but with no tracks
        if (ViewController.blockedArtists.contains(ViewController.visitedArtists[ViewController.visitedArtists.count-2])){
            ViewController.visitedArtists.removeLast()
        }
        ViewController.visitedArtists.removeLast()
        let lastID = ViewController.visitedArtists.removeLast()
        ViewController.currentArtistID = lastID
        let url = "https://api.spotify.com/v1/artists/" + lastID
        let requestURL = NSURL(string: url)
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL!)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(urlRequest) { (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                do{
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                    if let name = json["name"] {
                        ViewController.currentArtistsName = name as! String
                        self.updateLabels()
                    }
                    if let images = json["images"] {
                        if images!.count == 0 {
                            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                                let image = UIImage(named: "nilartist.png")!
                                self.artistPicture.image = image
                            }
                        }else{
                            let urlString = images![0]["url"] as! String
                            let imageUrl = NSURL(string: urlString)
                            self.downloadImage(imageUrl!, view: self.artistPicture)
                        }
                    }
                    if let urls = json["external_urls"] {
                        if let spotify_url = urls!["spotify"] {
                            ViewController.currentArtistURL = spotify_url as! String
                        }
                    }
                    ViewController.visitedArtists.append(lastID)
                }catch {
                    print("Error: \(error)")
                }
            }
        }
        task.resume()
        self.findTopSong(0)
        if (ViewController.visitedArtists.count == 1){
            rewindButton.enabled = false
            okButton.enabled = true
            okButton.alpha = 1
            likeButton.enabled = false
            likeButton.alpha = 0
            dislikeButton.enabled = false
            dislikeButton.alpha = 0
            ViewController.initialSearch = true
        }
    }
    
    func searchSpotifyForArtist(q: String){
        let url = "https://api.spotify.com/v1/search"
        let parameters = ["q": q, "type": "artist"]
        let requestURL = NSURL(string: url + "?" + parameters.stringFromHttpParameters())
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL!)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Authorization")
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(urlRequest) { (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                do{
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                    if let artists = json["artists"] {
                        if let items = artists!["items"] {
                            if (items!.count == 0) {
                                return
                            }
                            if let name = items![0]["name"] {
                                ViewController.currentArtistsName = name as! String
                                self.updateLabels()
                            }
                            if let urls = items![0]["external_urls"] {
                                if let spotify_url = urls!["spotify"] {
                                    ViewController.currentArtistURL = spotify_url as! String
                                }
                            }
                            if let id = items![0]["id"] {
                                //GOT THE ARTIST ID
                                ViewController.currentArtistID = id as! String
                                ViewController.visitedArtists.append(id as! String)
                                self.findTopSong(0)
                                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                                    self.updateUI()
                                }
                            }
                            if let images = items![0]["images"] {
                                if images!.count == 0 {
                                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                                        let image = UIImage(named: "nilartist.png")!
                                        self.artistPicture.image = image
                                    }
                                }else{
                                    let urlString = images![0]["url"] as! String
                                    let imageUrl = NSURL(string: urlString)
                                    self.downloadImage(imageUrl!, view: self.artistPicture)
                                }
                            }
                        }
                    }
                }catch {
                    print("Error: \(error)")
                }
            }
        }
        task.resume()
    }
    
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    func downloadImage(url: NSURL, view: UIImageView){
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                view.image = UIImage(data: data)
            }
        }
    }
    
    func findTopSong(trackNumber: Int){
        let url = "https://api.spotify.com/v1/artists/\(ViewController.currentArtistID)/top-tracks"
        let parameters = ["country": "US"]
        let requestURL = NSURL(string: url + "?" + parameters.stringFromHttpParameters())
        
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL!)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(urlRequest) { (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                do{
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                    if let tracks = json["tracks"] as! NSArray? {
                        if tracks.count == 0 {
                            ViewController.blockedArtists.append(ViewController.currentArtistID)
                            ViewController.currentArtistID = ViewController.visitedArtists[ViewController.visitedArtists.count-2]
                            self.findRelatedArtist(self.likeButton)
                            return
                        }
                        if let topTrack = tracks[trackNumber] as AnyObject? {
                            if let preview = topTrack["preview_url"] {
                                //If top track doesn't have a preview, continue through artist's tracks
                                if preview is NSNull {
                                    self.findTopSong(trackNumber+1)
                                }
                                else {
                                    let url = NSURL(string: preview as! String)
                                    self.playSong(url!)
                                }
                            }
                            if let name = topTrack["name"] {
                                ViewController.currentSongName = name as! String
                                self.updateLabels()
                            }
                            if let album = topTrack["album"] {
                                if let images = album!["images"] {
                                    let urlString = images![0]["url"] as! String
                                    let imageUrl = NSURL(string: urlString)
                                    self.downloadImage(imageUrl!, view: self.backgroundPicture)
                                }
                            }
                        }
                    }
                }catch {
                    print("Error: \(error)")
                }
            }
        }
        task.resume()
    }
    
    func playSong(url: NSURL){
        do {
            let soundData = NSData(contentsOfURL:url)
            self.songPlaying = try AVAudioPlayer(data: soundData!)
            songPlaying.prepareToPlay()
            songPlaying.volume = 1.0
            songPlaying.delegate = self
            songPlaying.numberOfLoops = -1
            if (pauseButton.currentImage == UIImage(named: "play.png")){
                songPlaying.pause()
            }else{
                songPlaying.play()
            }
        } catch {
            // couldn't find file
        }
    }
        
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
    //Buttons
    @IBAction func newSearch(sender: UIButton) {
        let alert = UIAlertController(title: "Start a new Musiquest?", message: "Enter a new artist below", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler {
                (newSearchQ) -> Void in
                newSearchQ.placeholder = "ex: The Beatles"
            }
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Start!", style: .Default, handler: { action in
            switch action.style{
            case .Default:
                ViewController.visitedArtists.removeAll()
                ViewController.visitedArtists.append("")
                self.searchSpotifyForArtist((alert.textFields?.first!.text)!)
                ViewController.initialSearch = true
            case .Cancel:
                print("cancel")
            case .Destructive:
                print("destructive")
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    @IBAction func info(sender: UIButton) {
        let alert = UIAlertController(title: "Welcome to Musiquest!", message: "Enter an artist and begin discovering new music, with information provided by Spotify's library.\n\nIf you're having trouble finding an artist, make sure that your search is spelled correctly. Also, remember that not every musician allows their music to be streamed on Spotify.\n\n\nEnjoy your Musiquest!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok!", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

extension String {
    func stringByAddingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
    }
}

extension Dictionary {
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).stringByAddingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).stringByAddingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        return parameterArray.joinWithSeparator("&")
    }
}

