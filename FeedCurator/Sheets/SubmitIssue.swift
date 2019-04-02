//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import OctoKit
import RSWeb

class SubmitIssue: NSWindowController {
	
	@IBOutlet var bodyTextView: NSTextView!
	@IBOutlet weak var progressIndicator: NSProgressIndicator!
	@IBOutlet weak var cancelButton: NSButton!
	@IBOutlet weak var submitButton: NSButton!
	
	private weak var hostWindow: NSWindow?
	private var filename: String!
	private var title: String!
	private var gistURL: String!

	convenience init(filename: String, title: String, gistURL: String) {
		self.init(windowNibName: NSNib.Name("SubmitIssue"))
		self.filename = filename
		self.title = title
		self.gistURL = gistURL
	}
	
	func runSheetOnWindow(_ hostWindow: NSWindow) {
		self.hostWindow = hostWindow
		hostWindow.beginSheet(window!)
	}
	
	// MARK: Actions
	
	@IBAction func cancel(_ sender: NSButton) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.cancel)
	}
	
	@IBAction func submit(_ sender: NSButton) {

		bodyTextView.isEditable = false
		progressIndicator.isHidden = false
		progressIndicator.startAnimation(self)
		cancelButton.isEnabled = false
		submitButton.isEnabled = false
		
		guard let tokenConfig = appDelegate.githubTokenConfig else { return }
		let octoKit = Octokit(tokenConfig)
		
		let issueTitle = NSLocalizedString("Add Request: ", comment: "Add Request") + title
		let body = bodyTextView.string + "\n\n \(gistURL ?? "")"
		
		octoKit.postIssue(owner: "vincode-io", repository: "FeedCompass", title: issueTitle, body: body) { [weak self] response in
			
			switch response {
				
			case .success(let issue):
				
				self?.storeIssueURL(issue: issue)
				
				DispatchQueue.main.async {
					if let htmlURL = issue.htmlURL {
						MacWebBrowser.openURL(htmlURL, inBackground: false)
					}
					if let window = self?.window {
						self?.hostWindow!.endSheet(window, returnCode: NSApplication.ModalResponse.OK)
					}
				}
			
			case .failure(let error):
				
				DispatchQueue.main.async {
					let e = NSLocalizedString("Unable to Submit: ", comment: "Unable to Submit") + error.localizedDescription
					NSApplication.shared.presentError(e)
					if let window = self?.window {
						self?.hostWindow!.endSheet(window, returnCode: NSApplication.ModalResponse.cancel)
					}
				}
				
			}
		}

	}
	
	func storeIssueURL(issue: Issue) {
		
		var issueURLs: [String: Any?] = {
			if let files = AppDefaults.issueURLs {
				return files
			} else {
				return [String: Any?]()
			}
		}()
		
		issueURLs[filename] = issue.htmlURL?.absoluteString
		
		AppDefaults.issueURLs = issueURLs
		
	}
	
}
