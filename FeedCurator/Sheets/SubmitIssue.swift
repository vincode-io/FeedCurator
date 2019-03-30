//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit

protocol SubmitIssueDelegate: class {
	func submitIssueUserDidSubmit(_ : String)
	func submitIssueUserDidCancel()
}

class SubmitIssue: NSWindowController {
	
	@IBOutlet var bodyTextView: NSTextView!
	
	private weak var hostWindow: NSWindow?
	private weak var delegate: SubmitIssueDelegate?
	
	convenience init(delegate: SubmitIssueDelegate) {
		self.init(windowNibName: NSNib.Name("SubmitIssue"))
		self.delegate = delegate
	}
	
	func runSheetOnWindow(_ hostWindow: NSWindow) {
		
		self.hostWindow = hostWindow
		
		hostWindow.beginSheet(window!) { [unowned self] (returnCode: NSApplication.ModalResponse) -> Void in
			if returnCode == NSApplication.ModalResponse.OK {
				self.delegate?.submitIssueUserDidSubmit(self.bodyTextView.string)
			} else {
				self.delegate?.submitIssueUserDidCancel()
			}
		}
		
	}
	
	// MARK: Actions
	
	@IBAction func cancel(_ sender: NSButton) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.cancel)
	}
	
	@IBAction func submit(_ sender: NSButton) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.OK)
	}
	
	// MARK: NSTextFieldDelegate
	
}
