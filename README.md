# CryptorExample

This repo is a demo showing how to decrypt a file while downloading it from server.



Specially, the demo uses AES-CBC (PKCS#7 for padding) as it's only way of encryption & decryption.


As the encryption method mentioned above is the most used one, it's also a guide to implemention of AES-related function on iOS, in both ways of OpenSSL and Apple.



这个repo展示了下载时解密的逻辑。



该repo仅使用AES-CBC (PKCS#7 for padding)作为其加密/解密方式


因为AES-CBC (PKCS#7 for padding)是最常用的加解密方式，这个repo也是一个在iOS上实现AES加解密的教程。OpenSSL和Apple的方式均包含在其中。




##Attention:
Before testing, you need to update the settings in this project to make correct reference to your OpenSSL libraries and header files. A star is appreciated is this repo is helpful to you~~


##注意:
使用前，你需要自己更新项目中的设置，使其可以正确引用你的OpenSSL库。最后，如果此repo对你有帮助，star一下吧~~