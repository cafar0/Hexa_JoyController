//
//  StartViewController.swift
//  Hexa_JoyController
//
//  Created by Rodina, Calin on 24/05/2017.
//  Copyright © 2017 Rodina, Calin. All rights reserved.
//

import UIKit
//import CoreGraphics


class JoysticksViewController: UIViewController, SocketManagerDelegate {
    
    //MARK :- Joystick declarations
    private var radius : CGFloat = 0
    private var displacement : CGFloat = 0
    private var lastAngleRadians : Float = 0
    private var angle : CGFloat = 0
    private var isJoystickEnable = false
    private var leftJoyStick : JoyStick?
    private var rightJoyStick: JoyStick?
    
    private var lastLeftJoystickState : joystickState = .neutral
    private var lastRightJoystickState: joystickState = .neutral

    let socketManager = SocketManager.sharedInstance
    
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
        socketManager.networkEnable()
        
        connectButton.alpha = 0.3
        connectButton.isEnabled = false
        
    }
    
    @IBAction func onGetKey(_ sender: Any) {
        if let data = "Client: OK".data(using: String.Encoding.utf8) {
            let _  = data.withUnsafeBytes({ socketManager.outStream?.write($0, maxLength: data.count) })
        }
    }
    
    @IBAction func onQuit(_ sender: Any) {
        if let data = "Quit".data(using: String.Encoding.utf8) {
            let _  = data.withUnsafeBytes({ socketManager.outStream?.write($0, maxLength: data.count) })
        }
    }

    
    @IBAction func onButton(_ sender: Any) {
        let TAG_PUBLIC_KEY = "com.company.tag_public"
        
        let data = "iPhone secret message".data(using: String.Encoding.utf8)!
        let prefix = "encrypted_message=".data(using: String.Encoding.utf8)!
        
        let encryptedMessage = RSAUtils.encryptWithRSAPublicKey(data,
                                                                pubkeyBase64: socketManager.keyString,
                                                                keychainTag: TAG_PUBLIC_KEY)!
        let dataArray = NSMutableData()
        dataArray.append(prefix)
        dataArray.append(encryptedMessage)
        
        let finalMessage = dataArray as Data
        let _ = finalMessage.withUnsafeBytes({ socketManager.outStream?.write( $0, maxLength: finalMessage.count)})
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
        socketManager.delegate = self
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
        
        if isJoystickEnable{
            if leftJoyStick.containerView.frame.contains(location) {
                updatePosition(location: touch.location(in: leftJoyContainer), joyStick: leftJoyStick)
            }
            else if rightJoyStick.containerView.frame.contains(location) {
                updatePosition(location: touch.location(in: righJoyContainer), joyStick: rightJoyStick)
            }
        }
        
    }
    
    //MARK :- Update Button Position
    func resetPosition(location: CGPoint) {
        if isJoystickEnable {
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
                socketManager.send(message: joyStick.upValue)
            case .backward:
                socketManager.send(message: joyStick.downValue)
            case .left:
                socketManager.send(message: joyStick.leftValue)
            case .right:
                socketManager.send(message: joyStick.rightValue)
            default:
                socketManager.send(message: joyStick.neutralValue)
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
    
    func toggleJoystick(enable: Bool) {
        if enable {
            isJoystickEnable = true
            leftJoyStick?.buttonView.alpha = 1
            rightJoyStick?.buttonView.alpha = 1
        }
        else{
            isJoystickEnable = false
            leftJoyStick?.buttonView.alpha = 0.5
            rightJoyStick?.buttonView.alpha = 0.5
        }
        
    }

    //MARK :- SocketManagerDelegate
    func endEncoutered() {
        statusLabel.text = "Connection stopped by server"
        connectButton.isEnabled = true
        toggleJoystick(enable: false)
    }
    
    func errorOccurred() {
        statusLabel.text = "Failed to connect to server"
        connectButton.isEnabled = true
        toggleJoystick(enable: false)
        presentAlert()
    }
    
    func hasBytesAvailable() {
        statusLabel.text = "Got server key"
        getKeyButton.isEnabled = false
        toggleJoystick(enable: true)
    }
    
    func openCompleted() {
        statusLabel.text = "Connected to server"
        getKeyButton.isEnabled = true
    }
    
    //MARK :- Alert
    func presentAlert() {
        let alert = UIAlertController(title: "Connection error",
                                      message: "Please check address",
                                      preferredStyle: .alert)
        alert.addTextField(configurationHandler: {[weak self] textField in
            textField.text = self?.socketManager.addr
        })
        
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default,
                                      handler: { [weak self, weak alert] _ in
                                        let textField = alert?.textFields![0]
                                        self?.socketManager.addr = (textField?.text)!
                                        print("Text filed: \(textField?.text ?? "")")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }

}
