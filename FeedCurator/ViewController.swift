//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSParser

class ViewController: NSViewController {

	@IBOutlet weak var titleTextField: NSTextField!
	
	var document: Document {
		return self.view.window?.windowController?.document as! Document
	}
	
	override func viewDidAppear() {
		
		super.viewDidAppear()
		
		guard let opmlDocument = document.opmlDocument else {
			return
		}
		
		titleTextField.stringValue = opmlDocument.title
		
	}

	override var representedObject: Any? {
		didSet {
			print("stored rep object")
		}
	}

}
