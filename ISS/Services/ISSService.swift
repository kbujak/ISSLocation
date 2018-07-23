//
//  ISSService.swift
//  ISS
//
//  Created by Krystian Bujak on 22/07/2018.
//  Copyright © 2018 Krystian Bujak. All rights reserved.
//

import Foundation
import RxSwift
import RxAlamofire
import SwiftyJSON

class ISSService{
    static let instance = ISSService()
    
    private let issPositionURLString = "http://api.open-notify.org/iss-now.json"
    private let astronautsURLString = "http://api.open-notify.org/astros.json"
    
    func createAstronautsObservable() -> Observable<[Astronaut]>{
        return Observable<Int>
            .timer(0, period: 3600, scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<(HTTPURLResponse, Any)> in
                return requestJSON(.get, (self?.astronautsURLString)!)
            }
            .filter { response, _ -> Bool in
                return 200..<300 ~= response.statusCode
            }
            .map{ _, data -> [Astronaut] in
                let json = JSON(data)
                var astronauts = [Astronaut]()
                if let jsonAstronauts = json["people"].array{
                    astronauts = jsonAstronauts.map({ person -> Astronaut in
                        Astronaut(craft: person["craft"].stringValue, name: person["name"].stringValue)
                    })
                }
                return astronauts
            }
    }
    
    func createLocationObservable() -> Observable<Location> {
        return Observable<Int>
            .timer(0, period: 10, scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<(HTTPURLResponse, Any)> in
                return requestJSON(.get, (self?.issPositionURLString)!)
            }
            .timeout(11, scheduler: MainScheduler.instance)
            .filter { response, _ -> Bool in
                return 200..<300 ~= response.statusCode
            }
            .map{ [weak self] _, data -> Location in
                return (self?.createLocation(from: data))!
        }
    }
    
    private func createLocation(from data: Any) -> Location{
        let json = JSON(data)
        guard let latitude = Double(json["iss_position"]["latitude"].stringValue),
            let longitude = Double(json["iss_position"]["longitude"].stringValue),
            let timestamp = json["timestamp"].double else { return Location(longitude: 0, latitude: 0, timeStamp: 0)}
        
        UserDefaults.standard.set(latitude, forKey: "latitude")
        UserDefaults.standard.set(longitude, forKey: "longitude")
        UserDefaults.standard.set(timestamp, forKey: "timestamp")
        UserDefaults.standard.setValue(Date(), forKey: "lastSync")
        
        return Location(longitude: longitude, latitude: latitude, timeStamp: timestamp)
    }
}
