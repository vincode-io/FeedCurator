//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSCore
import RSParser
import RSWeb

class ViewController: NSViewController, NSUserInterfaceValidations {

	@IBOutlet weak var outlineView: NSOutlineView!

	private var addFeed: AddFeed?
	private var feedFinder: FeedFinder?
	private var indeterminateProgress: IndeterminateProgress?
	private var numberOfFeedsBeingFound = 0

	private var windowController: WindowController? {
		return self.view.window?.windowController as? WindowController
	}
	
	var document: Document? {
		return windowController?.document as? Document
	}

	var currentlySelectedEntries: [OPMLEntry] {
		return outlineView.selectedRowIndexes.compactMap{ outlineView.item(atRow: $0) as? OPMLEntry }
	}
	
	var currentlySelectedParent: OPMLEntry? {
		guard currentlySelectedEntries.count == 1, let current = currentlySelectedEntries.first else {
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
		outlineView.registerForDraggedTypes([OPMLFeed.feedUTIType, OPMLEntry.folderUTIType, .URL, .string])
		outlineView.allowsMultipleSelection = true
		
		NotificationCenter.default.addObserver(self, selector: #selector(opmlDocumentChildrenDidChange(_:)), name: .OPMLDocumentChildrenDidChange, object: nil)

	}

	override func viewDidAppear() {
		
		super.viewDidAppear()

		windowController!.titleButton.title = document?.opmlDocument.title ?? WindowController.clickHere
		outlineView.reloadData()
		
	}

	public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
		if item.action == #selector(importOPML(_:)) {
			return true
		}
		
		if item.action == #selector(delete(_:)) {
			if currentlySelectedEntries.count > 0 {
				return true
			}
		}
		
		return false
	}

	// MARK: Actions
	
	@IBAction func delete(_ sender: AnyObject?) {
		for entry in currentlySelectedEntries {
			deleteEntry(entry)
		}
	}

	@IBAction func newFeed(_ sender: AnyObject?) {
		if let window = view.window {
			addFeed = AddFeed(delegate: self)
			addFeed!.runSheetOnWindow(window)
		}
	}
		
	@IBAction func newFolder(_ sender: AnyObject?) {
		let entry = OPMLEntry(title: NSLocalizedString("New Folder", comment: "New Folder"))
		insertEntry(entry)
	}
	
	@IBAction func renameEntry(_ sender: NSTextField) {
		guard let entry = currentlySelectedEntries.first else {
			return
		}
		document?.updateTitle(entry: entry, title: sender.stringValue)
	}
	
	@IBAction func importOPML(_ sender: AnyObject?) {
		let panel = NSOpenPanel()
		panel.canDownloadUbiquitousContents = true
		panel.canResolveUbiquitousConflicts = true
		panel.canChooseFiles = true
		panel.allowsMultipleSelection = true
		panel.canChooseDirectories = false
		panel.resolvesAliases = true
		panel.allowedFileTypes = ["opml", "xml"]
		panel.allowsOtherFileTypes = false
		
		panel.beginSheetModal(for: view.window!) { result in
			if result == NSApplication.ModalResponse.OK {
				for url in panel.urls {
					self.importOPML(url: url)
				}
			}
		}
	}
	
	func importOPML(url: URL) {
		guard let data = try? Data(contentsOf: url) else {
			return
		}
		
		let parserData = ParserData(url: "", data: data)
		guard let rsDoc = try? RSOPMLParser.parseOPML(with: parserData),
			let opmlDocument = rsDoc.translateToOPMLEntry(parent: nil) as? OPMLDocument else {
				return
		}
		
		let importFolder = OPMLEntry(title: opmlDocument.title ?? "")
		for child in opmlDocument.entries {
			importFolder.entries.append(child)
		}
		
		appendEntry(importFolder)
	}
	
	
	// MARK: Notifications
	@objc func opmlDocumentChildrenDidChange(_ note: Notification) {
		// Save the entry to restore the selection
		let selectedRowIndexes = outlineView.selectedRowIndexes
		outlineView.reloadData()
		outlineView.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)
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
		numberOfFeedsBeingFound = numberOfFeedsBeingFound - 1
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
		
		if numberOfFeedsBeingFound == 0 {
			let msg = NSLocalizedString("Downloading feed data...", comment: "Downloading feed")
			indeterminateProgress = IndeterminateProgress(message: msg)
			view.window?.beginSheet(indeterminateProgress!.window!)
		}
		
		numberOfFeedsBeingFound =  numberOfFeedsBeingFound + 1

		feedFinder = FeedFinder(url: url, delegate: self)
	}

	func deleteEntry(_ entry: OPMLEntry) {
		guard let document = document else {
			assertionFailure()
			return
		}
		
		let parent = outlineView.parent(forItem: entry) as? OPMLEntry
		let childIndex = outlineView.childIndex(forItem: entry)
		
		guard childIndex != -1 else { return }
		
		// Update the model
		let realParent = parent == nil ? document.opmlDocument : parent!
		document.removeEntry(parent: realParent, childIndex: childIndex)
		
		// Update the outline
		let indexSet = IndexSet(integer: childIndex)
		outlineView.removeItems(at: indexSet, inParent: parent, withAnimation: .slideUp)
	}
	
	func appendEntry(_ entry: OPMLEntry) {
		let childIndex = outlineView.numberOfChildren(ofItem: nil)
		insertEntry(entry, parent: nil, childIndex: childIndex)
	}
	
	func insertEntry(_ entry: OPMLEntry) {
		let parent = currentlySelectedParent
		let childIndex: Int = {
			if let current = currentlySelectedEntries.last {
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

		let correctedChildIndex: Int = {
			guard !(parent?.isFolder ?? true) else { return parent?.entries.count ?? document.opmlDocument.entries.count }

			if childIndex == NSOutlineViewDropOnItemIndex {
				return 0
			} else {
				return childIndex
			}
		}()
		
		// Update the model
		let realParent = parent == nil ? document.opmlDocument : parent!
		document.insertEntry(parent: realParent, childIndex: correctedChildIndex, entry: entry)
		
		// Update the outline
		let indexSet = IndexSet(integer: correctedChildIndex)
		outlineView.insertItems(at: indexSet, inParent: parent, withAnimation: .slideDown)
		
		outlineView.expandItem(parent, expandChildren: false)
		let rowIndex = outlineView.row(forItem: entry)
		outlineView.rs_selectRowAndScrollToVisible(rowIndex)
		
	}
	
	func moveEntry(_ entry: OPMLEntry, toParent: OPMLEntry?, toChildIndex: Int) {
		
		guard let document = document else {
			assertionFailure()
			return
		}

		let fromParent = outlineView.parent(forItem: entry) as? OPMLEntry
		let fromChildIndex = outlineView.childIndex(forItem: entry)

		// The first thing we do in this mess is check to see if the item was dropped
		// on a folder or not.  If it was, we add it at the beginning by setting the
		// index to zero.  After that we check to see if we are moving stuff inside the
		// same parent folder or not.  If we are, we have to remove one from the "to"
		// index, but only if the "from" object is higher up than the "to" object.
		let correctedToChildIndex: Int = {
			guard !(toParent?.isFolder ?? true) else { return toParent?.entries.count ?? document.opmlDocument.entries.count }

			if toChildIndex == NSOutlineViewDropOnItemIndex {
				return 0
			} else {
				if toParent == fromParent {
					if fromChildIndex < toChildIndex {
						return toChildIndex - 1
					} else {
						return toChildIndex
					}
				} else {
					return toChildIndex
				}
			}
		}()
		
		// Update the model
		let realToParent = toParent == nil ? document.opmlDocument : toParent!
		let realFromParent = fromParent == nil ? document.opmlDocument : fromParent!
		document.moveEntry(fromParent: realFromParent, fromChildIndex: fromChildIndex, toParent: realToParent, toChildIndex: correctedToChildIndex, entry: entry)
		
		// Update the outline
		outlineView.moveItem(at: fromChildIndex, inParent: fromParent, to: correctedToChildIndex, inParent: toParent)
	}
	
}
