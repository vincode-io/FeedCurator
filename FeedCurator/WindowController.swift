//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit

class WindowController: NSWindowController {

	static let clickHere = NSLocalizedString("Click Here to Add Title", comment: "Area to click to add title")

	private var updateTitle: UpdateTitle?
	
	@IBOutlet weak var titleButton: NSButton!
	
	override func windowDidLoad() {
        super.windowDidLoad()
    	self.shouldCascadeWindows = true
		NotificationCenter.default.addObserver(self, selector: #selector(opmlDocumentTitleDidChange(_:)), name: .OPMLDocumentTitleDidChange, object: nil)
    }

	@IBAction func titleButtonClicked(_ sender: NSButton) {
		updateTitle = UpdateTitle()
		updateTitle!.runSheetOnWindow(window!)
	}
	
	@objc func opmlDocumentTitleDidChange(_ note: Notification) {
		if let doc = self.document as? Document {
			if doc.opmlDocument.title == nil {
				titleButton.title = WindowController.clickHere
			} else {
				titleButton.title = doc.opmlDocument.title ?? ""
			}
		}
	}
	
}
