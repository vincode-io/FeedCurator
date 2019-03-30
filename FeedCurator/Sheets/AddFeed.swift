//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit

protocol AddFeedDelegate: class {
	func addFeedUserDidAdd(_ : String)
	func addFeedUserDidCancel()
}

class AddFeed: NSWindowController {

	@IBOutlet weak var urlTextField: NSTextField!
	
	@IBOutlet weak var progressIndicator: NSProgressIndicator!
	@IBOutlet weak var cancelButton: NSButton!
	@IBOutlet weak var addButton: NSButton!
	
	private weak var hostWindow: NSWindow?
	private weak var delegate: AddFeedDelegate?
	
	convenience init(delegate: AddFeedDelegate) {
		self.init(windowNibName: NSNib.Name("AddFeed"))
		self.delegate = delegate
	}
	
	func runSheetOnWindow(_ hostWindow: NSWindow) {
		
		self.hostWindow = hostWindow
		
		hostWindow.beginSheet(window!) { [unowned self] (returnCode: NSApplication.ModalResponse) -> Void in
			if returnCode == NSApplication.ModalResponse.OK {
				self.delegate?.addFeedUserDidAdd(self.urlTextField.stringValue)
			} else {
				self.delegate?.addFeedUserDidCancel()
			}
		}
		
	}
	
	// MARK: Actions
	
	@IBAction func cancel(_ sender: NSButton) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.cancel)
	}
	
	@IBAction func add(_ sender: NSButton) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.OK)
	}

	// MARK: NSTextFieldDelegate
	
	@objc func controlTextDidEndEditing(_ obj: Notification) {
		updateUI()
	}
	
	@objc func controlTextDidChange(_ obj: Notification) {
		updateUI()
	}

	private func updateUI() {
		addButton.isEnabled = urlTextField.stringValue.rs_stringMayBeURL()
	}
	
}
