//
//  PrintViewController.swift
//  EpsonPrinterBTDemo
//
//  Created by Abhishek on 12/04/18.
//  Copyright © 2018 Marvel. All rights reserved.
//

import UIKit

struct EPOS_CONSTANT {
    static let PAGE_AREA_HEIGHT: Int = 500
    static let PAGE_AREA_WIDTH: Int = 500
    static let FONT_A_HEIGHT: Int = 24
    static let FONT_A_WIDTH: Int = 12
    static let BARCODE_HEIGHT_POS: Int = 70
    static let BARCODE_WIDTH_POS: Int = 110
}

class PrintViewController: UIViewController {

    var deviceInfo: Epos2DeviceInfo!
    var printer: Epos2Printer?

    let valuePrinterSeries: Epos2PrinterSeries = EPOS2_TM_M30 // EPOS2_TM_M10
    let valuePrinterModel: Epos2ModelLang = EPOS2_MODEL_ANK
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let result = Epos2Log.setLogSettings(EPOS2_PERIOD_TEMPORARY.rawValue,
                                             output: EPOS2_OUTPUT_STORAGE.rawValue,
                                             ipAddress: nil,
                                             port: 0,
                                             logSize: 1,
                                             logLevel: EPOS2_LOGLEVEL_LOW.rawValue)
        
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method: "setLogSettings")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func printReceipt(_ sender: UIButton) {
        if !self.runPrinterReceiptSequence() {
            
        }
    }
}

extension PrintViewController: Epos2PtrReceiveDelegate {
    
    func onPtrReceive(_ printerObj: Epos2Printer!, code: Int32, status: Epos2PrinterStatusInfo!, printJobId: String!) {
        
        self.showAlert(msg: self.makeErrorMessage(status))
        self.dispPrinterWarnings(status)
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
            self.disconnectPrinter()
        })
    }
    
    func disconnectPrinter() {
        var result: Int32 = EPOS2_SUCCESS.rawValue
        
        if printer == nil {
            return
        }
        
        result = printer!.endTransaction()
        if result != EPOS2_SUCCESS.rawValue {
            DispatchQueue.main.async(execute: {
                MessageView.showErrorEpos(result, method:"endTransaction")
            })
        }
        
        result = printer!.disconnect()
        if result != EPOS2_SUCCESS.rawValue {
            DispatchQueue.main.async(execute: {
                MessageView.showErrorEpos(result, method:"disconnect")
            })
        }
        
        finalizePrinterObject()
    }
}

extension PrintViewController {
    
    func connectPrinter() -> Bool {
        var result: Int32 = EPOS2_SUCCESS.rawValue
        
        if self.printer == nil {
            return false
        }
        
        result = self.printer!.connect(self.deviceInfo.target, timeout:Int(EPOS2_PARAM_DEFAULT))
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"connect")
            return false
        }
        
        result = self.printer!.beginTransaction()
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"beginTransaction")
            printer!.disconnect()
            return false
            
        }
        return true
    }
    
    func runPrinterReceiptSequence() -> Bool {
        
        if !self.initializePrinterObject() {
            return false
        }
        
        if !self.customReceiptData() {
            self.finalizePrinterObject()
            return false
        }
        
        if !self.printData() {
            self.finalizePrinterObject()
            return false
        }
        
        return true
    }
    
    func initializePrinterObject() -> Bool {
        self.printer = Epos2Printer(printerSeries: self.valuePrinterSeries.rawValue,
                               lang: self.valuePrinterModel.rawValue)
        
        if self.printer == nil {
            return false
        }
        
        self.printer!.setReceiveEventDelegate(self)
        
        return true
    }
    
    func finalizePrinterObject() {
        
        if self.printer == nil {
            return
        }
        
        self.printer!.clearCommandBuffer()
        self.printer!.setReceiveEventDelegate(nil)
        self.printer = nil
    }
    
    
    func printData() -> Bool {
        var status: Epos2PrinterStatusInfo?
        
        if printer == nil {
            return false
        }
        
        if !connectPrinter() {
            return false
        }
        
        status = self.printer!.getStatus()
        self.dispPrinterWarnings(status)
        
        if !self.isPrintable(status) {
            MessageView.show(makeErrorMessage(status))
            printer!.disconnect()
            return false
        }
        
        let result = printer!.sendData(Int(EPOS2_PARAM_DEFAULT))
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"sendData")
            self.printer!.disconnect()
            return false
        }
        
        return true
    }
    
    func isPrintable(_ status: Epos2PrinterStatusInfo?) -> Bool {
        if status == nil {
            return false
        }
        
        if status!.connection == EPOS2_FALSE {
            return false
        }
        else if status!.online == EPOS2_FALSE {
            return false
        }
        else {
            // print available
        }
        return true
    }
    
    func customReceiptData() -> Bool {
        
        var result = EPOS2_SUCCESS.rawValue
        
        let textData: NSMutableString = NSMutableString()
        let logoData = UIImage(named: "dutch_500.png")
        
        if logoData == nil { return false }
        
        result = printer!.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addTextAlign")
            return false
        }
        
        result = printer!.add(logoData, x: 0, y:0,
                              width:Int(logoData!.size.width),
                              height:Int(logoData!.size.height),
                              color:EPOS2_COLOR_1.rawValue,
                              mode:EPOS2_MODE_MONO.rawValue,
                              halftone:EPOS2_HALFTONE_DITHER.rawValue,
                              brightness:Double(EPOS2_PARAM_DEFAULT),
                              compress:EPOS2_COMPRESS_AUTO.rawValue)
        
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addImage")
            return false
        }
        
        // Section 1 : Store information
        result = printer!.addFeedLine(1)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addFeedLine")
            return false
        }
        
        textData.append("Order #1-010              12/29/17, 2:03 PM\n")
        textData.append("\n")
        textData.append("Sale for J.N...       Served by thedutchess\n")
        textData.append("\n")
        textData.append("Transaction             #233854011291710009\n")
        textData.append("\n")
        textData.append("-------------------------------------------\n")
        textData.append("1 X Wine (Glass)                     7.00 T\n")
        textData.append("-------------------------------------------\n")
        textData.append("Subtotal                               7.00\n")
        textData.append("Tax                                    0.57\n")
        textData.append("\n")
        
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addText")
            return false
        }
        
        textData.setString("")
        textData.append("Total                                  7.57\n")
        
        result = printer!.addTextStyle(EPOS2_PARAM_DEFAULT, ul:EPOS2_PARAM_DEFAULT, em:EPOS2_TRUE, color:EPOS2_PARAM_DEFAULT)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addTextStyle")
            return false
        }
        
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addText")
            return false
        }
        
        textData.setString("")
        
        result = printer!.addTextStyle(EPOS2_PARAM_DEFAULT, ul:EPOS2_PARAM_DEFAULT, em:EPOS2_FALSE, color:EPOS2_PARAM_DEFAULT)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addTextStyle")
            return false
        }
        
        textData.append("-------------------------------------------\n")
        textData.append("VISA 2262                              7.57\n")
        textData.append("\n")
        textData.append("Name                    NEWMAN/JEFFREY ALAN\n")
        textData.append("Approval Code                        003911\n")
        textData.append("Data Source                       Chip Read\n")
        textData.append("-------------------------------------------\n")
        textData.append("Mode                                Issuer \n")
        textData.append("\n")
        textData.append("AID                          a0000000980840\n")
        textData.append("TVR                              8080040000\n")
        textData.append("IAD                          06010a03a02000\n")
        textData.append("TSI                                    6800\n")
        textData.append("ARC                                      00\n")
        textData.append("-------------------------------------------\n")
        textData.append("\n")
        textData.append("Amount                                 7.57\n")
        textData.append("\n")
        textData.append("Tip                  ______________________\n")
        textData.append("\n")
        textData.append("Total                ______________________\n")
        textData.append("\n")
        textData.append("I agree to pay the above\n")
        textData.append("total amount acording to\n")
        textData.append("the card issuer agreement\n")
        textData.append("\n\n")
        textData.append("Signature           _______________________\n")
        textData.append("                              Customer Copy\n")
        textData.append("___________________________________________\n")
        
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addText")
            return false
        }
        
        textData.setString("")
        result = printer!.addCut(EPOS2_CUT_FEED.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addCut")
            return false
        }
        
        return true
    }
    
    func dispPrinterWarnings(_ status: Epos2PrinterStatusInfo?) {
        
        if status == nil {
            return
        }
        
        if status!.paper == EPOS2_PAPER_NEAR_END.rawValue {
            self.showAlert(msg: "warn_receipt_near_end")
        }
        
        if status!.batteryLevel == EPOS2_BATTERY_LEVEL_1.rawValue {
            self.showAlert(msg: "warn_battery_near_end")
        }
    }
    
    func makeErrorMessage(_ status: Epos2PrinterStatusInfo?) -> String {
        let errMsg = NSMutableString()
        if status == nil {
            return ""
        }
        
        if status!.online == EPOS2_FALSE {
            errMsg.append(NSLocalizedString("err_offline", comment:""))
        }
        if status!.connection == EPOS2_FALSE {
            errMsg.append(NSLocalizedString("err_no_response", comment:""))
        }
        if status!.coverOpen == EPOS2_TRUE {
            errMsg.append(NSLocalizedString("err_cover_open", comment:""))
        }
        if status!.paper == EPOS2_PAPER_EMPTY.rawValue {
            errMsg.append(NSLocalizedString("err_receipt_end", comment:""))
        }
        if status!.paperFeed == EPOS2_TRUE || status!.panelSwitch == EPOS2_SWITCH_ON.rawValue {
            errMsg.append(NSLocalizedString("err_paper_feed", comment:""))
        }
        if status!.errorStatus == EPOS2_MECHANICAL_ERR.rawValue || status!.errorStatus == EPOS2_AUTOCUTTER_ERR.rawValue {
            errMsg.append(NSLocalizedString("err_autocutter", comment:""))
            errMsg.append(NSLocalizedString("err_need_recover", comment:""))
        }
        if status!.errorStatus == EPOS2_UNRECOVER_ERR.rawValue {
            errMsg.append(NSLocalizedString("err_unrecover", comment:""))
        }
        
        if status!.errorStatus == EPOS2_AUTORECOVER_ERR.rawValue {
            if status!.autoRecoverError == EPOS2_HEAD_OVERHEAT.rawValue {
                errMsg.append(NSLocalizedString("err_overheat", comment:""))
                errMsg.append(NSLocalizedString("err_head", comment:""))
            }
            if status!.autoRecoverError == EPOS2_MOTOR_OVERHEAT.rawValue {
                errMsg.append(NSLocalizedString("err_overheat", comment:""))
                errMsg.append(NSLocalizedString("err_motor", comment:""))
            }
            if status!.autoRecoverError == EPOS2_BATTERY_OVERHEAT.rawValue {
                errMsg.append(NSLocalizedString("err_overheat", comment:""))
                errMsg.append(NSLocalizedString("err_battery", comment:""))
            }
            if status!.autoRecoverError == EPOS2_WRONG_PAPER.rawValue {
                errMsg.append(NSLocalizedString("err_wrong_paper", comment:""))
            }
        }
        if status!.batteryLevel == EPOS2_BATTERY_LEVEL_0.rawValue {
            errMsg.append(NSLocalizedString("err_battery_real_end", comment:""))
        }
        
        return errMsg as String
    }
    
}
