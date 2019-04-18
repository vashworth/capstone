//
//  Stroke.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/18/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import ARKit

class Stroke {
    var strokeAnchorIDs: [UUID] = []
    var currentStrokeAnchorNode: SCNNode?
    var currentNodePosition: CGPoint?
    var previousPosition: SCNVector3?
    
    private var anchors: [ARAnchor] = []
    private var anchorNodes: [SCNNode] = []
    private var anchorIDs: [UUID] = []
    
    private var arkitf: matrix_float4x4 = matrix_identity_float4x4
    var reticleNode: SCNNode = SCNNode()
    private var reticlePreviewNode: SCNNode = SCNNode()
    private var reticleActive: Bool = false
    private var reticleHit: Bool = false
    private var reticleHitIdx: Int = -1
    private var reticleHitTf: SCNMatrix4 = SCNMatrix4Identity
    
    private var sceneView: ARSCNView
    
    init() {
        sceneView = ARSCNView()
    }

    init(arview: ARSCNView) { //default initializer and default red reticle
        let reticleGeo: SCNGeometry = SCNCylinder(radius: 0.01, height: 0)
        reticleGeo.materials.first?.diffuse.contents = UIColor.red
        reticleNode = SCNNode(geometry: reticleGeo)
        reticleNode.opacity = 0.4
        reticleActive = true
        sceneView = arview
    }
    
    init (arview: ARSCNView, reticle: SCNNode) {
        reticleNode = reticle
        sceneView = arview
    }
    
    // Reticle Functions
    func addModelAtReticle(color: UIColor) -> SCNNode? {
        guard let currentStrokeNode = currentStrokeAnchorNode else { return nil }
        let node = getModel(color)
        node.transform = SCNMatrix4Mult(reticleHitTf, node.transform)
        
        let localPosition = currentStrokeNode.convertPosition(node.position, from: nil)
        
        node.position = localPosition
        
        currentStrokeNode.addChildNode(node)
        
        return node
    }
    
    func fillGap(last: SCNVector3, first: SCNVector3, strokeAnchor: StrokeAnchor, color: UIColor) {
        let mid = SCNVector3Make((last.x + first.x)/2.0, (last.y + first.y)/2.0, (last.z + first.z)/2.0)
        
        guard let node = addModelAtReticle(color: color) else { return }
        node.position = mid
        strokeAnchor.sphereLocations.append([node.position.x, node.position.y, node.position.z])
        
        var x_dif = last.x - node.position.x
        var y_dif = last.y - node.position.y
        var z_dif = last.z - node.position.z
        
        if (abs(x_dif) > 0.0005 || abs(y_dif) > 0.0005 || abs(z_dif) > 0.0005) {
            fillGap(last: last, first: mid, strokeAnchor: strokeAnchor, color: color)
        }
        
        x_dif = first.x - node.position.x
        y_dif = first.y - node.position.y
        z_dif = first.z - node.position.z
        
        if (abs(x_dif) > 0.0005 || abs(y_dif) > 0.0005 || abs(z_dif) > 0.0005) {
            fillGap(last: mid, first: first, strokeAnchor: strokeAnchor, color: color)
        }
    }
    
    func addPlaneNode(planeNode: SCNNode, anchor: ARAnchor) {
        anchors.append(anchor)
        anchorNodes.append(planeNode)
        anchorIDs.append(anchor.identifier)
    }
    
    func updatePlaneNode(planeNode: SCNNode, anchor: ARAnchor) {
        let idx = getAnchorIndex(id: anchor.identifier)
        if (idx > -1) {
            anchorNodes[idx] = planeNode
        }
    }
    
    func updateReticle() {
        if (reticleActive) {
            let hitTestResults = sceneView.hitTest(sceneView.center, types: .existingPlaneUsingExtent)
            if (hitTestResults.count > 0) {
                
                let hitResult: ARHitTestResult = hitTestResults.first!
                //                print("Distance: \(hitResult.distance)")
                reticleNode.transform = SCNMatrix4(hitResult.worldTransform)
                let idx = getAnchorIndex(id: (hitResult.anchor?.identifier)!)
                if (idx < anchorNodes.count && idx > -1) {
                    sceneView.scene.rootNode.addChildNode(reticleNode)
                    reticleHit = true
                    reticleHitIdx = idx
                    reticleHitTf = reticleNode.transform
                }
                else {
                    reticleHit = false
                }
            }
            else {
                reticleNode.removeFromParentNode()
                reticleHit = false
            }
        }
    }
    
    private func getAnchorIndex(id: UUID) -> Int {
        var c_index: Int = 0
        for c_id in anchorIDs {
            if (c_id == id) {
                return c_index
            }
            c_index = c_index + 1
        }
        return -1
    }
    
    // Drawing Functions
    func sortStrokeAnchorIDsInOrderOfDateCreated() {
        var strokeAnchorsArray: [StrokeAnchor] = []
        for anchorID in strokeAnchorIDs {
            if let strokeAnchor = anchorForID(anchorID) {
                strokeAnchorsArray.append(strokeAnchor)
            }
        }
        strokeAnchorsArray.sort(by: { $0.dateCreated < $1.dateCreated })
    
        strokeAnchorIDs = []
        for anchor in strokeAnchorsArray {
            strokeAnchorIDs.append(anchor.identifier)
        }
    }
    
    func anchorForID(_ anchorID: UUID) -> StrokeAnchor? {
        return sceneView.session.currentFrame?.anchors.first(where: { $0.identifier == anchorID }) as? StrokeAnchor
    }
    
    func addModelAtPosition(atPosition position: SCNVector3, andAddToStrokeAnchor strokeAnchor: StrokeAnchor, color color: UIColor) {
        print("addModelAtPosition")
        guard let currentStrokeNode = currentStrokeAnchorNode else { return }
        // Get the reference sphere node and clone it
        let node = getModel(color)
        // Convert the position from world transform to local transform (relative to the anchors default node)
        let localPosition = currentStrokeNode.convertPosition(position, from: nil)
        node.position = localPosition
        
        currentStrokeNode.addChildNode(node)
        
        strokeAnchor.sphereLocations.append([node.position.x, node.position.y, node.position.z])
    }
    
    func getModel(_ color: UIColor) -> SCNNode {
        let reticleGeo: SCNGeometry = SCNCylinder(radius: 0.005, height: 0)
        reticleGeo.materials.first?.diffuse.contents = color
        let node = SCNNode(geometry: reticleGeo)
        return node
    }
 
}
