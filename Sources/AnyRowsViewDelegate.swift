//
//  AnyRowsViewDelegate.swift
//  RowsView
//
//  Created by Konstantin Pavlikhin on 30.09.16.
//  Copyright © 2016 Konstantin Pavlikhin. All rights reserved.
//

import Foundation

// MARK: - Box base.

class AnyRowsViewDelegateBoxBase<A: AnyObject>: RowsViewDelegate {
  // MARK: RowsViewDelegate Implementation

  func cellForItemInRowsView(rowsView: RowsView<A>, atCoordinate coordinate: Coordinate) -> RowsViewCell {
    abstract()
  }
}

// * * *.

// MARK: - Box.

class AnyRowsViewDelegateBox<A: RowsViewDelegate>: AnyRowsViewDelegateBoxBase<A.A> {
  private weak var base: A?

  // MARK: Initialization

  init(_ base: A) {
    self.base = base
  }

  // MARK: RowsViewDelegate Implementation

  override func cellForItemInRowsView(rowsView: RowsView<A.A>, atCoordinate coordinate: Coordinate) -> RowsViewCell {
    if let b = base {
      return b.cellForItemInRowsView(rowsView: rowsView, atCoordinate: coordinate)
    } else {
      return RowsViewCell(frame: NSZeroRect)
    }
  }
}

// * * *.

// MARK: - Type-erased RowsViewDelegate.

public final class AnyRowsViewDelegate<A: AnyObject> : RowsViewDelegate {
  private let _box: AnyRowsViewDelegateBoxBase<A>

  // MARK: Initialization

  // This class can be initialized with any RowsViewDelegate.
  init<S: RowsViewDelegate>(_ base: S) where S.A == A {
    _box = AnyRowsViewDelegateBox(base)
  }

  // MARK: RowsViewDelegate Implementation

  public func cellForItemInRowsView(rowsView: RowsView<A>, atCoordinate coordinate: Coordinate) -> RowsViewCell {
    return _box.cellForItemInRowsView(rowsView: rowsView, atCoordinate: coordinate)
  }
}
