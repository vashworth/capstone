//
//  ViewController.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 1/10/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SwiftHUEColorPicker
import Firebase
import GeoFire
import MapKit
import CoreLocation
import MultipeerConnectivity

class ViewController : UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var HUD: UIView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var screenshotPreview: UIImageView!

    @IBOutlet weak var paintButton: UIButton!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!

    // World Options
    @IBOutlet weak var worldButton: UIButton!
    @IBOutlet weak var worldOptionsView: UIVisualEffectView!
    @IBOutlet weak var multiplayerButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!


    // Save Options
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var saveStatus: UILabel!
    @IBOutlet weak var saveOptionsView: UIVisualEffectView!
    @IBOutlet weak var saveToWorldButton: UIButton!
    @IBOutlet weak var saveToShareButton: UIButton!


    // SwiftHUEColorPicker
    @IBOutlet weak var colorPickerView: UIVisualEffectView!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var colorPicker: SwiftHUEColorPicker!
    @IBOutlet weak var colorBrightness: SwiftHUEColorPicker!
    @IBOutlet weak var colorAlpha: SwiftHUEColorPicker!

    // Tracking State View
    @IBOutlet weak var trackingStateView: UIView!
    @IBOutlet weak var trackingStateImageView: UIImageView!
    @IBOutlet weak var trackingStateTitleLabel: UILabel!
    @IBOutlet weak var trackingStateMessageLabel: UILabel!
    
    var lines: Stroke = Stroke()

    var selectedColor = UIColor.white
    var buttonHighlighted = false
    var first = true

    var locationManager:CLLocationManager!
    var userLocation: CLLocation!
    var ref: DatabaseReference!
    var geoRef: GeoFire!

    // Multiplayer
    var sharing = false
    var multipeerSession: MultipeerSession!
    var mapProvider: MCPeerID?

    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        return configuration
    }

    // MARK - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the multiplayer variable

        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)

        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self

//        Show debug UI to view performance metrics (e.g. frames per second).
//        sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
//        sceneView.showsStatistics = true

        // sceneView Lighting
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true

        UIApplication.shared.isIdleTimerDisabled = true
        sceneView.preferredFramesPerSecond = 60

        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.session.run(defaultConfiguration)

        setupUI()

        lines = Stroke(arview: sceneView)

        ref = Database.database().reference(withPath: "artwork")
        geoRef = GeoFire(firebaseRef: ref)

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()

        if CLLocationManager.locationServicesEnabled(){
            locationManager.startUpdatingLocation()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK - Actions
    @IBAction func pressWorldButton(_ sender: Any) {
        if (worldOptionsView.isHidden) {
            worldOptionsView.isHidden = false
        } else {
            worldOptionsView.isHidden = true
        }
    }

    @IBAction func pressMapButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let artListVC = storyboard.instantiateViewController(
            withIdentifier: "ArtworkListViewController") as? ArtworkListViewController {
            artListVC.delegate = self as ArtworkListViewControllerDelegate
            if CLLocationManager.locationServicesEnabled() {
                locationManager.requestLocation()
                artListVC.ref = ref
                artListVC.geoRef = geoRef
                artListVC.userLocation = userLocation
            } else {
                locationManager.requestWhenInUseAuthorization()
            }

            artListVC.modalPresentationStyle = .popover
            let popOverVC = artListVC.popoverPresentationController
            popOverVC?.delegate = self as UIPopoverPresentationControllerDelegate
            popOverVC?.sourceView = self.HUD
            popOverVC?.permittedArrowDirections = []
            popOverVC?.sourceRect = CGRect(x: self.HUD.bounds.midX, y: self.HUD.bounds.minY, width: 0, height: 0)

            self.present(artListVC, animated: true)
            self.view.addBlurEffect()
        }
    }


    @IBAction func pressMultiplayerButton(_ sender: Any) {
        trackingStateView.isHidden = false
        trackingStateImageView.image = UIImage(named: "phone")
        trackingStateTitleLabel.text = "Connecting to peer..."
        trackingStateMessageLabel.text = ""
        sharing = true
        updateWorld()
    }

    @IBAction func pressSaveButton(_ sender: Any) {
        if (saveOptionsView.isHidden) {
            saveOptionsView.isHidden = false
        } else {
            saveOptionsView.isHidden = true
        }
    }

    @IBAction func pressSaveToWorldButton(_ sender: Any) {
        guard let currentFrame = sceneView.session.currentFrame else { return }

        switch currentFrame.worldMappingStatus {
        case .notAvailable, .limited:
            saveStatus.text = "Not available or limited"
        case .extending, .mapped:
            saveStatus.text = "Extended or mapped"
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let saveVC = storyboard.instantiateViewController(
                withIdentifier: "SaveViewController") as? SaveViewController {
                saveVC.delegate = self as SavingViewControllerDelegate
                saveVC.image = UIImage(data: getScreenShotData(ofScene: sceneView, stroke: lines)!)
                saveVC.modalPresentationStyle = .popover
                let popOverVC = saveVC.popoverPresentationController
                popOverVC?.delegate = self as UIPopoverPresentationControllerDelegate
                popOverVC?.sourceView = self.HUD
                popOverVC?.permittedArrowDirections = []
                popOverVC?.sourceRect = CGRect(x: self.HUD.bounds.midX, y: self.HUD.bounds.minY, width: 0, height: 0)

                self.present(saveVC, animated: true)
                self.view.addBlurEffect()
            }
        }
    }

    @IBAction func pressSaveToShareButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let recordVC = storyboard.instantiateViewController(
            withIdentifier: "RecordViewController") as? RecordViewController {
            recordVC.delegate = self as RecordViewControllerDelegate
            recordVC.modalPresentationStyle = .overFullScreen
            let popOverVC = recordVC.popoverPresentationController
            popOverVC?.delegate = self as UIPopoverPresentationControllerDelegate

            let navVC = UINavigationController(rootViewController: recordVC)
            navVC.modalPresentationStyle = .overFullScreen
            self.present(navVC, animated: true)
            self.hideUI()
        }
    }

    @IBAction func pressUndoButton(_ sender: Any) {
        lines.sortStrokeAnchorIDsInOrderOfDateCreated()

        guard let currentStrokeAnchorID = lines.strokeAnchorIDs.last, let currentStrokeAnchor = lines.anchorForID(currentStrokeAnchorID) else {
            print("No stroke to remove")
            return
        }
        sceneView.session.remove(anchor: currentStrokeAnchor)

        lines.currentStrokeAnchorNode = nil
    }

    @IBAction func pressColorButton(_ sender: Any) {
        if (colorPickerView.isHidden) {
            colorPickerView.isHidden = false
        } else {
            colorPickerView.isHidden = true
        }
    }

    // MARK - Helper functions
    func setupUI() {
        colorPicker.delegate = self
        colorPicker.direction = SwiftHUEColorPicker.PickerDirection.horizontal
        colorPicker.type = SwiftHUEColorPicker.PickerType.color

        colorBrightness.delegate = self
        colorBrightness.direction = SwiftHUEColorPicker.PickerDirection.horizontal
        colorBrightness.type = SwiftHUEColorPicker.PickerType.brightness

        colorAlpha.delegate = self
        colorAlpha.direction = SwiftHUEColorPicker.PickerDirection.horizontal
        colorAlpha.type = SwiftHUEColorPicker.PickerType.alpha

        worldOptionsView.layer.cornerRadius = 5
        worldOptionsView.clipsToBounds = true

        saveOptionsView.layer.cornerRadius = 5
        saveOptionsView.clipsToBounds = true

        screenshotPreview.layer.cornerRadius = 5
        screenshotPreview.clipsToBounds = true
    }

    func hideUI() {
        HUD.isHidden = true
        lines.reticleNode.isHidden = true
    }

    func showUI() {
        HUD.isHidden = false
        lines.reticleNode.isHidden = false
    }

    func updateTrackingStateView(forCamera camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            print("unavailable")
            trackingStateView.isHidden = true
            break
        case .limited(.initializing):
            print("initializing")
            trackingStateView.isHidden = false
            trackingStateImageView.image = UIImage(named: "phone")
            trackingStateTitleLabel.text = "Detecting world"
            trackingStateMessageLabel.text = "Move your device around slowly"
        case .limited(.relocalizing):
            print("relocalizing")
            trackingStateView.isHidden = true
            trackingStateMessageLabel.text = "Tracking state limited(relocalizing)"
        case .limited(.excessiveMotion):
            print("excessiveMotion")
            trackingStateView.isHidden = false
            trackingStateImageView.image = UIImage(named: "movement")
            trackingStateTitleLabel.text = "Too much movement"
            trackingStateMessageLabel.text = "Move your device more slowly"
        case .limited(.insufficientFeatures):
            print("insufficientFeatures")
            trackingStateView.isHidden = false
            trackingStateImageView.image = UIImage(named: "light")
            trackingStateTitleLabel.text = "Not enough detail"
            trackingStateMessageLabel.text = "Move around or find a better lit place"
        case .normal:
            print("normal")
            trackingStateView.isHidden = true
            screenshotPreview.isHidden = true
            break
        }
    }

    func updateDebugWorldMappingStatusInfoLabel(forframe frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            saveStatus.text = "Not enough data points"
        case .extending, .mapped:
            saveStatus.text = "Ready"
        }
    }

    func loadWorldMapAndScreenShot(_ art: Artwork){
        do {
            let worldMap = try loadWorldMap(from: art)
            restartSession(withWorldMap: worldMap)

            print("Map successfuly loaded")

            let screenshot = UIImage(data: art.screenshot! as Data)
            screenshotPreview!.image = screenshot
            screenshotPreview.isHidden = false
        } catch {
            print("Could not load worldMap. Error: \(error)")
        }
    }

    func restartSession(withWorldMap worldMap: ARWorldMap?) {
        let configuration = ARWorldTrackingConfiguration()
        if let worldMap = worldMap {
            configuration.initialWorldMap = worldMap
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.environmentTexturing = .automatic
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        } else {
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.environmentTexturing = .automatic
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        userLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager: didFailWithError")
        print("Error \(error)")
    }

    func updateWorld() {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
        }
        
        trackingStateView.isHidden = true
    }

    func receivedData(_ data: Data, from peer: MCPeerID) {
        do {
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                // Run the session with the received world map.
                print("got world map")
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

                // Remember who provided the map for showing UI feedback.
                mapProvider = peer

                trackingStateView.isHidden = true
            }
            else {
                print("got anchor")
                if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: StrokeAnchor.self, from: data) {
                    // Add anchor to the session, ARSCNView delegate adds visible content.
                    sceneView.session.add(anchor: anchor)
                }
                else {
                    print("unknown data recieved from \(peer)")
                }
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }

}
