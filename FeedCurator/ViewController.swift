//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSCore
import RSParser

class ViewController: NSViewController, NSUserInterfaceValidations {

	@IBOutlet weak var outlineView: NSOutlineView!

	private let folderImage: NSImage? = {
		return NSImage(named: "NSFolder")
	}()
	
	private let faviconImage: NSImage? = {
		let path = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/BookmarkIcon.icns"
		return NSImage(contentsOfFile: path)
	}()

	private var windowController: WindowController? {
		return self.view.window?.windowController as? WindowController
	}
	
	private var document: Document? {
		return windowController?.document as? Document
	}

	var currentlySelectedEntry: OPMLEntry? {
		let selectedRow = outlineView.selectedRow
		if selectedRow != -1 {
			return outlineView.item(atRow: selectedRow) as? OPMLEntry
		}
		return nil
	}
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		outlineView.delegate = self
		outlineView.dataSource = self
		
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
		
		let parent = outlineView.parent(forItem: current) as? OPMLEntry
		let childIndex = outlineView.childIndex(forItem: current)
		
		guard let document = document else {
			assertionFailure()
			return
		}
		
		// Update the model
		let realParent = parent == nil ? document.opmlDocument : parent!
		document.removeEntry(parent: realParent, childIndex: childIndex)
		
		// Update the outline
		let indexSet = IndexSet(integer: childIndex)
		outlineView.removeItems(at: indexSet, inParent: parent, withAnimation: .slideUp)
		
	}

	@IBAction func newFolder(_ sender: AnyObject?) {
		
		let current = currentlySelectedEntry
		let parent: OPMLEntry? = {
			if current == nil || current!.isFolder {
				return current
			} else {
  				return outlineView.parent(forItem: current) as? OPMLEntry
			}
		}()
		
		let entry = OPMLEntry(title: NSLocalizedString("New Folder", comment: "New Folder"))
		entry.isFolder = true

		guard let document = document else {
			assertionFailure()
			return
		}
		
		// Update the model
		let realParent = parent == nil ? document.opmlDocument : parent!
		document.appendEntry(parent: realParent, entry: entry)
		
		// Update the outline
		let newRow = outlineView.numberOfChildren(ofItem: parent) - 1
		let indexSet = IndexSet(integer: newRow)
		outlineView.insertItems(at: indexSet, inParent: parent, withAnimation: .slideDown)
		
		outlineView.expandItem(parent, expandChildren: false)
		let rowIndex = outlineView.row(forItem: entry)
		outlineView.rs_selectRowAndScrollToVisible(rowIndex)
		
	}
	
	@IBAction func renameEntry(_ sender: NSTextField) {
		guard let entry = currentlySelectedEntry else {
			return
		}
		document?.updateTitle(entry: entry, title: sender.stringValue)
	}
	
	// MARK: Notifications
	@objc func opmlDocumentChildrenDidChange(_ note: Notification) {
		
		// Save the row to restore the selection
		let rowIndex = outlineView.selectedRow
		
		outlineView.reloadData()
		
		if rowIndex != -1 {
			outlineView.rs_selectRowAndScrollToVisible(rowIndex)
		}
		
	}

}

// MARK: NSOutlineViewDataSource

extension ViewController: NSOutlineViewDataSource {
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		
		if item == nil {
			return document!.opmlDocument.entries[index]
		}
		
		let entry = item as! OPMLEntry
		return entry.entries[index]
		
	}
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		
		if item == nil {
			return document?.opmlDocument.entries.count ?? 0
		}
		
		let entry = item as! OPMLEntry
		return entry.entries.count
		
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		let entry = item as! OPMLEntry
		return entry.isFolder
	}
	
}

// MARK: NSOutlineViewDelegate

extension ViewController: NSOutlineViewDelegate {
	
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		
		switch tableColumn?.identifier.rawValue {
		case "nameColumn":
			if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "nameCell"), owner: nil) as? NSTableCellView {
				let entry = item as! OPMLEntry
				if entry.isFolder {
					cell.imageView?.image = folderImage
					cell.textField?.isEditable = true
				} else {
					cell.imageView?.image = faviconImage
					cell.textField?.isEditable = false
				}
				cell.textField?.stringValue = entry.title ?? ""
				return cell
			}
		case "pageColumn":
			if let feed = item as? OPMLFeed {
				if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "pageCell"), owner: nil) as? NSTableCellView {
					cell.textField?.stringValue = feed.pageURL ?? ""
					return cell
				}
			}
		case "feedColumn":
			if let feed = item as? OPMLFeed {
				if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "feedCell"), owner: nil) as? NSTableCellView {
					cell.textField?.stringValue = feed.feedURL
					return cell
				}
			}
		default:
			return nil
		}
		
		return nil
		
	}
	
	func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
		return 22.0
	}
	
	func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
		return false
	}
	
	func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
		let entry = item as! OPMLEntry
		return entry.isFolder
	}
	
	func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
		return true
	}
	
	func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
	}
	
	func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
		if let feed = item as? OPMLFeed {
			return URLPasteboardWriter(urlString: feed.feedURL)
		}
		return nil
	}
	
	func outlineViewSelectionDidChange(_ notification: Notification) {
		
	}
	
}
