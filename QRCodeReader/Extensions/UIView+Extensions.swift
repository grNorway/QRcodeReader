//
//  UIView+Extensions.swift
//  QRCodeReader
//
//  Created by PS Shortcut on 04/04/2019.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import UIKit

extension UIView {
    func mask(withRect rect: CGRect, inverse: Bool = false) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)// UIBezierPath(rect: rect)
        
        let maskLayer = CAShapeLayer()
        //maskLayer.cornerRadius = 2
        
        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        }
        
        maskLayer.path = path.cgPath
        
        self.layer.mask = maskLayer
    }
    
    func mask(withPath path: UIBezierPath, inverse: Bool = false) {
        let path = path
        let maskLayer = CAShapeLayer()
        
        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        }
        
        maskLayer.path = path.cgPath
        
        self.layer.mask = maskLayer
    }
}
