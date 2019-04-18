//
//  ViewController+ARSessionDelegate.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/18/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import ARKit

extension ViewController : ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        updateDebugWorldMappingStatusInfoLabel(forframe: frame)
        lines.updateReticle()
        
        guard let currentStrokeAnchorID = lines.strokeAnchorIDs.last, let currentStrokeAnchor = lines.anchorForID(currentStrokeAnchorID) else { return }
        
        guard let node = lines.addModelAtReticle(color: selectedColor) else { return }
        
        currentStrokeAnchor.colorArray = [Float(selectedColor.redValue), Float(selectedColor.greenValue), Float(selectedColor.blueValue), Float(selectedColor.alphaValue)]
        currentStrokeAnchor.sphereLocations.append([node.position.x, node.position.y, node.position.z])
        
        if let pos = lines.previousPosition {
            let x_dif = pos.x - node.position.x
            let y_dif = pos.y - node.position.y
            let z_dif = pos.z - node.position.z
            
            if (abs(x_dif) > 0.0005 || abs(y_dif) > 0.0005 || abs(z_dif) > 0.0005) {
                lines.fillGap(last: pos, first: node.position, strokeAnchor: currentStrokeAnchor, color: selectedColor)
            }
        }
        lines.previousPosition = node.position
        
        
        /// - Tag: CheckMappingStatus

        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            multiplayerButton.isEnabled = false
        case .extending:
            multiplayerButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        case .mapped:
            multiplayerButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        guard let currentFrame = session.currentFrame else { return }
        updateTrackingStateView(forCamera: camera)
        updateDebugWorldMappingStatusInfoLabel(forframe: currentFrame)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("*****Session was interrupted*****")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("*****Session interruption ended*****")
        // "Resuming session — move to where you were when the session was interrupted."
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("session: didFailWithError")
        print(error)
    }
}
