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
	
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		
		switch tableColumn?.identifier.rawValue {
		case "nameColumn":
			if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "nameCell"), owner: nil) as? NSTableCellView {
				let entry = item as! OPMLEntry
				if entry.isFolder {
					cell.imageView?.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
					cell.textField?.isEditable = true
				} else {
					cell.imageView?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)?.withSymbolConfiguration(.init(pointSize: 14, weight: .light))
					cell.textField?.isEditable = false
				}
				cell.imageView?.contentTintColor = NSColor.controlAccentColor
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
					cell.textField?.stringValue = feed.feedURL ?? ""
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
		return item as? NSPasteboardWriting
	}

	func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
		guard let draggedEntries = OPMLEntry.entries(with: info.draggingPasteboard), !draggedEntries.isEmpty else {
			return []
		}
		
		guard !(item is OPMLFeed) else {
			return []
		}
		
		if let proposedEntry = item as? OPMLEntry, proposedEntry.address == draggedEntries.first?.address {
			return []
		}
		
		if (info.draggingSource as AnyObject) === outlineView {
			return .move
		} else {
			if draggedEntries.first?.isFolder ?? true {
				return []
			} else {
				return .copy
			}
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
		guard let draggedEntries = OPMLEntry.entries(with: info.draggingPasteboard), !draggedEntries.isEmpty else {
			return false
		}
		
		if (info.draggingSource as AnyObject) === outlineView {
			acceptLocalDrop(outlineView, draggedEntries, parent: item as? OPMLEntry, index)
		} else {
			acceptNonLocalDrop(outlineView, draggedEntries, parent: item as? OPMLEntry, index)
		}
		
		return true
	}
	
}

private extension ViewController {

	func acceptNonLocalDrop(_ outlineView: NSOutlineView, _ draggedEntries: [OPMLEntry], parent: OPMLEntry?, _ index: Int) {
		for entry in draggedEntries {
			if let feed = entry as? OPMLFeed, let feedURL = feed.feedURL {
				currentDragData = (parent: parent, index: index)
				findFeed(feedURL)
			}
		}
	}
	
	func acceptLocalDrop(_ outlineView: NSOutlineView, _ draggedEntries: [OPMLEntry], parent: OPMLEntry?, _ index: Int) {
		for foundEntries in draggedEntries.compactMap({ $0.address }).compactMap({ document?.opmlDocument.entry(for: $0) }) {
			moveEntry(foundEntries, toParent: parent, toChildIndex: index)
		}
	}
	
}
