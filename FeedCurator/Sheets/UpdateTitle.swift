//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit

class UpdateTitle: NSWindowController {

	@IBOutlet weak var titleTextField: NSTextField!
	
	private weak var hostWindow: NSWindow?
	
	convenience init() {
		self.init(windowNibName: NSNib.Name("UpdateTitle"))
	}
	
	override func windowDidLoad() {
		
		guard let windowController = hostWindow?.windowController as? WindowController else {
			assertionFailure()
			return
		}
		
		if windowController.titleButton.title != WindowController.clickHere {
			titleTextField.stringValue = windowController.titleButton.title
		}
		
	}
	
	func runSheetOnWindow(_ hostWindow: NSWindow) {
		
		self.hostWindow = hostWindow
		
		hostWindow.beginSheet(window!) { (returnCode: NSApplication.ModalResponse) -> Void in
			if returnCode == NSApplication.ModalResponse.OK {
				self.updateTitle()
			}
		}
		
	}

	private func updateTitle() {
		
		// Update the model
		guard let document = hostWindow?.windowController?.document as? Document else {
			assertionFailure()
			return
		}
		
		if titleTextField.stringValue.isEmpty {
			document.updateTitle(entry: document.opmlDocument, title: nil)
		} else {
			document.updateTitle(entry: document.opmlDocument, title: titleTextField.stringValue)
		}
		
	}

	@IBAction func cancel(_ sender: NSButton) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.cancel)
	}
	
	@IBAction func update(_ sender: NSButton) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.OK)
	}
	
}
