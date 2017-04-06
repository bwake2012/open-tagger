//
//  BeaconMonitor.swift
//  tagger
//
//  Created by Paolo Longato on 28/07/2015.
//  Copyright (c) 2015 Paolo Longato. All rights reserved.
//

enum BeaconMonitorError: String, CustomStringConvertible {
    case BluetoothOff = "BluetoothOff"
    case BluetoothUpdating = "Bluetooth state is currently updating and therefore temporairliy unavailable"
    case BluetoothUnauthorized = "The app is not authorized to use Bluetooth low energy"
    case AuthorizationDenied = "Authorisation Denied By User"
    case AuthorizationNotAsked = "Authorisation Not Asked"
    case AuthorizationRestricted = "Authorisation Restricted"
    case LocationServicesOff = "Location Services Off"
    var description : String {get {return self.rawValue}}
}

enum BeaconMonitorAuthorisationType {
    case always
    case whenInUse
}

protocol BeaconMonitorDelegate: class {
    func beaconMonitor(_ monitor: BeaconMonitor, didFindCLBeacons beacons: [CLBeacon])
    func beaconMonitor(_ monitor: BeaconMonitor, errorScanningBeacons error: BeaconMonitorError)
    func beaconMonitor(_ monitor: BeaconMonitor, didFindStatusErrors errors: [BeaconMonitorError])
    func beaconMonitor(_ monitor: BeaconMonitor, didFindBLEErrors errors: [BeaconMonitorError])
    func beaconMonitor(_ monitor: BeaconMonitor, didReceiveAuthorisation authorisation: BeaconMonitorAuthorisationType)
}

import Foundation
import CoreLocation
import CoreBluetooth

class BeaconMonitor: NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate {
    let uuid: String
    let requiredAuthorisation: BeaconMonitorAuthorisationType
    fileprivate var uuidPrivate: UUID?
    fileprivate var beaconRegion: CLBeaconRegion?
    fileprivate let locationManager: CLLocationManager
    fileprivate var bluetoothManager: CBCentralManager
    fileprivate var delegates: [Weak<AnyObject>] = []
    
    init?(UUID: String, authorisation: BeaconMonitorAuthorisationType) {
        self.locationManager = CLLocationManager()
        let options = [CBCentralManagerOptionShowPowerAlertKey: false]
        self.bluetoothManager = CBCentralManager()
        self.requiredAuthorisation = authorisation
        self.uuid = UUID
        if let id = Foundation.UUID(uuidString: UUID) {
            self.uuidPrivate = id
            self.beaconRegion = CLBeaconRegion(proximityUUID: id, identifier: "com.contextmobile.tagger")
            self.beaconRegion!.notifyEntryStateOnDisplay = true
            super.init()
            bluetoothManager = CBCentralManager(delegate: self, queue: DispatchQueue.main, options: options)
        } else {
            print("UUID string supplied is not valid!")
            super.init()
            self.bluetoothManager = CBCentralManager(delegate: self, queue: DispatchQueue.main, options: options)
            return nil
        }
    }
    
    func statusErrors() -> [BeaconMonitorError] {
        var returnValue: [BeaconMonitorError] = []
        if CLLocationManager.authorizationStatus() == .notDetermined {
            returnValue.append(.AuthorizationNotAsked)
        }
        if CLLocationManager.authorizationStatus() == .denied {
            returnValue.append(.AuthorizationDenied)
        }
        if !CLLocationManager.locationServicesEnabled() {
            returnValue.append(.LocationServicesOff)
        }
        if CLLocationManager.authorizationStatus() == .restricted {
            returnValue.append(.AuthorizationRestricted)
        }
        return returnValue
    }
    
    func bleErrors() -> [BeaconMonitorError] {
        var returnValue: [BeaconMonitorError] = []
        if bluetoothManager.state == .poweredOff {
            returnValue.append(.BluetoothOff)
            // DEBUG PRINTS:
            //println("OFF")
        }
        if bluetoothManager.state == .resetting || bluetoothManager.state == .unknown {
            returnValue.append(.BluetoothUpdating)
            // DEBUG PRINTS:
            //println("Unknown")
        }
        if bluetoothManager.state == .unauthorized {
            returnValue.append(.BluetoothUnauthorized)
            // DEBUG PRINTS:
            //println("Unauthorized")
        }
        return returnValue
    }
    
    @objc func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            self.callDelegates(self, didReceiveAuthorisation: .whenInUse)
        case .authorizedAlways:
            self.callDelegates(self, didReceiveAuthorisation: .always)
        default: print(status)
        }
        print("STATUS CHANGE")
    }
    
    func requireAuthorization(){
        if requiredAuthorisation == .whenInUse {
            if locationManager.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization)) {
                locationManager.requestWhenInUseAuthorization()
                //println("requiring when in use auth")
            }
        } else if requiredAuthorisation == .always {
            if locationManager.responds(to: #selector(CLLocationManager.requestAlwaysAuthorization)) {
                locationManager.requestAlwaysAuthorization()
                //println("requiring always auth")
            }
        }
    }
    
    func stop() {
        locationManager.stopRangingBeacons(in: beaconRegion!)
        locationManager.stopMonitoring(for: beaconRegion!)
    }
    
    func start() {
        self.locationManager.delegate = self
        let errors = statusErrors()
        if errors.isEmpty {startMonitoring()}
        
        // TESTING MODE?  Use the following code as a template for generating CLBeacons if you need to test and do not have real beacons.  Copy and paste the code where relevant.
        /*
        let testMode = false
        var testBeacons: [CLBeacon] = []
        
        let beacon1 = CLBeacon()
        testBeacons.append(beacon1)
        testBeacons[0].setValue(NSUUID(UUIDString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e"), forKey: "proximityUUID")
        testBeacons[0].setValue(16985, forKey: "major")
        testBeacons[0].setValue(52643, forKey: "minor")
        testBeacons[0].setValue(0.5, forKey: "accuracy")
        
        if testMode {
            self.delegate.beaconMonitor(self, didFindCLBeacons: testBeacons)
        }
        */
    }
    
    func addDelegate(_ delegate: AnyObject) {
        self.delegates = self.delegates.filter({ $0.value != nil  })
        self.delegates.append(Weak(value: delegate))
    }
    
    fileprivate func callDelegates(_ monitor: BeaconMonitor, didFindBeacons beacons: [CLBeacon]) {
        let _ = self.delegates.map({ (delegate) in
            if let d = delegate.value as? BeaconMonitorDelegate {
                d.beaconMonitor(monitor, didFindCLBeacons: beacons)
            }
        })
    }
    
    fileprivate func callDelegates(_ monitor: BeaconMonitor, errorScanningBeacons error: BeaconMonitorError) {
        let _ = self.delegates.map({ (delegate) in
            if let d = delegate.value as? BeaconMonitorDelegate {
                d.beaconMonitor(monitor, errorScanningBeacons: error)
            }
        })
    }
    
    fileprivate func callDelegates(_ monitor: BeaconMonitor, didFindStatusErrors errors: [BeaconMonitorError]) {
        let _ = self.delegates.map({ (delegate) in
            if let d = delegate.value as? BeaconMonitorDelegate {
                d.beaconMonitor(monitor, didFindStatusErrors: errors)
            }
        })
    }
    
    fileprivate func callDelegates(_ monitor: BeaconMonitor, didFindBLEErrors errors: [BeaconMonitorError]) {
        let _ = self.delegates.map({ (delegate) in
            if let d = delegate.value as? BeaconMonitorDelegate {
                d.beaconMonitor(monitor, didFindBLEErrors: errors)
            }
        })
    }
    
    fileprivate func callDelegates(_ monitor: BeaconMonitor, didReceiveAuthorisation authorisation: BeaconMonitorAuthorisationType) {
        let _ = self.delegates.map({ (delegate) in
            if let d = delegate.value as? BeaconMonitorDelegate {
                d.beaconMonitor(monitor, didReceiveAuthorisation: authorisation)
            }
        })
    }
    
    fileprivate func startMonitoring() {
        locationManager.startMonitoring(for: beaconRegion!)
        locationManager.startRangingBeacons(in: beaconRegion!)
        print("Region monitor starting \(String(describing: beaconRegion))")
    }
    
    // Unimplemented
    @objc func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Ranging beacons starting")
    }
    
    // Unimplemented
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("didFailWithError \(error)")
    }
    
    // Unimplemented
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
//        print("monitoringDidFailForRegion \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        let bcs = beacons 
        if bcs.count > 0 {
            self.callDelegates(self, didFindBeacons: bcs)
        }
    }
    
    // BLUETOOTH CHANGE OF STATE
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.callDelegates(self, didFindBLEErrors: bleErrors())
    }
    
}

