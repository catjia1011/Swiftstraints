//
//  LayoutConstraints.swift
//  Swiftstraints
//
//  Created by Bradley Hilton on 5/12/15.
//  Copyright (c) 2015 Skyvive. All rights reserved.
//

import Foundation

private func vflKey(_ object: AnyObject) -> String {
    return "A\(UInt(bitPattern: Unmanaged.passUnretained(object).toOpaque().hashValue))B"
}

/// Represents constraints created from a interpolated string in the visual format language.
public struct VisualFormatLanguage : ExpressibleByStringInterpolation {
    
    let format: String
    var metrics = NSMapTable<NSString, NSNumber>(keyOptions: .copyIn, valueOptions: .copyIn)
    var views = NSMapTable<NSString, UIView>(keyOptions: .copyIn, valueOptions: .weakMemory)
    var viewCount: Int = 0  // used to check if this VFL is still valid; since views won't persist the view pointers, if the view is deallocated, there will be an exception when constraints are created later
    
    public init(stringInterpolation strings: VisualFormatLanguage...) {
        var format = ""
        for vfl in strings {
            format.append(vfl.format)
            if let keys = vfl.metrics.keyEnumerator().allObjects as? [NSString] {
                for key in keys {
                    metrics.setObject(vfl.metrics.object(forKey: key), forKey: key)
                }
            }
            if let keys = vfl.views.keyEnumerator().allObjects as? [NSString] {
                for key in keys {
                    if views.object(forKey: key) == nil {
                        views.setObject(vfl.views.object(forKey: key), forKey: key)
                        viewCount += 1
                    }
                }
            }
        }
        self.format = format
    }
    
    public init<T>(stringInterpolationSegment expr: T) {
        if let view = expr as? UIView {
            format = vflKey(view)
            views.setObject(view, forKey: format as NSString)
        } else if let number = expr as? NSNumber {
            format = vflKey(number)
            metrics.setObject(number, forKey: format as NSString)
        } else {
            format = String(describing: expr)
        }
    }
    
    func vflDictionary<T>(_ table: NSMapTable<NSString, T>) -> [String : AnyObject] {
        var dictionary = [String : AnyObject]()
        (table.keyEnumerator().allObjects as? [NSString])?.forEach { key in
            dictionary[key as String] = table.object(forKey: key)
        }
        return dictionary
    }
    
    /// Returns layout constraints with options.
    public func constraints(_ options: NSLayoutFormatOptions) -> [NSLayoutConstraint] {
        /// fail it if views are changed in case of the weak pointers' targets being deallocated
        guard views.count == viewCount else { return [] }
        return NSLayoutConstraint.constraints(withVisualFormat: format, options: options, metrics: vflDictionary(metrics), views: vflDictionary(views))
    }
    
    /// Returns layout constraints.
    public var constraints: [NSLayoutConstraint] {
        return constraints([])
    }
    
}

public typealias NSLayoutConstraints = [NSLayoutConstraint]

extension Array where Element : NSLayoutConstraint {
    
    /// Create a list of constraints using a string interpolated with nested views and metrics.
    /// You can optionally include NSLayoutFormatOptions as the second parameter.
    public init(_ visualFormatLanguage: VisualFormatLanguage, options: NSLayoutFormatOptions = []) {
        if let constraints = visualFormatLanguage.constraints(options) as? [Element] {
            self = constraints
        } else {
            self = []
        }
    }
    
}
