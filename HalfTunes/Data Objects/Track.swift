//
//  Track.swift
//  HalfTunes
//
//  Created by Evan on 2016/6/8.
//  Copyright © 2016年 Evan. All rights reserved.
//

class Track
{
    var name: String?
    var artist: String?
    var previewUrl: String?
    
    init(name: String?, artist: String?, previewUrl: String?)
    {
        self.name = name
        self.artist = artist
        self.previewUrl = previewUrl
    }
}
