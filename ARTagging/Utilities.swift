//
//  Utilities.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 1/13/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import ARKit
import SceneKit
import UIKit

func getScreenShotData(ofScene scene: ARSCNView?, stroke: Stroke) -> Data? {
    guard let sceneView = scene else { return nil }
    // hide reticle
    stroke.reticleNode.isHidden = true
    let screenshot = sceneView.snapshot()
    let data = screenshot.pngData()! as Data
    stroke.reticleNode.isHidden = false
    return data
}

extension UIColor {
    var redValue: CGFloat{ return CIColor(color: self).red }
    var greenValue: CGFloat{ return CIColor(color: self).green }
    var blueValue: CGFloat{ return CIColor(color: self).blue }
    var alphaValue: CGFloat{ return CIColor(color: self).alpha }
}


extension UIView
{
    func addBlurEffect() {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        
        self.addSubview(blurEffectView)
    }
    
    func removeBlurEffect() {
        for subview in self.subviews {
            if subview is UIVisualEffectView {
                subview.removeFromSuperview()
            }
        }
    }
}
