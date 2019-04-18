//
//  ViewController+SwiftHUEColorPickerDelegate.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/18/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import SwiftHUEColorPicker

extension ViewController: SwiftHUEColorPickerDelegate {
    func valuePicked(_ color: UIColor, type: SwiftHUEColorPicker.PickerType) {
        selectedColor = color
        colorView.backgroundColor = color
        paintButton.tintColor = color
        
        colorPicker.currentColor = color
        colorBrightness.currentColor = color
        colorAlpha.currentColor = color
    }
}
