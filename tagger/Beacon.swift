//
//  Beacon.swift
//  tagger
//
//  Created by Paolo Longato on 28/07/2015.
//  Copyright (c) 2015 Paolo Longato. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - Beacon Class

class Beacon: NSObject, WithEquivalence {
    let uuid:String
    let major:Int
    let minor:Int
    let timestamp:Date = Date()
    var rssi: Int
    var accuracy: Double
    var isNull: Bool {
        get {
            return rssi == 0 || accuracy == -1
        }
    }
    
    init(uuid: UUID, major:Int, minor:Int) {
        self.uuid = uuid.uuidString
        self.major = major
        self.minor = minor
        self.rssi = 0
        self.accuracy = -1
        super.init()
    }
    
    convenience init(beacon: CLBeacon) {
        self.init(uuid: beacon.proximityUUID, major: Int(beacon.major), minor: Int(beacon.minor))
        self.rssi = beacon.rssi
        self.accuracy = beacon.accuracy
    }
    
}

// MARK: - nullBeacon Class

class nullBeacon: Beacon {
    init() {
        super.init(uuid: NSUUID(uuidBytes:"00000000-0000-0000-0000-0000000000000") as UUID, major: 0, minor: 0)
    }
}

// MARK: - Beacon Equivalence Operators

func <=>(lhs: Beacon, rhs: Beacon) -> Bool{
    return lhs.uuid == rhs.uuid && lhs.minor == rhs.minor && lhs.major == rhs.major
}

func <=>(lhs: Beacon, rhs: CLBeacon) -> Bool{
    return lhs.uuid == rhs.proximityUUID.uuidString && lhs.minor == Int( rhs.minor ) && lhs.major == Int( rhs.major )
}

func <=>(lhs: CLBeacon, rhs: Beacon) -> Bool{
    return lhs.proximityUUID.uuidString == rhs.uuid && Int( lhs.minor ) == rhs.minor && Int( lhs.major ) == rhs.major
}

// MARK: - Convenience CLBeacon extension

extension CLBeacon {
    var isNull: Bool {
        get {
            return rssi == 0
        }
    }
}

