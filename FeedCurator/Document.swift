//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSParser

public extension Notification.Name {
	static let OPMLDocumentTitleDidChange = Notification.Name(rawValue: "OPMLDocumentTitleDidChange")
}

class Document: NSDocument {

	var opmlDocument = OPMLDocument(title: nil)

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
		
		let xml = opmlDocument.makeXML(indentLevel: 0)
		let xmlData = xml.data(using: .utf8)
		
		if xmlData == nil || xmlData!.count < 1 {
			throw NSLocalizedString("Error generating OPML file", comment: "Error generating OPML file")
		}
		
		return xmlData!
		
	}

	override func read(from data: Data, ofType typeName: String) throws {
		let parserData = ParserData(url: "", data: data)
		let rsDoc = try RSOPMLParser.parseOPML(with: parserData)
		opmlDocument = rsDoc.translateToOPMLEntry() as! OPMLDocument
	}

	override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
		
		if item.action == #selector(save(_:)) {
			if opmlDocument.entries.isEmpty {
				return false
			}
		}

		return super.validateUserInterfaceItem(item)
		
	}
	
	func updateTitle(_ title: String?) {
		
		undoManager?.registerUndo(withTarget: opmlDocument) { [oldTitle = opmlDocument.title] target in
			target.title = oldTitle
			NotificationCenter.default.post(name: .OPMLDocumentTitleDidChange, object: self, userInfo: nil)
		}
		
		opmlDocument.title = title
		NotificationCenter.default.post(name: .OPMLDocumentTitleDidChange, object: self, userInfo: nil)
		
	}
	
}
