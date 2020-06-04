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
    
    func beginRequest(with context: NSExtensionContext) {
                
        precondition(context.inputItems.count == 1)
        guard let inputItem = context.inputItems[0] as? NSExtensionItem else {
            context.cancelRequest(withError: NSError(domain: "Expected an extension item", code: 0, userInfo: nil))
            preconditionFailure("Expected an extension item")
        }

        guard let inputAttachments = inputItem.attachments else {
            context.cancelRequest(withError:  NSError(domain: "Expected a valid array of attachments", code: 0, userInfo: nil))
            preconditionFailure("Expected a valid array of attachments")
        }
        if inputAttachments.isEmpty {
            context.cancelRequest(withError:  NSError(domain: "Expected at least one attachment", code: 0, userInfo: nil))
            preconditionFailure("Expected at least one attachment")
        }
//        var outputAttachments: [NSItemProvider] = inputAttachments
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
                    context.cancelRequest(withError:  NSError(domain: "Expected either a valid URL or an error.", code: 0, userInfo: nil))
                    preconditionFailure("Expected either a valid URL or an error.")
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            let outputItem = NSExtensionItem()
            outputItem.attachments = outputAttachments
            context.completeRequest(returningItems: [outputItem], completionHandler: nil)
        }
    }
    
    
    fileprivate func createUnsignedConfig(_ sourceUrl: URL, typeIdentifier: String, with context: NSExtensionContext) -> NSItemProvider {
        let itemProvider = NSItemProvider()
        itemProvider.registerFileRepresentation(
            forTypeIdentifier: typeIdentifier, fileOptions: [.openInPlace],
            visibility: .all, loadHandler: { completionHandler in
                
                
                guard let data = try? Data(contentsOf: sourceUrl) else {
                    context.cancelRequest(withError:  NSError(domain: "Data could not be read.", code: 0, userInfo: nil))
                    preconditionFailure("Data could not be read.")
                }

                guard let decoder = SwiftyCMSDecoder() else {
                    context.cancelRequest(withError:  NSError(domain: "Decoder could not be created.", code: 0, userInfo: nil))
                    preconditionFailure("Decoder could not be created.")
                    
                }
                
                decoder.updateMessage(data: data as NSData)
                decoder.finaliseMessage()
                
                var decodedData = decoder.data ?? data
                                
                if let xml = try? XMLDocument.init(data: decodedData, options: .nodePrettyPrint) {
                    decodedData = xml.xmlData(options:.nodePrettyPrint)
                }
                
                guard let fileUrl = try? self.fileUrl(for: sourceUrl) else {
                    context.cancelRequest(withError:  NSError(domain: "File url could not be found.", code: 0, userInfo: nil))
                    preconditionFailure("File url could not be found.")
                }
                do {
                    try decodedData.write(to: fileUrl)
                }
                catch {
                    context.cancelRequest(withError:  NSError(domain: "File could not be written.", code: 0, userInfo: nil))
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
}
