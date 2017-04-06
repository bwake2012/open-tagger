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
        self.name = decoder.decodeObject(forKey: "name") as! String
        self.des = decoder.decodeObject(forKey: "des") as! String
        self.picture = decoder.decodeObject(forKey: "picture") as! UIImage
        self.id = decoder.decodeInteger(forKey: "id")
        self.data = decoder.decodeObject(forKey: "data") as! [[Double]]
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
    
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(des, forKey: "des")
        coder.encode(picture, forKey: "picture")
        coder.encode(id, forKey: "id")
        coder.encode(data, forKey: "data")
        print("Encode one area")
    }
    
}

private func makeDefaultPicture() -> UIImage {
    
    let rectangle = CGRect(x: 0, y: 0, width: 180, height: 180)
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 180, height: 180), false, 0)
    let context = UIGraphicsGetCurrentContext()
    let R = CGFloat(arc4random_uniform(256)) / 256
    let G = CGFloat(arc4random_uniform(256)) / 256
    let B = CGFloat(arc4random_uniform(256)) / 256
    context?.setFillColor(red: R, green: G, blue: B, alpha: 1.0)
    context?.setStrokeColor(red: R, green: G, blue: B, alpha: 1.0)
    context?.fill(rectangle)
    context?.stroke(rectangle)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
}
