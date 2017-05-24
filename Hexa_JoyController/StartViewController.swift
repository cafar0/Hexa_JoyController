//
//  StartViewController.swift
//  Hexa_JoyController
//
//  Created by Rodina, Calin on 24/05/2017.
//  Copyright © 2017 Rodina, Calin. All rights reserved.
//

import UIKit
//import CoreGraphics

class JoyStick : NSObject{
    
    var containerView : UIView
    var baseView: UIView
    var buttonView: UIView
    var update : ((String)->Void)?
    
    
    init(containerView: UIView, baseView: UIView, buttonView: UIView) {
        self.containerView = containerView
        self.baseView = baseView
        self.buttonView = buttonView

        super.init()
    }
    
}

class StartViewController: UIViewController {
    
    
    private var radius : CGFloat = 0
    private var displacement : CGFloat = 0
    private var lastAngleRadians : Float = 0
    private var angle : CGFloat = 0
    
    private var leftJoyStick : JoyStick?
    private var rightJoyStick: JoyStick?
    
    @IBOutlet weak var leftJoyContainer: UIView!
    @IBOutlet weak var righJoyContainer: UIView!
    @IBOutlet weak var leftJoyBase: UIImageView!
    @IBOutlet weak var rightJoyBase: UIImageView!
    @IBOutlet weak var leftJoyButton: UIImageView!
    @IBOutlet weak var rightJoyButton: UIImageView!
    @IBOutlet weak var leftAngleLabel: UILabel!
    @IBOutlet weak var rightAngleLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftJoyStick   = JoyStick(containerView: leftJoyContainer, baseView: leftJoyBase, buttonView: leftJoyButton)
        leftJoyStick?.update = {[weak self] radians in
            self?.leftAngleLabel.text = radians + "º"
        }
        rightJoyStick = JoyStick(containerView: righJoyContainer, baseView: rightJoyBase, buttonView: rightJoyButton)
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
            joyStick.update!(self.angle.description)
            
        }

    }
   
}
