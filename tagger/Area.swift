//
//  Area.swift
//  tagger
//
//  Created by Paolo Longato on 25/07/2015.
//  Copyright (c) 2015 Paolo Longato. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class Area: NSObject, NSCoding {
    var name:String = "Please name this area"
    var des:String = "Please provide a description for this area"
    var picture:UIImage = makeDefaultPicture()
    var id:Int
    var data:[[Double]] = []
    
    init(id:Int) {
        self.id = id
        super.init()
    }
    
    required convenience init?(coder decoder: NSCoder) {
        self.init(id: 0)
        ///*
        self.name = decoder.decodeObjectForKey("name") as! String
        self.des = decoder.decodeObjectForKey("des") as! String
        self.picture = decoder.decodeObjectForKey("picture") as! UIImage
        self.id = decoder.decodeIntegerForKey("id")
        self.data = decoder.decodeObjectForKey("data") as! [[Double]]
        //*/
        print("Decode one area")
    }
    
    func makeCopy() -> Area {
        let copy = Area(id: self.id)
        copy.name = self.name
        copy.des = self.des
        copy.picture = self.picture
        copy.data = self.data
        return copy
    }
    
    func encodeWithCoder(coder: NSCoder) {
        ///*
        coder.encodeObject(name, forKey: "name")
        coder.encodeObject(des, forKey: "des")
        coder.encodeObject(picture, forKey: "picture")
        coder.encodeInteger(id, forKey: "id")
        coder.encodeObject(data, forKey: "data")
        //*/
        print("Encode one area")
    }
    
    //func fingerprintsAggregateData() -> [[Double]] {
    //    return fingerprints.list.reduce([]) { $0+$1.data }
    //}
}

private func makeDefaultPicture() -> UIImage {
    let rectangle = CGRectMake(0, 0, 180, 180)
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 180, height: 180), false, 0)
    let context = UIGraphicsGetCurrentContext()
    let R = CGFloat(arc4random_uniform(256)) / 256
    let G = CGFloat(arc4random_uniform(256)) / 256
    let B = CGFloat(arc4random_uniform(256)) / 256
    CGContextSetRGBFillColor(context, R, G, B, 1.0)
    CGContextSetRGBStrokeColor(context, R, G, B, 1.0)
    CGContextFillRect(context, rectangle)
    CGContextStrokeRect(context, rectangle)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}