//
//  FileReader_RandomLength.swift
//  CryptorExample
//
//  Created by White on 2017/8/5.
//  Copyright © 2017年 White. All rights reserved.
//

import Foundation

protocol FileReaderDelegate: class {
    func fileReader(_ reader: FileReader, didReadData data: Data)
    func fileReaderFinishedReading(_ reader: FileReader)
}

final class FileReader {
    
    private let inputStream: InputStream
    private let maxLengthReading: UInt32
    private var timer: Timer?
    private weak var delegate: FileReaderDelegate?
    
    init(withFileURL fileURL: URL, delegate:FileReaderDelegate, maxLengthReading: UInt32 = 1024 * 300) {
        self.delegate = delegate
        self.maxLengthReading = maxLengthReading
        self.inputStream = InputStream.init(url: fileURL)!
        self.inputStream.open()
    }
    
    func begin() {
        timer?.invalidate()
        timer = Timer.init(timeInterval: 0.1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
    }

    
    @objc private func timerFired() {
        if self.inputStream.hasBytesAvailable {
            let bufferLen = Int(arc4random()%maxLengthReading)
            var buffer = [UInt8].init(repeating: 0, count: bufferLen)
            let lenRead =  self.inputStream.read(&buffer, maxLength: bufferLen)
            
            if lenRead == 0 {
                return
            }
            
            let data = Data.init(bytes: buffer, count: lenRead)
            self.delegate?.fileReader(self, didReadData: data)
        } else {
            self.finish()
        }
    }
    
    private func finish() {
        timer?.invalidate()
        timer = nil
        self.delegate?.fileReaderFinishedReading(self)
    }
}
