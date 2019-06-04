//
//  ViewController.swift
//  BusTime
//
//  Created by Joseph Barkley on 6/4/19.
//  Copyright © 2019 Joseph Barkley. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    let locationManager = CLLocationManager()
    let address = "https://feeds.divvybikes.com/stations/stations.json"
    var selectedAnnotation = MKPointAnnotation()
    
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        mapView.delegate = self
        
        query()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
        
        selectedAnnotation = view.annotation as! MKPointAnnotation
        let annotationLocation = CLLocation(latitude: selectedAnnotation.coordinate.latitude, longitude: selectedAnnotation.coordinate.longitude)
        let user = MKUserLocation()
        let location = CLLocation(latitude: user.coordinate.latitude, longitude: user.coordinate.longitude)
        let distanceInMeters = location.distance(from: annotationLocation)
        var bikeNumber : Int = -1
        var bikeString : String = ""
        if let url = URL(string: address){
            if let data = try? Data(contentsOf: url){
                let json = try! JSON(data: data)
                bikeNumber = getBikeNumber(json: json, annotation: selectedAnnotation)
            }else{
                self.loadError()
            }
        }else{
            self.loadError()
        }
        if bikeNumber == -1{
            bikeString = "Error Getting Number of Bikes"
        }else{
            bikeString = "\(bikeNumber)"
        }
        let alertController = UIAlertController(title: "Distance in Meters & Number of Bikes:", message: "\(distanceInMeters) meters\n \(bikeString) bikes", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.first
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let center = location?.coordinate
        let region = MKCoordinateRegion(center: center!, span: span)
        mapView.setRegion(region, animated: true)
        
    }
    
    func parse(json: JSON){
        for result in json["stationBeanList"].arrayValue {
            let latitude = result["latitude"].doubleValue
            let longitude = result["longitude"].doubleValue
            let name = result["stationName"].stringValue
            let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            annotation.title = name
            mapView.addAnnotation(annotation)
        }
    }
    
    func loadError(){
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Error In Loading", message: "There was a problem loading the bus stop data.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK THIS IS UNEPIC", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        }
    }
    
    func query() {
        
        let query = address
        DispatchQueue.global(qos: .userInitiated).async {
            [unowned self] in
            if let url = URL(string: query){
                if let data = try? Data(contentsOf: url){
                    let json = try! JSON(data: data)
                    self.parse(json: json)
                }else{
                    self.loadError()
                }
            }else{
                self.loadError()
            }
        }
    }
    
    func getBikeNumber(json: JSON, annotation: MKPointAnnotation) -> Int{
        for result in json["stationBeanList"].arrayValue {
            let latitude = result["latitude"].doubleValue
            let longitude = result["longitude"].doubleValue
            if annotation.coordinate.latitude == latitude && annotation.coordinate.longitude == longitude {
                let numberOfBikes = result["availableBikes"].intValue
                return numberOfBikes
            }
        }
        return -1
    }
}

