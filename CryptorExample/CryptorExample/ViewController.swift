//
//  ViewController.swift
//  CryptorExample
//
//  Created by White on 2017/8/4.
//  Copyright © 2017年 White. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        do {
            let destURL = try AESCryptor.aes_CBC_(withSourceFileURL: URL(fileURLWithPath: "/Users/white/Desktop/高级口译教程第四.pdf"),
                                iv: Data.init(bytes: [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]),
                                key: "11111111111111111111111111111111",
                                isEncrypt: true,
                                userService: .openSSL)
            print(destURL)
        } catch {
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

