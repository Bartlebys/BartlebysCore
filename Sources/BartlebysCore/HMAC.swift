//
//  HMAC.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 10/09/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation
import CommonCrypto

enum HMACAlgorithms {

    case md5, sha1, sha224, sha256, sha384, sha512

    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .md5:
            result = CC_MD5_DIGEST_LENGTH
        case .sha1:
            result = CC_SHA1_DIGEST_LENGTH
        case .sha224:
            result = CC_SHA224_DIGEST_LENGTH
        case .sha256:
            result = CC_SHA256_DIGEST_LENGTH
        case .sha384:
            result = CC_SHA384_DIGEST_LENGTH
        case .sha512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}


public struct HMAC {


    /// Return the digest
    ///
    /// - Parameters:
    ///   - string: the string to digest
    ///   - algo: the algorythm to use
    /// - Returns: the digest string
    static func digestString(_ string: String, algo: HMACAlgorithms) -> String {
        if let stringData = string.data(using: String.Encoding.utf8, allowLossyConversion: false){
            let digest = HMAC._digest(stringData, algo: algo)
            return HMAC._hexStringFromData(digest)
        }
        return ""
    }

    /// Return the digest
    ///
    /// - Parameters:
    ///   - string: the Data to digest
    ///   - algo: the algorythm to use
    /// - Returns: the digest string
    static func digestData(_ data: Data, algo: HMACAlgorithms) -> String {
        let digest = HMAC._digest(data, algo: algo)
        return HMAC._hexStringFromData(digest)
    }


    /// Returns the hash Data
    /// Note that hash data are not always UTF8 valid string we need to _hexStringFromData to return a valid String
    /// - Parameters:
    ///   - data: the data to digest
    ///   - algo: the algorythm to use
    /// - Returns: the digest data
    private static func _digest(_ data : Data, algo: HMACAlgorithms) -> Data {
        let digestLength = algo.digestLength()
        var hash = [UInt8](repeating: 0,count: digestLength)
        switch algo {
        case .md5:
            data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) ->Void in
                CC_MD5(bytes, UInt32(data.count), &hash)
            })
            break
        case .sha1:
            data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) ->Void in
                CC_SHA1(bytes, UInt32(data.count), &hash)
            })
            break
        case .sha224:
            data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) ->Void in
                CC_SHA224(bytes, UInt32(data.count), &hash)
            })
            break
        case .sha256:
            data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) ->Void in
                CC_SHA256(bytes, UInt32(data.count), &hash)
            })
            break
        case .sha384:
            data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) ->Void in
                CC_SHA384(bytes, UInt32(data.count), &hash)
            })
            break
        case .sha512:
            data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) ->Void in
                CC_SHA512(bytes, UInt32(data.count), &hash)
            })
            break
        }
        return Data(bytes: hash, count: digestLength)
    }



    /// Return a valid UTF8 string.
    ///
    /// - Parameter data: the Data
    /// - Returns: the String
    private static func _hexStringFromData(_ data: Data) -> String {
        var bytes = [UInt8](repeating: 0,count:data.count)
        data.copyBytes(to:&bytes, count: data.count)
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        return hexString
    }

}


public extension String {

    var md5: String {
        return HMAC.digestString(self, algo: HMACAlgorithms.md5)
    }

    var sha1: String {
        return HMAC.digestString(self, algo: HMACAlgorithms.sha1)
    }

    var sha224: String {
        return HMAC.digestString(self, algo: HMACAlgorithms.sha224)
    }

    var sha256: String {
        return HMAC.digestString(self, algo: HMACAlgorithms.sha256)
    }

    var sha384: String {
        return HMAC.digestString(self, algo: HMACAlgorithms.sha384)
    }

    var sha512: String {
        return HMAC.digestString(self, algo: HMACAlgorithms.sha512)
    }

}
