//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSParser

public extension Notification.Name {
	static let OPMLDocumentTitleDidChange = Notification.Name(rawValue: "OPMLDocumentTitleDidChange")
	static let OPMLDocumentChildrenDidChange = Notification.Name(rawValue: "OPMLDocumentChildrenDidChange")
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
		
		let oldTitle = opmlDocument.title
		
		undoManager?.setActionName(NSLocalizedString("Title Change", comment: "Update Title"))
		undoManager?.registerUndo(withTarget: opmlDocument) { [weak self] target in
			self?.updateTitle(oldTitle)
			NotificationCenter.default.post(name: .OPMLDocumentTitleDidChange, object: self, userInfo: nil)
		}
		
		opmlDocument.title = title
		NotificationCenter.default.post(name: .OPMLDocumentTitleDidChange, object: self, userInfo: nil)
		
	}
	
	func removeEntry(parent: OPMLEntry?, childIndex: Int) {
		
		let current: OPMLEntry = {
			if parent == nil {
				return opmlDocument.entries[childIndex]
			} else {
				return parent!.entries[childIndex]
			}
		}()
		
		let target = (parent == nil ? opmlDocument : parent)!

		if !(undoManager?.isUndoing ?? false) {
			if current.isFolder {
				undoManager?.setActionName(NSLocalizedString("Delete Folder", comment: "Delete Folder"))
			} else {
				undoManager?.setActionName(NSLocalizedString("Delete Row", comment: "Delete Row"))
			}
		
		}

		undoManager?.registerUndo(withTarget: target) { [weak self] target in
			self?.insertEntry(parent: target, entry: current, childIndex: childIndex)
			NotificationCenter.default.post(name: .OPMLDocumentChildrenDidChange, object: self, userInfo: nil)
		}
		
		if parent == nil {
			opmlDocument.entries.remove(at: childIndex)
		} else {
			parent!.entries.remove(at: childIndex)
		}
		
	}
	
	func insertEntry(parent: OPMLEntry?, entry: OPMLEntry, childIndex: Int) {
		
		let target = (parent == nil ? opmlDocument : parent)!

		if !(undoManager?.isUndoing ?? false) {
			if entry.isFolder {
				undoManager?.setActionName(NSLocalizedString("Insert Folder", comment: "Insert Folder"))
			} else {
				undoManager?.setActionName(NSLocalizedString("Insert Row", comment: "Insert Row"))
			}
		}

		undoManager?.registerUndo(withTarget: target) { [weak self] target in
			self?.removeEntry(parent: target, childIndex: childIndex)
			NotificationCenter.default.post(name: .OPMLDocumentChildrenDidChange, object: self, userInfo: nil)
		}
		
		if parent == nil {
			opmlDocument.entries.insert(entry, at: childIndex)
		} else {
			parent!.entries.insert(entry, at: childIndex)
		}
		
	}
	
}
