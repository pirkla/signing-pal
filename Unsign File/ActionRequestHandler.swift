//
//  ActionRequestHandler.swift
//  Unsign Profile
//
//  Created by Andrew Pirkl on 6/1/20.
//  Copyright © 2020 Pirklator. All rights reserved.
//

import Foundation
import Cocoa

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
    
    var myContext: NSExtensionContext?
    func beginRequest(with context: NSExtensionContext) {
        myContext = context
        precondition(context.inputItems.count == 1)
        guard let inputItem = context.inputItems[0] as? NSExtensionItem else {
            preconditionFailure("Expected an extension item")
        }

        guard let inputAttachments = inputItem.attachments else {
            preconditionFailure("Expected a valid array of attachments")
        }
        if inputAttachments.isEmpty {
            preconditionFailure("Expected at least one attachment")
        }

        var outputAttachments: [NSItemProvider] = []

        let dispatchGroup = DispatchGroup()

        for attachment in inputAttachments {
            dispatchGroup.enter()
            
            attachment.loadInPlaceFileRepresentation(forTypeIdentifier: attachment.registeredTypeIdentifiers[0] ) {
                (url, inPlace, error) in
                
                if let sourceUrl = url {
                    let itemProvider = self.createUnsignedConfig(sourceUrl, typeIdentifier: attachment.registeredTypeIdentifiers[0], with: context)
                    outputAttachments.append(itemProvider)
                } else if let error = error {
                    print(error)
                } else {
                    preconditionFailure("Expected either a valid URL or an error.")
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            let outputItem = NSExtensionItem()
            outputItem.attachments = outputAttachments
            context.completeRequest(returningItems: [outputItem], completionHandler: self.RequestCompletion)
        }
    }
    
    
    fileprivate func createUnsignedConfig(_ sourceUrl: URL, typeIdentifier: String, with context: NSExtensionContext) -> NSItemProvider {
        let itemProvider = NSItemProvider()
        itemProvider.registerFileRepresentation(
            forTypeIdentifier: typeIdentifier, fileOptions: [.openInPlace],
            visibility: .all, loadHandler: { completionHandler in
                
                
                guard let data = try? Data(contentsOf: sourceUrl) else {
                    preconditionFailure("Data could not be read.")
                }

                guard let decoder = SwiftyCMSDecoder() else {
                    preconditionFailure("Decoder could not be created.")
                    
                }
                
                decoder.updateMessage(data: data as NSData)
                decoder.finaliseMessage()
                
                var decodedData = decoder.data ?? data
                                
                if let xml = try? XMLDocument.init(data: decodedData, options: .nodePrettyPrint) {
                    decodedData = xml.xmlData(options:.nodePrettyPrint)
                }
                
                guard let fileUrl = try? self.fileUrl(for: sourceUrl) else {
                    preconditionFailure("File url could not be found.")
                }
                do {
                    try decodedData.write(to: fileUrl)
                }
                catch {
                    preconditionFailure("File could not be written.")
                }
                completionHandler(fileUrl, false, nil)
                return nil
            }
        )
        return itemProvider
    }
    
    func fileUrl(for sourceUrl: URL)throws -> URL {
        let itemReplacementDirectory = try FileManager.default.url(
            for: .itemReplacementDirectory, in: .userDomainMask,
            appropriateFor: URL(fileURLWithPath: NSHomeDirectory()), create: true)
        let filename = "unsigned_" + sourceUrl.lastPathComponent
        return itemReplacementDirectory.appendingPathComponent(filename)
    }
    fileprivate func RequestCompletion(_ expired: Bool) {
        if expired {
            let cancelError = NSError(domain: "Task interrupted", code: 0, userInfo: nil)
            myContext?.cancelRequest(withError: cancelError)
        }
    }
    
}
