//
//  Controller.swift
//  RowsView
//
//  Created by Konstantin Pavlikhin on 30.08.16.
//  Copyright © 2016 Konstantin Pavlikhin. All rights reserved.
//

import Foundation

import AppKit

// * * *.

class Peer
{
  internal let name: String

  init(name: String)
  {
    self.name = name
  }
}

// * * *.

class PeerCell: RowsViewCell
{
  let label: NSTextField

  override var objectValue: AnyObject?
  {
    didSet
    {
      if objectValue != nil
      {
        let peer = objectValue as! Peer

        label.objectValue = peer.name
      }
    }
  }

  override init(frame: NSRect)
  {
    label = NSTextField(frame: NSZeroRect)

    label.editable = false

    label.bordered = false

    label.drawsBackground = false

    label.alignment = .Center

    label.font = NSFont.systemFontOfSize(24)

    // * * *.

    super.init(frame: frame)

    // * * *.

    wantsLayer = true

    layer?.backgroundColor = NSColor.redColor().CGColor

    layer?.borderWidth = 1

    // * * *.

    label.translatesAutoresizingMaskIntoConstraints = false

    addSubview(label)
  }

  override func layout()
  {
    let x = NSMinX(self.bounds) + (NSWidth(self.bounds) - NSWidth(label.frame)) / 2.0

    let y = NSMinY(self.bounds) + (NSHeight(self.bounds) - NSHeight(label.frame)) / 2.0

    let rect = NSMakeRect(x, y, label.frame.size.width, label.frame.size.height)

    label.frame = backingAlignedRect(rect, options: .AlignAllEdgesNearest)
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }
}

// * * *.

class Controller: NSObject, RowsViewDataSource, RowsViewDelegate
{
  @IBOutlet var window: NSWindow!

  let rowsView = RowsView(frame: NSZeroRect)

  // * * *.

  @IBOutlet var inspector: NSPanel!

  // Insert.
  @IBOutlet var insertNameTextField: NSTextField!

  @IBOutlet var inserIndexTextField: NSTextField!

  @IBOutlet var insertRowPopupButton: NSPopUpButton!

  @IBOutlet var insertAnimatedCheckbox: NSButton!

  @IBOutlet var insertButton: NSButton!

  // Insert.
  @IBOutlet var removeIndexTextField: NSTextField!

  @IBOutlet var removeRowPopupButton: NSPopUpButton!

  @IBOutlet var removeAnimatedCheckbox: NSButton!

  @IBOutlet var removeButton: NSButton!

  // Move.
  @IBOutlet var moveFromIndexTextField: NSTextField!

  @IBOutlet var moveFromRowPopupButton: NSPopUpButton!

  @IBOutlet var moveToIndexTextField: NSTextField!

  @IBOutlet var moveToRowPopupButton: NSPopUpButton!

  @IBOutlet var moveAnimatedCheckbox: NSButton!

  @IBOutlet var moveButton: NSButton!

  // * * *.

  var mePeer: Peer = Peer(name: "Me")

  private var rowToItems: [RowsViewRow: [Peer]] = [:]

  // * * *.

  internal override func awakeFromNib()
  {
    super.awakeFromNib()

    // * * *.

    for row in RowsViewRow.allRows()
    {
      rowToItems[row] = []
    }

    rowToItems[.Top] = [Peer(name: "1"), Peer(name: "2"), Peer(name: "3")]

    rowToItems[.Bottom] = [mePeer]

    // * * *.

    rowsView.dataSource = self

    rowsView.delegate = self

    // * * *.

    rowsView.translatesAutoresizingMaskIntoConstraints = false

    window.contentView?.addSubview(rowsView)

    let views = ["rowsView": rowsView]

    window.contentView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[rowsView]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))

    window.contentView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[rowsView]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))

    // * * *.

    rowsView.reloadData()
  }

  // MARK: - Interface Callbacks

  @IBAction private func insertItem(sender: AnyObject?)
  {
    let peer = Peer(name: insertNameTextField.stringValue)

    // * * *.

    let index = inserIndexTextField.integerValue

    let row = (insertRowPopupButton.indexOfSelectedItem == 0 ? RowsViewRow.Top : RowsViewRow.Bottom)

    // * * *.

    rowToItems[row]!.insert(peer, atIndex: index)

    // * * *.

    rowsView.insertItems(atCoordinates: [(index: index, row: row)], animated: insertAnimatedCheckbox.state == NSOnState)
  }

  @IBAction private func removeItem(sender: AnyObject?)
  {
    let index = removeIndexTextField.integerValue

    let row = (removeRowPopupButton.indexOfSelectedItem == 0 ? RowsViewRow.Top : RowsViewRow.Bottom)

    // * * *.

    rowToItems[row]!.removeAtIndex(index)

    if row == .Top
    {
      if rowToItems[.Top]!.count == 0
      {
        rowToItems[.Top] = rowToItems[.Bottom]

        rowToItems[.Bottom] = []
      }
    }

    // * * *.

    rowsView.removeItems(atCoordinates: [(index: index, row: row)], animated: removeAnimatedCheckbox.state == NSOnState)
  }

  @IBAction private func moveItem(sender: AnyObject?)
  {
    let startIndex = moveFromIndexTextField.integerValue

    let startRow = (moveFromRowPopupButton.indexOfSelectedItem == 0 ? RowsViewRow.Top : RowsViewRow.Bottom)

    // * * *.

    let targetIndex = moveToIndexTextField.integerValue

    let targetRow = (moveToRowPopupButton.indexOfSelectedItem == 0 ? RowsViewRow.Top : RowsViewRow.Bottom)

    // * * *.

    rowToItems[targetRow]!.insert(rowToItems[startRow]!.removeAtIndex(startIndex), atIndex: targetIndex)

    // * * *.

    if targetRow == .Bottom
    {
      if rowToItems[.Top]!.count == 0
      {
        rowToItems[.Top] = rowToItems[.Bottom]

        rowToItems[.Bottom] = []
      }
    }

    // * * *.

    rowsView.moveItems(atCoordinates: [(index: startIndex, row: startRow)], toCoordinates: [(index: targetIndex, row: targetRow)], animated: moveAnimatedCheckbox.state == NSOnState)
  }

  @IBAction private func enlargeFirst(sender: AnyObject?)
  {
    rowToItems[.Bottom]!.insert(rowToItems[.Top]!.removeAtIndex(0), atIndex: 0)

    rowToItems[.Bottom]!.insert(rowToItems[.Top]!.removeAtIndex(0), atIndex: 0)

    // * * *.

    let from: [(Coordinate)] = [(index: 1, row: .Top), (index: 2, row: .Top)]

    let to: [(Coordinate)] = [(index: 0, row: .Bottom), (index: 1, row: .Bottom)]

    rowsView.moveItems(atCoordinates: from, toCoordinates: to, animated: moveAnimatedCheckbox.state == NSOnState)
  }

  @IBAction private func collapseFirst(sender: AnyObject?)
  {
    rowToItems[.Top]!.insert(rowToItems[.Bottom]!.removeAtIndex(0), atIndex: 0)

    rowToItems[.Top]!.insert(rowToItems[.Bottom]!.removeAtIndex(0), atIndex: 0)

    // * * *.

    let from: [(Coordinate)] = [(index: 0, row: .Bottom), (index: 1, row: .Bottom)]

    let to: [(Coordinate)] = [(index: 1, row: .Top), (index: 2, row: .Top)]

    rowsView.moveItems(atCoordinates: from, toCoordinates: to, animated: moveAnimatedCheckbox.state == NSOnState)
  }

  // MARK: - RowsViewDataSource Protocol Implementation

  func numberOfItemsForRowsView(rowsView rowsView: RowsView, inRow row: RowsViewRow) -> Int
  {
    return rowToItems[row]!.count
  }

  func itemForRowsView(rowsView rowsView: RowsView, atCoordinate coordinate: Coordinate) -> AnyObject
  {
    return rowToItems[coordinate.row]![coordinate.index]
  }

  // MARK: - RowsViewDelegate Protocol Implementation

  func cellForItemInRowsView(rowsView rowsView: RowsView, atCoordinate coordinate: Coordinate) -> RowsViewCell
  {
    return PeerCell(frame: NSZeroRect)
  }
}
