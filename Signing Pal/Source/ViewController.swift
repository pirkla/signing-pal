//
//  ViewController.swift
//  Signing Pal
//
//  Created by Andrew Pirkl on 6/3/20.
//  Copyright © 2020 Pirklator. All rights reserved.
//

import Cocoa
class ViewController: NSViewController {

    var path: URL?
    @IBOutlet weak var PathLabel: NSTextField!
    
    @IBOutlet weak var SigningIdentityPopup: NSPopUpButton!
    
    @IBAction func UnsignButton(_ sender: Any) {
        guard let myUrl = path else {
            return
        }
        guard let data = try? Data(contentsOf: myUrl) else {
            return
        }

        guard let decoder = SwiftyCMSDecoder() else {
            return
            
        }
        
        decoder.updateMessage(data: data as NSData)
        decoder.finaliseMessage()
        
        var decodedData = decoder.data ?? data
                        
        if let xml = try? XMLDocument.init(data: decodedData, options: .nodePrettyPrint) {
            decodedData = xml.xmlData(options:.nodePrettyPrint)
        }
        
//        guard let fileUrl = try? self.fileUrl(for: myUrl) else {
//            preconditionFailure("File url could not be found.")
//        }
        do {
            try decodedData.write(to: myUrl)
            NSWorkspace.shared.activateFileViewerSelecting([myUrl])
        }
        catch {
            print("Error: \(error)")
            preconditionFailure("File could not be written.")
        }
    }
    
    @IBAction func SignButton(_ sender: Any) {
        guard let myUrl = path else {
            return
        }
        guard let data = try? Data(contentsOf: myUrl) else {
            preconditionFailure("Data could not be read.")
        }
        guard let signingId = ((SigningIdentityPopup.selectedItem?.representedObject) as! SecIdentity?) else {
            preconditionFailure("Security Identity could not be found")
        }
        
        guard let encodedData = try? SecurityWrapper.sign(data: data, using: signingId ) else {
            preconditionFailure("Could not sign file")
        }
        do {
            try encodedData.write(to: myUrl)
            NSWorkspace.shared.activateFileViewerSelecting([myUrl])
        }
        catch {
            preconditionFailure("File could not be written.")
        }
//        print(SigningIdentityPopup.selectedItem?.representedObject)
    }
    
    @IBAction func SysPrefButton(_ sender: Any) {
        let myUrl = URL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane")
        NSWorkspace.shared.open(myUrl)
    }
    
    @IBAction func ChooseDirectoryButton(_ sender: Any) {
        let dialog = NSOpenPanel();

        dialog.title                   = "Choose a file";
        dialog.canChooseDirectories = false;

        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            path = dialog.url
            PathLabel.stringValue = dialog.url?.path ?? ""
        }
            
        else {
            if let window = self.view.window {
                showAlert(SigningPalError.noUrlFound, for: window)
            }
            return
        }
    }
    
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
        SigningIdentityPopup.menu = someMenu
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    fileprivate func showAlert(_ error: LocalizedError, for window: NSWindow) {
        let alertWindow: NSAlert = NSAlert()
        alertWindow.messageText = "Operation Failed"
        alertWindow.informativeText = error.errorDescription ?? "An unknown error occurred."
        alertWindow.addButton(withTitle: "OK")
        alertWindow.alertStyle = .warning
        alertWindow.beginSheetModal(for: window)
    }
    
//    func fileUrl(for sourceUrl: URL)throws -> URL {
//        let itemReplacementDirectory = try FileManager.default.url(
//            for: .itemReplacementDirectory, in: .userDomainMask,
//            appropriateFor: URL(fileURLWithPath: NSHomeDirectory()), create: true)
//        let filename = "unsigned_" + sourceUrl.lastPathComponent
//        return itemReplacementDirectory.appendingPathComponent(filename)
//    }
}

