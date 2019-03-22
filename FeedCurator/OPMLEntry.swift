//Copyright © 2019 Vincode, Inc. All rights reserved.

import Foundation

class OPMLEntry {
	
	var title: String?
	var isFolder = true
	var entries = [OPMLEntry]()
	
	init(title: String?) {
		self.title = title
	}
	
}
