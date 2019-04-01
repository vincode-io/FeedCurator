//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import OctoKit
import RSWeb

class UploadOPML: NSWindowController {
	
	@IBOutlet weak var progressIndicator: NSProgressIndicator!
	@IBOutlet weak var cancelButton: NSButton!
	@IBOutlet weak var uploadButton: NSButton!
	
	private static let description = NSLocalizedString("Feed Curator OPML", comment: "Feed Curator OPML")
	private weak var hostWindow: NSWindow?
	private var filename: String!
	private var fileContent: String!
	
	convenience init(filename: String, fileContent: String) {
		self.init(windowNibName: NSNib.Name("UploadOPML"))
		self.filename = filename
		self.fileContent = fileContent
	}
	
	func runSheetOnWindow(_ hostWindow: NSWindow) {
		self.hostWindow = hostWindow
		hostWindow.beginSheet(window!)
	}
	
	// MARK: Actions
	
	@IBAction func cancel(_ sender: NSButton) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.cancel)
	}
	
	@IBAction func upload(_ sender: NSButton) {
		
		progressIndicator.isHidden = false
		progressIndicator.startAnimation(self)
		cancelButton.isEnabled = false
		uploadButton.isEnabled = false
		
		if let gistId = AppDefaults.gistID {
			patchOPML(gistId: gistId)
		} else {
			postOPML()
		}
		
	}
	
}

private extension UploadOPML {
	
	func postOPML() {
		
		guard let tokenConfig = appDelegate.githubTokenConfig else { return }
		let octoKit = Octokit(tokenConfig)
		
		octoKit.postGistFile(description: "Feed Curator OPML", filename: filename, fileContent: fileContent, publicAccess: true) { [weak self] response in
			
			switch response {
				
			case .success(let gist):
				AppDefaults.gistID = gist.id
				self?.storeRawFileURL(gist: gist)
				self?.closeSheet()
			case .failure(let error):
				self?.handleError(error)
			}
			
		}
		
	}
	
	func patchOPML(gistId: String) {
		
		guard let tokenConfig = appDelegate.githubTokenConfig else { return }
		let octoKit = Octokit(tokenConfig)
		
		octoKit.patchGistFile(id: gistId, description: "Feed Curator OPML", filename: filename, fileContent: fileContent) { [weak self] response in
			
			switch response {
			case .success(let gist):
				self?.storeRawFileURL(gist: gist)
				self?.closeSheet()
			case .failure(let error):
				self?.handleError(error)
			}
			
		}
		
	}
	
	func storeRawFileURL(gist: Gist) {
		
		var gistFiles: [String: Any?] = {
			if let files = AppDefaults.gistFiles {
				return files
			} else {
				return [String: Any?]()
			}
		}()
		
		if let filename = self.filename {
			for fileEntry in gist.files {
				if fileEntry.key == filename {
					gistFiles[filename] = fileEntry.value.rawURL
				}
			}
		}
		
	}
	
	func closeSheet() {
		DispatchQueue.main.async {
			if let window = self.window {
				self.hostWindow!.endSheet(window, returnCode: NSApplication.ModalResponse.OK)
			}
		}
	}
	
	func handleError(_ error: Error) {
		DispatchQueue.main.async {
			let e = NSLocalizedString("Unable to Upload: ", comment: "Unable to Upload") + error.localizedDescription
			NSApplication.shared.presentError(e)
			if let window = self.window {
				self.hostWindow!.endSheet(window, returnCode: NSApplication.ModalResponse.cancel)
			}
		}
	}
	
}
