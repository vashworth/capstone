//
//  ViewController+RecordViewControllerDelegate.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 4/8/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import UIKit
import SceneKitVideoRecorder

extension ViewController : RecordViewControllerDelegate {
    func setupRecorder() -> SceneKitVideoRecorder? {
        var recorder: SceneKitVideoRecorder?
        var options = SceneKitVideoRecorder.Options.default
        
        let scale = UIScreen.main.nativeScale
        let sceneSize = sceneView.bounds.size
        options.videoSize = CGSize(width: sceneSize.width * scale, height: sceneSize.height * scale)
        recorder = try! SceneKitVideoRecorder(withARSCNView: sceneView, options: options)
        
        return recorder
    }
    
    func screenshot() -> UIImage {
        let image = UIImage(data: getScreenShotData(ofScene: self.sceneView, stroke: self.lines)!)
        return image!
    }
}
