//
//  Artwork.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/18/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import Firebase
import MapKit

class Artwork {
    public var worldMap: Data?
    public var screenshot: Data?
    public var screenshotOrientation: Int = 1
    public var dateCreated: Date?
    public var name: String = ""
    public var author: String = ""
    public var coordinate: CLLocation?
    
    init() {
    }
    
    func encode() -> Any {
        // Can only store objects of type NSNumber, NSString, NSDictionary, and NSArray
        
        let world_string = worldMap?.base64EncodedString(options: Data.Base64EncodingOptions())
        
        let screenshot_string = screenshot?.base64EncodedString(options: NSData.Base64EncodingOptions())
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        let date_string = formatter.string(from: dateCreated!)
        
        return [
            "name": name,
            "author": author,
            "dateCreated": date_string,
            "screenshot": screenshot_string ?? "",
            "screenshotOrientation": screenshotOrientation,
            "worldMap": world_string ?? ""
        ]
    }
    
}
