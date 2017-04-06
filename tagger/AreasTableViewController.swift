//
//  AreasTableTableViewController.swift
//  
//
//  Created by Paolo Longato on 25/07/2015.
//
//

import UIKit
import CoreLocation

class AreasTableViewController: UITableViewController, BeaconMonitorDelegate {

    var areas = Areas()
    var labels:[String] = []
    var remoteBeacons = beaconDB()
    var selectedCell = -1
    var selectedCellIndexPath:IndexPath?
    var beacons: Reel<Beacon>?
    var monitor:BeaconMonitor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "secondTabActive"), object: nil, queue: nil) { (notif) in
            guard (self.monitor != nil) else {
                return }
            self.monitor!.stop()
        }
        self.areas.load()
        self.beacons = Reel(elements: self.remoteBeacons.beacons, limit: 5, nullValue: nullBeacon())
        if let m = BeaconMonitor(UUID: remoteBeacons.beacons.first!.uuid, authorisation: .always){
            m.addDelegate(self)
            monitor = m
            let e = m.statusErrors()
            if !e.isEmpty {
                for v in e {
                    if v == .AuthorizationNotAsked {
                        m.requireAuthorization()
                    }
                    print(v.description)
                }
            } else {
                monitor?.start()
            }
        }
        
    }

    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "firstTabActive"), object: nil)
        monitor?.start()
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "firstTabInactive"), object: self.areas.makeCopy())
        super.viewDidDisappear(animated)
        // DEBUG PRINTS:
        //print(areas.data())
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "secondTabActive"), object: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return areas.list.count
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            areas.list.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        default:
            print("Invalid editing style")
        }
    }

    @IBAction func addArea() {
        areas.addArea()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AreasCellView", for: indexPath) as! AreasCellView
        // Configure the cell...
        cell.icon.image = areas.list[indexPath.row].picture
        cell.desc.text = areas.list[indexPath.row].name
        cell.editButton.tag = indexPath.row
        cell.tag = indexPath.row
        return cell
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
    
    // MARK: - Unimplemented table view editing methods
    // At the moment the only supported tavle view editing is "swipe left" to delete a cell / area
        
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "editArea", let sender = sender as? UIView {

            let index = sender.tag
            let VC = segue.destination as! EditAreaViewController
            VC.area = areas.list[index]
            VC.updateTable = reloadTable
        }
    }
    
    // MARK: - BEACON MONITOR DELEGATE METHODS
    
    func beaconMonitor(_ monitor: BeaconMonitor, didFindCLBeacons beacons: [CLBeacon]){
        
        // Process ans store raw RSSI data:
        // CLBeacons are "translated" into pure Swift Beacon objects
        // Push beacons in the appropriate queues. If 4 or fewer a beacon readings are missing or their RSSI == 0 (Apple calculations gone wrong), then:
        // the latest available Beacon reading are used to fill such missing value.  Else:
        // a "null Beacon" placeholder is used.
        // Beacons data are then stored only if there is an area "label" associated to it (i.e. the user has selected a cell and is therefore "fingerprinting an area")
        
        guard (self.beacons != nil) else { return }
        let bcs = beacons.reduce([]) { $0 + [Beacon(beacon: $1)] }
        self.beacons = self.beacons!.pushMatchingElementsIn(bcs)
        let avgRssi: [Double] = Utility.filterRssi(self.beacons!.getItemsInAllQueues())
        var relativeRssi: [Double] = [] //= Histogram(data: avgRssi)?.distribution()
        if let rr = Histogram(data: avgRssi)?.distribution() {
            relativeRssi = rr
        }
        
        if selectedCell > -1 && relativeRssi.count > 0 {
            self.areas.list[selectedCell].data.append(relativeRssi)
        }

        // DEBUG PRINTS:
        //beacons.map({print($0.major)})
        //print(avgRssi)
        //print(relativeRssi)
        //print(selectedCell)
        
    }
    
    func beaconMonitor(_ monitor: BeaconMonitor, errorScanningBeacons error: BeaconMonitorError){
        // Unimplemented error handling
        // DEBUG PRINTS:
        print(error)
    }
    
    func beaconMonitor(_ monitor: BeaconMonitor, didFindStatusErrors errors: [BeaconMonitorError]) {
        // Unimplemented error handling
        // DEBUG PRINTS:
        let _ = errors.map({print($0)})
    }
    
    func beaconMonitor(_ monitor: BeaconMonitor, didFindBLEErrors errors: [BeaconMonitorError]) {
        // Unimplemented error handling
        // DEBUG PRINTS:
        let _ = errors.map({print($0)})
    }
    
    func beaconMonitor(_ monitor: BeaconMonitor, didReceiveAuthorisation authorisation: BeaconMonitorAuthorisationType) {
        // DEBUG PRINTS:
        //print("Authorisation received")
        monitor.start()
    }
    
    // MARK: - TABLE VIEW DELEGATE METHODS
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // DEBUG PRINTS:
        //print("DESELECTED")
        selectedCell = -1
        selectedCellIndexPath = nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // DEBUG PRINTS:
        //print("DID SELECT")
        selectedCell = indexPath.row
        selectedCellIndexPath = indexPath
    }
    
    override func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        // DEBUG PRINTS:
        //print("WILL DESELECT")
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        if cell?.isSelected == true {
            _ = tableView.delegate?.tableView!(tableView, willDeselectRowAt: indexPath)
            tableView.deselectRow(at: indexPath, animated: false)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
            return nil
        }
        return indexPath
    }

}
