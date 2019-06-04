//
//  DetailViewController.swift
//  BusTime
//
//  Created by Joseph Barkley on 6/4/19.
//  Copyright © 2019 Joseph Barkley. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class DetailViewController: UIViewController, CLLocationManagerDelegate {
    
    var selectedLattitude : Double = 0.0
    var selectedLongitude : Double = 0.0
    var name = ""
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        let coordinate = CLLocationCoordinate2D(latitude: selectedLattitude, longitude: selectedLongitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = name
        mapView.addAnnotation(annotation)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mapView.showAnnotations(mapView.annotations, animated: true)
        locationManager.stopUpdatingLocation()
    }
}
