//Copyright © 2019 Vincode, Inc. All rights reserved.

import AppKit
import RSCore
import RSParser

class ViewController: NSViewController {

	@IBOutlet weak var titleTextField: NSTextField!
	@IBOutlet weak var feedOutlineView: NSOutlineView!

	private let folderImage: NSImage? = {
		return NSImage(named: "NSFolder")
	}()
	
	private let faviconImage: NSImage? = {
		let path = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/BookmarkIcon.icns"
		return NSImage(contentsOfFile: path)
	}()

	var document: Document {
		return self.view.window?.windowController?.document as! Document
	}

	var opmlDocument: RSOPMLDocument?

	override func viewDidLoad() {
		super.viewDidLoad()
		feedOutlineView.delegate = self
		feedOutlineView.dataSource = self
	}

	override func viewDidAppear() {
		
		super.viewDidAppear()
		if document.opmlDocument == nil {
			return
		}
		
		opmlDocument = document.opmlDocument
		titleTextField.stringValue = opmlDocument!.title
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
			return opmlDocument!.children![index]
		}
		
		let opml = item as! RSOPMLItem
		return opml.children![index]
		
	}
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		
		if item == nil {
			return opmlDocument?.children?.count ?? 0
		}
		
		let opml = item as! RSOPMLItem
		return opml.children?.count ?? 0
		
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		let opml = item as! RSOPMLItem
		return opml.isFolder
	}
	
}

// MARK: NSOutlineViewDelegate

extension ViewController: NSOutlineViewDelegate {
	
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		
		switch tableColumn?.identifier.rawValue {
		case "nameColumn":
			if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "nameCell"), owner: nil) as? NSTableCellView {
				if let opmlDoc = item as? RSOPMLDocument {
					cell.imageView?.image = folderImage
					cell.textField?.stringValue = titleOrUntitled(opmlDoc.title)
				} else if let opmlItem = item as? RSOPMLItem {
					if opmlItem.children?.count ?? 0 > 0 {
						cell.imageView?.image = folderImage
					} else {
						cell.imageView?.image = faviconImage
					}
					cell.textField?.stringValue = titleOrUntitled(opmlItem.titleFromAttributes)
				}
				return cell
			}
		case "pageColumn":
			if let opmlItem = item as? RSOPMLItem, let feedSpecifier = opmlItem.feedSpecifier {
				if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "pageCell"), owner: nil) as? NSTableCellView {
					cell.textField?.stringValue = feedSpecifier.homePageURL ?? ""
					return cell
				}
			}
		case "feedColumn":
			if let opmlItem = item as? RSOPMLItem, let feedSpecifier = opmlItem.feedSpecifier {
				if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "feedCell"), owner: nil) as? NSTableCellView {
					cell.textField?.stringValue = feedSpecifier.feedURL
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
		let opml = item as! RSOPMLItem
		return opml.children?.count ?? 0 > 0
	}
	
	func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
		return true
	}
	
	func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
	}
	
	func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
		guard let opmlItem = item as? RSOPMLItem, let feedURL = opmlItem.feedSpecifier?.feedURL else {
			return nil
		}
		return URLPasteboardWriter(urlString: feedURL)
	}
	
	func outlineViewSelectionDidChange(_ notification: Notification) {
		
	}
	
}

private extension ViewController {
	
	func titleOrUntitled(_ title: String?) -> String {
		if title == nil || title?.count ?? 0 < 1 {
			return NSLocalizedString("(Untitled)", comment: "Untitled entity")
		}
		return title!
	}

}
