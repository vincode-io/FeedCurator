//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSWeb

var appDelegate: AppDelegate!

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	override init() {
		super.init()
		appDelegate = self
	}
	
	func applicationWillFinishLaunching(_ notification: Notification) {
	}

	func applicationDidFinishLaunching(_ notification: Notification) {
	}
	
	@IBAction func showHelp(_ sender: Any?) {
		MacWebBrowser.openURL(URL(string: "https://vincode.io/feed-curator-help/")!, inBackground: false)
	}

	@IBAction func showWebsite(_ sender: Any?) {
		MacWebBrowser.openURL(URL(string: "https://vincode.io/feed-curator/")!, inBackground: false)
	}
	
	@IBAction func showGithubRepo(_ sender: Any?) {
		MacWebBrowser.openURL(URL(string: "https://github.com/vincode-io/FeedCurator")!, inBackground: false)
	}
	
	@IBAction func showGithubIssues(_ sender: Any?) {
		MacWebBrowser.openURL(URL(string: "https://github.com/vincode-io/FeedCurator/issues")!, inBackground: false)
	}
	
}
