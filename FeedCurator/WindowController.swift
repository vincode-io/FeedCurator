//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit

class WindowController: NSWindowController {

	static let clickHere = NSLocalizedString("Click Here to Add Title", comment: "Area to click to add title")

	private var updateTitle: UpdateTitle?
	
	@IBOutlet weak var titleButton: NSButton!
	
	override func windowDidLoad() {
        super.windowDidLoad()
    	self.shouldCascadeWindows = true
    }

	@IBAction func titleButtonClicked(_ sender: NSButton) {
		updateTitle = UpdateTitle()
		updateTitle!.runSheetOnWindow(window!)
	}
	
}
