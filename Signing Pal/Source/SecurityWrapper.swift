//
//  SecurityWrapper.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2018 Jamf Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//


// Source: https://github.com/jamf/PPPC-Utility/edit/master/Source/SecurityWrapper.swift
// Modified by Andrew Pirkl

import Foundation

class SigningIdentity: NSObject {
    
    @objc dynamic var displayName: String
    public var title: String
    var reference: SecIdentity?

    init(name: String, reference: SecIdentity?) {
        displayName = name
        title = name
        super.init()
        self.reference = reference
    }
}


struct SecurityWrapper {
    
    static func execute(block: ()->(OSStatus)) throws {
        let status = block()
        if status != 0 {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }
    
    static func sign(data: Data, using identity: SecIdentity) throws -> Data {
        
        var outputData: CFData?
        var encoder: CMSEncoder?
        try execute { CMSEncoderCreate(&encoder) }
        try execute { CMSEncoderAddSigners(encoder!,identity) }
        try execute { CMSEncoderAddSignedAttributes(encoder!,.attrSmimeCapabilities) }
        try execute { CMSEncoderUpdateContent(encoder!,(data as NSData).bytes,data.count) }
        try execute { CMSEncoderCopyEncodedContent(encoder!,&outputData) }
        
        return outputData! as Data
    }
    
    static func loadSigningIdentities() throws -> [SigningIdentity] {
        
        let dict = [
            kSecClass as String         : kSecClassIdentity,
            kSecReturnRef as String     : true,
            kSecMatchLimit as String    : kSecMatchLimitAll
        ] as CFDictionary
        
        var result: AnyObject?
        try execute { SecItemCopyMatching(dict, &result) }
        
        guard let secIdentities = result as? [SecIdentity] else { return [] }
        print(secIdentities)
        
        return secIdentities.map({
            let name = try? getCertificateCommonName(for: $0)
            return SigningIdentity(name: name ?? "Unknown \($0.hashValue)", reference: $0)
        })
    }
    
    static func getCertificateCommonName(for identity: SecIdentity) throws -> String {
        var certificate: SecCertificate?
        var commonName: CFString?
        try execute { SecIdentityCopyCertificate(identity, &certificate) }
        try execute { SecCertificateCopyCommonName(certificate!, &commonName) }
        return commonName! as String
    }
}

