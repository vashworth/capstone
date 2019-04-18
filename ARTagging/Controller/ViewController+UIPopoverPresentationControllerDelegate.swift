//
//  ViewController+UIPopoverPresentationControllerDelegate.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/27/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import UIKit

extension ViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController)
        -> UIModalPresentationStyle {
            return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        self.view.removeBlurEffect()
    }
}
