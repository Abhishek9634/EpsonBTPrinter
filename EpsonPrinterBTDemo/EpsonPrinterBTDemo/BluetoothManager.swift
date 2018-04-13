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
