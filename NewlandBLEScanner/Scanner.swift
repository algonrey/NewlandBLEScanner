//
//  Scanner.swift
//  NewlandBLEScanner
//
//  Created by Berto on 23/3/23.
//

import Foundation
import CoreBluetooth

class Scanner: NSObject {
    
    var peripheral:CBPeripheral
    var selected:Bool = false
    var connected:Bool = false
    var rssi:Int = 0
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
    }
    
}
