//
//  ArtworkListViewController.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 2/18/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GeoFire
import MapKit
import CoreLocation


protocol ArtworkListViewControllerDelegate {
    func dismiss()
    func returnArtwork(art: Artwork)
}

class ArtworkListViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBAction func pressCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        delegate?.dismiss()
    }
    
    var delegate : ArtworkListViewControllerDelegate?
    var artworkIDs: [String] = []
    var geoRef: GeoFire!
    var userLocation: CLLocation!
    var ref: DatabaseReference!
    var artwork: [Artwork] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        let query = geoRef.query(at: userLocation, withRadius: 100)

        query.observe(.keyEntered, with: { key, location in
            print("Key: " + key + " entered the search radius.")
            self.artworkIDs.append(key)
        })
        
        let myGroup = DispatchGroup()
        
        query.observeReady {
            for key in self.artworkIDs {
                myGroup.enter()
                retrieveArtworkFromFirebase(dbRef: self.ref, artworkID: key) { (art) in
                    print("Finished request \(key)")
                    self.artwork.append(art)
                    myGroup.leave()
                }
            }
            
            myGroup.notify(queue: .main) {
                print("Finished all requests.")
                self.artwork.sort(by: { self.userLocation.distance(from: $0.coordinate!) < self.userLocation.distance(from: $1.coordinate!) })
                self.tableview.reloadData()
                self.spinner.stopAnimating()
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artworkIDs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArtInfoCell", for: indexPath)

        cell.textLabel?.text = "\(artwork[indexPath.row].name) by \(artwork[indexPath.row].author)"
        let distance = userLocation.distance(from: artwork[indexPath.row].coordinate!)
        cell.detailTextLabel?.text = "Approximately \(String(format:"%.3f", distance)) meters away"
        return cell
    }
    
    
   // Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.returnArtwork(art: artwork[indexPath.row])
        self.dismiss(animated: true, completion: nil)
        delegate?.dismiss()
    }
}
