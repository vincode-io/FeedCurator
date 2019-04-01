//Copyright © 2019 Vincode, Inc. All rights reserved.

import Foundation

struct AppDefaults {
	
	struct Key {
		static let gistID = "gistID"
		static let gistFiles = "gistFiles"
	}
	
	static var gistID: String? {
		get {
			return UserDefaults.standard.string(forKey: Key.gistID)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.gistID)
		}
	}
	
	static var gistFiles: [String: Any?]? {
		get {
			return UserDefaults.standard.dictionary(forKey: Key.gistFiles)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.gistFiles)
		}
	}
	
}
