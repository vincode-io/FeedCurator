//Copyright © 2019 Vincode, Inc. All rights reserved.

import Foundation
import RSCore

class OPMLFeed: OPMLEntry {
	
	static let feedUTI = "io.vicode.opml-feed"
	static let feedUTIType = NSPasteboard.PasteboardType(rawValue: feedUTI)

	struct Key {
		static let pageURL = "pageURL"
		static let feedURL = "feedURL"
	}

	var pageURL: String?
	var feedURL: String?
	
	override var isLocalEntry: Bool {
		return title != nil || pageURL != nil
	}
	
	init(feedURL: String) {
		super.init(title: nil)
		self.feedURL = feedURL
	}
	
	init(title: String?, pageURL: String?, feedURL: String?, parent: OPMLEntry? = nil) {
		self.pageURL = pageURL
		self.feedURL = feedURL
		super.init(title: title, parent: parent)
	}
	
	convenience init?(plist: [String: Any]) {
		let title = plist[Key.title] as? String
		let pageURL = plist[Key.pageURL] as? String
		let feedURL = plist[Key.feedURL] as? String
		self.init(title: title, pageURL: pageURL, feedURL: feedURL)
	}

	convenience init?(pasteboardItem: NSPasteboardItem) {
		
		if pasteboardItem.types.contains(OPMLFeed.folderUTIType) {
			guard let plist = pasteboardItem.propertyList(forType: OPMLFeed.feedUTIType) as? [String: Any] else {
				return nil
			}
			self.init(plist: plist)
			return
		}
	
		var pasteboardType: NSPasteboard.PasteboardType?
		if pasteboardItem.types.contains(.URL) {
			pasteboardType = .URL
		}
		else if pasteboardItem.types.contains(.string) {
			pasteboardType = .string
		}
		if let foundType = pasteboardType {
			if let possibleURLString = pasteboardItem.string(forType: foundType) {
				if possibleURLString.rs_stringMayBeURL() {
					self.init(feedURL: possibleURLString)
					return
				}
			}
		}

		return nil
		
	}

	override func makeXML(indentLevel: Int) -> String {
		
		let t = title?.rs_stringByEscapingSpecialXMLCharacters() ?? ""
		let p = pageURL?.rs_stringByEscapingSpecialXMLCharacters() ?? ""
		let f = feedURL?.rs_stringByEscapingSpecialXMLCharacters() ?? ""
		
		var s = "<outline text=\"\(t)\" title=\"\(t)\" description=\"\" type=\"rss\" version=\"RSS\" htmlUrl=\"\(p)\" xmlUrl=\"\(f)\"/>\n"
		s = s.rs_string(byPrependingNumberOfTabs: indentLevel)
		
		return s
		
	}

	override func makePlist() -> Any? {
		
		var result = [String: Any]()
		
		result[OPMLEntry.Key.uti] = OPMLFeed.feedUTI
		result[OPMLEntry.Key.address] = address
		result[OPMLEntry.Key.title] = title
		result[Key.pageURL] = pageURL
		result[Key.feedURL] = feedURL

		return result
		
	}
	
	// MARK: NSPasteboardWriting
	
	override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
		return [OPMLFeed.feedUTIType, .URL, .string]
	}
	
	override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
		
		let plist: Any?
		
		switch type {
		case .string:
			plist = title
		case .URL:
			plist = feedURL
		case OPMLFeed.feedUTIType:
			plist = makePlist()
		default:
			plist = nil
		}
		
		return plist
		
	}
	
}
