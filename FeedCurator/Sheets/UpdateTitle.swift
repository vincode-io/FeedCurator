//Copyright © 2019 Vincode, Inc. All rights reserved.

import Cocoa

class UpdateTitle: NSWindowController {

	@IBOutlet weak var titleTextField: NSTextField!
	
	private var hostWindow: NSWindow?
	
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
		
		guard let windowController = hostWindow?.windowController as? WindowController else {
			assertionFailure()
			return
		}
		
		windowController.titleButton.title = titleTextField.stringValue
		
	}

	@IBAction func update(_ sender: NSButton) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.OK)
	}
	
}
