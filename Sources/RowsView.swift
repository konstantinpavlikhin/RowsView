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
  case Top

  case Bottom

  public static func allRows() -> [RowsViewRow]
  {
    return [.Top, .Bottom]
  }
}

// * * *.

public typealias Coordinate = (index: Int, inRow: RowsViewRow)

// MARK: - RowsViewCell

public class RowsViewCell: NSView
{
  internal var objectValue: AnyObject?
}

// MARK: - RowsViewDataSource

public protocol RowsViewDataSource
{
  func numberOfItemsForRowsView(rowsView rowsView: RowsView, inRow row: RowsViewRow) -> Int

  func itemForRowsView(rowsView rowsView: RowsView, atCoordinate coordinate: Coordinate) -> AnyObject
}

// * * *.

public protocol RowsViewDelegate
{
  func cellForItemInRowsView(rowsView rowsView: RowsView, atCoordinate coordinate: Coordinate) -> RowsViewCell
}

// MARK: - RowsView

// TODO: множественные апдейты beginUpdates/endUpdates?

public class RowsView: NSView
{
  public var dataSource: RowsViewDataSource? = nil

  public var delegate: RowsViewDelegate? = nil

  // * * *.

  private var rowToItems: [RowsViewRow: [AnyObject]] = [:]

  private var rowToCells: [RowsViewRow: [RowsViewCell]] = [:]

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

    self.layer?.backgroundColor = NSColor.yellowColor().colorWithAlphaComponent(0.5).CGColor
  }
  
  required public init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - NSView Overrides

  override public func layout()
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

      let frames = framesForEquallySizedAndSpacedCells(count: cells.count, inRow: row)

      for i in 0..<cells.count
      {
        cells[i].frame = frames[i]
      }
    }
  }

  // MARK: - Public Methods

  // Полностью сбрасывает состояние и перезапрашивает у датасурса все необходимое.
  public func reloadData()
  {
    clearState()

    // * * *.

    assert(dataSource != nil, "Data source not set.")

    assert(delegate != nil, "Delegate not set.")

    // * * *.

    for row in RowsViewRow.allRows()
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

  public func numberOfItems(inRow row: RowsViewRow) -> Int
  {
    return rowToItems[row]!.count
  }

  public func item(atCoordinate coordinate: Coordinate) -> AnyObject
  {
    return rowToItems[coordinate.inRow]![coordinate.index]
  }

  // Вставляет элементы по данным координатам.
  public func insertItems(atCoordinates coordinates: [Coordinate], animated: Bool)
  {
    // Сходить в датасурса и запросить модельные объекты.
    let items = coordinates.map { coordinate -> AnyObject in
      return dataSource!.itemForRowsView(rowsView: self, atCoordinate: coordinate)
    }

    // Элементы могут быть вставлены либо в верхний, либо в нижний ряд.
    for (coordinate, item) in zip(coordinates, items)
    {
      rowToItems[coordinate.inRow]!.insert(item, atIndex: coordinate.index)
    }

    // Вычислить, какие ряды зааффекчены и сколько в каждый производится вставок.
    var affectedRowsToInsertionsCount: [RowsViewRow: Int] = [:]

    for coordinate in coordinates
    {
      if let insertionsCount = affectedRowsToInsertionsCount[coordinate.inRow]
      {
        affectedRowsToInsertionsCount[coordinate.inRow] = insertionsCount + 1
      }
      else
      {
        affectedRowsToInsertionsCount[coordinate.inRow] = 1
      }
    }

    // Закешировать финальные фреймы ячеек.
    var rowsToFinalFrames: [RowsViewRow: [NSRect]] = [:]

    for (row, insertionsCount) in affectedRowsToInsertionsCount
    {
      rowsToFinalFrames[row] = framesForEquallySizedAndSpacedCells(count: (rowToCells[row]!.count + insertionsCount), inRow: row)
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
      let indicesSortedByAscending = insertionIndices.sort {$0 < $1}

      rowsToInsertionFrames[row] = rowsToFinalFrames[row]!.remove(atIndices: indicesSortedByAscending)
    }

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

    let zippedCoordinatesAndCellsSortedByAscendingIndex = zippedCoordinatesAndCells.sort { (a, b) -> Bool in
      return a.0.index < b.0.index
    }

    for (coordinate, cell) in zippedCoordinatesAndCellsSortedByAscendingIndex
    {
      rowToCells[coordinate.inRow]!.insert(cell, atIndex: coordinate.index)

      addSubview(cell)
    }

    var uglyMutableIndex = 0

    for (coordinate, cell) in zippedCoordinatesAndCellsSortedByAscendingIndex
    {
      cell.frame = rowsToInsertionFrames[coordinate.inRow]![uglyMutableIndex]

      uglyMutableIndex += 1

      if animated
      {
        NSAnimationContext.runAnimationGroup({ (animationContext) in
          animationContext.duration = 0.5

          animationContext.timingFunction = nil

          animationContext.allowsImplicitAnimation = false

          let animation = RowsView.animationForFading(fromAlpha: 0, toAlpha: 1, beginTime: CACurrentMediaTime() + 0.5)

          cell.animations = ["alphaValue": animation]

          cell.layer?.addAnimation(animation, forKey: "opacity")

          cell.animator().alphaValue = 1
        }, completionHandler: nil)
      }
    }
  }

  public func moveItems(atCoordinates atCoordinates: [Coordinate], toCoordinates: [Coordinate], animated: Bool)
  {
    assert(atCoordinates.count == toCoordinates.count, "Initial and target coordinate arrays are of different length.")

    // * * *.

    let transitionsAsIs = zip(atCoordinates, toCoordinates)

    // * * *.

    let transitionsSortedByDescendingStartingIndices = transitionsAsIs.sort { (a, b) -> Bool in
      return a.0.index > b.0.index
    }

    // * * *.

    var itemsAndCells: [(AnyObject, RowsViewCell)] = []

    for (atCoordinate, _) in transitionsSortedByDescendingStartingIndices
    {
      // Изъять объекты из кеша модели со старых мест (для каждого ряда).
      let removedItem = rowToItems[atCoordinate.inRow]!.removeAtIndex(atCoordinate.index)

      // Изъять ячейки со старых рядов.
      let removedCell = rowToCells[atCoordinate.inRow]!.removeAtIndex(atCoordinate.index)

      itemsAndCells.append((removedItem, removedCell))
    }

    // * * *.

    let transitionsZippedWithItemAndCellTuples = zip(transitionsSortedByDescendingStartingIndices, itemsAndCells)

    let transitionsZippedWithItemAndCellTuplesSortedByAscendingTargetIndices = transitionsZippedWithItemAndCellTuples.sort { (a, b) -> Bool in
      return a.0.1.index < b.0.1.index
    }

    for (transition, itemAndCell) in transitionsZippedWithItemAndCellTuplesSortedByAscendingTargetIndices
    {
      let targetCoordinate = transition.1

      // Поместить объекты в кеш модели на новые места (для каждого ряда).
      rowToItems[targetCoordinate.inRow]!.insert(itemAndCell.0, atIndex: targetCoordinate.index)

      // Поместить ячейки в новые ряды.
      rowToCells[targetCoordinate.inRow]!.insert(itemAndCell.1, atIndex: targetCoordinate.index)
    }

    // Рассчитать лейаут для всех ячеек, опционально анимируя изменения.

    var affectedRowsWithPossibleDuplicates: [RowsViewRow] = []

    affectedRowsWithPossibleDuplicates.appendContentsOf(atCoordinates.map { (coordinate) -> RowsViewRow in
      return coordinate.inRow
    })

    affectedRowsWithPossibleDuplicates.appendContentsOf(toCoordinates.map { (coordinate) -> RowsViewRow in
      return coordinate.inRow
    })

    let uniqueAffectedRows = Set(affectedRowsWithPossibleDuplicates)

    var rowsToFinalFrames: [RowsViewRow: [NSRect]] = [:]

    for row in uniqueAffectedRows
    {
      rowsToFinalFrames[row] = framesForEquallySizedAndSpacedCells(count: rowToCells[row]!.count, inRow: row)
    }

    if animated
    {
      NSAnimationContext.runAnimationGroup({ (animationContext) in
        animationContext.duration = 0.5

        animationContext.timingFunction = nil

        animationContext.allowsImplicitAnimation = false

        for row in uniqueAffectedRows
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
      for row in uniqueAffectedRows
      {
        for i in 0..<self.rowToCells[row]!.count
        {
          self.rowToCells[row]![i].frame = rowsToFinalFrames[row]![i]
        }
      }
    }
  }

  // Убирает элементы по данным индексам.
  public func removeItems(atCoordinates coordinates: [Coordinate], animated: Bool)
  {
    // Смапить координаты в словарь [RowsViewRow: [Int]], где [Int] — массив индектов вставок в данном ряду.
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
      rowToItems[row]!.remove(atIndices: indices)
    }

    // Викинуть ячейки с опциональной анимацией fade-out.
    let cells = affectedRowsToRemovalIndices.flatMap { (tuple: (RowsViewRow, [Int])) in
      return self.rowToCells[tuple.0]!.remove(atIndices: tuple.1)
    }

    // * * *.

    let framesAlterationClosure =
    {
      // Сдвинуть существующие элементы, чтобы занять освободившееся место.
      var rowsToFinalFrames: [RowsViewRow: [NSRect]] = [:]

      for row in affectedRowsToRemovalIndices.keys
      {
        rowsToFinalFrames[row] = self.framesForEquallySizedAndSpacedCells(count: self.rowToCells[row]!.count, inRow: row)
      }

      if animated
      {
        NSAnimationContext.runAnimationGroup({ (animationContext) in
          animationContext.duration = 0.5

          animationContext.timingFunction = nil

          animationContext.allowsImplicitAnimation = false

          for row in affectedRowsToRemovalIndices.keys
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
        for row in affectedRowsToRemovalIndices.keys
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

          cell.layer?.addAnimation(animation, forKey: "opacity")

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

  // Дропает ячейки и запрашивает замену у делегата.
  public func reacquireCellsForItems(atCoordinates coordinates: [Coordinate])
  {
    let coordinatesSortedByDescendingIndices = coordinates.sort { (coordinateA, coordinateB) -> Bool in
      return coordinateA.index > coordinateB.index
    }

    for coordinate in coordinatesSortedByDescendingIndices
    {
      let ejectedCell = rowToCells[coordinate.inRow]!.removeAtIndex(coordinate.index)

      let existingFrame = ejectedCell.frame

      ejectedCell.removeFromSuperview()

      let spareCell = delegate!.cellForItemInRowsView(rowsView: self, atCoordinate: coordinate)

      rowToCells[coordinate.inRow]!.insert(spareCell, atIndex: coordinate.index)

      spareCell.objectValue = rowToItems[coordinate.inRow]![coordinate.index]

      addSubview(spareCell)

      spareCell.frame = existingFrame
    }
  }

  // MARK: - Private Methods

  private func clearState()
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

  private let rowsProportion: CGFloat = 2.0 / 3.0

  private func availableRect(forRow row: RowsViewRow) -> NSRect
  {
    var topRect: NSRect = NSZeroRect

    var bottomRect: NSRect = NSZeroRect

    // * * *.

    NSDivideRect(bounds, &topRect, &bottomRect, (bounds.height * rowsProportion), .MaxY)

    // * * *.

    let possiblyFractionalRect: NSRect

    let margins = self.margins(forRow: row)

    switch row
    {
      case .Top:
        possiblyFractionalRect = NSInsetRect(topRect, margins.width, margins.height)

      case .Bottom:
        possiblyFractionalRect = NSInsetRect(bottomRect, margins.width, margins.height)
    }

    // * * *.

    return backingAlignedRect(possiblyFractionalRect, options: .AlignAllEdgesNearest)
  }

  private func margins(forRow row: RowsViewRow) -> NSSize
  {
    switch row
    {
      case .Top:
        return NSMakeSize(0, 0)

      case .Bottom:
        let margin = bounds.height * 0.05

        return NSMakeSize(margin, margin)
    }
  }

  private func gapWidth(forRow row: RowsViewRow) -> CGFloat
  {
    switch row
    {
      case .Top:
        return 0

      case .Bottom:
        return bounds.width * 0.05
    }
  }

  private func cellWidthLimit(forHeight height: CGFloat, inRow row: RowsViewRow) -> CGFloat?
  {
    switch row
    {
      case .Top:
        return nil

      case .Bottom:
        let sixteenByNine: CGFloat = 16.0 / 9.0

        return height * sixteenByNine
    }
  }

  private func framesForEquallySizedAndSpacedCells(count count: Int, inRow row: RowsViewRow) -> [NSRect]
  {
    assert(count > 0, "U mad? You gave me a zero count!")

    // * * *.

    let availableRect = self.availableRect(forRow: row)

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

      frames.append(backingAlignedRect(frame, options: .AlignAllEdgesNearest))

      currentX += frameWidth + gapWidth
    }

    return frames
  }

  // MARK: - Private Methods | Animations

  private static func animationForMovingCellApart(currentFrame: NSRect, targetFrame: NSRect) -> CABasicAnimation
  {
    let animation = CABasicAnimation()

    // Animation.

    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

    animation.delegate = nil

    animation.removedOnCompletion = true

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

    animation.additive = false

    animation.cumulative = false

    animation.valueFunction = nil

    // Basic Animation.

    animation.fromValue = NSValue(rect: currentFrame)

    animation.toValue = NSValue(rect: targetFrame)

    animation.byValue = nil

    return animation
  }

  private static func animationForFading(fromAlpha fromAlpha: Double, toAlpha: Double, beginTime: CFTimeInterval) -> CABasicAnimation
  {
    let animation = CABasicAnimation()

    // Animation.

    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)

    animation.delegate = nil

    animation.removedOnCompletion = true

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

    animation.additive = false

    animation.cumulative = false

    animation.valueFunction = nil

    // Basic Animation.

    animation.fromValue = NSNumber(double: fromAlpha)

    animation.toValue = NSNumber(double: toAlpha)

    animation.byValue = nil

    return animation
  }
}

// MARK: - Array Extension

extension Array
{
  public mutating func insert(elements: [Element], atIndices indices: [Int])
  {
    assert(elements.count == indices.count, "The elements count didn't match the indices count.")

    let ascendingIndices = indices.sort { (a, b) -> Bool in
      return a < b
    }

    for (element, index) in zip(elements, ascendingIndices)
    {
      insert(element, atIndex: index)
    }
  }

  /// Возвращает удаленные объекты в порядке их следования в изначальном массиве.
  public mutating func remove(atIndices indices: [Int]) -> [Element]
  {
    let descendingIndices = indices.sort { (a, b) -> Bool in
      return a > b
    }

    var elementsToReturn: [Element] = []

    for index in descendingIndices
    {
      elementsToReturn.insert(removeAtIndex(index), atIndex: 0)
    }

    return elementsToReturn
  }
}
