//
//  RowsView.swift
//  RowsView
//
//  Created by Konstantin Pavlikhin on 26.08.16.
//  Copyright © 2016 Konstantin Pavlikhin. All rights reserved.
//

import Cocoa

// MARK: - RowsViewRow

public enum RowsViewRow
{
  case top

  case bottom

  public static func allRows() -> [RowsViewRow]
  {
    return [.top, .bottom]
  }
}

// MARK: - Coordinate

public typealias Coordinate = (index: Int, row: RowsViewRow)

// MARK: - RowsViewCell

open class RowsViewCell: NSView
{
  internal var objectValue: AnyObject?
}

// MARK: - RowsViewDataSource

public protocol RowsViewDataSource
{
  func bottomRowForRowsView(rowsView: RowsView) -> Bool

  func numberOfItemsForRowsView(rowsView: RowsView, inRow row: RowsViewRow) -> Int

  func itemForRowsView(rowsView: RowsView, atCoordinate coordinate: Coordinate) -> AnyObject

  // Возвращает индексы элементов в нижнем ряду, которые будут перемещены на место исчезнувшего верхнего ряда.
  func topRowVanishesInRowsView(rowsView: RowsView) -> [Int]
}

// * * *.

public protocol RowsViewDelegate
{
  func cellForItemInRowsView(rowsView: RowsView, atCoordinate coordinate: Coordinate) -> RowsViewCell
}

// MARK: - RowsView

open class RowsView: NSView
{
  open var dataSource: RowsViewDataSource? = nil

  open var delegate: RowsViewDelegate? = nil

  // * * *.

  fileprivate var rowToItems: [RowsViewRow: [AnyObject]] = [:]

  fileprivate var rowToCells: [RowsViewRow: [RowsViewCell]] = [:]

  // MARK: - Initialization

  override init(frame frameRect: NSRect)
  {
    for row in RowsViewRow.allRows()
    {
      rowToItems[row] = []

      rowToCells[row] = []
    }

    // * * *.

    super.init(frame: frameRect)

    self.wantsLayer = true

    self.layer?.backgroundColor = NSColor.yellow.withAlphaComponent(0.5).cgColor
  }
  
  required public init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - NSView Overrides

  override open func layout()
  {
    super.layout()

    // * * *.

    for row in RowsViewRow.allRows()
    {
      let cells = rowToCells[row]!

      guard cells.count > 0 else
      {
        continue
      }

      let frames = framesForEquallySizedAndSpacedCells(count: cells.count, inRow: row, hasBottomRow: rowToCells[.bottom]!.count > 0)

      for i in 0..<cells.count
      {
        cells[i].frame = frames[i]
      }
    }
  }

  // MARK: - Public Methods

  // Полностью сбрасывает состояние и перезапрашивает у датасурса все необходимое.
  open func reloadData()
  {
    clearState()

    // * * *.

    assert(dataSource != nil, "Data source not set.")

    assert(delegate != nil, "Delegate not set.")

    // * * *.

    let rowsToQuery: [RowsViewRow] = [.top] + (dataSource!.bottomRowForRowsView(rowsView: self) ? [.bottom] : [])

    for row in rowsToQuery
    {
      let numberOfItemsInRow = dataSource!.numberOfItemsForRowsView(rowsView: self, inRow: row)

      for i in 0..<numberOfItemsInRow
      {
        let coordinate = (i, row)

        // * * *.

        let item = dataSource!.itemForRowsView(rowsView: self, atCoordinate: coordinate)

        rowToItems[row]!.append(item)

        // * * *.

        let cell = delegate!.cellForItemInRowsView(rowsView: self, atCoordinate: coordinate)

        cell.objectValue = item

        rowToCells[row]!.append(cell)

        //cell.layerContentsRedrawPolicy = .BeforeViewResize

        addSubview(cell)
      }
    }

    needsLayout = true
  }

  open func numberOfItems(inRow row: RowsViewRow) -> Int
  {
    return rowToItems[row]!.count
  }

  open func item(atCoordinate coordinate: Coordinate) -> AnyObject
  {
    return rowToItems[coordinate.row]![coordinate.index]
  }

  // Вставляет элементы по данным координатам.
  open func insertItems(atCoordinates coordinates: [Coordinate], animated: Bool)
  {
    // Сходить в датасурса и запросить модельные объекты.
    let items = coordinates.map { coordinate -> AnyObject in
      return dataSource!.itemForRowsView(rowsView: self, atCoordinate: coordinate)
    }

    let wasEmptyBeforeInsertionsHappened = (rowToItems[.top]!.count == 0) && (rowToItems[.bottom]!.count == 0)

    let hadBottomRowBeforeInsertionsHappened = rowToItems[.bottom]!.count > 0

    // Элементы могут быть вставлены либо в верхний, либо в нижний ряд.
    for (coordinate, item) in zip(coordinates, items)
    {
      rowToItems[coordinate.row]!.insert(item, at: coordinate.index)
    }

    // Вычислить, какие ряды зааффекчены и сколько в каждый производится вставок.
    var affectedRowsToInsertionsCount: [RowsViewRow: Int] = [:]

    for coordinate in coordinates
    {
      if let insertionsCount = affectedRowsToInsertionsCount[coordinate.row]
      {
        affectedRowsToInsertionsCount[coordinate.row] = insertionsCount + 1
      }
      else
      {
        affectedRowsToInsertionsCount[coordinate.row] = 1
      }
    }

    // Если до изменений нижний ряд отсутствовал, но в него производятся вставки...
    if !hadBottomRowBeforeInsertionsHappened && affectedRowsToInsertionsCount[.bottom] != nil
    {
      if affectedRowsToInsertionsCount[.top] == nil
      {
        // Вставок не было, но нам надо перерассчитать все фреймы в верхнем ряду.
        affectedRowsToInsertionsCount[.top] = 0
      }
    }

    // Закешировать финальные фреймы ячеек.
    var rowsToFinalFrames: [RowsViewRow: [NSRect]] = [:]

    for (row, insertionsCount) in affectedRowsToInsertionsCount
    {
      rowsToFinalFrames[row] = framesForEquallySizedAndSpacedCells(count: (rowToCells[row]!.count + insertionsCount), inRow: row, hasBottomRow: rowToItems[.bottom]!.count > 0)
    }

    // Смапить координаты в словарь [RowsViewRow: [Int]], где [Int] — массив индектов вставок в данном ряду.
    var affectedRowsToInsertionIndices: [RowsViewRow: [Int]] = [:]

    for (index, row) in coordinates
    {
      if var insertionIndices = affectedRowsToInsertionIndices[row]
      {
        insertionIndices.append(index)

        affectedRowsToInsertionIndices[row] = insertionIndices
      }
      else
      {
        affectedRowsToInsertionIndices[row] = [index]
      }
    }

    // Сначала необходимо раздвинуть существующие элементы, чтобы освободить место под вставку.
    var rowsToInsertionFrames: [RowsViewRow: [NSRect]] = [:]

    for (row, insertionIndices) in affectedRowsToInsertionIndices
    {
      let indicesSortedByAscending = insertionIndices.sorted {$0 < $1}

      rowsToInsertionFrames[row] = rowsToFinalFrames[row]!.remove(atIndices: indicesSortedByAscending)
    }

    if(!wasEmptyBeforeInsertionsHappened)
    {
      if animated
      {
        NSAnimationContext.runAnimationGroup({ (animationContext) in
          animationContext.duration = 0.5

          animationContext.timingFunction = nil

          animationContext.allowsImplicitAnimation = false

          for (row, frames) in rowsToFinalFrames
          {
            for i in 0..<self.rowToCells[row]!.count
            {
              let currentFrame = self.rowToCells[row]![i].frame

              let animation = RowsView.animationForMovingCellApart(currentFrame, targetFrame: frames[i])

              self.rowToCells[row]![i].animations = ["frame": animation]

              self.rowToCells[row]![i].animator().frame = frames[i]
            }
          }
        }, completionHandler: nil)
      }
      else
      {
        for (row, frames) in rowsToFinalFrames
        {
          for i in 0..<self.rowToCells[row]!.count
          {
            self.rowToCells[row]![i].frame = frames[i]
          }
        }
      }
    }

    // Сходить в делегата и запросить ячейки.
    let cells = coordinates.map { (coordinate) -> RowsViewCell in
      let cell = delegate!.cellForItemInRowsView(rowsView: self, atCoordinate: coordinate)

      cell.wantsLayer = true

      return cell
    }

    // Задать ячейкам модельный объект.
    for (cell, item) in zip(cells, items)
    {
      cell.objectValue = item
    }

    // Потом необходимо вставить новые элементы с опциональной анимацией fade-in.
    let zippedCoordinatesAndCells = zip(coordinates, cells)

    let zippedCoordinatesAndCellsSortedByAscendingIndex = zippedCoordinatesAndCells.sorted { (a, b) -> Bool in
      return a.0.index < b.0.index
    }

    for (coordinate, cell) in zippedCoordinatesAndCellsSortedByAscendingIndex
    {
      rowToCells[coordinate.row]!.insert(cell, at: coordinate.index)

      addSubview(cell)
    }

    var uglyMutableIndex = 0

    for (coordinate, cell) in zippedCoordinatesAndCellsSortedByAscendingIndex
    {
      cell.frame = rowsToInsertionFrames[coordinate.row]![uglyMutableIndex]

      uglyMutableIndex += 1

      if animated
      {
        NSAnimationContext.runAnimationGroup({ (animationContext) in
          animationContext.duration = 0.5

          animationContext.timingFunction = nil

          animationContext.allowsImplicitAnimation = false

          let animation = RowsView.animationForFading(fromAlpha: 0, toAlpha: 1, beginTime: CACurrentMediaTime() + (wasEmptyBeforeInsertionsHappened ? 0 : 0.5))

          cell.animations = ["alphaValue": animation]

          cell.layer?.add(animation, forKey: "opacity")

          cell.animator().alphaValue = 1
        }, completionHandler: nil)
      }
    }
  }

  open func moveItems(atCoordinates: [Coordinate], toCoordinates: [Coordinate], animated: Bool)
  {
    assert(atCoordinates.count == toCoordinates.count, "Initial and target coordinate arrays are of different length.")

    // * * *.

    let transitionsAsIs = zip(atCoordinates, toCoordinates)

    // * * *.

    let transitionsSortedByDescendingStartingIndices = transitionsAsIs.sorted { (a, b) -> Bool in
      return a.0.index > b.0.index
    }

    // * * *.

    var itemsAndCells: [(AnyObject, RowsViewCell)] = []

    for (atCoordinate, _) in transitionsSortedByDescendingStartingIndices
    {
      // Изъять объекты из кеша модели со старых мест (для каждого ряда).
      let removedItem = rowToItems[atCoordinate.row]!.remove(at: atCoordinate.index)

      // Изъять ячейки со старых рядов.
      let removedCell = rowToCells[atCoordinate.row]!.remove(at: atCoordinate.index)

      itemsAndCells.append((removedItem, removedCell))
    }

    // * * *.

    let transitionsZippedWithItemAndCellTuples = zip(transitionsSortedByDescendingStartingIndices, itemsAndCells)

    let transitionsZippedWithItemAndCellTuplesSortedByAscendingTargetIndices = transitionsZippedWithItemAndCellTuples.sorted { (a, b) -> Bool in
      return a.0.1.index < b.0.1.index
    }

    for (transition, itemAndCell) in transitionsZippedWithItemAndCellTuplesSortedByAscendingTargetIndices
    {
      let targetCoordinate = transition.1

      // Поместить объекты в кеш модели на новые места (для каждого ряда).
      rowToItems[targetCoordinate.row]!.insert(itemAndCell.0, at: targetCoordinate.index)

      // Поместить ячейки в новые ряды.
      rowToCells[targetCoordinate.row]!.insert(itemAndCell.1, at: targetCoordinate.index)
    }

    // Рассчитать лейаут для всех ячеек, опционально анимируя изменения.

    var affectedRowsWithPossibleDuplicates: [RowsViewRow] = []

    affectedRowsWithPossibleDuplicates.append(contentsOf: atCoordinates.map { (coordinate) -> RowsViewRow in
      return coordinate.row
    })

    affectedRowsWithPossibleDuplicates.append(contentsOf: toCoordinates.map { (coordinate) -> RowsViewRow in
      return coordinate.row
    })

    let uniqueAffectedRows = Set(affectedRowsWithPossibleDuplicates)

    // * * *.

    var affectedRows: Set<RowsViewRow> = []

    if(rowToItems[.top]!.count > 0 && rowToItems[.bottom]!.count > 0)
    {
      // Все нормально, дырок нет, ничего делать не надо.
      affectedRows = uniqueAffectedRows
    }
    else if(rowToItems[.top]!.count == 0 && rowToItems[.bottom]!.count > 0)
    {
      // Верхний ряд полностью пропал, в нижнем есть элементы.

      let bottomRowIndices = dataSource!.topRowVanishesInRowsView(rowsView: self)

      assert(bottomRowIndices.count > 0, "topRowVanishesInRowsView(rowsView:) should never return an empty array!")

      // Переместить айтемы и ячейки.
      rowToItems[.top] = rowToItems[.bottom]!.remove(atIndices: bottomRowIndices)

      rowToCells[.top] = rowToCells[.bottom]!.remove(atIndices: bottomRowIndices)

      // Вернуть заафекченные ряды.
      affectedRows = Set([.top] + (rowToItems[.bottom]!.count > 0 ? [.bottom] : []))
    }
    else if(rowToItems[.top]!.count > 0 && rowToItems[.bottom]!.count == 0)
    {
      // В верхнем ряду есть элементы, нижний ряд полностью пропал.
      affectedRows = [.top]
    }
    
    // * * *.

    var rowsToFinalFrames: [RowsViewRow: [NSRect]] = [:]

    for row in affectedRows
    {
      rowsToFinalFrames[row] = framesForEquallySizedAndSpacedCells(count: rowToCells[row]!.count, inRow: row, hasBottomRow: rowToItems[.bottom]!.count > 0)
    }

    if animated
    {
      NSAnimationContext.runAnimationGroup({ (animationContext) in
        animationContext.duration = 0.5

        animationContext.timingFunction = nil

        animationContext.allowsImplicitAnimation = false

        for row in affectedRows
        {
          for i in 0..<self.rowToCells[row]!.count
          {
            let currentFrame = self.rowToCells[row]![i].frame

            let animation = RowsView.animationForMovingCellApart(currentFrame, targetFrame: rowsToFinalFrames[row]![i])

            self.rowToCells[row]![i].animations = ["frame": animation]

            self.rowToCells[row]![i].animator().frame = rowsToFinalFrames[row]![i]
          }
        }
      }, completionHandler: nil)
    }
    else
    {
      for row in affectedRows
      {
        for i in 0..<self.rowToCells[row]!.count
        {
          self.rowToCells[row]![i].frame = rowsToFinalFrames[row]![i]
        }
      }
    }
  }

  // Убирает элементы по данным индексам.
  open func removeItems(atCoordinates coordinates: [Coordinate], animated: Bool)
  {
    // Смапить координаты в словарь [RowsViewRow: [Int]], где [Int] — массив индексов удалений из соответствующего ряда.
    var affectedRowsToRemovalIndices: [RowsViewRow: [Int]] = [:]

    for (index, row) in coordinates
    {
      if var removalIndices = affectedRowsToRemovalIndices[row]
      {
        removalIndices.append(index)

        affectedRowsToRemovalIndices[row] = removalIndices
      }
      else
      {
        affectedRowsToRemovalIndices[row] = [index]
      }
    }

    // Выбросить элементы из кеша модели.
    for (row, indices) in affectedRowsToRemovalIndices
    {
      let _ = rowToItems[row]!.remove(atIndices: indices)
    }

    // Викинуть ячейки с опциональной анимацией fade-out.
    let cells = affectedRowsToRemovalIndices.flatMap { (tuple: (RowsViewRow, [Int])) in
      return self.rowToCells[tuple.0]!.remove(atIndices: tuple.1)
    }

    // * * *.

    // Возможно, получились «дырки» в модели.
    var affectedRows: [RowsViewRow] = []

    if(rowToItems[.top]!.count > 0 && rowToItems[.bottom]!.count > 0)
    {
      // Все нормально, дырок нет, ничего делать не надо.
      affectedRows = Array(affectedRowsToRemovalIndices.keys)
    }
    else if(rowToItems[.top]!.count == 0 && rowToItems[.bottom]!.count > 0)
    {
      // Верхний ряд полностью пропал, в нижнем есть элементы.

      let bottomRowIndices = dataSource!.topRowVanishesInRowsView(rowsView: self)

      assert(bottomRowIndices.count > 0, "topRowVanishesInRowsView(rowsView:) should never return an empty array!")

      // Переместить айтемы и ячейки.
      rowToItems[.top] = rowToItems[.bottom]!.remove(atIndices: bottomRowIndices)

      rowToCells[.top] = rowToCells[.bottom]!.remove(atIndices: bottomRowIndices)

      // Вернуть заафекченные ряды.
      affectedRows = [.top] + (rowToItems[.bottom]!.count > 0 ? [.bottom] : [])
    }
    else if(rowToItems[.top]!.count > 0 && rowToItems[.bottom]!.count == 0)
    {
      // В верхнем ряду есть элементы, нижний ряд полностью пропал.
      affectedRows = [.top]
    }

    // * * *.

    let framesAlterationClosure =
    {
      // Сдвинуть существующие элементы, чтобы занять освободившееся место.
      var rowsToFinalFrames: [RowsViewRow: [NSRect]] = [:]

      for row in affectedRows
      {
        rowsToFinalFrames[row] = self.framesForEquallySizedAndSpacedCells(count: self.rowToCells[row]!.count, inRow: row, hasBottomRow: self.rowToItems[.bottom]!.count > 0)
      }

      if animated
      {
        NSAnimationContext.runAnimationGroup({ (animationContext) in
          animationContext.duration = 0.5

          animationContext.timingFunction = nil

          animationContext.allowsImplicitAnimation = false

          for row in affectedRows
          {
            for i in 0..<self.rowToCells[row]!.count
            {
              let currentFrame = self.rowToCells[row]![i].frame

              let animation = RowsView.animationForMovingCellApart(currentFrame, targetFrame: rowsToFinalFrames[row]![i])

              self.rowToCells[row]![i].animations = ["frame": animation]

              self.rowToCells[row]![i].animator().frame = rowsToFinalFrames[row]![i]
            }
          }
        }, completionHandler: nil)
      }
      else
      {
        for row in affectedRows
        {
          for i in 0..<self.rowToCells[row]!.count
          {
            self.rowToCells[row]![i].frame = rowsToFinalFrames[row]![i]
          }
        }
      }
    }

    // * * *.

    if animated
    {
      NSAnimationContext.runAnimationGroup({ (animationContext) in
        animationContext.duration = 0.5

        animationContext.timingFunction = nil

        animationContext.allowsImplicitAnimation = false

        let animation = RowsView.animationForFading(fromAlpha: 1, toAlpha: 0, beginTime: 0)

        for cell in cells
        {
          cell.animations = ["alphaValue": animation]

          cell.layer?.add(animation, forKey: "opacity")

          cell.animator().alphaValue = 0
        }
      }, completionHandler:
      {
        for cell in cells
        {
          cell.removeFromSuperview()
        }

        framesAlterationClosure()
      })
    }
    else
    {
      for cell in cells
      {
        cell.removeFromSuperview()
      }

      framesAlterationClosure()
    }
  }

  // Возвращает ячейку, соответствующую item, если таковой объект известен таблице.
  open func cell(forItem item: AnyObject) -> RowsViewCell?
  {
    for row in RowsViewRow.allRows()
    {
      let itemsCount = rowToItems[row]!.count

      for i in 0..<itemsCount
      {
        if rowToItems[row]![i] === item
        {
          return rowToCells[row]![i]
        }
      }
    }

    return nil
  }

  open func coordinate(forItem item: AnyObject) -> Coordinate?
  {
    for row in RowsViewRow.allRows()
    {
      for (index, element) in rowToItems[row]!.enumerated()
      {
        if element === item
        {
          return (row: row, index: index)
        }
      }
    }

    return nil
  }

  // Дропает ячейки и запрашивает замену у делегата.
  open func reacquireCellsForItems(atCoordinates coordinates: [Coordinate])
  {
    let coordinatesSortedByDescendingIndices = coordinates.sorted { (coordinateA, coordinateB) -> Bool in
      return coordinateA.index > coordinateB.index
    }

    for coordinate in coordinatesSortedByDescendingIndices
    {
      let ejectedCell = rowToCells[coordinate.row]!.remove(at: coordinate.index)

      let existingFrame = ejectedCell.frame

      ejectedCell.removeFromSuperview()

      let spareCell = delegate!.cellForItemInRowsView(rowsView: self, atCoordinate: coordinate)

      rowToCells[coordinate.row]!.insert(spareCell, at: coordinate.index)

      spareCell.objectValue = rowToItems[coordinate.row]![coordinate.index]

      addSubview(spareCell)

      spareCell.frame = existingFrame
    }
  }

  // MARK: - Private Methods

  fileprivate func clearState()
  {
    for row in RowsViewRow.allRows()
    {
      rowToItems[row]!.removeAll()

      rowToCells[row]!.removeAll()
    }

    // * * *.

    for subview in subviews
    {
      subview.removeFromSuperview()
    }
  }

  // MARK: Private Methods | Geometry

  fileprivate let rowsProportion: CGFloat = 2.0 / 3.0

  fileprivate func availableRect(forRow row: RowsViewRow, hasBottomRow: Bool) -> NSRect
  {
    // Рассматриваем специальный случай, когда ряд всего один.
    if(row == .top && !hasBottomRow)
    {
      let margins = self.margins(forRow: .top)

      return backingAlignedRect(NSInsetRect(bounds, margins.width, margins.height), options: .alignAllEdgesNearest)
    }

    // * * *.

    var topRect: NSRect = NSZeroRect

    var bottomRect: NSRect = NSZeroRect

    // * * *.

    NSDivideRect(bounds, &topRect, &bottomRect, (bounds.height * rowsProportion), .maxY)

    // * * *.

    let possiblyFractionalRect: NSRect

    let margins = self.margins(forRow: row)

    switch row
    {
      case .top:
        possiblyFractionalRect = NSInsetRect(topRect, margins.width, margins.height)

      case .bottom:
        possiblyFractionalRect = NSInsetRect(bottomRect, margins.width, margins.height)
    }

    // * * *.

    return backingAlignedRect(possiblyFractionalRect, options: .alignAllEdgesNearest)
  }

  fileprivate func margins(forRow row: RowsViewRow) -> NSSize
  {
    switch row
    {
      case .top:
        return NSMakeSize(0, 0)

      case .bottom:
        let margin = bounds.height * 0.05

        return NSMakeSize(margin, margin)
    }
  }

  fileprivate func gapWidth(forRow row: RowsViewRow) -> CGFloat
  {
    switch row
    {
      case .top:
        return 0

      case .bottom:
        return bounds.width * 0.05
    }
  }

  fileprivate func cellWidthLimit(forHeight height: CGFloat, inRow row: RowsViewRow) -> CGFloat?
  {
    switch row
    {
      case .top:
        return nil

      case .bottom:
        let sixteenByNine: CGFloat = 16.0 / 9.0

        return height * sixteenByNine
    }
  }

  fileprivate func framesForEquallySizedAndSpacedCells(count: Int, inRow row: RowsViewRow, hasBottomRow: Bool) -> [NSRect]
  {
    guard count != 0 else
    {
      return []
    }

    // * * *.

    let availableRect = self.availableRect(forRow: row, hasBottomRow:  hasBottomRow)

    let gapWidth = self.gapWidth(forRow: row)

    let availableCellWidth = (availableRect.width - CGFloat(count - 1) * gapWidth) / CGFloat(count)

    // * * *.

    let frameWidth: CGFloat

    if let cellWidthLimit = cellWidthLimit(forHeight: availableRect.height, inRow:  row)
    {
      frameWidth = availableCellWidth > cellWidthLimit ? cellWidthLimit : availableCellWidth
    }
    else
    {
      frameWidth = availableCellWidth
    }

    // * * *.

    var frames: [NSRect] = []

    let cellsBoundingWidth = CGFloat(count) * frameWidth + CGFloat(count - 1) * gapWidth

    var currentX = NSMinX(availableRect) + (NSWidth(availableRect) - cellsBoundingWidth) / 2.0

    for _ in 0..<count
    {
      let frame = NSMakeRect(currentX, NSMinY(availableRect), frameWidth, availableRect.height)

      frames.append(backingAlignedRect(frame, options: .alignAllEdgesNearest))

      currentX += frameWidth + gapWidth
    }

    return frames
  }

  // MARK: - Private Methods | Animations

  fileprivate static func animationForMovingCellApart(_ currentFrame: NSRect, targetFrame: NSRect) -> CABasicAnimation
  {
    let animation = CABasicAnimation()

    // Animation.

    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

    animation.delegate = nil

    animation.isRemovedOnCompletion = true

    // CAMediaTiming.

    animation.beginTime = 0

    // NSAnimationContext doesn't respect this value 😢.
    animation.duration = 0

    animation.speed = 1

    animation.timeOffset = 0

    animation.repeatCount = 0

    animation.repeatDuration = 0

    animation.autoreverses = false

    animation.fillMode = kCAFillModeRemoved

    // Property Animation.

    animation.keyPath = "frame"

    animation.isAdditive = false

    animation.isCumulative = false

    animation.valueFunction = nil

    // Basic Animation.

    animation.fromValue = NSValue(rect: currentFrame)

    animation.toValue = NSValue(rect: targetFrame)

    animation.byValue = nil

    return animation
  }

  fileprivate static func animationForFading(fromAlpha: Double, toAlpha: Double, beginTime: CFTimeInterval) -> CABasicAnimation
  {
    let animation = CABasicAnimation()

    // Animation.

    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)

    animation.delegate = nil

    animation.isRemovedOnCompletion = true

    // CAMediaTiming.

    animation.beginTime = beginTime

    // NSAnimationContext doesn't respect this value 😢.
    animation.duration = 0

    animation.speed = 1

    animation.timeOffset = 0

    animation.repeatCount = 1

    animation.repeatDuration = 0

    animation.autoreverses = false

    animation.fillMode = kCAFillModeBackwards

    // Property Animation.

    animation.keyPath = "opacity"

    animation.isAdditive = false

    animation.isCumulative = false

    animation.valueFunction = nil

    // Basic Animation.

    animation.fromValue = NSNumber(value: fromAlpha as Double)

    animation.toValue = NSNumber(value: toAlpha as Double)

    animation.byValue = nil

    return animation
  }
}

// MARK: - Array Extension

extension Array
{
  public mutating func insert(_ elements: [Element], atIndices indices: [Int])
  {
    assert(elements.count == indices.count, "The elements count didn't match the indices count.")

    let ascendingIndices = indices.sorted { (a, b) -> Bool in
      return a < b
    }

    for (element, index) in zip(elements, ascendingIndices)
    {
      insert(element, at: index)
    }
  }

  /// Возвращает удаленные объекты в порядке их следования в изначальном массиве.
  public mutating func remove(atIndices indices: [Int]) -> [Element]
  {
    let descendingIndices = indices.sorted { (a, b) -> Bool in
      return a > b
    }

    var elementsToReturn: [Element] = []

    for index in descendingIndices
    {
      elementsToReturn.insert(self.remove(at: index), at: 0)
    }

    return elementsToReturn
  }
}
