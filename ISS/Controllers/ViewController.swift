//
//  ViewController.swift
//  ISS
//
//  Created by Krystian Bujak on 21/07/2018.
//  Copyright © 2018 Krystian Bujak. All rights reserved.
//

import UIKit
import Mapbox
import RxSwift

class ViewController: UIViewController, MGLMapViewDelegate {

    private let disposeBag = DisposeBag()
    
    var mapView: MGLMapView!
    var currentAnnotation: MGLPointAnnotation?
    var astronauts = [Astronaut]()
    var lastSyncTimeTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createMapView()
        createLastSyncTimeLabel()
        
        // Update list of astronauts every hour
        ISSService.instance.createAstronautsObservable()
            .subscribe(onNext:{
                [weak self] astronauts in
                self?.astronauts = astronauts
            })
            .disposed(by: disposeBag)
        
        ISSService.instance.createLocationObservable()
            .subscribe(onNext: {
                [weak self] location in
                self?.setMarker(to: location)
                },
                       onError:{ [weak self] _ in
                        let dict = UserDefaults.standard.dictionaryWithValues(forKeys: ["latitude","longitude","timestamp"])
                        if let timestamp = dict["timestamp"] as? Double,
                            let latitude = dict["latitude"] as? Double,
                            let longitude = dict["longitude"] as? Double{
                            self?.setMarker(to: Location(longitude: longitude, latitude: latitude, timeStamp: timestamp))
                        }else{
                            self?.setMarker(to: Location(longitude: 0, latitude: 0, timeStamp: 0))
                        }
            })
            .disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func createMapView(){
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        mapView.delegate = self
    }
    
    private func setMarker(to location: Location){
        let locationCoordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        
        if let currentAnnotation = currentAnnotation{
            mapView.removeAnnotation(currentAnnotation)
        }
        
        currentAnnotation = MGLPointAnnotation()
        currentAnnotation?.coordinate = locationCoordinate
        currentAnnotation?.title = ""
        currentAnnotation?.subtitle = ""
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(self.currentAnnotation!)
            self.mapView.setCenter(locationCoordinate, zoomLevel: 3, animated: false)
            if let lastSyncTime = UserDefaults.standard.value(forKey: "lastSync"){
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
                self.lastSyncTimeTextView.text = "Last sync:\n\(dateFormatter.string(from: lastSyncTime as! Date))"
            }else{
                self.lastSyncTimeTextView.text = "Last sync:\n Couldn't retrive data"
            }
        }
    }
    
    private func createLastSyncTimeLabel(){
        lastSyncTimeTextView = UITextView(frame: CGRect(x: view.bounds.minX, y: view.bounds.minY + 50, width: 200, height: 100))
        lastSyncTimeTextView.backgroundColor = UIColor.clear
        lastSyncTimeTextView.textColor = .black
        lastSyncTimeTextView.textAlignment = .left
        view.addSubview(lastSyncTimeTextView)
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        currentAnnotation?.title = "Astronauts in space"
        currentAnnotation?.subtitle = !astronauts.isEmpty ? astronauts.reduce("", { $0 + "\($1.name), " }) : "Data not retrived yet"
        
        return true
    }
}

