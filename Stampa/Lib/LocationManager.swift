//
//  LocationManager.swift
//  Stampa
//
//  Created by a on 2/16/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  @Published var lastLocation: CLLocation?
  
  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
  }
  
  func requestLocation() {
    manager.requestWhenInUseAuthorization()
    manager.requestLocation()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    lastLocation = locations.first
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location update failed: \(error.localizedDescription)")
  }
}
