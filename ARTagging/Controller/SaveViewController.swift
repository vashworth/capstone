//
//  SaveViewController.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/27/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import UIKit

protocol SavingViewControllerDelegate {
    func dismiss()
    func saveMap(title: String, author: String, screenshot: UIImage)
}

class SaveViewController : UIViewController {
    
    // Outlets
    @IBOutlet weak var screenshotPreview: UIImageView!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var authorField: UITextField!
    @IBOutlet weak var publicSwitch: UISwitch!
    
    // Actions
    @IBAction func pressCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        delegate?.dismiss()
    }
    
    @IBAction func pressSave(_ sender: Any) {
        delegate?.saveMap(title: (titleField.text)!, author: (authorField.text)!, screenshot: image)
        self.dismiss(animated: true, completion: nil)
        delegate?.dismiss()
    }
    
    // Variables
    var image: UIImage!
    var delegate : SavingViewControllerDelegate?
    
    // View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        screenshotPreview.image = image
        
        screenshotPreview.layer.cornerRadius = 5
        screenshotPreview.clipsToBounds = true
    }
}



