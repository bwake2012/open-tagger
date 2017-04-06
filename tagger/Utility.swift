//
//  Utility.swift
//  tagger
//
//  Created by Paolo Longato on 21/08/2015.
//  Copyright (c) 2015 Paolo Longato. All rights reserved.
//

import Foundation

class Utility {

    // MARK: - Time axis operations
    
    class func average(_ observations: [Double]) -> Double? {
        if observations.count > 0 {
            return observations.reduce(0) { $0 + $1 } / Double(observations.count)
        } else {
            return nil
        }
    }
    
    class func average(_ observations: [Double], ignoring value: Double) -> Double? {
        return average(observations.filter({ $0 != value }))
    }
    
    class func entryFilter(_ observations: [Double], threshold value: Int) -> [Double] {
        if observations.filter({ $0 != 0 }).count >= value {
            return observations
        } else {
            return [Double](repeating: 0, count: observations.count)
        }
    }
    
    class func filterRssi(_ rssiMatrix: [[Beacon]]) -> [Double] {
        let rssi: [[Double]] = rssiMatrix.reduce([]) { $0 + [$1.map({ Double($0.rssi) })] }.map( { Utility.entryFilter($0, threshold: 5) } )
        let avgRssi: [Double] = rssi.map( { Utility.average($0, ignoring: 0) } ).map({ if $0 == nil || $0 == 0 { return -95 } else { return $0! } })
        return avgRssi
    }
    
    // MARK: - Spectrum operations
    
    class func areaForecasts(_ currentArray: [Double], labels: [Int], arraysDatabase: [[Double]]) -> [(Int, Double)] {
        guard arraysDatabase.count > 0 else { return [] }
        guard currentArray.count == arraysDatabase.first!.count else { return [] }
        let distances = arraysDatabase.map({ self.squareDistance(x: $0, y: currentArray) })
        return zip(labels, distances).sorted(by: { $0.1 < $1.1 })
    }
    
    class func filter(_ areaForecasts: [(Int, Double)], forDistance d: Double) -> [(Int, Double)] {
        return areaForecasts.filter({ $0.1 < d })
    }
    
    fileprivate class func squareDistance(x a1:[Double], y a2:[Double]) -> Double {
        return zip(a1, a2).reduce(0){ ($1.0 - $1.1) * ($1.0 - $1.1) + $0 }
    }
    
    fileprivate class func manhattanDistance(x a1:[Double], y a2:[Double]) -> Double {
        return zip(a1, a2).reduce(0) { abs($1.0 - $1.1) + $0 }
    }
    
}
