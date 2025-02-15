//
//  NearbyInteractionManager.swift
//  Stampa
//
//  Created by a on 2/15/25.
//
import Foundation
import NearbyInteraction
import SwiftUI

final class NearbyInteractionManager: NSObject, ObservableObject, NISessionDelegate {
  private var niSession: NISession?
  
  // 自身の discoveryToken を保持（MultipeerConnectivity 経由で相手に送信）
  @Published var myDiscoveryToken: NIDiscoveryToken?
  
  // 相手との距離（メートル）
  @Published var distance: Float?
  
  override init() {
    super.init()
    guard NISession.isSupported else {
      print("NearbyInteraction is not supported on this device.")
      return
    }
    
    niSession = NISession()
    niSession?.delegate = self
    
    // セッションは、リモートデバイスの discoveryToken が得られたタイミングで開始
  }
  
  /// リモートデバイスの discoveryToken を使用して NearbyInteraction セッションを開始
  func runSession(with remotePeerToken: NIDiscoveryToken) {
    let config = NINearbyPeerConfiguration(peerToken: remotePeerToken)
    niSession?.run(config)
  }
  
  // MARK: - NISessionDelegate
  
  // 距離などの更新情報を受け取る
  func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
    if let object = nearbyObjects.first,
       let distanceMeasurement = object.distance {
      // object.distance が既に Float 型の場合、直接利用
      let measuredDistance = distanceMeasurement
      DispatchQueue.main.async {
        self.distance = measuredDistance
      }
      print("更新された距離: \(measuredDistance) m")
    }
  }
  
  func session(_ session: NISession, didInvalidateWith error: Error) {
    print("NearbyInteraction session invalidated: \(error.localizedDescription)")
  }
  
  func sessionWasSuspended(_ session: NISession) {
    print("NearbyInteraction session was suspended")
  }
  
  func sessionSuspensionEnded(_ session: NISession) {
    print("NearbyInteraction session suspension ended")
  }
  
  // 自身の discoveryToken が更新された際に呼ばれる
  func session(_ session: NISession, didUpdate discoveryToken: NIDiscoveryToken) {
    DispatchQueue.main.async {
      self.myDiscoveryToken = discoveryToken
    }
    print("更新された discoveryToken を取得")
  }
}

