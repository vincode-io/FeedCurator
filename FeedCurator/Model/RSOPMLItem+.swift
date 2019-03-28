//Copyright © 2019 Vincode, Inc. All rights reserved.

import Foundation
import RSParser

extension RSOPMLItem {
	
	func translateToOPMLEntry(parent: OPMLEntry?) -> OPMLEntry {
		
		let opmlEntry: OPMLEntry = {
			if let fs = self.feedSpecifier {
				return OPMLFeed(title: titleFromAttributes, pageURL: fs.homePageURL, feedURL: fs.feedURL, parent: parent)
			} else {
				if let document = self as? RSOPMLDocument {
					return OPMLDocument(title: document.title)
				} else {
					return OPMLEntry(title: titleFromAttributes, parent: parent)
				}
			}
		}()
		
		if let opmlItems = children {
			for opmlItem in opmlItems {
				let childEntry = opmlItem.translateToOPMLEntry(parent: opmlEntry)
				opmlEntry.entries.append(childEntry)
			}
		}
		
		return opmlEntry
		
	}
	
}
