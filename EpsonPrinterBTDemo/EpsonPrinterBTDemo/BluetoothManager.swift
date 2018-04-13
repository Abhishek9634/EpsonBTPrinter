//
//  BluetoothManager.swift
//  EpsonPrinterBTDemo
//
//  Created by Abhishek on 13/04/18.
//  Copyright © 2018 Marvel. All rights reserved.
//

import CoreBluetooth

public let BLUETOOTH_DISABLED = "BLUETOOTH_DISABLED"

class BluetoothManager: NSObject, CBCentralManagerDelegate {
    
    var manager:CBCentralManager!
    
    override init() {
        super.init()
        self.manager = CBCentralManager()
        self.manager.delegate = self
    }
    
    var state: CBManagerState = CBManagerState.unknown
    
    public var isBTEnabled: Bool {
        return self.state == CBManagerState.poweredOn
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.state = central.state
        switch central.state {
        case .poweredOn:
            print("powered on")
        case .poweredOff:
            print("powered off")
            NotificationCenter.default.post(Notification.init(
                name: Notification.Name(rawValue: BLUETOOTH_DISABLED)
            ))
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

extension UIViewController {
    
    func showBluetoohAlert() {
        let alertVC = UIAlertController(title: "Bluetooth",
                                        message: "Please Enable Bluetooth!!!",
                                        preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        let settingAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            if let url = URL(string: UIApplicationOpenSettingsURLString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        
        alertVC.addAction(settingAction)
        alertVC.addAction(okAction)
        
        self.present(alertVC, animated: true, completion: nil)
    }
}



