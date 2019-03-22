//Copyright © 2019 Vincode, Inc. All rights reserved.

import Foundation

class OPMLFeed: OPMLEntry {
	
	var pageURL: String?
	var feedURL: String
	
	init(title: String?, pageURL: String?, feedURL: String) {
		self.pageURL = pageURL
		self.feedURL = feedURL
		super.init(title: title)
		self.isFolder = false
	}
	
}
