import SwiftUI
import MultipeerConnectivity

class MultipeerManager: NSObject, ObservableObject {
  private let serviceType = "stampa"
  private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
  private var session: MCSession!
  private var advertiser: MCNearbyServiceAdvertiser!
  private var browser: MCNearbyServiceBrowser!
  
  @Published var connectedPeers: [MCPeerID] = []
  
  override init() {
    super.init()
    
    session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
    session.delegate = self
    
    advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
    advertiser.delegate = self
    advertiser.startAdvertisingPeer()
    print("Advertising started for peer: \(myPeerID.displayName)")
    
    browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
    browser.delegate = self
    browser.startBrowsingForPeers()
    print("Browsing started for service type: \(serviceType)")
  }
  
  func send(message: String) {
    guard !session.connectedPeers.isEmpty,
          let data = message.data(using: .utf8) else {
      print("送信失敗: 接続されているピアがいないか、データ変換に失敗")
      return
    }
    do {
      try session.send(data, toPeers: session.connectedPeers, with: .reliable)
      print("送信成功: \(message)")
    } catch {
      print("送信エラー: \(error.localizedDescription)")
    }
  }
}

// MARK: - MCSessionDelegate
extension MultipeerManager: MCSessionDelegate {
  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    DispatchQueue.main.async {
      self.connectedPeers = session.connectedPeers
    }
    print("Peer \(peerID.displayName) changed state to: \(state.rawValue)")
  }
  
  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    if let message = String(data: data, encoding: .utf8) {
      print("受信メッセージ from \(peerID.displayName): \(message)")
    } else {
      print("受信したデータの変換に失敗")
    }
  }
  
  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    print("Did receive stream from \(peerID.displayName) with stream name: \(streamName)")
  }
  
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    print("Started receiving resource \(resourceName) from \(peerID.displayName)")
  }
  
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    if let error = error {
      print("Error receiving resource \(resourceName) from \(peerID.displayName): \(error.localizedDescription)")
    } else {
      print("Finished receiving resource \(resourceName) from \(peerID.displayName)")
    }
  }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
  // 広告開始に失敗した場合のハンドリング
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
    print("広告の開始に失敗: \(error.localizedDescription)")
  }
  
  // 招待を受けた際、常に接続する例
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                  didReceiveInvitationFromPeer peerID: MCPeerID,
                  withContext context: Data?,
                  invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    print("招待を受けました from: \(peerID.displayName)")
    invitationHandler(true, self.session)
  }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
  // ブラウジング開始に失敗した場合のハンドリング
  func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
    print("ブラウジングの開始に失敗: \(error.localizedDescription)")
  }
  
  // 新しいピアを発見した場合、招待を送信
  func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
    print("ピアを発見: \(peerID.displayName)")
    browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
  }
  
  // ピアが見失われた場合の処理
  func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    print("ピアを見失いました: \(peerID.displayName)")
  }
}
