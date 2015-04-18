//
//  MWLogger.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 01/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import Foundation

private let SHOULD_SAVE_LOG_TO_FILE = true
private let SHOULD_INCLUDE_TIME     = true
private let logQueue = dispatch_queue_create("Log Queue", DISPATCH_QUEUE_SERIAL)

// Enables a call like MWLog() to simply print a new line
func MWLog(filePath: String = __FILE__, functionName: String = __FUNCTION__, lineNumber: Int = __LINE__) {
    MWLog("", filePath: filePath, functionName: functionName, lineNumber: lineNumber)
}

func MWLog(message: String, filePath: String = __FILE__, functionName: String = __FUNCTION__, lineNumber: Int = __LINE__) {
//    dispatch_async(logQueue, { () -> Void in
        var printString = ""
        
        if SHOULD_INCLUDE_TIME {
            let date = NSDate()
            
            var milliseconds = date.timeIntervalSince1970 as Double
            milliseconds -= floor(milliseconds)
            let tensOfASecond = Int(milliseconds * 10000)
            
            // Adding extra "0"s to the milliseconds if necessary
            var tensOfASecondString = "\(tensOfASecond)"
            while count(tensOfASecondString) < 4 {
                tensOfASecondString = "0" + tensOfASecondString
            }
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
            let dateString = dateFormatter.stringFromDate(date)
            
            printString += "\(dateString).\(tensOfASecondString)   "
        }
        
        var fileName = filePath.lastPathComponent
        var functionNameToPrint = functionName
        
        if count(fileName) > 25 {
            fileName = ((fileName as NSString).substringToIndex(22) as String) + "..."
        }
        
        if count(functionName) > 45 {
            functionNameToPrint = ((functionName as NSString).substringToIndex(42) as String) + "..."
        }
        
        printString += String(format: "l:%-5d %-25s  %-45s  %@",
            lineNumber,
            COpaquePointer(fileName.lastPathComponent.cStringUsingEncoding(NSUTF8StringEncoding)!),
            COpaquePointer(functionNameToPrint.cStringUsingEncoding(NSUTF8StringEncoding)!),
            message)
        
        println(printString)
//    });
}
