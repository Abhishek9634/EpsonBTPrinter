//
//  ViewController.swift
//  EpsonPrinterBTDemo
//
//  Created by Abhishek on 11/04/18.
//  Copyright © 2018 Marvel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let printviewId = "printview"
    
    fileprivate var printerList: [Epos2DeviceInfo] = []
    fileprivate var filterOption: Epos2FilterOption = Epos2FilterOption()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setup() {
        self.filterOption.deviceType = EPOS2_TYPE_PRINTER.rawValue
//        self.filterOption.portType = EPOS2_PORTTYPE_BLUETOOTH.rawValue
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let result = Epos2Discovery.start(filterOption, delegate: self)
        if result != EPOS2_SUCCESS.rawValue {
            //ShowMsg showErrorEpos(result, method: "start")
            print(result)
        }
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        while Epos2Discovery.stop() == EPOS2_ERR_PROCESSING.rawValue {
            // retry stop function
        }
        
        self.printerList.removeAll()
    }
    
    @IBAction func discovery(_ sender: UIButton) {
     
        var result = EPOS2_SUCCESS.rawValue;
        
        while true {
            result = Epos2Discovery.stop()
            
            if result != EPOS2_ERR_PROCESSING.rawValue {
                if (result == EPOS2_SUCCESS.rawValue) {
                    break
                } else {
                    MessageView.showErrorEpos(result, method:"stop")
                    return
                }
            }
        }
        
        self.printerList.removeAll()
        self.tableView.reloadData()
        
        result = Epos2Discovery.start(filterOption, delegate:self)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"start")
        }
    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let printer = self.printerList[indexPath.row]
        self.performSegue(withIdentifier: self.printviewId, sender: printer)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "DeviceTableViewCell"
        ) as! DeviceTableViewCell
        cell.textLabel?.text = self.printerList[indexPath.row].deviceName
        cell.detailTextLabel?.text = self.printerList[indexPath.row].target
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(self.printerList.count)
        return self.printerList.count
    }
}

extension ViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier, segue.destination, sender) {
        case (self.printviewId, let vc as PrintViewController, let model as Epos2DeviceInfo):
            vc.deviceInfo = model
        default:
            break
        }
        super.prepare(for: segue, sender: sender)
    }
    
}

extension ViewController: Epos2DiscoveryDelegate {
    
    func onDiscovery(_ deviceInfo: Epos2DeviceInfo!) {
        self.printerList.append(deviceInfo)
        self.tableView.reloadData()
    }
}

extension UIViewController {
    
    func showAlert(msg: String) {
        let alert = UIAlertView(title: "",
                                message: msg,
                                delegate: nil,
                                cancelButtonTitle: nil,
                                otherButtonTitles: "OK")
        alert.show()
    }
}
