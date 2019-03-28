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
		opmlDocument = rsDoc.translateToOPMLEntry(parent: nil) as! OPMLDocument
	}

	override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
		
		if item.action == #selector(save(_:)) {
			if opmlDocument.entries.isEmpty {
				return false
			}
		}

		return super.validateUserInterfaceItem(item)
		
	}
	
	func updateTitle(entry: OPMLEntry, title: String?) {
		
		let oldTitle = entry.title
		
		if entry is OPMLDocument {
			undoManager?.setActionName(NSLocalizedString("Title Change", comment: "Update Title"))
		} else {
			undoManager?.setActionName(NSLocalizedString("Folder Rename", comment: "Update Title"))
		}
		
		undoManager?.registerUndo(withTarget: opmlDocument) { [weak self] target in
			self?.updateTitle(entry: entry, title: oldTitle)
		}
		
		entry.title = title
		
		// Not too happy with this.  Revisit and refactor later.
		if entry is OPMLDocument {
			NotificationCenter.default.post(name: .OPMLDocumentTitleDidChange, object: self, userInfo: nil)
		} else {
			NotificationCenter.default.post(name: .OPMLDocumentChildrenDidChange, object: self, userInfo: nil)
		}
		
	}
	
	func removeEntry(parent: OPMLEntry, childIndex: Int) {
		
		let current = parent.entries[childIndex]

		if !(undoManager?.isUndoing ?? false) {
			if current.isFolder {
				undoManager?.setActionName(NSLocalizedString("Delete Folder", comment: "Delete Folder"))
			} else {
				undoManager?.setActionName(NSLocalizedString("Delete Feed", comment: "Delete Row"))
			}
		}

		undoManager?.registerUndo(withTarget: parent) { [weak self] target in
			self?.insertEntry(parent: target, childIndex: childIndex, entry: current)
			NotificationCenter.default.post(name: .OPMLDocumentChildrenDidChange, object: self, userInfo: nil)
		}

		parent.entries.remove(at: childIndex)
		
	}
	
	func insertEntry(parent: OPMLEntry, childIndex: Int, entry: OPMLEntry) {
		
		if !(undoManager?.isUndoing ?? false) {
			if entry.isFolder {
				undoManager?.setActionName(NSLocalizedString("Insert Folder", comment: "Insert Folder"))
			} else {
				undoManager?.setActionName(NSLocalizedString("Insert Feed", comment: "Insert Row"))
			}
		}

		undoManager?.registerUndo(withTarget: parent) { [weak self] target in
			self?.removeEntry(parent: target, childIndex: childIndex)
			NotificationCenter.default.post(name: .OPMLDocumentChildrenDidChange, object: self, userInfo: nil)
		}
		
		parent.entries.insert(entry, at: childIndex)
		entry.parent = parent
		
	}
	
	func moveEntry(fromParent: OPMLEntry, fromChildIndex: Int, toParent: OPMLEntry, toChildIndex: Int, entry: OPMLEntry) {

		if !(undoManager?.isUndoing ?? false) {
			if entry.isFolder {
				undoManager?.setActionName(NSLocalizedString("Move Folder", comment: "Insert Folder"))
			} else {
				undoManager?.setActionName(NSLocalizedString("Move Feed", comment: "Insert Row"))
			}
		}

		undoManager?.registerUndo(withTarget: fromParent) { [weak self] target in
			self?.moveEntry(fromParent: toParent, fromChildIndex: toChildIndex, toParent: fromParent, toChildIndex: fromChildIndex, entry: entry)
			NotificationCenter.default.post(name: .OPMLDocumentChildrenDidChange, object: self, userInfo: nil)
		}
		
		fromParent.entries.remove(at: fromChildIndex)
		toParent.entries.insert(entry, at: toChildIndex)
		entry.parent = toParent

	}
	
}
