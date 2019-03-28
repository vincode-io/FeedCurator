//Copyright © 2019 Vincode, Inc. All rights reserved.

import Foundation
import RSCore

class OPMLEntry: NSObject, NSPasteboardWriting {
	
	static let folderUTI = "io.vicode.opml-folder"
	static let folderUTIType = NSPasteboard.PasteboardType(rawValue: folderUTI)
	
	struct Key {
		static let uti = "uti"
		static let title = "title"
		static let entries = "entries"
	}
	
	var title: String?
	var entries = [OPMLEntry]()

	var isFolder: Bool {
		return type(of: self) == OPMLEntry.self
	}
	
	var isLocalEntry: Bool {
		return true
	}
	
	init(title: String?, entries: [OPMLEntry]? = nil) {
		self.title = title
	}
	
	convenience init?(plist: [String: Any]) {
		let title = plist[Key.title] as? String
		let plistEntries = plist[Key.entries] as! [[String: Any]]
		let entries = plistEntries.compactMap { return OPMLEntry.entry(plist: $0) }
		self.init(title: title, entries: entries)
	}
	
	convenience init?(pasteboardItem: NSPasteboardItem) {
		guard let plist = pasteboardItem.propertyList(forType: OPMLEntry.folderUTIType) as? [String: Any] else {
			return nil
		}
		self.init(plist: plist)
	}
	
	func makeXML(indentLevel: Int) -> String {
		
		let t = title?.rs_stringByEscapingSpecialXMLCharacters() ?? ""
		var s = "<outline text=\"\(t)\" title=\"\(t)\">\n".rs_string(byPrependingNumberOfTabs: indentLevel)

		for entry in entries {
			s += entry.makeXML(indentLevel: indentLevel + 1)
		}
		
		s += "</outline>\n".rs_string(byPrependingNumberOfTabs: indentLevel)

		return s
		
	}
	
	func makePlist() -> Any? {
		var result = [String: Any]()
		result[Key.uti] = OPMLEntry.folderUTI
		result[Key.title] = title
		return result
	}
	
	static func entries(with pasteboard: NSPasteboard) -> [OPMLEntry]? {
		
		guard let items = pasteboard.pasteboardItems else {
			return nil
		}
		
		let results: [OPMLEntry] = items.compactMap { item in
			if item.types.contains(OPMLEntry.folderUTIType) {
				return OPMLEntry(pasteboardItem: item)
			} else {
				return OPMLFeed(pasteboardItem: item)
			}
		}
		
		return results.isEmpty ? nil : results
		
	}
	
	static func entry(plist: [String: Any]) -> OPMLEntry? {
		if let uti = plist[OPMLFeed.feedUTI] as? String {
			if uti == OPMLFeed.feedUTI {
				return OPMLFeed(plist: plist)
			} else {
				return OPMLEntry(plist: plist)
			}
		}
		return nil
	}
	
	// MARK: NSPasteboardWriting
	
	func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
		return [OPMLEntry.folderUTIType, .string]
	}
	
	func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
		
		let plist: Any?
		
		switch type {
		case .string:
			plist = title
		case OPMLEntry.folderUTIType:
			plist = makePlist()
		default:
			plist = nil
		}
		
		return plist
		
	}

}
