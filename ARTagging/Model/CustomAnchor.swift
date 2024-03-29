//
//  CustomAnchor.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/18/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import UIKit
import ARKit

class StrokeAnchor: ARAnchor {
    
    var sphereLocations: [[Float]] = []
    let dateCreated: TimeInterval
    var color: UIColor = .white
    
    override init(name: String, transform: float4x4) {
        self.dateCreated = NSDate().timeIntervalSince1970
        super.init(name: name, transform: transform)
    }
    
    required init(anchor: ARAnchor) {
        self.sphereLocations = (anchor as! StrokeAnchor).sphereLocations
        self.dateCreated = (anchor as! StrokeAnchor).dateCreated
        self.color = (anchor as! StrokeAnchor).color
        super.init(anchor: anchor)
    }
    
    required init?(coder aDecoder: NSCoder) {
        if let sphereLocations = aDecoder.decodeObject(forKey: "array") as? [[Float]],
            let dateCreated = aDecoder.decodeObject(forKey: "dateCreated") as? NSNumber,
            let color = aDecoder.decodeObject(forKey: "color") as? String{
            self.sphereLocations = sphereLocations
            self.dateCreated = dateCreated.doubleValue
            self.color = StrokeColor(rawValue: color)!
        } else {
            return nil
        }
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(sphereLocations, forKey: "array")
        aCoder.encode(NSNumber(value: dateCreated), forKey: "dateCreated")
        aCoder.encode(color.rawValue, forKey: "color")
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
    
}
