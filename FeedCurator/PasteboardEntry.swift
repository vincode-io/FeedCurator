//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSCore

typealias PasteboardEntryDictionary = [String: String]

struct PasteboardEntry: Hashable {
	
	private struct Key {
		static let feedURL = "URL"
		static let pageURL = "homePageURL"
		static let title = "name"
		static let isLocal = "isLocal"
	}
	
	let feedURL: String
	let pageURL: String?
	let title: String?
	let isLocalEntry: Bool

	init(feedURL: String, pageURL: String?, title: String?, isLocalEntry: Bool) {
		self.feedURL = feedURL
		self.pageURL = pageURL
		self.title = title
		self.isLocalEntry = isLocalEntry
	}

	init?(dictionary: PasteboardEntryDictionary) {
		
		guard let feedURL = dictionary[Key.feedURL] else {
			return nil
		}
		
		let pageURL = dictionary[Key.pageURL]
		let title = dictionary[Key.title]
		let isLocalEntry = dictionary[Key.isLocal] == "true" ? true : false
		
		self.init(feedURL: feedURL, pageURL: pageURL, title: title, isLocalEntry: isLocalEntry)
		
	}
	
	init?(pasteboardItem: NSPasteboardItem) {
		
		var pasteboardType: NSPasteboard.PasteboardType?
		
//		if pasteboardItem.types.contains(FeedPasteboardWriter.feedUTIInternalType) {
//			pasteboardType = FeedPasteboardWriter.feedUTIInternalType
//		} else if pasteboardItem.types.contains(FeedPasteboardWriter.feedUTIType) {
//			pasteboardType = FeedPasteboardWriter.feedUTIType
//		}
//
//		if let foundType = pasteboardType {
//			if let feedDictionary = pasteboardItem.propertyList(forType: foundType) as? PasteboardFeedDictionary {
//				self.init(dictionary: feedDictionary)
//				return
//			}
//			return nil
//		}
		
		// Check for URL or a string that may be a URL.
		if pasteboardItem.types.contains(.URL) {
			pasteboardType = .URL
		} else if pasteboardItem.types.contains(.string) {
			pasteboardType = .string
		}
		
		if let foundType = pasteboardType {
			if let possibleURLString = pasteboardItem.string(forType: foundType) {
				if possibleURLString.rs_stringMayBeURL() {
					self.init(feedURL: possibleURLString, pageURL: nil, title: nil, isLocalEntry: false)
					return
				}
			}
		}
		
		return nil
		
	}
	
	static func pasteboardEntries(with pasteboard: NSPasteboard) -> Set<PasteboardEntry>? {
		guard let items = pasteboard.pasteboardItems else {
			return nil
		}
		let entries = items.compactMap { PasteboardEntry(pasteboardItem: $0) }
		return entries.isEmpty ? nil : Set(entries)
	}
	
	// MARK: - Writing
	
	func dictionary(isLocalEntry: Bool) -> PasteboardEntryDictionary {
		var d = PasteboardEntryDictionary()
		d[Key.feedURL] = feedURL
		d[Key.pageURL] = pageURL ?? ""
		d[Key.title] = title ?? ""
		d[Key.isLocal] = isLocalEntry ? "true" : "false"
		return d
	}
	
}
