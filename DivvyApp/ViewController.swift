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

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    let address = "https://feeds.divvybikes.com/stations/stations.json"
    var selectedAnnotation = MKPointAnnotation()
    var dictionArray : [[String: Any]] = []
    var dictionary = ["lattitude": 0.0, "longitude": 0.0, "name": "", "numberOfBikes": 0, "distance" : 0.0] as [String : Any]
    var selectedCell = 0
    
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedController: UISegmentedControl!
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
        let distanceInMeters = userLocation.distance(from: annotationLocation)
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
        let distanceDouble = distanceInMeters/1609.34
        let distance = String(format: "%.2f", distanceDouble as CVarArg)
        let alertController = UIAlertController(title: selectedAnnotation.title, message: "Distance in Miles: \(distance) Miles\nNumber of Bikes: \(bikeString) bike(s)", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.first
        userLocation = location!
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
            let numberOfBikes = result["availableBikes"].intValue
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let distanceInMiles = userLocation.distance(from: location)/1609.34
            print(distanceInMiles)
            dictionary["name"] = name
            dictionary["lattitude"] = latitude
            dictionary["longitude"] = longitude
            dictionary["numberOfBikes"] = numberOfBikes
            dictionary["distance"] = distanceInMiles
            dictionArray.append(dictionary)
            let sortedResults = (dictionArray as NSArray).sortedArray(using: [NSSortDescriptor(key: "distance", ascending: true)]) as! [[String:Any]]
            dictionArray = sortedResults
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
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
    @IBAction func onSegmentSelected(_ sender: UISegmentedControl) {
        if segmentedController.selectedSegmentIndex == 0{
            mapView.isHidden = false
            tableView.isHidden = true
        }
        if segmentedController.selectedSegmentIndex == 1{
            mapView.isHidden = true
            tableView.isHidden = false
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dictionArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID")
        let usedDictionary = dictionArray[indexPath.row]
        let distanceDouble = usedDictionary["distance"]
        let distance = String(format: "%.2f", distanceDouble as! CVarArg)
        cell?.textLabel!.text = (usedDictionary["name"] as! String)
        cell?.detailTextLabel!.text = "\(distance) Miles\n\(usedDictionary["numberOfBikes"]!) bike(s)"
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dvc = segue.destination as! DetailViewController
        let usedDictionary = dictionArray[selectedCell]
        dvc.selectedLattitude = usedDictionary["lattitude"] as! Double
        dvc.selectedLongitude = usedDictionary["longitude"] as! Double
        dvc.name = usedDictionary["name"] as! String
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCell = indexPath.row
        performSegue(withIdentifier: "segueToDetailVC", sender: nil)
    }
}

