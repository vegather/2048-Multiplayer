//
//  MOONLogger.swift
//  MOON
//
//  Created by Vegard Solheim Theriault on 01/04/15.
//  Copyright (c) 2015 MOON Wearables. All rights reserved.
//

//		.___  ___.   ______     ______   .__   __.
//		|   \/   |  /  __  \   /  __  \  |  \ |  |
//		|  \  /  | |  |  |  | |  |  |  | |   \|  |
//		|  |\/|  | |  |  |  | |  |  |  | |  . `  |
//		|  |  |  | |  `--'  | |  `--'  | |  |\   |
//		|__|  |__|  \______/   \______/  |__| \__|
//		 ___  _____   _____ _    ___  ___ ___ ___
//		|   \| __\ \ / / __| |  / _ \| _ \ __| _ \
//		| |) | _| \ V /| _|| |_| (_) |  _/ _||   /
//		|___/|___| \_/ |___|____\___/|_| |___|_|_\


import Foundation

private struct Constants {
    static let LogFileName       = "MOONLog.txt"
    static let ShouldIncludeTime = true
    static let FileNameWidth     = 25
    static let MethodNameWidth   = 40
}

private let logQueue = dispatch_queue_create("com.moonLogger.logQueue", DISPATCH_QUEUE_SERIAL)
private var logFile: UnsafeMutablePointer<FILE> = nil
private let IsDebugging = false



/**
 A log statement that lets you easily see which file, function, and line number a log statement came from.
 
 - Parameter items: An optional list of items you want printed. Every item will be converted to a `String` like this: `"\(item)"`.
 - Parameter separator: An optional separator string that will be inserted between each of the `items`.
 - Parameter stream: The stream to write the `items` to. Primarily used for testing. Defaults to stdout, which is the same place the normal `print(...)` call prints to.

 The `filePath`, `functionName`, and `lineNumber` arguments should be left as they are. They default to `#file`, `#function`, and `#line` respectively, which is how `MOONLog(...)` is able to do its magic.
 */
func MOONLog(
    items       : Any...,
    separator   : String = " ",
    filePath    : String = #file,
    functionName: String = #function,
    lineNumber  : Int    = #line,
    stream      : UnsafeMutablePointer<FILE> = stdout)
{
    if IsDebugging {
        dispatch_async(logQueue) {
            
            var printString = ""
            
            // Going with this ANSI C solution here because it's about 1.5x
            // faster than the NSDateFormatter alternative.
            if Constants.ShouldIncludeTime {
                let bufferSize = 32
                var buffer = [Int8](count: bufferSize, repeatedValue: 0)
                var timeValue = time(nil)
                let tmValue = localtime(&timeValue)
                
                strftime(&buffer, bufferSize, "%Y-%m-%d %H:%M:%S", tmValue)
                if let dateFormat = String(CString: buffer, encoding: NSUTF8StringEncoding) {
                    var timeForMilliseconds = timeval()
                    gettimeofday(&timeForMilliseconds, nil)
                    let timeSince1970 = NSDate().timeIntervalSince1970
                    let seconds = floor(timeSince1970)
                    let thousands = UInt(floor((timeSince1970 - seconds) * 1000.0))
                    let milliseconds = String(format: "%03u", arguments: [thousands])
                    printString = dateFormat + "." + milliseconds + "    "
                }
            }
            
            // Limit the fileName to 25 characters
            var fileName = (filePath as NSString).lastPathComponent
            if fileName.characters.count > Constants.FileNameWidth {
                fileName = fileName.substringToIndex(fileName.startIndex.advancedBy(Constants.FileNameWidth - 3)) + "..."
            }
            
            // Limit the functionName to 40 characters
            var functionNameToPrint = functionName
            if functionName.characters.count > Constants.MethodNameWidth {
                functionNameToPrint = functionName.substringToIndex(functionName.startIndex.advancedBy(Constants.MethodNameWidth - 3)) + "..."
            }
            
            // Construct the message to be printed
            var message = ""
            for (i, item) in items.enumerate() {
                message += "\(item)"
                if i < items.count-1 { message += separator }
            }

            printString += String(format: "l:%-5d %-\(Constants.FileNameWidth)s  %-\(Constants.MethodNameWidth)s  %@",
                lineNumber,
                COpaquePointer(fileName.cStringUsingEncoding(NSUTF8StringEncoding)!),
                COpaquePointer(functionNameToPrint.cStringUsingEncoding(NSUTF8StringEncoding)!),
                message)
            
            // Write to the specified stream (stdout by default)
            MOONLogger.writeMessage(printString, toStream: stream)
            
            if logFile != nil {
                // Write to the logFile
                MOONLogger.writeMessage(printString, toStream: logFile)
            }
        }
    }
}


public struct MOONLogger {
    
    /**
     Sets up the log file. If there already exists a log file, future `MOONLog(...)` calls will simply append to that file. If no file exists, a new one is created.
     
     This should be called as soon as you want to store `MOONLog(...)` calls in a log file. Typically you would call this at the beginning of `application(_: didFinishLaunchingWithOptions:)` in your `AppDelegate`.
     
     - seealso: `application(_: didFinishLaunchingWithOptions:)`
     */
    public static func startWritingToLogFile() {
        if logFile == nil { logFile = fopen(getLogFilePath(), "a+") }
    }
    
    
    /**
     After calling this, all calls to `MOONLog(...)` will not be written to the log file. If you want your `MOONLog...` calls to be written to the log file again, simply call `MOONLogger.startWritingToLogFile()`. This method writes everything written to the file thus far to be saved (by flushing the file), and then closes the file. There's no need to call this when the app is closing (in `applicationWillTerminate()`) as the file will be saved and closed automatically be the system.
     
     - seealso: `MOONLogger.startWritingToLogFile()`
     */
    public static func stopWritingToLogFile() {
        if logFile != nil {
            dispatch_async(logQueue) {
                flockfile(logFile)
                fclose(logFile)
                funlockfile(logFile)
                logFile = nil
            }
        }
    }
    
    
    /**
     If the file is open (from calling `startWritingToLogFile()`), this will wait (asynchronously in the background) until every pending write to the file is completed before clearing the file. It will immediately regardless of the state of the log file. 
     
     After calling this, the `NSData` returned from `MOONLogger.getLogFile(...)` might return `nil`, depending on if the log file is open or closed.
     
     - seealso: `MOONLogger.getLogFile(...)`
     */
    public static func clearLogFile() {
        // If the file is open, use freopen to close it and the reopen it with a new mode (w+)
        if logFile != nil {
            // Doing it asynchronously on the logQueue to make sure all the MOONLog(...)
            // statements that were done before this call is finished before clearing it.
            // That way you won't get any leftover junk in the file.
            dispatch_async(logQueue) {
                // The file might have been closed while waiting
                if logFile != nil {
                    // Open the file for reading & writing, and destroy any content that's in there.
                    logFile = freopen(getLogFilePath(), "w+", logFile)
                } else {
                    remove(getLogFilePath())
                }
            }
        }
        // If the file is closed, just delete the file at the file path. It will get recreated in 
        // getLogFile(...) or through startWritingToLogFile() at some later point
        else {
            remove(getLogFilePath())
        }
    }
    
    
    /**
     If you have initialized a log file (see `startWritingToLogFile()`), this will wait until all pending `MOONLog(...)` calls are written to the file, and then returns the `logFile` data in the `completionHandler` on the main queue. If you have not initialized the log file, or closed it (see `stopWritingToLogFile()`), the log file will get returned immediately in the completion handler on the main thread.
     
     - seealso: `startWritingToLogFile()`
     
     `stopWritingToLogFile()`
     
     - Parameter completionHandler: A completion handler that returns both the `logData` as well as the `mimeType` of the log file (currently `text/txt`). If there were some problem fetching the `logFile`, it will be nil.
     */
    public static func getLogFile(completionHandler: (logFile: NSData?, mimeType: String) -> ()) {
        dispatch_async(logQueue) {
            if logFile == nil {
                let tempLogFile = fopen(getLogFilePath(), "r")
                if tempLogFile == nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        completionHandler(logFile: nil, mimeType: "")
                    }
                    return
                }
                let data = fetchTheFile(tempLogFile)
                fclose(tempLogFile)
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(logFile: data, mimeType: "text/plain")
                }
            } else {
                fflush(logFile)
                let data = fetchTheFile(logFile)
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(logFile: data, mimeType: "text/plain")
                }
            }
        }
    }
    
    
    /// *Synchronously* gets the data that's in the logFile, and returns it as an NSData.
    private static func fetchTheFile(file: UnsafeMutablePointer<FILE>) -> NSData {
        flockfile(file)
        rewind(file)
        
        let data = NSMutableData()
        var c = fgetc(file)
        while c != EOF {
            data.appendBytes(&c, length: sizeof(Int8))
            c = fgetc(file)
        }
        funlockfile(file)
        
        return data
    }
    
    /// Do the printing using `putc()` nested in `flockfile()` and `funlockfile()` to
    /// ensure that `MOONLog()` and regular `print()` statements doesn't get interleaved.
    private static func writeMessage(message: String, toStream outStream: UnsafeMutablePointer<FILE>) {
        flockfile(outStream)
        for char in (message + "\n").utf8 {
            putc(Int32(char), outStream)
        }
        funlockfile(outStream)
    }
    
    // Returns the path to a file named by the constant LOG_FILE_NAME in the users documents directory.
    private static func getLogFilePath() -> String {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(
            NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.UserDomainMask,
            true)[0]
        
        return (documentsDirectory as NSString).stringByAppendingPathComponent(Constants.LogFileName)
    }
}

