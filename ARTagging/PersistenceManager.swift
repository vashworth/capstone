//
//  PersistenceManger.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/18/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import Firebase
import GeoFire
import ARKit
//import MapKit

func getCurrentWorldMap(forSceneView sceneView: ARSCNView, withStroke stroke: Stroke, completion: @escaping (_ wordlMap: ARWorldMap?, _ errorMessage: String?) -> Void) {
    sceneView.session.getCurrentWorldMap { (worldMap, error) in
        let message: String
        guard let worldMap = worldMap else {
            message = ("Can't get world map: \(error!.localizedDescription)")
            completion(nil, message)
            return
        }
        
        completion(worldMap, nil)
    }
}
// get the current world map and take a screenshot
func getCurrentWorldMapAndScreenShot(forSceneView sceneView: ARSCNView, withStroke stroke: Stroke, completion: @escaping (_ wordlMap: ARWorldMap?, _ screenshot: Data?, _ errorMessage: String?) -> Void) {
    sceneView.session.getCurrentWorldMap { (worldMap, error) in
        let message: String
        guard let worldMap = worldMap else {
            message = ("Can't get world map: \(error!.localizedDescription)")
            completion(nil, nil, message)
            return
        }
        
        // hide UI elements
        stroke.reticleNode.isHidden = true
        
        guard let screenshot = getScreenShotData(ofScene: sceneView, stroke: stroke) else {
            message = "Could not convert screenshot to data"
            completion(nil, nil, message)
            return
        }
        
        // show UI elements
        stroke.reticleNode.isHidden = false
        
        completion(worldMap, screenshot, nil)
        
    }
}

func saveArtworkToFirebase(dbRef ref: DatabaseReference, geoRef: GeoFire, withWorldMap worldMap: ARWorldMap, name: String, author: String, screenshot: Data, userLocation: CLLocation, completion: @escaping (Bool, String) ->Void ) {
    
    let art = Artwork()
    do {
        let worldMapData = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        art.worldMap = worldMapData
    } catch {
        let message = ("Could not convert the worldMap into data. \(error.localizedDescription)")
        completion(false, message)
    }
    
    art.screenshot = screenshot
    art.dateCreated = Date()
    art.name = name
    art.author = author
    
    let artRef = ref.childByAutoId()
    let artRefId = artRef.key
    artRef.setValue(art.encode())
    
    geoRef.setLocation(userLocation, forKey: artRefId!) { (error) in
        if (error != nil) {
            print("An error occured: \(String(describing: error))")
        } else {
            print("Saved location successfully!")
        }
    }
}

func saveWorldMap(sceneView: ARSCNView, stroke: Stroke, ref: DatabaseReference, geoRef: GeoFire, userLocation: CLLocation, name: String, author: String, screenshot: UIImage) {
    guard let currentFrame = sceneView.session.currentFrame else { return }
    
    switch currentFrame.worldMappingStatus {
    case .notAvailable, .limited:
        print("Not available or limited")
    case .extending, .mapped:
        print("Extending or mapped")
    
        // get world map & screen shot
        getCurrentWorldMap(forSceneView: sceneView, withStroke: stroke) {
            (worldMap, errorMessage) in
            if errorMessage != nil {
                // Some error happened
                print(errorMessage!)
                return
            }
            
            let screenshot_data = screenshot.pngData()! as Data
            
            // save to firebase
            saveArtworkToFirebase(dbRef: ref, geoRef: geoRef, withWorldMap: worldMap!, name: name, author: author, screenshot: screenshot_data, userLocation: userLocation, completion: {
                (success, message) in
                if success {
                    print("Scene Successfully Saved")
                } else {
                    print("Unable To Save Scene")
                }
                print(message)
            })
        }
    }
}

func loadWorldMap(from art: Artwork) throws -> ARWorldMap {
    let mapData = art.worldMap! as Data
    guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
        else {
            throw ARError(.invalidWorldMap)
    }
    return worldMap
}

func retrieveArtworkFromFirebase(dbRef ref: DatabaseReference, artworkID artID: String, completion: @escaping (Artwork) ->Void) {
    let art = Artwork()
    ref.child(artID).observeSingleEvent(of: .value, with: {(snapshot) in
        let values = snapshot.value as! [String: Any]
        let name = values["name"] as! String
        let author = values["author"] as! String
        let screenshot = values["screenshot"] as! String
        let date = values["dateCreated"] as! String
        let worldMap = values["worldMap"] as! String
        let coordinates = values["l"] as! NSArray
        
        art.worldMap = decode(worldMap)
        art.screenshot = decode(screenshot)
        //        art.dateCreated = date
        art.name = name
        art.author = author
        art.coordinate = CLLocation(latitude: coordinates[0] as! Double, longitude: coordinates[1] as! Double)
        completion(art)
    })
}

func decode(_ dataString: String) -> Data {
    let dataObj = Data(base64Encoded: dataString, options: Data.Base64DecodingOptions())
    return dataObj!
}
