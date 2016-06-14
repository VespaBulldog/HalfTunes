//
//  ViewController.swift
//  HalfTunes
//
//  Created by Evan on 2016/6/8.
//  Copyright © 2016年 Evan. All rights reserved.
//

import UIKit
import MediaPlayer

class SearchViewController: UIViewController,NSURLSessionDelegate
{
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    var searchResults = [Track]()
    
    lazy var tapRecognizer:UITapGestureRecognizer = {
        var recognizer = UITapGestureRecognizer(target:self, action: #selector(self.dismissKeyboard))
        return recognizer
    }()
    
    // 1. 創造 NSURLSession 並初始化成 defaultSessionConfiguration
    let defaultSession = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration())
    
    // 2. 宣告一個 DataTask 的變數 當使用者執行搜尋時 你將用他去執行HTTP GET 請求，每次使用者有心的請求這個 DataTask 將會被重複使用及重複初始化。
    var dataTask : NSURLSessionDataTask?
    
    var activeDownloads = [String : Download]()
    
    //lazy 適當有需要時，才初始化
    // 用default configuration 初始化一個額外的session 用來處理 download Task
    lazy var downloadSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.barTintColor = UIColor(red: 242/255, green: 71/255, blue: 63/255, alpha: 1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // This helper method helps parse response JSON NSData into an array of Track objects.
    // 把json data 轉換成 Track物件 並存入陣列中
    func updateSearchResults(data: NSData?) {
        searchResults.removeAll()
        do {
            // NSJSONSerialization 用來轉換json data
            //+ JSONObjectWithData:options:error: 用來產生 json物件
            // NSJSONReadingOptions 根據json data 來創造物件
            if let data = data, response = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions(rawValue:0)) as? [String: AnyObject]
            //if let data = data, response = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [String: AnyObject]
            {
                // Get the results array
                // 把得到的結果一個一個放到陣列內
                if let array: AnyObject = response["results"] {
                    // 再把每個陣列內的值放入字典中
                    for trackDictonary in array as! [AnyObject] {
                        if let trackDictonary = trackDictonary as? [String: AnyObject], previewUrl = trackDictonary["previewUrl"] as? String {
                            // Parse the search result
                            let name = trackDictonary["trackName"] as? String
                            let artist = trackDictonary["artistName"] as? String
                            searchResults.append(Track(name: name, artist: artist, previewUrl: previewUrl))
                        } else {
                            print("Not a dictionary")
                        }
                    }
                } else {
                    print("Results key not found in dictionary")
                }
            } else {
                print("JSON Error")
            }
        } catch let error as NSError {
            print("Error parsing results: \(error.localizedDescription)")
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
            // tableView移到最上面
            self.tableView.setContentOffset(CGPointZero, animated: false)
        }
    }
    
    func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    
    // Called when the Download button for a track is tapped
    func startDownload(track: Track) {
        // TODO
    }
    
    // Called when the Pause button for a track is tapped
    func pauseDownload(track: Track) {
        // TODO
    }
    
    // Called when the Cancel button for a track is tapped
    func cancelDownload(track: Track) {
        // TODO
    }
    
    // Called when the Resume button for a track is tapped
    func resumeDownload(track: Track) {
        // TODO
    }

    func playDownload(track: Track) {
        if let urlString = track.previewUrl, url = localFilePathForUrl(urlString) {
            let moviePlayer:MPMoviePlayerViewController! = MPMoviePlayerViewController(contentURL: url)
            presentMoviePlayerViewControllerAnimated(moviePlayer)
        }
    }
    
    // MARK: Download helper methods
    
    // This method generates a permanent local file path to save a track to by appending
    // the lastPathComponent of the URL (i.e. the file name and extension of the file)
    // to the path of the app’s Documents directory.
    func localFilePathForUrl(previewUrl: String) -> NSURL? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        if let url = NSURL(string: previewUrl), lastPathComponent = url.lastPathComponent {
            let fullPath = documentsPath.stringByAppendingPathComponent(lastPathComponent)
            return NSURL(fileURLWithPath:fullPath)
        }
        return nil
    }
    
    // This method checks if the local file exists at the path generated by localFilePathForUrl(_:)
    func localFileExistsForTrack(track: Track) -> Bool {
        if let urlString = track.previewUrl, localUrl = localFilePathForUrl(urlString) {
            var isDir : ObjCBool = false
            if let path = localUrl.path {
                return NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir)
            }
        }
        return false
    }
    
}

// MARK: - UISearchBarDelegate
//擴充 SearchViewController 內的 UISearchBarDelegate 方法
extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        // Dimiss the keyboard
        dismissKeyboard()
        
        if !searchBar.text!.isEmpty
        {
            // 1. 如果有dataTask的話就先取消
            if dataTask != nil
            {
                dataTask?.cancel()
            }
            
            // 2.networkActivityIndicator 可見
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            // 3.轉換searchBar text
            let expectedCharSet = NSCharacterSet.URLQueryAllowedCharacterSet()
            let searchTerm = searchBar.text!.stringByAddingPercentEncodingWithAllowedCharacters(expectedCharSet)!
            
            // 4.把轉換過的searchBar text 加到url
            let url = NSURL(string: "https://itunes.apple.com/search?media=music&entity=song&term=\(searchTerm)")
            
            // 5. 初始化 NSURLSessionDataTask 來處理 HTTP GET
            dataTask = defaultSession.dataTaskWithURL(url!){
                data,response,error in
                
                // 6. 當 dataTask 接收到callBack 去主執行緒把 networkActivityIndicatorVisible 關閉
                dispatch_async(dispatch_get_main_queue()) {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
                
                // 7.成功時呼叫 updateSearchResults
                if let error = error
                {
                    print(error.localizedDescription)
                }
                else if let httpResponse = response as? NSHTTPURLResponse
                {
                    if httpResponse.statusCode == 200
                    {
                        self.updateSearchResults(data)
                    }
                }
            }
            // 8. 啟動
            dataTask?.resume()
        }
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        view.addGestureRecognizer(tapRecognizer)
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        view.removeGestureRecognizer(tapRecognizer)
    }
}

// MARK: TrackCellDelegate

extension SearchViewController: TrackCellDelegate {
    func pauseTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let track = searchResults[indexPath.row]
            pauseDownload(track)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func resumeTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let track = searchResults[indexPath.row]
            resumeDownload(track)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func cancelTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let track = searchResults[indexPath.row]
            cancelDownload(track)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func downloadTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let track = searchResults[indexPath.row]
            startDownload(track)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
}

// MARK: UITableViewDataSource

extension SearchViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as!TrackCell
        
        // Delegate cell button tap events to this view controller
        cell.delegate = self
        
        let track = searchResults[indexPath.row]
        
        // Configure title and artist labels
        cell.titleLabel.text = track.name
        cell.artistLabel.text = track.artist
        
        // If the track is already downloaded, enable cell selection and hide the Download button
        let downloaded = localFileExistsForTrack(track)
        cell.selectionStyle = downloaded ? UITableViewCellSelectionStyle.Gray : UITableViewCellSelectionStyle.None
        cell.downloadButton.hidden = downloaded
        
        return cell
    }
}

// MARK: UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 62.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let track = searchResults[indexPath.row]
        if localFileExistsForTrack(track) {
            playDownload(track)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

