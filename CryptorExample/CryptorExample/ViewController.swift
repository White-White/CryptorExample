//
//  ViewController.swift
//  CryptorExample
//
//  Created by White on 2017/8/4.
//  Copyright © 2017年 White. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var fileReader: FileReader!
    
    var bufferData: Data = Data()
    var outputStream: OutputStream!
    var urlForDownloadedFile: URL = URL(fileURLWithPath: NSTemporaryDirectory() + "DownloadedFile")
    
    var fileSize_EncryptFile: Int!
    var size_HadDecrypted: Int = 0
    var ivDataForNextDataBlock: Data!
    
    //Fake data
//    let sourceFileURL = URL(fileURLWithPath: "/foo/foo/Japanese_Love_Action_Movie.avi")
    let sourceFileURL = URL(fileURLWithPath: "/Users/white/Desktop/test.pdf")

    let iv = Data.init(bytes: [11, 11, 11, 75, 11, 11, 11, 11, 49, 11, 11, 11, 74, 53, 11, 11])
    let key = "xxxxxxxxxxxxxxxx"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Create ouputStream for downloaded file
        try? FileManager.default.removeItem(at: urlForDownloadedFile)
        self.outputStream = OutputStream.init(url: urlForDownloadedFile, append: true)!
        self.outputStream.open()
        self.ivDataForNextDataBlock = iv
        
        do {
            //Encrypt target file and save.
            let destURL = try AESCryptor.aes_CBC_(withSourceFileURL: sourceFileURL,
                                                  iv: iv,
                                                  key: key,
                                                  isEncrypt: true,
                                                  usingService: .apple)
            
            let destURLTmp = URL(fileURLWithPath: NSTemporaryDirectory() + UUID.init().uuidString)
            try FileManager.default.moveItem(at: destURL, to: destURLTmp)
            
            //Save file size of the encrypted file. We need to know the size of the downloaded file beforehand.
            fileSize_EncryptFile = try (FileManager.default.attributesOfItem(atPath: destURLTmp.path)[.size] as! NSNumber).intValue
            
            //Simulate downloading from server
            fileReader = FileReader.init(withFileURL: destURLTmp, delegate: self)
            fileReader.begin()
        } catch {
            print(error)
        }
    }

    /// Pretend to receive data from server.
    ///
    /// - Parameter data: data received
    func didReceiveDataFromServer(_ data: Data) {
        print("Did receive: \(data.count)")
        //
        self.bufferData += data
        //
        let blockSizeToEncrypt = 1024 * 1024 // Decryption threshhold
        
        guard self.bufferData.count >= blockSizeToEncrypt else {
            //Decrypt only if bufferData exceeds 1MB
            return
        }
        
        let bytesLeftForNextTime = self.bufferData.count % blockSizeToEncrypt
        
        let dataToDecrypt = self.bufferData.subdata(in: Range(uncheckedBounds: (self.bufferData.startIndex, self.bufferData.endIndex - bytesLeftForNextTime)))
        
        let dataToDecryptNextTime = self.bufferData.subdata(in: Range(uncheckedBounds: (self.bufferData.endIndex - bytesLeftForNextTime, self.bufferData.endIndex)))
        
        var ivDataNext: NSData?
        
        let dataDecrypted = AESCryptor.aes_CBC_OpenSSL(with: dataToDecrypt,
                                                       iv: self.ivDataForNextDataBlock,
                                                       ivOut: &ivDataNext,
                                                       key: self.key,
                                                       isEncrypt: false,
                                                       needsUnpadding: false)
        
        _ = dataDecrypted.withUnsafeBytes {
            self.outputStream.write($0, maxLength: dataDecrypted.count)
        }
        
        //Save IV
        if let ivDataNext = ivDataNext {
            self.ivDataForNextDataBlock = ivDataNext as Data
        }
        
        //已解密的data数量增加
        self.size_HadDecrypted += dataToDecrypt.count
        self.bufferData = dataToDecryptNextTime
        
        print("Had decrypted data: \(self.size_HadDecrypted), progress: \(CGFloat(self.size_HadDecrypted)/CGFloat(self.fileSize_EncryptFile))%")
    }
    
    //Had received all data.
    func didReceiveAllDataFromServer() {
        
        guard self.bufferData.count != 0 else {
            self.outputStream.close()
            return
        }
        
        //Write the last part of the file
        let dataDecrypted = AESCryptor.aes_CBC_OpenSSL(with: self.bufferData,
                                                       iv: self.ivDataForNextDataBlock,
                                                       ivOut: nil,
                                                       key: self.key,
                                                       isEncrypt: false,
                                                       needsUnpadding: true)
        
        //Write decrypted data to file
        _ = dataDecrypted.withUnsafeBytes {
            self.outputStream.write($0, maxLength: dataDecrypted.count)
        }
        
        
        self.size_HadDecrypted += self.bufferData.count
        self.bufferData = Data()
        self.outputStream.close()
        
        print("Did download file to \(self.urlForDownloadedFile.path). \n The file had already been decrypted. ^_^")
    }
}

extension ViewController: FileReaderDelegate {
    func fileReaderFinishedReading(_ reader: FileReader) {
        self.didReceiveAllDataFromServer()
    }
    
    func fileReader(_ reader: FileReader, didReadData data: Data) {
        self.didReceiveDataFromServer(data)
    }
}

