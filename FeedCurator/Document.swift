//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSParser

class Document: NSDocument {

	var viewController: ViewController {
		return windowControllers[0].contentViewController as! ViewController
	}
	
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
		let entry = viewController.opmlDocument!
		
		entry.title = viewController.titleTextField.stringValue
		
		let xml = entry.makeXML(indentLevel: 0)
		
		// TODO: add error handling here...
		// Throw an exception if there isn't any data
		
		return xml.data(using: .utf8)!
	}

	override func read(from data: Data, ofType typeName: String) throws {
		let parserData = ParserData(url: "", data: data)
		let rsDoc = try! RSOPMLParser.parseOPML(with: parserData)
		opmlDocument = rsDoc.translateToOPMLEntry()
	}

}

private extension Document {
	
//	func serializeOPML() -> Data {
//
//	}
	
}
