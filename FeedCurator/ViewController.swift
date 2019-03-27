//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSCore
import RSParser

class ViewController: NSViewController, NSUserInterfaceValidations {

	@IBOutlet weak var outlineView: NSOutlineView!

	private var addFeed: AddFeed?
	private var feedFinder: FeedFinder?
	private var indeterminateProgress: IndeterminateProgress?

	private var windowController: WindowController? {
		return self.view.window?.windowController as? WindowController
	}
	
	var document: Document? {
		return windowController?.document as? Document
	}

	var currentlySelectedEntry: OPMLEntry? {
		let selectedRow = outlineView.selectedRow
		if selectedRow != -1 {
			return outlineView.item(atRow: selectedRow) as? OPMLEntry
		}
		return nil
	}
	
	var currentlySelectedParent: OPMLEntry? {
		guard let current = currentlySelectedEntry else {
			return nil
		}
		if current.isFolder {
			return current
		} else {
			return outlineView.parent(forItem: current) as? OPMLEntry
		}
	}
	
	typealias DragData = (parent: OPMLEntry?, index: Int)
	
	var currentDragData: DragData?
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		outlineView.delegate = self
		outlineView.dataSource = self
		outlineView.setDraggingSourceOperationMask(.copy, forLocal: false)
		outlineView.setDraggingSourceOperationMask(.move, forLocal: true)
		outlineView.registerForDraggedTypes([.URL, .string])
		
		NotificationCenter.default.addObserver(self, selector: #selector(opmlDocumentChildrenDidChange(_:)), name: .OPMLDocumentChildrenDidChange, object: nil)

	}

	override func viewDidAppear() {
		
		super.viewDidAppear()

		windowController!.titleButton.title = document?.opmlDocument.title ?? WindowController.clickHere
		outlineView.reloadData()
		
	}

	public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
		
		if item.action == #selector(delete(_:)) {
			if currentlySelectedEntry != nil {
				return true
			}
		}
		
		return false
		
	}

	// MARK: Actions
	
	@IBAction func delete(_ sender: AnyObject?) {
		guard let current = currentlySelectedEntry else {
			return
		}
		deleteEntry(current)
	}

	@IBAction func newFeed(_ sender: AnyObject?) {
		if let window = view.window {
			addFeed = AddFeed(delegate: self)
			addFeed?.runSheetOnWindow(window)
		}
	}
		
	@IBAction func newFolder(_ sender: AnyObject?) {
		let entry = OPMLEntry(title: NSLocalizedString("New Folder", comment: "New Folder"))
		insertEntry(entry)
	}
	
	@IBAction func renameEntry(_ sender: NSTextField) {
		guard let entry = currentlySelectedEntry else {
			return
		}
		document?.updateTitle(entry: entry, title: sender.stringValue)
	}
	
	// MARK: Notifications
	@objc func opmlDocumentChildrenDidChange(_ note: Notification) {
		
		// Save the entry to restore the selection
		let current = currentlySelectedEntry
		
		outlineView.reloadData()
		
		if current != nil {
			let rowIndex = outlineView.row(forItem: current)
			outlineView.rs_selectRowAndScrollToVisible(rowIndex)
		}
		
	}

}

// MARK: AddFeedDelegate

extension ViewController: AddFeedDelegate {
	
	func addFeedUserDidAdd(_ urlString: String) {
		findFeed(urlString)
	}
	
	func addFeedUserDidCancel() {
	}
	
}

// MARK: FeedFinderDelegate

extension ViewController: FeedFinderDelegate {
	
	public func feedFinder(_ feedFinder: FeedFinder, didFindFeeds feedSpecifiers: Set<FeedSpecifier>) {
		
		view.window?.endSheet(indeterminateProgress!.window!)
		let dragData = currentDragData
		currentDragData = nil
		
		if let error = feedFinder.initialDownloadError {
			if feedFinder.initialDownloadStatusCode == 404 {
				showNoFeedsErrorMessage()
			}
			else {
				showInitialDownloadError(error)
			}
			return
		}
		
		guard let bestFeedSpecifier = FeedSpecifier.bestFeed(in: feedSpecifiers) else {
			showNoFeedsErrorMessage()
			return
		}
		
		if let url = URL(string: bestFeedSpecifier.urlString) {
			
			InitialFeedDownloader.download(url) { [weak self] (parsedFeed) in
				
				guard let parsedFeed = parsedFeed else {
					assertionFailure()
					return
				}
				
				let opmlFeed = OPMLFeed(title: parsedFeed.title, pageURL: parsedFeed.homePageURL, feedURL: bestFeedSpecifier.urlString)
				
				if dragData == nil {
					self?.insertEntry(opmlFeed)
				} else {
					self?.insertEntry(opmlFeed, parent: dragData!.parent, childIndex: dragData!.index)
				}
				
			}
			
		} else {
			showNoFeedsErrorMessage()
		}
		
	}
	
	private func showInitialDownloadError(_ error: Error) {
		
		let alert = NSAlert()
		alert.alertStyle = .informational
		alert.messageText = NSLocalizedString("Download Error", comment: "Feed finder")
		
		let formatString = NSLocalizedString("Can’t add this feed because of a download error: “%@”", comment: "Feed finder")
		let errorText = NSString.localizedStringWithFormat(formatString as NSString, error.localizedDescription)
		alert.informativeText = errorText as String
		
		if let window = view.window {
			alert.beginSheetModal(for: window)
		}
		
	}
	
	private func showNoFeedsErrorMessage() {
		
		let alert = NSAlert()
		alert.alertStyle = .informational
		alert.messageText = NSLocalizedString("Feed not found", comment: "Feed finder")
		alert.informativeText = NSLocalizedString("Can’t add a feed because no feed was found.", comment: "Feed finder")
		
		if let window = view.window {
			alert.beginSheetModal(for: window)
		}

	}
	
}

// MARK: API

extension ViewController {
	
	func findFeed(_ urlString: String) {
		
		guard let url = URL(string: urlString.rs_normalizedURL()) else {
			return
		}
		
		let msg = NSLocalizedString("Downloading feed data...", comment: "Downloading feed")
		indeterminateProgress = IndeterminateProgress(message: msg)
		view.window?.beginSheet(indeterminateProgress!.window!)

		feedFinder = FeedFinder(url: url, delegate: self)
		
	}

	func deleteEntry(_ entry: OPMLEntry) {
		
		guard let document = document else {
			assertionFailure()
			return
		}
		
		let parent = outlineView.parent(forItem: entry) as? OPMLEntry
		let childIndex = outlineView.childIndex(forItem: entry)
		
		// Update the model
		let realParent = parent == nil ? document.opmlDocument : parent!
		document.removeEntry(parent: realParent, childIndex: childIndex)
		
		// Update the outline
		let indexSet = IndexSet(integer: childIndex)
		outlineView.removeItems(at: indexSet, inParent: parent, withAnimation: .slideUp)
		
	}
	
	func insertEntry(_ entry: OPMLEntry) {
		
		let parent = currentlySelectedParent
		let childIndex: Int = {
			if let current = currentlySelectedEntry {
				if current.isFolder {
					return outlineView.numberOfChildren(ofItem: parent)
				} else {
					return outlineView.childIndex(forItem: current) + 1
				}
			} else {
				return outlineView.numberOfChildren(ofItem: parent)
			}
		}()
		
		insertEntry(entry, parent: parent, childIndex: childIndex)
		
	}
	
	func insertEntry(_ entry: OPMLEntry, parent: OPMLEntry?, childIndex: Int) {
		
		guard let document = document else {
			assertionFailure()
			return
		}
		
		// If we didn't get an index, append to the end
		let fixedIndex: Int = {
			if childIndex == -1 {
				return outlineView.numberOfChildren(ofItem: parent)
			} else {
				return childIndex
			}
		}()
		
		// Update the model
		let realParent = parent == nil ? document.opmlDocument : parent!
		document.insertEntry(parent: realParent, entry: entry, childIndex: fixedIndex)
		
		// Update the outline
		let indexSet = IndexSet(integer: fixedIndex)
		outlineView.insertItems(at: indexSet, inParent: parent, withAnimation: .slideDown)
		
		outlineView.expandItem(parent, expandChildren: false)
		let rowIndex = outlineView.row(forItem: entry)
		outlineView.rs_selectRowAndScrollToVisible(rowIndex)
		
	}
}
