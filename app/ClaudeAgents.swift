// Claude Agents — menu bar app hiển thị trạng thái các phiên Claude Code (dữ liệu từ `ccmon serve`).
import AppKit
import SwiftUI

struct Row: Codable, Identifiable {
    let session_id: String
    let state: String
    let project: String?
    let app: String?
    let updated: Double?
    let turn_started: Double?
    let seen: Bool?
    let last_prompt: String?
    let reply: String?
    let message: String?
    let activity: String?
    let name: String?
    let auto_name: String?
    let title: String?
    let ctx_pct: Int?
    var id: String { session_id }
    var displayTitle: String { title ?? project ?? "?" }
    var hasCustomName: Bool { !(name ?? "").isEmpty }
    var isNew: Bool { ["waiting", "done", "interrupted"].contains(state) && !(seen ?? true) }
}

struct Limit: Codable { let used_percentage: Double?; let resets_at: Double? }
struct Usage: Codable { let updated: Double?; let five_hour: Limit?; let seven_day: Limit? }
struct Snap: Codable { let now: Double; let rows: [Row]; let usage: Usage? }

func quotaColor(_ p: Double) -> Color { p >= 90 ? .red : p >= 70 ? .orange : .green }

func resetText(_ t: Double?, _ now: Double) -> String {
    guard let t = t else { return "" }
    if t <= now { return "đã reset" }
    let f = DateFormatter()
    f.locale = Locale(identifier: "vi_VN")
    f.dateFormat = t - now < 86400 ? "HH:mm" : "EEE HH:mm"
    return "reset " + f.string(from: Date(timeIntervalSince1970: t))
}

let LABEL = ["waiting": "CHỜ BẠN", "done": "XONG", "running": "ĐANG CHẠY",
             "interrupted": "BỊ NGẮT", "idle": "MỞ, CHƯA LÀM", "closed": "ĐÃ ĐÓNG"]
let COLOR: [String: Color] = ["waiting": .orange, "done": .green, "running": .blue,
                              "interrupted": .pink, "idle": .gray, "closed": .gray]

func ago(_ t: Double?, _ now: Double) -> String {
    let s = Int(max(0, now - (t ?? now)))
    if s < 60 { return "\(s)s" }
    if s < 3600 { return "\(s / 60)m" }
    if s < 86400 { return String(format: "%dh%02dm", s / 3600, s % 3600 / 60) }
    return "\(s / 86400)d"
}

final class Store: ObservableObject {
    @Published var rows: [Row] = []
    @Published var now: Double = 0
    @Published var online = true
    @Published var usage: Usage?
    @Published var showClosed = false { didSet { refresh() } }
    private let base = "http://127.0.0.1:7788"
    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
    }

    var need: Int { rows.filter { $0.isNew }.count }
    var running: Int { rows.filter { $0.state == "running" }.count }

    func refresh() {
        let url = URL(string: "\(base)/api/sessions?all=\(showClosed ? 1 : 0)")!
        URLSession.shared.dataTask(with: url) { d, _, _ in
            let snap = d.flatMap { try? JSONDecoder().decode(Snap.self, from: $0) }
            DispatchQueue.main.async {
                guard let snap = snap else { self.online = false; return }
                self.online = true
                self.rows = snap.rows
                self.now = snap.now
                self.usage = snap.usage
                NSApp.dockTile.badgeLabel = self.need > 0 ? "\(self.need)" : nil
            }
        }.resume()
    }

    func pct(_ l: Limit?) -> Int? {
        guard let l = l, let p = l.used_percentage else { return nil }
        if let r = l.resets_at, r < now { return 0 }
        return Int(p.rounded())
    }

    func act(_ action: String, _ id: String, _ extra: [URLQueryItem] = []) {
        var c = URLComponents(string: "\(base)/api/\(action)")!
        c.queryItems = [URLQueryItem(name: "id", value: id)] + extra
        var req = URLRequest(url: c.url!)
        req.httpMethod = "POST"
        req.setValue("1", forHTTPHeaderField: "X-CCMon")
        URLSession.shared.dataTask(with: req) { _, _, _ in
            DispatchQueue.main.async { self.refresh() }
        }.resume()
    }

    // chạy focus từ chính app để quyền Automation (iTerm) gắn với app này
    func focus(_ id: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        p.arguments = [NSHomeDirectory() + "/bin/ccmon", "focus", id]
        p.terminationHandler = { _ in DispatchQueue.main.async { self.refresh() } }
        try? p.run()
    }

    func rename(_ r: Row) {
        let alert = NSAlert()
        alert.messageText = "Đổi tên phiên"
        alert.informativeText = "\(r.project ?? "") · \(r.session_id.prefix(8))\nĐể trống = dùng tên tự động" +
            ((r.auto_name ?? "").isEmpty ? "." : " (\(r.auto_name!)).")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        field.stringValue = r.name ?? ""
        field.placeholderString = r.auto_name ?? r.project ?? ""
        alert.accessoryView = field
        alert.addButton(withTitle: "Lưu")
        alert.addButton(withTitle: "Hủy")
        NSApp.activate(ignoringOtherApps: true)
        alert.window.initialFirstResponder = field
        if alert.runModal() == .alertFirstButtonReturn {
            act("rename", r.session_id, [URLQueryItem(name: "name", value: field.stringValue)])
        }
    }

    func startServer() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = ["kickstart", "-k", "gui/\(getuid())/io.github.trantholock.ccmon"]
        try? p.run()
    }
}

struct RowView: View {
    let r: Row
    let now: Double
    @EnvironmentObject var store: Store
    @State private var hover = false

    var detail: String {
        switch r.state {
        case "running": return r.activity ?? ""
        case "waiting": return r.message ?? ""
        case "done": return r.reply ?? ""
        default: return ""
        }
    }

    var body: some View {
        let c = COLOR[r.state] ?? .gray
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 4)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text((r.isNew ? "● " : "") + (LABEL[r.state] ?? r.state))
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(c.opacity(0.18)).foregroundColor(c).cornerRadius(8)
                    Text((r.hasCustomName ? "📌 " : "") + r.displayTitle)
                        .font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    if hover {
                        Button { store.rename(r) } label: { Image(systemName: "pencil") }
                            .buttonStyle(.borderless).help("Đổi tên phiên")
                    }
                    Text((r.displayTitle != r.project ? (r.project ?? "") + " · " : "") + (r.app ?? ""))
                        .font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
                    Spacer()
                    if r.state == "running", r.turn_started != nil {
                        Text("chạy " + ago(r.turn_started, now)).font(.system(size: 11)).foregroundColor(.secondary)
                    } else {
                        Text(ago(r.updated, now)).font(.system(size: 11)).foregroundColor(.secondary)
                    }
                }
                if let p = r.last_prompt, !p.isEmpty {
                    Text("» " + p).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
                }
                if !detail.isEmpty {
                    Text(detail).font(.system(size: 12)).lineLimit(3)
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(hover ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(r.isNew ? c.opacity(0.7) : .clear, lineWidth: 1.5))
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .onTapGesture { store.focus(r.session_id) }
        .help("Bấm để mở tab/cửa sổ của phiên này")
        .contextMenu {
            Button("Mở phiên") { store.focus(r.session_id) }
            Button("Đổi tên…") { store.rename(r) }
            if r.isNew { Button("Đánh dấu đã xem") { store.act("ack", r.session_id) } }
            Button("Copy session ID") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(r.session_id, forType: .string)
            }
            if r.state == "closed" { Button("Xóa khỏi danh sách") { store.act("forget", r.session_id) } }
        }
    }
}

struct QuotaBar: View {
    let label: String
    let pct: Int
    let reset: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.system(size: 11))
                Text("\(pct)%").font(.system(size: 11, weight: .bold)).foregroundColor(quotaColor(Double(pct)))
                Spacer()
                Text(reset).font(.system(size: 10)).foregroundColor(.secondary)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.12))
                    Capsule().fill(quotaColor(Double(pct))).frame(width: g.size.width * CGFloat(min(pct, 100)) / 100)
                }
            }.frame(height: 6)
        }
    }
}

struct QuotaView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        if let u = store.usage, u.updated != nil {
            HStack(spacing: 14) {
                if let p = store.pct(u.five_hour) {
                    QuotaBar(label: "Quota 5 giờ", pct: p, reset: resetText(u.five_hour?.resets_at, store.now))
                }
                if let p = store.pct(u.seven_day) {
                    QuotaBar(label: "Quota 7 ngày", pct: p, reset: resetText(u.seven_day?.resets_at, store.now))
                }
            }
            .help("Cập nhật \(ago(u.updated, store.now)) trước, từ statusLine của phiên Claude gần nhất")
            .padding(.horizontal, 12).padding(.bottom, 10)
        }
    }
}

struct Panel: View {
    @EnvironmentObject var store: Store
    @Environment(\.openWindow) private var openWindow
    var inWindow = false

    var groups: [(String, [Row])] {
        var used = Set<String>()
        let defs: [(String, (Row) -> Bool)] = [
            ("Cần bạn xử lý", { $0.isNew }),
            ("Đang chạy", { $0.state == "running" }),
            ("Chờ bạn", { $0.state == "waiting" }),
            ("Xong / đã xem", { $0.state == "done" || $0.state == "interrupted" }),
            ("Mở, chưa làm gì", { $0.state == "idle" }),
            ("Đã đóng", { $0.state == "closed" }),
        ]
        var out: [(String, [Row])] = []
        for (title, f) in defs {
            let g = store.rows.filter { !used.contains($0.id) && f($0) }
            g.forEach { used.insert($0.id) }
            if !g.isEmpty { out.append((title, g)) }
        }
        return out
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Claude Agents").font(.headline)
                Spacer()
                Text("\(store.need) cần bạn").font(.system(size: 11, weight: .semibold)).foregroundColor(.orange)
                Text("· \(store.running) đang chạy").font(.system(size: 11)).foregroundColor(.blue)
                if store.need > 0 {
                    Button("Đã xem hết") { store.act("ack", "all") }.controlSize(.small)
                }
            }
            .padding(12)
            QuotaView()
            Divider()
            if !store.online {
                VStack(spacing: 8) {
                    Text("Không kết nối được ccmon (127.0.0.1:7788)").foregroundColor(.secondary)
                    Button("Khởi động lại ccmon serve") { store.startServer() }
                }.frame(maxWidth: .infinity, minHeight: 120)
            } else if store.rows.isEmpty {
                Text("Không có phiên nào.\nMở một phiên Claude Code để bắt đầu theo dõi.")
                    .multilineTextAlignment(.center).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(groups, id: \.0) { g in
                            Text("\(g.0.uppercased()) (\(g.1.count))")
                                .font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary)
                                .padding(.top, 6)
                            ForEach(g.1) { r in RowView(r: r, now: store.now) }
                        }
                    }.padding(10)
                }.frame(maxHeight: inWindow ? .infinity : 560)
            }
            Divider()
            HStack {
                Toggle("Hiện phiên đã đóng", isOn: $store.showClosed).toggleStyle(.checkbox).font(.system(size: 11))
                Spacer()
                if !inWindow {
                    Button("Mở cửa sổ") { openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true) }
                }
                Button("Dashboard web") { NSWorkspace.shared.open(URL(string: "http://127.0.0.1:7788")!) }
                Button("Thoát") { NSApp.terminate(nil) }
            }
            .controlSize(.small)
            .padding(10)
        }
        .frame(minWidth: 460, idealWidth: 560, maxWidth: inWindow ? .infinity : 460,
               minHeight: inWindow ? 400 : nil, maxHeight: inWindow ? .infinity : nil)
    }
}

@main
struct ClaudeAgentsApp: App {
    @StateObject private var store = Store()

    // "🟠2 🔵3 · 46% · 81%"
    var menuTitle: String {
        var parts: [String] = []
        if store.need > 0 { parts.append("🟠\(store.need)") }
        if store.running > 0 { parts.append("🔵\(store.running)") }
        var s = parts.isEmpty ? "✦" : parts.joined(separator: " ")
        let q = [store.pct(store.usage?.five_hour), store.pct(store.usage?.seven_day)].compactMap { $0 }
        if !q.isEmpty { s += " · " + q.map { "\($0)%" }.joined(separator: " · ") }
        return s
    }

    var windowTitle: String {
        let five = store.pct(store.usage?.five_hour), week = store.pct(store.usage?.seven_day)
        guard five != nil || week != nil else { return "Claude Agents" }
        return "Claude Agents — 5h \(five.map { "\($0)%" } ?? "?") · 7d \(week.map { "\($0)%" } ?? "?")"
    }

    var body: some Scene {
        Window("Claude Agents", id: "main") {
            Panel(inWindow: true).environmentObject(store)
                .navigationTitle(windowTitle)
        }
        .defaultSize(width: 600, height: 700)
        MenuBarExtra {
            Panel().environmentObject(store)
        } label: {
            if !store.online {
                Text("CC ⚠︎")
            } else {
                Text(menuTitle)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
