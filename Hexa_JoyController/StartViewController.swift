//
//  StartViewController.swift
//  Hexa_JoyController
//
//  Created by Rodina, Calin on 24/05/2017.
//  Copyright © 2017 Rodina, Calin. All rights reserved.
//

import UIKit
//import CoreGraphics


class StartViewController: UIViewController, StreamDelegate {
    
    //MARK :- Joystick declarations
    private var radius : CGFloat = 0
    private var displacement : CGFloat = 0
    private var lastAngleRadians : Float = 0
    private var angle : CGFloat = 0
    
    private var leftJoyStick : JoyStick?
    private var rightJoyStick: JoyStick?
    
    private var lastLeftJoystickState : joystickState = .neutral
    private var lastRightJoystickState: joystickState = .neutral
    
    //MARK :- Networking declarations
    var addr = "10.27.82.129"
    let port = 9876

    var inStream : InputStream?
    var outStream : OutputStream?
    
    var buffer = [UInt8](repeating: 0, count: 300)
    var inStreamLength : Int!
    var keyString = ""

    
    @IBOutlet weak var leftJoyContainer: UIView!
    @IBOutlet weak var righJoyContainer: UIView!
    @IBOutlet weak var leftJoyBase: UIImageView!
    @IBOutlet weak var rightJoyBase: UIImageView!
    @IBOutlet weak var leftJoyButton: UIImageView!
    @IBOutlet weak var rightJoyButton: UIImageView!
    @IBOutlet weak var leftAngleLabel: UILabel!
    @IBOutlet weak var rightAngleLabel: UILabel!

    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var getKeyButton: UIButton!
    @IBOutlet weak var quitButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    

    @IBAction func onConnect(_ sender: Any) {
        networkEnable()
        
        connectButton.alpha = 0.3
        connectButton.isEnabled = false
        
    }
    
    @IBAction func onGetKey(_ sender: Any) {
        if let data = "Client: OK".data(using: String.Encoding.utf8) {
            let _  = data.withUnsafeBytes({ outStream?.write($0, maxLength: data.count) })
        }
    }
    
    @IBAction func onQuit(_ sender: Any) {
        if let data = "Quit".data(using: String.Encoding.utf8) {
            let _  = data.withUnsafeBytes({ outStream?.write($0, maxLength: data.count) })
        }
    }

    
    @IBAction func onButton(_ sender: Any) {
        let TAG_PUBLIC_KEY = "com.company.tag_public"
        
        let data = "iPhone secret message".data(using: String.Encoding.utf8)!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftJoyStick   = JoyStick(identifier: "left", containerView: leftJoyContainer, baseView: leftJoyBase, buttonView: leftJoyButton)
        leftJoyStick?.update = {[weak self] radians in
            self?.leftAngleLabel.text = radians + "º"
        }
        rightJoyStick = JoyStick(identifier: "right", containerView: righJoyContainer, baseView: rightJoyBase, buttonView: rightJoyButton)
        rightJoyStick?.update = {[weak self]  radians in
            self?.rightAngleLabel.text = radians + "º"
        }
        self.navigationController?.isNavigationBarHidden = true
        radius = leftJoyContainer.bounds.size.width / 4.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK :- TouchesHandlers
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: view)
        
        dispatchTouch(location: location, touch: touch)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: view)
        
        dispatchTouch(location: location, touch: touch)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: view)
        
        resetPosition(location: location)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: view)
        
        resetPosition(location: location)
    }
    
    //MARK :- Identify JoyStick
    func dispatchTouch(location : CGPoint, touch: UITouch) {
        guard let leftJoyStick = leftJoyStick else {return}
        guard let rightJoyStick = rightJoyStick else {return}
        
        if leftJoyStick.containerView.frame.contains(location) {
            updatePosition(location: touch.location(in: leftJoyContainer), joyStick: leftJoyStick)
        }
        else if rightJoyStick.containerView.frame.contains(location) {
            updatePosition(location: touch.location(in: righJoyContainer), joyStick: rightJoyStick)
        }
        
    }
    
    //MARK :- Update Button Position
    func resetPosition(location: CGPoint) {
        guard let leftJoyStick = leftJoyStick else {return}
        guard let rightJoyStick = rightJoyStick else {return}
        
       
         if leftJoyStick.containerView.frame.contains(location) {
            updatePosition(location: CGPoint(x: leftJoyStick.baseView.frame.midX,
                                             y: leftJoyStick.baseView.frame.midY),
                           joyStick: leftJoyStick)
        }
        
         if rightJoyStick.containerView.frame.contains(location) {
            updatePosition(location: CGPoint(x: rightJoyStick.baseView.frame.midX,
                                             y: rightJoyStick.baseView.frame.midY),
                       joyStick: rightJoyStick)
        }
    }
    
    func updatePosition(location : CGPoint, joyStick: JoyStick) {
        
        let delta = location - joyStick.baseView.frame.mid
        let newDisplacement = delta.magnitude / radius
        let newAngleRadians = atan2f(Float(delta.dx), Float(delta.dy))
            
        if newDisplacement > 1.0 {
            let x = CGFloat(sinf(newAngleRadians)) * radius
            let y = CGFloat(cosf(newAngleRadians)) * radius
            joyStick.buttonView.frame.origin = CGPoint(x: x + joyStick.baseView.bounds.midX - joyStick.buttonView.bounds.size.width/2.0,
                                             y: y + joyStick.baseView.bounds.midY - joyStick.buttonView.bounds.size.height/2.0)
        }
        else {
            joyStick.buttonView.center = joyStick.baseView.bounds.mid + delta
        }
    
        let newClampedDisplacement = min(newDisplacement, 1.0)
        if newClampedDisplacement != displacement || newAngleRadians != lastAngleRadians {
            displacement = newClampedDisplacement
            lastAngleRadians = newAngleRadians
            
            self.angle = newClampedDisplacement != 0.0 ? CGFloat(180.0 - newAngleRadians * 180.0 / Float.pi) : 0.0
            joyStick.update!(newClampedDisplacement.description)
            
            if newClampedDisplacement > 0.9 {
                let state = valueOf(angle: angle)
                sendData(joyStick: joyStick, state: state)
            }
            if newClampedDisplacement == 0.0 {
                sendData(joyStick: joyStick, state: .neutral)
            }
        }
    }
    
    func sendData(joyStick: JoyStick, state: joystickState) {
        var lastState : joystickState = .neutral
        
        if joyStick.identifier == "left" { lastState = lastLeftJoystickState }
        else { lastState = lastRightJoystickState }
        
        if (state != lastState) {
            switch state {
                
            case .forward:
                send(message: joyStick.upValue)
            case .backward:
                send(message: joyStick.downValue)
            case .left:
                send(message: joyStick.leftValue)
            case .right:
                send(message: joyStick.rightValue)
            default:
                send(message: joyStick.neutralValue)
            }
            
            if joyStick.identifier == "left" { lastLeftJoystickState = state }
            else { lastRightJoystickState = state  }
        }
    }
    
    func valueOf(angle: CGFloat) -> joystickState {
        var state = joystickState.neutral
        
        if angle >= 315.0 && angle < 359.9 { state = joystickState.forward }
        if angle >= 0.1   && angle < 44.9  { state = joystickState.forward }
        if angle >= 45.0  && angle < 134.9 { state = joystickState.right }
        if angle >= 135.0 && angle < 224.9 { state = joystickState.backward }
        if angle >= 225.0 && angle < 314.9 { state = joystickState.left }
        
        return state
    }
    
    
    //MARK :- Networking
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
            statusLabel.text = "Connection stopped by server"
            removeConnections()
           connectButton.isEnabled = true
            
            buffer.removeAll(keepingCapacity: true)
            keyString = ""
            
        case Stream.Event.errorOccurred:
            print("Error ocurred")
            removeConnections()
            statusLabel.text = "Failed to connect to server"
            connectButton.isEnabled = true
            presentAlert()
            
        case Stream.Event.hasBytesAvailable:
            print("Has bytes available")
            if aStream == inStream {
                inStreamLength = inStream?.read(&buffer, maxLength: buffer.count)
                let bufferString = String(bytes: buffer, encoding: String.Encoding.utf8)
                
                if keyString.isEmpty {
                    statusLabel.text = "Got server key"
                    keyString = getKeyStringFromPEMString(PEMString: bufferString!) 
                    getKeyButton.isEnabled = false
                }
                else { print(bufferString ?? "default value") }
            }
        
        case Stream.Event.openCompleted:
            statusLabel.text = "Connected to server"
            getKeyButton.isEnabled = true
        
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
    
    func removeConnections() {
        inStream?.close()
        inStream?.remove(from: .current, forMode: .defaultRunLoopMode)
        outStream?.close()
        outStream?.remove(from: .current, forMode: .defaultRunLoopMode)
    }
}
