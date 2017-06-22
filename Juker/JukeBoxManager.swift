//
//  JukeBoxManager.swift
//  ConnectedColors
//
//  Created by Alex Mitchell on 2017-06-12.
//  Copyright © 2017 Example. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class JukeBoxManager: NSObject {

    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let JukeBoxServiceType = "Juker-mc-Juker"
    
    //user could choose unique name and have it displayed here
    //can archive so the user doesn't need to type it every time
    
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    let serviceBrowser : MCNearbyServiceBrowser
    
    var isPendingHost: Bool = false
    var isHost:Bool = false
//    var isAcceptingInvites: Bool = false
    
    var delegate : JukeBoxManagerDelegate?
    
    //MARK: NEW-----------
    func send(event : NSData) {
        NSLog("%@", "sendSong: \(event) to \(session.connectedPeers.count) peers")
        
        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(event as Data, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
        
    }
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .none)
        //changed encryption from .required to .none for test
        session.delegate = self
        return session
    }()
    
    
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: JukeBoxServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: JukeBoxServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        //self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
}

extension JukeBoxManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        //we can try grabbing the data from the host here and then transferring over to the main vc.
        //can we notify the userType Vc at this point which would make the button visible?

       //i think that the invite is coming before we are accepting, and then we can't accept it after this point
        //PROBLEM SPOT 3
//        if isAcceptingInvites == true {
        invitationHandler(true, self.session)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "receivedInvite"), object: nil, userInfo: ["hostName": "\(peerID.displayName)"])
            
//        }
        //notify the host that there is a new connection so they will send sync info
    }
    
}

extension JukeBoxManager : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        if isHost {
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 60)
            NSLog("%@", "invitePeer: \(peerID)")
            
            //need to handle enable / disable based on host
        }
        
    }
    
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
    
}

extension JukeBoxManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state)")
        if state == .connected {
            print("we've got a new successful connection")
            //host sends connection object
            self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
        }
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")

        //want to check if it is a new song or a timer object
        if let newEvent = NSKeyedUnarchiver.unarchiveObject(with: data) as? Event {
            self.delegate?.newEvent(manager: self, event: newEvent)
        }
        
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
}

protocol JukeBoxManagerDelegate {
    
    func connectedDevicesChanged(manager : JukeBoxManager, connectedDevices: [String])
    
    func newEvent(manager: JukeBoxManager, event: Event)
    
    
}
