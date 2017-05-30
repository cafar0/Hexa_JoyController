//
//  SocketManager.swift
//  Hexa_JoyController
//
//  Created by Rodina, Calin on 30/05/2017.
//  Copyright © 2017 Rodina, Calin. All rights reserved.
//

import Foundation
import UIKit

protocol SocketManagerDelegate: class {
    func endEncoutered()
    func errorOccurred()
    func hasBytesAvailable()
    func openCompleted()
}


class SocketManager : NSObject, StreamDelegate {

    
    var addr = "10.27.82.129"
    let port = 9876
    
    var inStream : InputStream?
    var outStream : OutputStream?
    
    var buffer = [UInt8](repeating: 0, count: 300)
    var inStreamLength : Int!
    var keyString = ""
    weak var delegate : SocketManagerDelegate?
    
    static let sharedInstance = SocketManager()
    private  override init() {}
    
    
    
    func networkEnable() {
        print("Network Enble")
        Stream.getStreamsToHost(withName: addr, port: port,
                                inputStream: &inStream, outputStream: &outStream)
        inStream?.delegate = self
        outStream?.delegate = self
        
        inStream?.schedule(in: .current, forMode: .defaultRunLoopMode)
        outStream?.schedule(in: .current, forMode: .defaultRunLoopMode)
        
        inStream?.open()
        outStream?.open()
        
        buffer = [UInt8](repeating: 0, count: 300)
    }

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
            
        case Stream.Event.endEncountered:
            print("End encountered")
            removeConnections()
            buffer.removeAll(keepingCapacity: true)
            keyString = ""
            delegate?.endEncoutered()
            
        case Stream.Event.errorOccurred:
            print("Error ocurred")
            removeConnections()
            delegate?.errorOccurred()
            
        case Stream.Event.hasBytesAvailable:
            print("Has bytes available")
            if aStream == inStream {
                inStreamLength = inStream?.read(&buffer, maxLength: buffer.count)
                let bufferString = String(bytes: buffer, encoding: String.Encoding.utf8)
                
                if keyString.isEmpty {
                    keyString = getKeyStringFromPEMString(PEMString: bufferString!)
                    delegate?.hasBytesAvailable()
                }
                else { print(bufferString ?? "default value") }
            }
            
        case Stream.Event.openCompleted:
            delegate?.openCompleted()
            
        default:
            print("Unknown")
        }
    }
    
    
    func send(message: String) {
        let TAG_PUBLIC_KEY = "com.company.tag_public"
        
        let data = message.data(using: String.Encoding.utf8)!
        let prefix = "encrypted_message=".data(using: String.Encoding.utf8)!
        
        let encryptedMessage = RSAUtils.encryptWithRSAPublicKey(data,
                                                                pubkeyBase64: keyString,
                                                                keychainTag: TAG_PUBLIC_KEY)!
        let dataArray = NSMutableData()
        dataArray.append(prefix)
        dataArray.append(encryptedMessage)
        
        let finalMessage = dataArray as Data
        let _ = finalMessage.withUnsafeBytes({ outStream?.write( $0, maxLength: finalMessage.count)})
    }

    func getKeyStringFromPEMString(PEMString : String) -> String {
        let keyArray = PEMString.components(separatedBy: "\n")
        var keyOutput = ""
        
        keyArray.filter({ !$0.contains("-----") })
            .filter({ !$0.contains("\0\0")})
            .forEach({ keyOutput += $0 })
        
        
        return keyOutput
    }

    
    func removeConnections() {
        inStream?.close()
        inStream?.remove(from: .current, forMode: .defaultRunLoopMode)
        outStream?.close()
        outStream?.remove(from: .current, forMode: .defaultRunLoopMode)
    }



}
