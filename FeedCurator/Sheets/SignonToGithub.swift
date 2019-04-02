//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSWeb

class SignonToGithub: NSWindowController {
	
	private weak var hostWindow: NSWindow?
	
	convenience init() {
		self.init(windowNibName: NSNib.Name("SignonToGithub"))
	}
	
	func runSheetOnWindow(_ hostWindow: NSWindow) {
		self.hostWindow = hostWindow
		hostWindow.beginSheet(window!)
	}
	
	@IBAction func signup(_ sender: NSButton) {
		let github = URL(string: "https://github.com")
		MacWebBrowser.openURL(github!, inBackground: false)
	}
	
	@IBAction func cancel(_ sender: NSButton) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.cancel)
	}
	
	@IBAction func signin(_ sender: NSButton) {
		if let url = appDelegate.githubOAuthConfig?.authenticate() {
			MacWebBrowser.openURL(url, inBackground: false)
		}
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.OK)
	}
	
}
