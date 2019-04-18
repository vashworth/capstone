//
//  ViewController+SavingViewControllerDelegate.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/27/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import UIKit

extension ViewController : SavingViewControllerDelegate {
    func saveMap(title: String, author: String, screenshot: UIImage) {
        saveWorldMap(sceneView: sceneView, stroke: lines, ref: ref, geoRef: geoRef, userLocation: userLocation, name: title, author: author, screenshot: screenshot)
    }
    
    func dismiss() {
        self.view.removeBlurEffect()
        self.showUI()
    }
}
