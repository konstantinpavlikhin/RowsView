//
//  DummyDelegate.swift
//  CAFun
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

class PeerCell: UsersLayoutViewCell
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

    let views = ["label": label]

    addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))

    addConstraint(NSLayoutConstraint(item: label, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0))
  }
  
  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }
}

// * * *.

class DummyDelegate: NSObject, UsersLayoutViewDataSource, UsersLayoutViewDelegate
{
  @IBOutlet var window: NSWindow!

  let usersLayoutView = UsersLayoutView(frame: NSZeroRect)

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

  private var rowToItems: [UsersLayoutViewRow: [Peer]] = [:]

  // * * *.

  internal override func awakeFromNib()
  {
    super.awakeFromNib()

    // * * *.

    for row in UsersLayoutViewRow.allRows()
    {
      rowToItems[row] = []
    }

    rowToItems[.Top] = [Peer(name: "1"), Peer(name: "2"), Peer(name: "3")]

    rowToItems[.Bottom] = [mePeer]

    // * * *.

    usersLayoutView.dataSource = self

    usersLayoutView.delegate = self

    // * * *.

    usersLayoutView.translatesAutoresizingMaskIntoConstraints = false

    window.contentView?.addSubview(usersLayoutView)

    let views = ["usersLayoutView": usersLayoutView]

    window.contentView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[usersLayoutView]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))

    window.contentView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[usersLayoutView]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views))

    // * * *.

    usersLayoutView.reloadData()
  }

  // MARK: - Interface Callbacks

  @IBAction private func insertItem(sender: AnyObject?)
  {
    let peer = Peer(name: insertNameTextField.stringValue)

    // * * *.

    let index = inserIndexTextField.integerValue

    let row = (insertRowPopupButton.indexOfSelectedItem == 0 ? UsersLayoutViewRow.Top : UsersLayoutViewRow.Bottom)

    // * * *.

    rowToItems[row]!.insert(peer, atIndex: index)

    // * * *.

    usersLayoutView.insertItems(atCoordinates: [(index: index, inRow: row)], animated: insertAnimatedCheckbox.state == NSOnState)
  }

  @IBAction private func removeItem(sender: AnyObject?)
  {
    let index = removeIndexTextField.integerValue

    let row = (removeRowPopupButton.indexOfSelectedItem == 0 ? UsersLayoutViewRow.Top : UsersLayoutViewRow.Bottom)

    // * * *.

    rowToItems[row]!.removeAtIndex(index)

    // * * *.

    usersLayoutView.removeItems(atCoordinates: [(index: index, inRow: row)], animated: removeAnimatedCheckbox.state == NSOnState)
  }

  @IBAction private func moveItem(sender: AnyObject?)
  {
    let startIndex = moveFromIndexTextField.integerValue

    let startRow = (moveFromRowPopupButton.indexOfSelectedItem == 0 ? UsersLayoutViewRow.Top : UsersLayoutViewRow.Bottom)

    // * * *.

    let targetIndex = moveToIndexTextField.integerValue

    let targetRow = (moveToRowPopupButton.indexOfSelectedItem == 0 ? UsersLayoutViewRow.Top : UsersLayoutViewRow.Bottom)

    // * * *.

    rowToItems[targetRow]!.insert(rowToItems[startRow]!.removeAtIndex(startIndex), atIndex: targetIndex)

    // * * *.

    usersLayoutView.moveItems(atCoordinates: [(index: startIndex, inRow: startRow)], toCoordinates: [(index: targetIndex, inRow: targetRow)], animated: moveAnimatedCheckbox.state == NSOnState)
  }

  @IBAction private func enlargeFirst(sender: AnyObject?)
  {
    rowToItems[.Bottom]!.insert(rowToItems[.Top]!.removeAtIndex(0), atIndex: 0)

    rowToItems[.Bottom]!.insert(rowToItems[.Top]!.removeAtIndex(0), atIndex: 0)

    // * * *.

    let from: [(Coordinate)] = [(index: 1, inRow: .Top), (index: 2, inRow: .Top)]

    let to: [(Coordinate)] = [(index: 0, inRow: .Bottom), (index: 1, inRow: .Bottom)]

    usersLayoutView.moveItems(atCoordinates: from, toCoordinates: to, animated: moveAnimatedCheckbox.state == NSOnState)
  }

  @IBAction private func collapseFirst(sender: AnyObject?)
  {
    rowToItems[.Top]!.insert(rowToItems[.Bottom]!.removeAtIndex(0), atIndex: 0)

    rowToItems[.Top]!.insert(rowToItems[.Bottom]!.removeAtIndex(0), atIndex: 0)

    // * * *.

    let from: [(Coordinate)] = [(index: 0, inRow: .Bottom), (index: 1, inRow: .Bottom)]

    let to: [(Coordinate)] = [(index: 1, inRow: .Top), (index: 2, inRow: .Top)]

    usersLayoutView.moveItems(atCoordinates: from, toCoordinates: to, animated: moveAnimatedCheckbox.state == NSOnState)
  }

  // MARK: - UsersLayoutViewDataSource Protocol Implementation

  func numberOfItemsForUsersLayoutView(usersLayoutView usersLayoutView: UsersLayoutView, inRow row: UsersLayoutViewRow) -> Int
  {
    return rowToItems[row]!.count
  }

  func itemForUsersLayoutView(usersLayoutView usersLayoutView: UsersLayoutView, atCoordinate coordinate: Coordinate) -> AnyObject
  {
    return rowToItems[coordinate.inRow]![coordinate.index]
  }

  // Включается enlarged-режим. Айтемы из верхнего ряда будут перемещены в начало нижнего ряда -> [Int: индексы в верхнем ряду].
  func willEnterEnlargedModeInUsersLayoutView(usersLayoutView usersLayoutView: UsersLayoutView, forItemAtCoordinate coordinate: Coordinate, topRowItemsIndicesToDepose indices: [Int]) // Indices of items in top row that were deposed to the beginning of a bottom row.
  {
    // Nothing to do.
  }

  func didEnterEnlargedModeInUsersLayoutView(usersLayoutView usersLayoutView: UsersLayoutView, forItemAtCoordinate coordinate: Coordinate, deposedTopRowItemsIndices indices: [Int]) // Indices of items in top row that were deposed to the beginning of a bottom row.
  {
    for index in indices.reverse()
    {
      let deposedPeer = rowToItems[.Top]!.removeAtIndex(index)

      rowToItems[.Bottom]!.insert(deposedPeer, atIndex: 0)
    }
  }

  // Enlarged-режим выключен. В верхнем ряду освобождается место. Что переместить туда из нижнего ряда? (индексы айтемов в нижнем ряду: до уменьшаемого, индексы айтемов в нижнем ряду: после уменьшаемого).
  func willExitEnlargedModeInUsersLayoutView(usersLayoutView usersLayoutView: UsersLayoutView) -> (bottomRowItemsToPutBefore: [Int]?, bottomRowItemsToPutAfter: [Int]?)
  {
    // Перестроить модель.
    let indices = [0, 1]

    for index in indices
    {
      let removedElement = rowToItems[.Bottom]!.removeAtIndex(index)

      rowToItems[.Top]!.append(removedElement)
    }

    return (nil, indices)
  }

  func didExitEnlargedModeInUsersLayoutView(usersLayoutView usersLayoutView: UsersLayoutView)
  {
    // Nothing to do.
  }

  // MARK: - UsersLayoutViewDelegate Protocol Implementation

  func cellForItemInUsersLayoutView(usersLayoutView usersLayoutView: UsersLayoutView, atCoordinate coordinate: Coordinate) -> UsersLayoutViewCell
  {
    return PeerCell(frame: NSZeroRect)
  }
}
