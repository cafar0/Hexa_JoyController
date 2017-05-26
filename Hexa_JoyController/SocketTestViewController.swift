//
//  SocketTestViewController.swift
//  Hexa_JoyController
//
//  Created by Rodina, Calin on 25/05/2017.
//  Copyright © 2017 Rodina, Calin. All rights reserved.
//

import UIKit

class SocketTestViewController: UIViewController, StreamDelegate {
    
    var buttonConnect : UIButton!
    var buttonGetKey: UIButton!
    var buttonSendMsg: UIButton!
    var buttonQuit: UIButton!
    
    var label : UILabel!
    var labelConnection: UILabel!
    
    var addr = "10.27.82.129"
    let port = 9876
    
    var inStream : InputStream?
    var outStream : OutputStream?
    
    var buffer = [UInt8](repeating: 0, count: 400)
    var inStreamLength : Int!
    var keyString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        buttonSetup()
        labelSetup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func buttonSetup() {
        buttonConnect = UIButton(frame: CGRect(x: 20, y: 50, width: 300, height: 30))
        buttonConnect.setTitle("Connect to server", for: .normal)
        buttonConnect.setTitleColor(.blue, for: .normal)
        buttonConnect.setTitleColor(.cyan, for: .highlighted)
        buttonConnect.addTarget(self, action: #selector(btnConnectPressed), for: .touchUpInside)
        view.addSubview(buttonConnect)
        
        buttonGetKey = UIButton(frame: CGRect(x: 20, y: 100, width: 300, height: 30))
        buttonGetKey.setTitle("Get server's public key", for: .normal)
        buttonGetKey.setTitleColor(.blue, for: .normal)
        buttonGetKey.setTitleColor(.cyan, for: .highlighted)
        buttonGetKey.addTarget(self, action: #selector(buttonGetKeyPressed), for: .touchUpInside)
        buttonGetKey.alpha = 0.3
        buttonGetKey.isEnabled = false
        view.addSubview(buttonGetKey)
        
        buttonSendMsg = UIButton(frame: CGRect(x: 20, y: 150, width: 300, height: 30))
        buttonSendMsg.setTitle("Send encrypted message", for: .normal)
        buttonSendMsg.setTitleColor(.blue, for: .normal)
        buttonSendMsg.setTitleColor(.cyan, for: .highlighted)
        buttonSendMsg.addTarget(self, action: #selector(SendEncryptMsg), for: .touchUpInside)
        buttonSendMsg.alpha = 0.3
        buttonSendMsg.isEnabled = false
        view.addSubview(buttonSendMsg)
        
        
        
//        let buttonIPhone = UIButton(frame: CGRect(x: 20, y: 100, width: 300, height: 30))
//        buttonIPhone.setTitle("Send \" This is iPhone\" ", for: .normal)
//        buttonIPhone.setTitleColor(.blue, for: .normal)
//        buttonIPhone.setTitleColor(.cyan, for: .highlighted)
//        buttonIPhone.addTarget(self, action: #selector(btnIPhonePressed), for: .touchUpInside)
//        view.addSubview(buttonIPhone)
        
        buttonQuit = UIButton(frame: CGRect(x: 20, y: 200, width: 300, height: 30))
        buttonQuit.setTitle("Send \" Quit\" ", for: .normal)
        buttonQuit.setTitleColor(.blue, for: .normal)
        buttonQuit.setTitleColor(.cyan, for: .highlighted)
        buttonQuit.addTarget(self, action: #selector(btnQuitPressed), for: .touchUpInside)
        view.addSubview(buttonQuit)
    }
    
    func labelSetup() {
        label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 150))
        label.center = CGPoint(x: view.center.x, y: view.center.y+100)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont(name: "Helvetica-Bold", size: 30)
        view.addSubview(label)
        
        labelConnection = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 30))
        labelConnection.center = view.center
        labelConnection.textAlignment = .center
        labelConnection.text = "Please connect to server"
        view.addSubview(labelConnection)
    }
    
    func btnConnectPressed(sender: UIButton) {
        networkEnable()
        
        buttonConnect.alpha = 0.3
        buttonConnect.isEnabled = false
        buttonConnect.setTitleColor(.blue, for: .normal)
    }
    
    func btnIPhonePressed(sender: UIButton) {
        let data = "This is oPhone".data(using: String.Encoding.utf8)!
        let _ = data.withUnsafeBytes({ outStream?.write($0, maxLength: data.count)})
    }
    
    func btnQuitPressed() {
        let data = "Quit".data(using: String.Encoding.utf8)!
        let _ = data.withUnsafeBytes({ outStream?.write($0, maxLength: data.count)})
    }
    
    func buttonGetKeyPressed() {
        let data = "Client: OK".data(using: String.Encoding.utf8)!
        let _ = data.withUnsafeBytes({ outStream?.write($0, maxLength: data.count)})
    }
    
    func SendEncryptMsg() {
        let data = "Secret message from iPhone".data(using: String.Encoding.utf8)!
        let TAG_PUBLIC_KEY = "com.mycompany.tag_public"
        
        let encryptStr = "encrypted_message="
        let encryptedStrData = encryptStr.data(using: String.Encoding.utf8)
        
        print(keyString)
        
        let encryptedData = RSAUtils.encryptWithRSAPublicKey(data,
                                                             pubkeyBase64: keyString,
                                                             keychainTag: TAG_PUBLIC_KEY)!
        
        let finalArray = NSMutableData()
        finalArray.append(encryptedStrData!)
        finalArray.append(encryptedData)
        
        let finalData = finalArray as Data
        
        let _ = finalData.withUnsafeBytes({ outStream?.write( $0, maxLength: finalData.count ) })
        
        buttonSendMsg.alpha = 0.3
        buttonSendMsg.isEnabled = false
        buttonSendMsg.alpha = 1.0
        buttonSendMsg.isEnabled = true
        
        label.text = "Encrypted message sent"
    }
    
    func networkEnable() {
        print("network enable")
        Stream.getStreamsToHost(withName: addr, port: port, inputStream: &inStream, outputStream: &outStream)
        
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
                labelConnection.text = "Connection stopped by server"
                inStream?.close()
                inStream?.remove(from: .current, forMode: .defaultRunLoopMode)
                outStream?.close()
                outStream?.remove(from: .current, forMode: .defaultRunLoopMode)
                buttonConnect.alpha = 1
                buttonConnect.isEnabled = true

                buffer.removeAll(keepingCapacity: true)
                keyString = ""
            
            
            
        case Stream.Event.errorOccurred:
                print("Error occurred")
                inStream?.close()
                inStream?.remove(from: .current, forMode: .defaultRunLoopMode)
                outStream?.close()
                outStream?.remove(from: .current, forMode: .defaultRunLoopMode)
                labelConnection.text = "Failed to connect to server"
                buttonConnect.alpha = 1
                buttonConnect.isEnabled = true
                label.text = ""
                presentAlert()

        case Stream.Event.hasBytesAvailable:
                print("Has bytes available")
                if aStream == inStream {
                    inStreamLength = inStream!.read(&buffer, maxLength: buffer.count)
                    let bufferStr = String(bytes: buffer, encoding: String.Encoding.utf8)//?.replacingOccurrences(of: "\0", with: "")
                    
                    if keyString == "" {
                        label.text = "Public key received"
                        keyString = getKeyStringFromPEMString(PEMString: bufferStr!)
                        buttonGetKey.alpha = 0.3
                        buttonGetKey.isEnabled = false
                        buttonSendMsg.alpha = 1.0
                        buttonSendMsg.isEnabled = true
                    }
                    else {
                        print(bufferStr ?? "default value")
                    }
                }
            
            
//                if aStream == inStream {
//                    inStream?.read(&buffer, maxLength: buffer.count)
//                    let bufferStr = String(bytes: buffer, encoding: String.Encoding.utf8)
//                    label.text = bufferStr
//                    print(bufferStr ?? "default value")
//                }
            
        case Stream.Event.openCompleted:
                    labelConnection.text = "Connected to server"
            
                    buttonGetKey.alpha = 1.0
                    buttonGetKey.isEnabled = true
                
        default:
                print("unknown")
            }
    }
    
    func getKeyStringFromPEMString(PEMString : String) -> String {
        let keyArray = PEMString.components(separatedBy: "\n")
        
        var keyOutput : String = ""
        
        for item in keyArray {
            if !item.contains("-----") && !item.contains("\0\0") {
                keyOutput += item
            }
        }
        return keyOutput
    }
    
    func presentAlert() {
        let alert = UIAlertController(title: "Connection error",
                                      message: "Please check address",
                                      preferredStyle: .alert)
        alert.addTextField(configurationHandler: {[weak self] textField in
            textField.text = self?.addr
        })
        
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default,
                                      handler: { [weak self, weak alert] _ in
                                        let textField = alert?.textFields![0]
                                        self?.addr = (textField?.text)!
                                        print("Text filed: \(textField?.text ?? "")")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}
