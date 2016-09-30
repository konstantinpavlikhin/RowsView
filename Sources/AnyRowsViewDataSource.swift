//
//  AnyRowsViewDataSource.swift
//  RowsView
//
//  Created by Konstantin Pavlikhin on 30.09.16.
//  Copyright © 2016 Konstantin Pavlikhin. All rights reserved.
//

import Foundation

func abstract(file: StaticString = #file, line: UInt = #line) -> Never  {
  fatalError("Method must be overridden", file: file, line: line)
}

// MARK: - Box base.

class AnyRowsViewDataSourceBoxBase<A: AnyObject>: RowsViewDataSource {
  // MARK: RowsViewDataSource Implementation

  func bottomRowForRowsView(rowsView: RowsView<A>) -> Bool {
    abstract()
  }

  func numberOfItemsForRowsView(rowsView: RowsView<A>, inRow row: RowsViewRow) -> Int {
    abstract()
  }

  func itemForRowsView(rowsView: RowsView<A>, atCoordinate coordinate: Coordinate) -> A {
    abstract()
  }

  func topRowVanishesInRowsView(rowsView: RowsView<A>) -> [Int] {
    abstract()
  }
}

// * * *.

// MARK: - Box.

class AnyRowsViewDataSourceBox<A: RowsViewDataSource>: AnyRowsViewDataSourceBoxBase<A.A> {
  private weak var base: A?

  // MARK: Initialization

  init(_ base: A) {
    self.base = base
  }

  // MARK: RowsViewDataSource Implementation

  override func bottomRowForRowsView(rowsView: RowsView<A.A>) -> Bool {
    if let b = base {
      return b.bottomRowForRowsView(rowsView: rowsView)
    } else {
      return false;
    }
  }

  override func numberOfItemsForRowsView(rowsView: RowsView<A.A>, inRow row: RowsViewRow) -> Int {
    if let b = base {
      return b.numberOfItemsForRowsView(rowsView: rowsView, inRow: row)
    } else {
      return 0;
    }
  }

  override func itemForRowsView(rowsView: RowsView<A.A>, atCoordinate coordinate: Coordinate) -> A.A {
    return base!.itemForRowsView(rowsView: rowsView, atCoordinate: coordinate)
  }

  override func topRowVanishesInRowsView(rowsView: RowsView<A.A>) -> [Int] {
    if let b = base {
      return b.topRowVanishesInRowsView(rowsView: rowsView)
    } else {
      return [];
    }
  }
}

// * * *.

// MARK: - Type-erased RowsViewDataSource.

public final class AnyRowsViewDataSource<A: AnyObject> : RowsViewDataSource {
  private let _box: AnyRowsViewDataSourceBoxBase<A>

  // MARK: Initialization

  // This class can be initialized with any RowsViewDataSource.
  init<S: RowsViewDataSource>(_ base: S) where S.A == A {
    _box = AnyRowsViewDataSourceBox(base)
  }

  // MARK: RowsViewDataSource Implementation

  public func bottomRowForRowsView(rowsView: RowsView<A>) -> Bool {
    return _box.bottomRowForRowsView(rowsView: rowsView)
  }

  public func numberOfItemsForRowsView(rowsView: RowsView<A>, inRow row: RowsViewRow) -> Int {
    return _box.numberOfItemsForRowsView(rowsView: rowsView, inRow: row)
  }

  public func itemForRowsView(rowsView: RowsView<A>, atCoordinate coordinate: Coordinate) -> A {
    return _box.itemForRowsView(rowsView: rowsView, atCoordinate: coordinate)
  }

  public func topRowVanishesInRowsView(rowsView: RowsView<A>) -> [Int] {
    return _box.topRowVanishesInRowsView(rowsView: rowsView)
  }
}
