//
//  BluetoothManager.swift
//  EpsonPrinterBTDemo
//
//  Created by Abhishek on 13/04/18.
//  Copyright © 2018 Marvel. All rights reserved.
//

import CoreBluetooth

extension UIViewController: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("powered on")
        case .poweredOff:
            print("powered off")
        case .resetting:
            print("resetting")
        case .unauthorized:
            print("unauthorized")
        case .unsupported:
            print("unsupported")
        case .unknown:
            print("unknown")
        }
    }
}
