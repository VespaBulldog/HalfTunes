//
//  Download.swift
//  HalfTunes
//
//  Created by Evan on 2016/6/14.
//  Copyright © 2016年 Evan. All rights reserved.
//

import UIKit

class Download: NSObject {
    var url : String
    var isDownloading = false
    var progress : Float = 0.0
    var downloadTask = NSURLSessionDownloadTask?()
    var resumeData = NSData?()
    
    init(url :String)
    {
        self.url = url
    }
    
}
