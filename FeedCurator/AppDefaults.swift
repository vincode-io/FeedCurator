//Copyright © 2019 Vincode, Inc. All rights reserved.

import Foundation

struct AppDefaults {
	
	struct Key {
		static let gistIds = "gistIds"
		static let gistRawURLs = "gistRawURLs"
		static let issueURLs = "issueURLs"
	}
	
	static var gistIds: [String: Any?]? {
		get {
			return UserDefaults.standard.dictionary(forKey: Key.gistIds)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.gistIds)
		}
	}

	static var gistRawURLs: [String: Any?]? {
		get {
			return UserDefaults.standard.dictionary(forKey: Key.gistRawURLs)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.gistRawURLs)
		}
	}
	
	static var issueURLs: [String: Any?]? {
		get {
			return UserDefaults.standard.dictionary(forKey: Key.issueURLs)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: Key.issueURLs)
		}
	}
	
}
