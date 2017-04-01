//
//  VFLComponent.swift
//  Swiftstraints
//
//  Created by Cat Jia on 1/4/2017.
//  Copyright © 2017 Skyvive. All rights reserved.
//

import UIKit

private func vflKey(_ object: AnyObject) -> String {
    return "A\(UInt(bitPattern: Unmanaged.passUnretained(object).toOpaque().hashValue))B"
}

prefix operator ==
prefix operator >=
prefix operator <=

prefix operator |
prefix operator |-
postfix operator |
postfix operator -|

public struct VFLComponent: ExpressibleByArrayLiteral, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public var format = ""
    var viewDict = [String: UIView]()
    
    public typealias Element = UIView
    public init(arrayLiteral elements: Element...) {
        guard elements.count == 1 else {
            fatalError("view component can contains only one UIView instance: \(elements)")
        }
        let view = elements[0]
        let key = vflKey(view)
        viewDict[key] = view
        self.format = "[\(key)]"
    }

    var metricDict = [String: NSNumber]()
    public typealias FloatLiteralType = Double
    public init(floatLiteral value: FloatLiteralType) {
        let number = value as NSNumber
        let key = vflKey(number)
        metricDict[key] = number
        self.format = key
    }
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: IntegerLiteralType) {
        let number = value as NSNumber
        let key = vflKey(number)
        metricDict[vflKey(number)] = number
        self.format = key
    }

}

// MARK: - operators
public prefix func ==(x: VFLComponent) -> VFLComponent {
    var x = x
    x.format = "(==" + x.format + ")"
    return x
}
public prefix func >=(x: VFLComponent) -> VFLComponent {
    var x = x
    x.format = "(>=" + x.format + ")"
    return x
}
public prefix func <=(x: VFLComponent) -> VFLComponent {
    var x = x
    x.format = "(<=" + x.format + ")"
    return x
}


public prefix func |(x: VFLComponent) -> VFLComponent {
    var x = x
    x.format = "|" + x.format
    return x
}
public prefix func |-(x: VFLComponent) -> VFLComponent {
    var x = x
    x.format = "|-" + x.format
    return x
}
public postfix func |(x: VFLComponent) -> VFLComponent {
    var x = x
    x.format = x.format + "|"
    return x
}
public postfix func -|(x: VFLComponent) -> VFLComponent {
    var x = x
    x.format = x.format + "-|"
    return x
}
public func -(lhs: VFLComponent, rhs: VFLComponent) -> VFLComponent {
    var result = lhs
    result.format = lhs.format + "-" + rhs.format
    for (key, value) in rhs.viewDict {
        result.viewDict.updateValue(value, forKey: key)
    }
    for (key, value) in rhs.metricDict {
        result.metricDict.updateValue(value, forKey: key)
    }
    return result
}

/// usage: let constraints = NSLayoutConstraints(H:|-[view1]-(>=5)-[view2]-3-|)
extension Array where Element: NSLayoutConstraint {
    public init(H: VFLComponent, options: NSLayoutFormatOptions = []) {
        self = NSLayoutConstraint.constraints(withVisualFormat: "H:" + H.format, options: options, metrics: H.metricDict, views: H.viewDict) as! [Element]
    }
    public init(V: VFLComponent, options: NSLayoutFormatOptions = []) {
        self = NSLayoutConstraint.constraints(withVisualFormat: "V:" + V.format, options: options, metrics: V.metricDict, views: V.viewDict) as! [Element]
    }
}
