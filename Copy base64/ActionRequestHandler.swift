//
//  ActionRequestHandler.swift
//  Copy base64
//
//  Created by Andrew Pirkl on 8/5/20.
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

        let dispatchGroup = DispatchGroup()

        for attachment in inputAttachments {
            dispatchGroup.enter()

            attachment.loadInPlaceFileRepresentation(forTypeIdentifier: attachment.registeredTypeIdentifiers[0] ) {
                (url, inPlace, error) in
                
                if let error = error {
                    print(error)
                    preconditionFailure(error.localizedDescription)
                }
                
                guard let url = url else {
                    preconditionFailure("No valid url could be found")
                }
                
                guard let data = try? Data(contentsOf: url) else {
                    preconditionFailure("Data could not be read.")
                }
                let encodedString = data.base64EncodedString()
                let pasteBoard = NSPasteboard.general
                pasteBoard.clearContents()
                pasteBoard.setString(encodedString, forType: .string)
                
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            context.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
