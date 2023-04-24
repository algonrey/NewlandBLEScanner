//
//  BleManager.swift
//  NewlandBLEScanner
//
//  Created by Berto on 23/3/23.
//

import Foundation
import CoreBluetooth
import UserNotifications
import UIKit

@objc public enum NewlandBLEScannerStatus:Int {
    case scanning
    case connecting
    case connected
    case disconnected
    case unknown
}

@objc public protocol NewlandBLEScannerDelegate{
    
    func barcodeRead(str:String)
    
}

@objc public protocol NewlandBLEScannerStatusDelegate{
    
    func scannerUpdateStatus(status: NewlandBLEScannerStatus)
    
}

@objc open class NewlandBLEScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    @objc public static let shared = NewlandBLEScanner()
    var centralManager: CBCentralManager!
    let centralQueue = DispatchQueue(label: "NewlandBLEScannerQueue")

    var devices = [Scanner]()
    @objc public var  status:NewlandBLEScannerStatus = .disconnected
    @objc public var delegate:NewlandBLEScannerDelegate?
    @objc public var statusDelegate:NewlandBLEScannerStatusDelegate?

    @objc public func start(){
        
        self.centralManager = CBCentralManager(delegate: self, queue: centralQueue, options: [CBCentralManagerOptionRestoreIdentifierKey: "NewlandBLEScanner"])
        print("Initializing")
    }

    
    @objc public func reset(){
        
        print("Restarting scan process")
        self.setStatus(.disconnected)
        if self.centralManager.isScanning {
            self.centralManager.stopScan()
        }
        if let d = self.connectedDevice() {
            self.centralManager.cancelPeripheralConnection(d.peripheral)
        }
        self.devices.removeAll();
        self.centralManager = CBCentralManager(delegate: self, queue: centralQueue, options: [CBCentralManagerOptionRestoreIdentifierKey: "NewlandBLEScanner"])

    }
    
    func connect(peripheral: CBPeripheral){
        print("Connecting to peripheral \(peripheral)")
        if let selected = self.selectedDevice(), !selected.connected, !self.centralManager.isScanning {
            print("Not scanning, and no connected, starting scan")
            startScan()
        }else{
            self.centralManager.stopScan()
            self.centralManager.connect(peripheral, options: nil);
        }
        
    }
    
    func startScan(){
        
        self.setStatus(.scanning)
        if let selected = self.selectedDevice() {
            centralManager.connect(selected.peripheral, options: nil)
        }else{
            self.centralManager.scanForPeripherals(withServices: [], options: nil)
        }
    }
    
    //PRAGMA MARK: - Central manager.
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported, call reset")
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                self.reset()
            })
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff, fire deviceDisconnectEvent")
            self.setStatus(.disconnected)
            if let d = self.connectedDevice() {
                d.connected = false
            }
        case .poweredOn:
            print("central.state is .poweredOn -> Start Scan")
            self.setStatus(.scanning)
            startScan()
        @unknown default:
            print("Unknown error in central manager.")
        }
        
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        print("Peripheral appeared: \(peripheral)")

        let scanner:Scanner
        if let d = deviceForPeripheral(peripheral) {
            d.peripheral = peripheral
            d.rssi = RSSI.intValue
            scanner = d
        }else{
            let d = Scanner(peripheral: peripheral)
            d.rssi = RSSI.intValue
            devices.append(d)
            scanner = d
        }
        
        
        if let name = peripheral.name, name.contains("BarCode") {
            scanner.selected = true
            self.centralManager.stopScan()
            self.setStatus(.connecting)
            self.centralManager.connect(peripheral, options: [
                CBConnectPeripheralOptionNotifyOnConnectionKey: true,
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
                CBConnectPeripheralOptionNotifyOnNotificationKey: true
            ])
        }
        

    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        self.setStatus(.connecting)
        print("-----------------CONNECTED to \(peripheral)-----------------")
        peripheral.delegate = self;
        peripheral.discoverServices(nil)
        
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("-----------------RESTORING-----------------")
        
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            
            print("Peripherals found: \(peripherals)")
            peripherals.forEach { (awakedPeripheral) in
        
                if let name = awakedPeripheral.name, name.contains("BarCode") {
                    
                    awakedPeripheral.delegate = self
                    var d:Scanner
                    if let scanner = deviceForPeripheral(awakedPeripheral) {
                        d = scanner
                    }else{
                        d = Scanner(peripheral: awakedPeripheral)
                        self.devices.append(d)
                    }
                    d.selected = true;

                    //If it's in other state, wait to be in poweredOn
                    if centralManager.state == .poweredOn {
                        awakedPeripheral.discoverServices(nil)
                    }
//                    self.setStatus(.connecting)
                    self.connect(peripheral: d.peripheral)
                }
            }
        }
        
    }
    
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        self.setStatus(.disconnected)
        print("-----------------FAIL TO CONNECT-----------------")
        print("\(error?.localizedDescription ?? "Unknown error.")")
        if let d = deviceForPeripheral(peripheral) {
            d.connected = false
        }
    }
    
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {

        self.setStatus(.disconnected)
        print("-----------------DISCONNECTED-----------------")
        print("\(error?.localizedDescription ?? "Unknown error.")")
        if let d = deviceForPeripheral(peripheral) {
            
            d.connected = false

            var uuids = [CBUUID]()
            for ser in d.peripheral.services ?? [] {
                uuids.append(ser.uuid)
            }
            central.connect(peripheral, options: [
                CBConnectPeripheralOptionNotifyOnConnectionKey: true,
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
                CBConnectPeripheralOptionNotifyOnNotificationKey: true
                ])
        }
    }
    
    
    //PRAGMA MARK: - Peripheral delegate.
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        print("Services found: \(peripheral.services?.count ?? 0)")
        
        if let services = peripheral.services {
            for ser in services {
                print("Service: \(ser), \(ser.uuid.uuidString)")
                if ser.uuid == NBSBLEConstants.service {
                    peripheral.discoverCharacteristics([NBSBLEConstants.characteristic], for: ser)
                }
            }
        }
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let chars = service.characteristics {
            
            for char in chars {
                
                if char.uuid == NBSBLEConstants.characteristic {
                    
                    peripheral.setNotifyValue(true, for: char)

                    if let d = deviceForPeripheral(peripheral) {
                        self.setStatus(.connected)
                        d.connected = true
                        d.peripheral = peripheral
                    }

                    
                }
            }
            
        }
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        
        if let data = characteristic.value, let str = String(data: data, encoding: .utf8) {
            print(str)
            self.notifyBarCodeEvent(str.replacingOccurrences(of: "\r", with: ""))
        }else{
            print("Error on the content of the characteristic.")
        }
        
    }
    
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        print("Updated name: \(String(describing: peripheral.name))")
    }
    
    
    //PRAGMA MARK: - Other.
    
    
    func deviceForPeripheral(_ peripheral: CBPeripheral) -> Scanner? {
        
        let founds = self.devices.filter { (p) -> Bool in
            return p.peripheral.identifier.uuidString == peripheral.identifier.uuidString
        }
        return founds.first
    }
    
    func selectedDevice() -> Scanner?{
        
        let founds = self.devices.filter { (p) -> Bool in
            return p.selected
        }

        return founds.first
        
    }
    
    func connectedDevice() -> Scanner?{
        
        let founds = self.devices.filter { (p) -> Bool in
            return p.connected
        }
        return founds.first        
    }
    
    
    func setStatus(_ status:NewlandBLEScannerStatus){
        self.status = status
        self.notifyBLEStatus()
    }
    
    func notifyBLEStatus(){
        DispatchQueue.main.async {
            self.statusDelegate?.scannerUpdateStatus(status: self.status)
        }
    }
    
    func notifyBarCodeEvent(_ str:String){
        DispatchQueue.main.async {
            self.delegate?.barcodeRead(str: str)
        }
    }
    
}
