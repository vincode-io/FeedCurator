//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSCore

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
	
	private static let folderImage: NSImage? = {
		return NSImage(named: "NSFolder")
	}()
	
	private static let faviconImage: NSImage? = {
		let path = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/BookmarkIcon.icns"
		return NSImage(contentsOfFile: path)
	}()

	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		
		switch tableColumn?.identifier.rawValue {
		case "nameColumn":
			if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "nameCell"), owner: nil) as? NSTableCellView {
				let entry = item as! OPMLEntry
				if entry.isFolder {
					cell.imageView?.image = ViewController.folderImage
					cell.textField?.isEditable = true
				} else {
					cell.imageView?.image = ViewController.faviconImage
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
	
	// Drag and Drop
	
	func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
		if let feed = item as? OPMLFeed {
			return URLPasteboardWriter(urlString: feed.feedURL)
		}
		return nil
	}

	func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
		
		// Will eventually have to determine between local and non-local here.
		
		if item == nil {
			return .copy
		}
		
		if let entry = item as? OPMLEntry, entry.isFolder {
			return .copy
		}
		
		return []
		
	}
	
	func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
		
		guard let draggedEntries = PasteboardEntry.pasteboardEntries(with: info.draggingPasteboard), !draggedEntries.isEmpty else {
			return false
		}
		
		let contentsType = draggedFeedContentsType(draggedEntries)
		
		switch contentsType {
		case .singleNonLocal:
			let draggedNonLocalEntry = singleNonLocalEntry(from: draggedEntries)!
			return acceptSingleNonLocalEntryDrop(outlineView, draggedNonLocalEntry, parent: item as? OPMLEntry, index)
//		case .singleLocal:
//			return acceptLocalFeedsDrop(outlineView, draggedFeeds, parentNode, index)
//		case .multipleLocal:
//			return acceptLocalFeedsDrop(outlineView, draggedFeeds, parentNode, index)
		default:
			return false
		}

	}
	
}

private extension ViewController {

	enum DraggedEntriesContentsType {
		case empty, singleLocal, singleNonLocal, multipleLocal, multipleNonLocal, mixed
	}
	
	func draggedFeedContentsType(_ draggedEntries: Set<PasteboardEntry>) -> DraggedEntriesContentsType {
		
		if draggedEntries.isEmpty {
			return .empty
		}
		
		if draggedEntries.count == 1 {
			let entry = draggedEntries.first!
			return entry.isLocalEntry ? .singleLocal : .singleNonLocal
		}
		
		var hasLocalFeed = false
		var hasNonLocalFeed = false
		
		for entry in draggedEntries {
			if entry.isLocalEntry {
				hasLocalFeed = true
			} else {
				hasNonLocalFeed = true
			}
			if hasLocalFeed && hasNonLocalFeed {
				return .mixed
			}
		}
		
		if hasLocalFeed {
			return .multipleLocal
		}
		
 	 	return .multipleNonLocal
		
	}
	
	func singleNonLocalEntry(from entries: Set<PasteboardEntry>) -> PasteboardEntry? {
		guard entries.count == 1, let entry = entries.first else {
			return nil
		}
		return entry.isLocalEntry ? nil : entry
	}
	
	func acceptSingleNonLocalEntryDrop(_ outlineView: NSOutlineView, _ draggedEntry: PasteboardEntry, parent: OPMLEntry?, _ index: Int) -> Bool {
		
		currentDragData = (parent: parent, index: index)
		
		findFeed(draggedEntry.feedURL)
		return true
		
	}
	
}
