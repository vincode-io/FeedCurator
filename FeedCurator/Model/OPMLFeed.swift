//Copyright © 2019 Vincode, Inc. All rights reserved.

import Foundation
import RSCore

class OPMLFeed: OPMLEntry {
	
	var pageURL: String?
	var feedURL: String
	
	init(title: String?, pageURL: String?, feedURL: String) {
		self.pageURL = pageURL
		self.feedURL = feedURL
		super.init(title: title)
		self.isFolder = false
	}
	
	override func makeXML(indentLevel: Int) -> String {
		
		let t = title?.rs_stringByEscapingSpecialXMLCharacters() ?? ""
		let p = pageURL?.rs_stringByEscapingSpecialXMLCharacters() ?? ""
		let f = feedURL.rs_stringByEscapingSpecialXMLCharacters()
		
		var s = "<outline text=\"\(t)\" title=\"\(t)\" description=\"\" type=\"rss\" version=\"RSS\" htmlUrl=\"\(p)\" xmlUrl=\"\(f)\"/>\n"
		s = s.rs_string(byPrependingNumberOfTabs: indentLevel)
		
		return s
		
	}
	
}
