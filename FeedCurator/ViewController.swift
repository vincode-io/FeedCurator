//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSCore
import RSParser

class ViewController: NSViewController {

	@IBOutlet weak var feedOutlineView: NSOutlineView!

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
	
	var opmlDocument: OPMLEntry?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		feedOutlineView.delegate = self
		feedOutlineView.dataSource = self
	}

	override func viewDidAppear() {
		
		super.viewDidAppear()

		opmlDocument = (windowController!.document as! Document).opmlDocument
		windowController!.titleButton.title = opmlDocument?.title ?? WindowController.clickHere
		feedOutlineView.reloadData()
		
	}

	override var representedObject: Any? {
		didSet {
			print("stored rep object")
		}
	}

}

// MARK: NSOutlineViewDataSource

extension ViewController: NSOutlineViewDataSource {
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		
		if item == nil {
			return opmlDocument!.entries[index]
		}
		
		let entry = item as! OPMLEntry
		return entry.entries[index]
		
	}
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		
		if item == nil {
			return opmlDocument?.entries.count ?? 0
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
				} else {
					cell.imageView?.image = faviconImage
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
