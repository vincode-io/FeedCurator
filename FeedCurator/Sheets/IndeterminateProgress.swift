//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit

class IndeterminateProgress: NSWindowController {

	@IBOutlet weak var messageLabel: NSTextField!
	@IBOutlet weak var progressIndicator: NSProgressIndicator!
	
	private var message: String!
	
	convenience init(message: String) {
		self.init(windowNibName: NSNib.Name("IndeterminateProgress"))
		self.message = message
	}
	
    override func windowDidLoad() {
        super.windowDidLoad()
		messageLabel.stringValue = message
		progressIndicator.startAnimation(self)
    }
    
}
