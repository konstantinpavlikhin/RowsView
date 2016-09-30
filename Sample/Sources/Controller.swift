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

    label.isEditable = false

    label.isBordered = false

    label.drawsBackground = false

    label.alignment = .center

    label.font = NSFont.systemFont(ofSize: 24)

    // * * *.

    super.init(frame: frame)

    // * * *.

    wantsLayer = true

    layer?.backgroundColor = NSColor.red.cgColor

    layer?.borderWidth = 1

    // * * *.

    addSubview(label)

    label.translatesAutoresizingMaskIntoConstraints = false

    addConstraint(NSLayoutConstraint.init(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))

    addConstraint(NSLayoutConstraint.init(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
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

  // Replace layout.
  @IBOutlet var replaceLayoutPopupButton: NSPopUpButton!

  @IBOutlet var replaceLayoutAnimatedCheckbox: NSButton!

  @IBOutlet var replaceLayoutButton: NSButton!

  // * * *.

  var mePeer: Peer = Peer(name: "Me")

  fileprivate var rowToItems: [RowsViewRow: [Peer]] = [:]

  // * * *.

  internal override func awakeFromNib()
  {
    super.awakeFromNib()

    // * * *.

    for row in RowsViewRow.allRows()
    {
      rowToItems[row] = []
    }

    rowToItems[.top] = [Peer(name: "1"), Peer(name: "2"), Peer(name: "3")]

    rowToItems[.bottom] = [mePeer]

    // * * *.

    rowsView.dataSource = self

    rowsView.delegate = self

    rowsView.layoutObject = SeparatedRowsViewLayout()

    // * * *.

    rowsView.translatesAutoresizingMaskIntoConstraints = false

    window.contentView?.addSubview(rowsView)

    let views = ["rowsView": rowsView]

    window.contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[rowsView]|", options: NSLayoutFormatOptions(), metrics: nil, views: views))

    window.contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[rowsView]|", options: NSLayoutFormatOptions(), metrics: nil, views: views))

    // * * *.

    rowsView.reloadData()
  }

  // MARK: - Interface Callbacks

  @IBAction fileprivate func insertItem(_ sender: AnyObject?)
  {
    let peer = Peer(name: insertNameTextField.stringValue)

    // * * *.

    let index = inserIndexTextField.integerValue

    let row = (insertRowPopupButton.indexOfSelectedItem == 0 ? RowsViewRow.top : RowsViewRow.bottom)

    // * * *.

    rowToItems[row]!.insert(peer, at: index)

    // * * *.

    rowsView.insertItems(atCoordinates: [(index: index, row: row)], animated: insertAnimatedCheckbox.state == NSOnState)
  }

  @IBAction fileprivate func removeItem(_ sender: AnyObject?)
  {
    let index = removeIndexTextField.integerValue

    let row = (removeRowPopupButton.indexOfSelectedItem == 0 ? RowsViewRow.top : RowsViewRow.bottom)

    // * * *.

    rowToItems[row]!.remove(at: index)

    // * * *.

    rowsView.removeItems(atCoordinates: [(index: index, row: row)], animated: removeAnimatedCheckbox.state == NSOnState)
  }

  @IBAction fileprivate func moveItem(_ sender: AnyObject?)
  {
    let startIndex = moveFromIndexTextField.integerValue

    let startRow = (moveFromRowPopupButton.indexOfSelectedItem == 0 ? RowsViewRow.top : RowsViewRow.bottom)

    // * * *.

    let targetIndex = moveToIndexTextField.integerValue

    let targetRow = (moveToRowPopupButton.indexOfSelectedItem == 0 ? RowsViewRow.top : RowsViewRow.bottom)

    // * * *.

    rowToItems[targetRow]!.insert(rowToItems[startRow]!.remove(at: startIndex), at: targetIndex)

    // * * *.

    rowsView.moveItems(atCoordinates: [(index: startIndex, row: startRow)], toCoordinates: [(index: targetIndex, row: targetRow)], animated: moveAnimatedCheckbox.state == NSOnState)
  }

  @IBAction fileprivate func enlargeFirst(_ sender: AnyObject?)
  {
    rowToItems[.bottom]!.insert(rowToItems[.top]!.remove(at: 0), at: 0)

    rowToItems[.bottom]!.insert(rowToItems[.top]!.remove(at: 0), at: 0)

    // * * *.

    let from: [(Coordinate)] = [(index: 1, row: .top), (index: 2, row: .top)]

    let to: [(Coordinate)] = [(index: 0, row: .bottom), (index: 1, row: .bottom)]

    rowsView.moveItems(atCoordinates: from, toCoordinates: to, animated: moveAnimatedCheckbox.state == NSOnState)
  }

  @IBAction fileprivate func collapseFirst(_ sender: AnyObject?)
  {
    rowToItems[.top]!.insert(rowToItems[.bottom]!.remove(at: 0), at: 0)

    rowToItems[.top]!.insert(rowToItems[.bottom]!.remove(at: 0), at: 0)

    // * * *.

    let from: [(Coordinate)] = [(index: 0, row: .bottom), (index: 1, row: .bottom)]

    let to: [(Coordinate)] = [(index: 1, row: .top), (index: 2, row: .top)]

    rowsView.moveItems(atCoordinates: from, toCoordinates: to, animated: moveAnimatedCheckbox.state == NSOnState)
  }

  @IBAction fileprivate func replaceLayout(_ sender: AnyObject?)
  {
    let newLayout = (replaceLayoutPopupButton.indexOfSelectedItem == 0 ? SeparatedRowsViewLayout() : OverlappingRowsViewLayout())

    if replaceLayoutAnimatedCheckbox.state == NSOnState
    {
      NSAnimationContext.runAnimationGroup({ (context) in
        context.allowsImplicitAnimation = true

        rowsView.layoutObject = newLayout

        rowsView.layoutSubtreeIfNeeded()
      }, completionHandler: nil)
    }
    else
    {
      rowsView.layoutObject = newLayout
    }
  }

  // MARK: - RowsViewDataSource Protocol Implementation

  func bottomRowForRowsView(rowsView: RowsView) -> Bool
  {
    if let bottomItems = rowToItems[.bottom]
    {
      return bottomItems.count > 0
    }
    else
    {
      return false
    }
  }

  func numberOfItemsForRowsView(rowsView: RowsView, inRow row: RowsViewRow) -> Int
  {
    return rowToItems[row]!.count
  }

  func itemForRowsView(rowsView: RowsView, atCoordinate coordinate: Coordinate) -> AnyObject
  {
    return rowToItems[coordinate.row]![coordinate.index]
  }

  func topRowVanishesInRowsView(rowsView: RowsView) -> [Int]
  {
    let indices = Array(rowToItems[.bottom]!.indices)

    rowToItems[.top] = rowToItems[.bottom]!.remove(atIndices: indices)

    return indices
  }

  // MARK: - RowsViewDelegate Protocol Implementation

  func cellForItemInRowsView(rowsView: RowsView, atCoordinate coordinate: Coordinate) -> RowsViewCell
  {
    return PeerCell(frame: NSZeroRect)
  }
}
