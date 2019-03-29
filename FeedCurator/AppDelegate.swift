//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSWeb
import OctoKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserInterfaceValidations {

	var githubOAuthConfig: OAuthConfiguration?
	var githubTokenConfig: TokenConfiguration?

	func applicationWillFinishLaunching(_ notification: Notification) {
		NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(AppDelegate.handleCallback(_:_:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
	}

	func applicationDidFinishLaunching(_ notification: Notification) {
		githubOAuthConfig = OAuthConfiguration(token: Secrets.GitHub.clientId, secret: Secrets.GitHub.clientSecret, scopes: ["repo"])
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
			self.validateAllToolbars()
		}
			
	}

	// MARK: NSUserInterfaceValidations
	
	func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {

		if item.action == #selector(loginToGithub(_:)) {
			return githubTokenConfig == nil
		}

		return false
		
	}

	// MARK: Actions
	
	@IBAction func loginToGithub(_ sender: Any?) {
		if let url = githubOAuthConfig?.authenticate() {
			MacWebBrowser.openURL(url, inBackground: false)
		}
	}
	
}

private extension AppDelegate {
	
	func validateAllToolbars() {
		DispatchQueue.main.async {
			NSApplication.shared.windows.forEach {
				$0.toolbar?.validateVisibleItems()
			}
		}
	}
	
}
