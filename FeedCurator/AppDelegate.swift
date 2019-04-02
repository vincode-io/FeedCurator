//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSWeb
import OctoKit

var appDelegate: AppDelegate!

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	var githubOAuthConfig: OAuthConfiguration?
	var githubTokenConfig: TokenConfiguration?

	override init() {
		super.init()
		appDelegate = self
	}
	
	func applicationWillFinishLaunching(_ notification: Notification) {
		NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(AppDelegate.handleCallback(_:_:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
	}

	func applicationDidFinishLaunching(_ notification: Notification) {
		githubOAuthConfig = OAuthConfiguration(token: Secrets.GitHub.clientId, secret: Secrets.GitHub.clientSecret, scopes: ["repo", "gist"])
	}
	
	@objc func handleCallback(_ event: NSAppleEventDescriptor, _ withReplyEvent: NSAppleEventDescriptor) {
		
		guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue else {
			return
		}

		guard let url = URL(string: urlString) else {
			return
		}
		
		githubOAuthConfig?.handleOpenURL(url: url) { [unowned self] tokenConfig in
			
			self.githubTokenConfig = tokenConfig
			
			DispatchQueue.main.async {
				NSApplication.shared.windows.forEach {
					$0.toolbar?.validateVisibleItems()
				}
			}

		}
			
	}

}
