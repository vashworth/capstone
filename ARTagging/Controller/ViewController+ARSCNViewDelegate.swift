//
//  ViewController+ARSCNViewDelegate.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/18/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import ARKit

extension ViewController : ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // This is only used when loading a worldMap
        if let strokeAnchor = anchor as? StrokeAnchor {
            print("load drawing")
            lines.currentStrokeAnchorNode = node
            lines.strokeAnchorIDs.append(strokeAnchor.identifier)
            
            if strokeAnchor.colorArray.count != 0 {
                print(strokeAnchor.colorArray)
                let color = UIColor(red: CGFloat(strokeAnchor.colorArray[0]), green: CGFloat(strokeAnchor.colorArray[1]), blue: CGFloat(strokeAnchor.colorArray[2]), alpha: CGFloat(strokeAnchor.colorArray[3]))
                for sphereLocation in strokeAnchor.sphereLocations {
                    lines.addModelAtPosition(atPosition: SCNVector3Make(sphereLocation[0], sphereLocation[1], sphereLocation[2]), andAddToStrokeAnchor: strokeAnchor, color: color)
                }
            }
        } else {
            guard anchor is ARPlaneAnchor else { return }
            lines.addPlaneNode(planeNode: node, anchor: anchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        lines.updatePlaneNode(planeNode: node, anchor: anchor)
        
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.buttonHighlighted = self.paintButton.isHighlighted
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if buttonHighlighted {
            if first {
                first = false
                DispatchQueue.main.async {
                    guard let hitTestResult = self.sceneView.hitTest(self.sceneView.center, types: .existingPlaneUsingExtent).first else { return }
                    let strokeAnchor = StrokeAnchor(name: "custom", transform: hitTestResult.worldTransform)
                    self.sceneView.session.add(anchor: strokeAnchor)
                    
                    // Send the anchor info to peers, so they can place the same content.
                    guard let data = try? NSKeyedArchiver.archivedData(withRootObject: strokeAnchor, requiringSecureCoding: true)
                        else { fatalError("can't encode strokeAnchor") }
                    self.multipeerSession.sendToAllPeers(data)
                }
            }
            DispatchQueue.main.async {
                self.lines.currentNodePosition = self.sceneView.center
            }
        } else {
            if (!multipeerSession.connectedPeers.isEmpty && sharing == true && first == false) {
                updateWorld()
            }
            first = true
            lines.currentNodePosition = nil
            lines.previousPosition = nil
            lines.currentStrokeAnchorNode = nil
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Remove the anchorID from the strokes array
        print("Anchor removed")
        lines.strokeAnchorIDs.removeAll(where: { $0 == anchor.identifier })
    }
}
