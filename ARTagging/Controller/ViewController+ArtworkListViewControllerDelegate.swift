//
//  ViewController+ArtworkListViewControllerDelegate.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/27/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import UIKit

extension ViewController : ArtworkListViewControllerDelegate {
    func returnArtwork(art: Artwork) {
        loadWorldMapAndScreenShot(art)
    }
}
