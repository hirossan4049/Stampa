import SwiftUI
import MultipeerConnectivity
import FirebaseAuth
import FirebaseDatabase

final class MultipeerManager: NSObject, ObservableObject {
    static let shared = MultipeerManager()
    
    private let serviceType = "stampa"
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var discoveredPeers: [MCPeerID] = []
    
    private override init() {
        super.init()
        // setup(userId:) should be called from your view as needed.
    }
    
    /// Set up Multipeer Connectivity using the provided userId as the peer's displayName.
    func setup(userId: String) {
        let myPeerID = MCPeerID(displayName: userId)
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
    
    /// Invite the specified peer using the Multipeer browser.
    func invite(peer: MCPeerID) {
        // Ensure the browser is available and send an invitation with a 10-second timeout.
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 10)
        print("Invitation sent to \(peer.displayName)")
    }
    
    /// Send event data via Multipeer Connectivity.
    func sendEventData(_ eventData: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: eventData, options: [])
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("Event data sent via MP")
        } catch {
            print("Error sending event data: \(error.localizedDescription)")
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
        // Check if the received data is event data.
        if let eventData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let isEvent = eventData["isEvent"] as? Bool, isEvent == true {
            print("Received event data from \(peerID.displayName)")
            // For join-side: Write the event data to the current user's Realtime Database.
            if let currentUser = Auth.auth().currentUser {
                let eventRef = Database.database().reference()
                    .child("users")
                    .child(currentUser.uid)
                    .child("events")
                    .childByAutoId()
                eventRef.setValue(eventData) { error, _ in
                    if let error = error {
                        print("Error saving event data on join side: \(error.localizedDescription)")
                    } else {
                        print("Event data saved on join side")
                    }
                }
            }
            return
        }
        // Handle regular messages if needed.
        if let message = String(data: data, encoding: .utf8) {
            print("Received message from \(peerID.displayName): \(message)")
        } else {
            print("Failed to convert received data")
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
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start advertising: \(error.localizedDescription)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Received invitation from: \(peerID.displayName)")
        invitationHandler(true, self.session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to start browsing: \(error.localizedDescription)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
        }
    }
}
