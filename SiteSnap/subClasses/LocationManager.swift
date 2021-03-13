//
//  LocationManager.swift
//  SiteSnap
//
//  Created by Paul Oprea on 19/12/2018.
//  Copyright © 2018 Paul Oprea. All rights reserved.
//

import UIKit
import CoreLocation



class LocationManager: CLLocationManager {
    var isUpdatingLocation = false
    
    
    static let shared = LocationManager()
    

    
    override func startUpdatingLocation() {
        super.startUpdatingLocation()
        
        isUpdatingLocation = true
    }
    
    override func stopUpdatingLocation() {
        super.stopUpdatingLocation()
        
        isUpdatingLocation = false
    }
    
    
}

