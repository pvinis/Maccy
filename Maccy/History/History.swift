import AppKit
import Defaults
import SwiftData

class History {
  var all: [HistoryItemL] {
//    let sorter = Sorter(by: Defaults[.sortBy])
//    var unpinned = sorter.sort(HistoryItemL.unpinned)
//    while unpinned.count > Defaults[.size] {
//      remove(unpinned.removeLast())
//    }

//    return sorter.sort(HistoryItemL.all)
    return []
  }

  private var sessionLog: [Int: HistoryItem] = [:]

  init() {
    if ProcessInfo.processInfo.arguments.contains("ui-testing") {
      clear()
    }
  }

  @MainActor
  func add(_ item: HistoryItem) {
    if let existingHistoryItem = findSimilarItem(item) {
      if isModified(item) == nil {
        item.contents = existingHistoryItem.contents
      }
      item.firstCopiedAt = existingHistoryItem.firstCopiedAt
      item.numberOfCopies += existingHistoryItem.numberOfCopies
      item.pin = existingHistoryItem.pin
      item.title = existingHistoryItem.title
      if !item.fromMaccy {
        item.application = existingHistoryItem.application
      }
      remove(existingHistoryItem)
    } else {
      Notifier.notify(body: item.title, sound: .write)
    }

    sessionLog[Clipboard.shared.changeCount] = item
    CoreDataManager.shared.saveContext()
  }

  func update(_ item: HistoryItemL?) {
//    CoreDataManager.shared.saveContext()
  }

  @MainActor
  func remove(_ item: HistoryItem?) {
    guard let item else { return }

    SwiftDataManager.shared.container.mainContext.delete(item)

//    item.getContents().forEach(CoreDataManager.shared.viewContext.delete(_:))
//    CoreDataManager.shared.viewContext.delete(item)
  }

  func clearUnpinned() {
//    all.filter({ $0.pin == nil }).forEach(remove(_:))
  }

  func clear() {
//    all.forEach(remove(_:))
  }

  @MainActor
  private func findSimilarItem(_ item: HistoryItem) -> HistoryItem? {
    let descriptor = FetchDescriptor<HistoryItem>()
    if let all = try? SwiftDataManager.shared.container.mainContext.fetch(descriptor) {
      let duplicates = all.filter({ $0 == item || $0.supersedes(item) })
      if duplicates.count > 1 {
        return duplicates.first(where: { $0 != item })
      } else {
        return isModified(item)
      }
    }

    return item
  }

  private func isModified(_ item: HistoryItem) -> HistoryItem? {
    if let modified = item.modified, sessionLog.keys.contains(modified) {
      return sessionLog[modified]
    }

    return nil
  }
}