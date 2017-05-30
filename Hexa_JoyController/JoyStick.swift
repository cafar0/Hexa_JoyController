//
//  JoyStick.swift
//  Hexa_JoyController
//
//  Created by Rodina, Calin on 26/05/2017.
//  Copyright © 2017 Rodina, Calin. All rights reserved.
//

import Foundation
import UIKit

enum joystickState {
    case forward
    case backward
    case left
    case right
    case neutral
}

class JoyStick : NSObject{
    
    var identifier = ""
    var containerView : UIView
    var baseView: UIView
    var buttonView: UIView
    var update : ((String)->Void)?
    
    var upValue    = ""
    var downValue  = ""
    var rightValue = ""
    var leftValue  = ""
    var neutralValue = ""
    
    
    init(identifier: String, containerView: UIView, baseView: UIView, buttonView: UIView) {
        self.identifier = identifier
        self.containerView = containerView
        self.baseView = baseView
        self.buttonView = buttonView
        super.init()
        
        setValues()
    }
    
    private func setValues() {
        self.upValue = self.identifier + ": up"
        self.downValue = self.identifier + ": down"
        self.rightValue = self.identifier + ": right"
        self.leftValue = self.identifier + ": left"
        self.neutralValue = self.identifier + ": neutral"
    }
    
    
}
