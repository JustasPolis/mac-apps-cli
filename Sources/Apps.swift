import ArgumentParser
import Cocoa
import Foundation

enum Utils {
  static func printToStderr(_ message: String) {
    if let data = (message + "\n").data(using: .utf8) {
      FileHandle.standardError.write(data)
    }
  }

  static func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    return output
  }
}

struct Apps: ParsableCommand {
  @Argument(help: "list apps, can be all, inactive, idle, active")
  var apps: String

  struct App: Codable, Hashable {
    let id: Int?
    let pid: pid_t?
    let app: String?
    let title: String?
    let path: String?

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      id = try container.decode(Int.self, forKey: .id)
      pid = try container.decode(pid_t.self, forKey: .pid)
      app = try container.decode(String.self, forKey: .app)
      title = try container.decode(String.self, forKey: .title)
      if let pid {
        path = NSRunningApplication(processIdentifier: pid)?.bundleURL?.relativePath
      } else {
        path = nil
      }
    }

    init(id: Int?, pid: pid_t?, app: String?, title: String?, path: String?) {
      self.id = id
      self.pid = pid
      self.app = app
      self.title = title
      self.path = path
    }

    static func == (lhs: App, rhs: App) -> Bool {
      lhs.path == rhs.path
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(path)
    }
  }

  private var activeApps: [App] = {
    var apps = [App]()
    if let data = Utils.shell("yabai -m query --windows").data(using: .utf8) {
      do {
        apps = try JSONDecoder().decode([App].self, from: data)
      } catch {
        Utils.printToStderr("failed to decode yabai query \(error)")
      }
    }
    return apps
  }()

  private var installedApplications: [Apps.App] = {
    let fileManager = FileManager.default
    let systemApplicationsURL = URL(fileURLWithPath: "/System/Applications")
    let keys: [URLResourceKey] = [.nameKey]

    do {
      let systemApplicationURLs = try fileManager.contentsOfDirectory(
        at: systemApplicationsURL,
        includingPropertiesForKeys: keys,
        options: .skipsHiddenFiles
      )
      .filter { $0.pathExtension == "app" }

      let applicationURLS = try fileManager.contentsOfDirectory(
        at: URL(fileURLWithPath: "/Applications"),
        includingPropertiesForKeys: keys,
        options: .skipsHiddenFiles
      )
      .filter { $0.pathExtension == "app" }

      return [systemApplicationURLs, applicationURLS].flatMap { $0 }.map { App(
        id: nil,
        pid: nil,
        app: $0.lastPathComponent.replacingOccurrences(of: ".app", with: ""),
        title: $0.lastPathComponent.replacingOccurrences(of: ".app", with: ""),
        path: $0.relativePath
      ) }
    } catch {
      Utils.printToStderr("Error reading /Applications directory: \(error)")
      return []
    }
  }()

  private lazy var idleApplications = Set(
    NSWorkspace.shared.runningApplications
      .map {
        App(
          id: nil,
          pid: $0.processIdentifier,
          app: $0.localizedName,
          title: $0.localizedName,
          path: $0.bundleURL?.relativePath
        )
      }
  )
  .intersection(Set(installedApplications))
  .symmetricDifference(Set(activeApps))

  private lazy var inactiveApplications = Set(installedApplications).symmetricDifference(idleApplications)

  struct Container: Codable {
    let active: [App]
    let idle: Set<App>
    let inactive: Set<App>
  }

  private lazy var container = Container(active: activeApps, idle: idleApplications, inactive: inactiveApplications)

  mutating func run() throws {
    switch apps {
    case "all":
      do {
        let jsonData = try JSONEncoder().encode(container)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
          print(jsonString)
        }
      } catch {
        Utils.printToStderr("Failed to encode JSON: \(error)")
      }
    case "inactive":
      do {
        let jsonData = try JSONEncoder().encode(inactiveApplications)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
          print(jsonString)
        }
      } catch {
        Utils.printToStderr("Failed to encode JSON: \(error)")
      }
    case "idle":
      do {
        let jsonData = try JSONEncoder().encode(idleApplications)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
          print(jsonString)
        }
      } catch {
        Utils.printToStderr("Failed to encode JSON: \(error)")
      }
    case "active":
      do {
        let jsonData = try JSONEncoder().encode(activeApps)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
          print(jsonString)
        }
      } catch {
        Utils.printToStderr("Failed to encode JSON: \(error)")
      }
    default:
      Utils.printToStderr("ERROR: value can be either: all, inactive, idle, active")
    }
  }
}
