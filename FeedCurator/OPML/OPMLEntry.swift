//Copyright © 2019 Vincode, Inc. All rights reserved.

import Foundation
import RSCore

class OPMLEntry {
	
	var title: String?
	var isFolder = true
	var entries = [OPMLEntry]()
	
	init(title: String?) {
		self.title = title
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
	
}
