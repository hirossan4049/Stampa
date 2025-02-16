//
//  reverseGeocode.swift
//  Stampa
//
//  Created by a on 2/16/25.
//

import CoreLocation

func reverseGeocode(location: CLLocation, completion: @escaping (String?) -> Void) {
  let geocoder = CLGeocoder()
  geocoder.reverseGeocodeLocation(location) { placemarks, error in
    if let error = error {
      print("Reverse geocode failed: \(error.localizedDescription)")
      completion(nil)
    } else if let placemark = placemarks?.first {
      // 住所の各要素を結合してひとつの文字列にする
      let address = [
        placemark.name,
        placemark.thoroughfare,
        placemark.locality,
        placemark.administrativeArea,
        placemark.postalCode,
        placemark.country
      ]
        .compactMap { $0 }
        .joined(separator: ", ")
      completion(address)
    } else {
      completion(nil)
    }
  }
}
