//
//  SocketIOManager.swift
//  Hexa_JoyController
//
//  Created by Rodina, Calin on 24/05/2017.
//  Copyright © 2017 Rodina, Calin. All rights reserved.
//

import Foundation

class SocketIOManager : NSObject {

    static let sharedInstance = SocketIOManager()
    var socket : SocketIOClient = SocketIOClient(socketURL: URL(string : "https://localhost:3500")!, config: [.log(true), .forcePolling(true), .nsp("/chat")])
    
    override init() {
        super.init()
    }
    
    func establishConnection() {
        socket.connect()
    }
    
    func closeConnection() {
        socket.disconnect()
    }
}
