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
    
    @IBAction func openDocument(_ sender: Any) {
        ChooseDirectoryButton(sender)
    }
//    @IBAction func showHelp(_ sender: Any) {
//        
//    }
    
    @IBAction func UnsignButton(_ sender: Any) {
        guard let myUrl = path else {
            showAlert(SigningPalError.noUrlFound, for: self.view.window)
            return
        }
        guard let data = try? Data(contentsOf: myUrl) else {
            showAlert(SigningPalError.noDataFound, for: self.view.window)
            return
        }

        guard let decoder = SwiftyCMSDecoder() else {
            showAlert(SigningPalError.decoderNotCreated, for: self.view.window)
            return
            
        }
        
        decoder.updateMessage(data: data as NSData)
        decoder.finaliseMessage()
        
        var decodedData = decoder.data ?? data
                        
        if let xml = try? XMLDocument.init(data: decodedData, options: .nodePrettyPrint) {
            decodedData = xml.xmlData(options:.nodePrettyPrint)
        }
        do {
            try decodedData.write(to: myUrl)
            NSWorkspace.shared.activateFileViewerSelecting([myUrl])
        }
        catch {
            showAlert(SigningPalError.fileNotWritten(description: error.localizedDescription), for: self.view.window)
            print(error)
        }
    }
    
    @IBAction func SignButton(_ sender: Any) {
        guard let myUrl = path else {
            showAlert(SigningPalError.noUrlFound, for: self.view.window)
            return
        }
        guard let data = try? Data(contentsOf: myUrl) else {
            showAlert(SigningPalError.noDataFound, for: self.view.window)
            return
        }
        guard let signingId = ((SigningIdentityPopup.selectedItem?.representedObject) as! SecIdentity?) else {
            showAlert(SigningPalError.noSigningId, for: self.view.window)
            return
        }
        
        guard let encodedData = try? SecurityWrapper.sign(data: data, using: signingId ) else {
            showAlert(SigningPalError.signFailed, for: self.view.window)
            return
        }
        do {
            try encodedData.write(to: myUrl)
            NSWorkspace.shared.activateFileViewerSelecting([myUrl])
        }
        catch {
            showAlert(SigningPalError.fileNotWritten(description: error.localizedDescription), for: self.view.window)
        }
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

    fileprivate func showAlert(_ error: LocalizedError, for window: NSWindow?) {
        guard let myWindow = window else {
            return
        }
        let alertWindow: NSAlert = NSAlert()
        alertWindow.messageText = "Operation Failed"
        alertWindow.informativeText = error.errorDescription ?? "An unknown error occurred."
        alertWindow.addButton(withTitle: "OK")
        alertWindow.alertStyle = .warning
        alertWindow.beginSheetModal(for: myWindow)
    }
    
}

