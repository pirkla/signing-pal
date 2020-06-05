//
//  ActionViewController.swift
//  Sign Profile
//
//  Created by Andrew Pirkl on 6/1/20.
//  Copyright © 2020 Pirklator. All rights reserved.
//

import Cocoa

class ActionViewController: NSViewController {

    @IBOutlet var myTextView: NSTextView!
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("ActionViewController")
    }
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    @IBOutlet weak var SigningIdPopUp: NSPopUpButton!
    
    override func loadView() {
        super.loadView()
        let signingIdentities = (try? SecurityWrapper.loadSigningIdentities()) ?? []
        let popUpItems = signingIdentities.map {
            (id) -> NSMenuItem in
            let menuItem = NSMenuItem()
            menuItem.title = id.displayName
            menuItem.representedObject = id.reference
            return menuItem
        }
        let someMenu = NSMenu()
        someMenu.items = popUpItems
        SigningIdPopUp.menu = someMenu
    }

    @IBAction func send(_ sender: AnyObject?) {
        guard let context = self.extensionContext
        else { return }
        
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
        // This extension is replacing the input attachments so start with an empty array.
        var outputAttachments: [NSItemProvider] = []
        let dispatchGroup = DispatchGroup()
        
        for attachment in inputAttachments {
            dispatchGroup.enter()
            
            attachment.loadInPlaceFileRepresentation(forTypeIdentifier: attachment.registeredTypeIdentifiers[0] ) {
                (url, inPlace, error) in
                
                if let sourceUrl = url {
                    let itemProvider = self.createSignedFile(sourceUrl, typeIdentifier: attachment.registeredTypeIdentifiers[0], with: context)
                    outputAttachments.append(itemProvider)
                } else if let error = error {
                    print(error)
                } else {
                    preconditionFailure("Expected either a valid URL or an error.")
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) { [unowned self] in
            guard let context = self.extensionContext
                else { return }
            let outputItem = NSExtensionItem()
            outputItem.attachments = outputAttachments
            context.completeRequest(returningItems: [outputItem], completionHandler: self.RequestCompletion)
            
        }
    }
    
    func RequestCompletion(_ expired: Bool) {
        if expired {
            let cancelError = NSError(domain: "Task interrupted", code: 0, userInfo: nil)
            self.extensionContext?.cancelRequest(withError: cancelError)
        }
    }
    
    
    @IBAction func cancel(_ sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext?.cancelRequest(withError: cancelError)
    }
    
    func fileUrl(for sourceUrl: URL) -> URL {
        do {
            let itemReplacementDirectory = try FileManager.default.url(
                for: .itemReplacementDirectory, in: .userDomainMask,
                appropriateFor: URL(fileURLWithPath: NSHomeDirectory()), create: true)
            let filename = "signed_" + sourceUrl.lastPathComponent
            return itemReplacementDirectory.appendingPathComponent(filename)
        } catch {
            print(error)
            preconditionFailure()
        }
    }
    
    fileprivate func createSignedFile(_ sourceUrl: URL, typeIdentifier: String, with context: NSExtensionContext ) -> NSItemProvider {
        let itemProvider = NSItemProvider()
        itemProvider.registerFileRepresentation(
            forTypeIdentifier: typeIdentifier, fileOptions: [.openInPlace],
            visibility: .all, loadHandler: {
                [weak self]
                completionHandler in
                guard let data = try? Data(contentsOf: sourceUrl) else {
                    preconditionFailure("Data could not be read.")
                }
                guard let signingId = ((self?.SigningIdPopUp.selectedItem?.representedObject) as! SecIdentity?) else {
                    preconditionFailure("Security Identity could not be found")
                }
                
                guard let encodedData = try? SecurityWrapper.sign(data: data, using: signingId ) else {
                    preconditionFailure("Could not sign file")
                }
                
                guard let fileUrl = self?.fileUrl(for: sourceUrl) else {
                    preconditionFailure("Could not find the file url")
                }
                do {
                    try encodedData.write(to: fileUrl)
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
}
