//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSParser

class Document: NSDocument {

	var opmlDocument: OPMLEntry?

	override class var autosavesInPlace: Bool {
		return true
	}

	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
		let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
		self.addWindowController(windowController)
	}

	override func data(ofType typeName: String) throws -> Data {
		
		let windowController = windowControllers[0] as! WindowController
		let viewController = windowController.contentViewController as! ViewController
		let entry = viewController.opmlDocument!

		if windowController.titleButton.title == WindowController.clickHere {
			entry.title = ""
		} else {
			entry.title = windowController.titleButton.title
		}
		
		let xml = entry.makeXML(indentLevel: 0)
		let xmlData = xml.data(using: .utf8)
		
		if xmlData == nil || xmlData!.count < 1 {
			throw NSLocalizedString("Error generating OPML file", comment: "Error generating OPML file")
		}
		
		return xmlData!
		
	}

	override func read(from data: Data, ofType typeName: String) throws {
		let parserData = ParserData(url: "", data: data)
		let rsDoc = try! RSOPMLParser.parseOPML(with: parserData)
		opmlDocument = rsDoc.translateToOPMLEntry()
	}

}
