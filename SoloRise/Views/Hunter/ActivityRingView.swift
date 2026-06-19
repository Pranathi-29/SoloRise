import SwiftUI
import SwiftData

// MARK: - Activity Ring (main screen)
struct ActivityRing: View {
    let progress: Double // 0.0 to 1.0
    let done: Int
    let total: Int
    @State private var animatedProgress: Double = 0
    @State private var showCalendar = false

    var body: some View {
        Button { showCalendar = true } label: {
            HStack(spacing: 20) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(Color.sysBlue.opacity(0.15), lineWidth: 11)
                        .frame(width: 84, height: 84)

                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            AngularGradient(
                                colors: [Color.sysPurple, Color.sysBlue, Color.sysCyan, Color.sysBlue, Color.sysPurple],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 11, lineCap: .round)
                        )
                        .frame(width: 84, height: 84)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.sysPurple.opacity(0.7), radius: 10)

                    VStack(spacing: 0) {
                        Text("\(done)")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("/\(total)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .fixedSize()

                // Right side text
                VStack(alignment: .leading, spacing: 8) {
                    Text("QUESTS TODAY")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                        .tracking(1)
                        .lineLimit(1)

                    if done == total {
                        Text("ALL CLEAR")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.sysGreen)
                            .lineLimit(1)
                    } else {
                        Text("\(total - done) LEFT")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)
                    }

                    // Mini progress dots
                    HStack(spacing: 4) {
                        ForEach(0..<total, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(i < done ? Color.sysBlue : Color.sysBorder)
                                .frame(width: 24, height: 5)
                        }
                    }
                }

                Spacer()

                // Chevron hint
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textDim)
            }
            .padding(16)
            .background(Color.sysCard2)
            .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(done == total ? Color.sysGreen : Color.sysBlue)
                    .frame(width: 3)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newVal in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newVal
            }
        }
        .sheet(isPresented: $showCalendar) {
            CalendarSheet(done: done, total: total)
        }
    }
}

// MARK: - Full Calendar Sheet
struct CalendarSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let done: Int
    let total: Int

    @State private var logs: [DailyLog] = []
    @State private var selectedDay: (log: DailyLog, date: Date)? = nil

    private let columns = ["M", "Tu", "W", "Th", "F", "Sa", "Su"]

    var body: some View {
        ZStack {
            Color.sysBG.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    sheetHeader

                    // Glow line
                    LinearGradient(colors: [.clear, .sysBlue.opacity(0.5), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(height: 1)

                    VStack(spacing: 20) {
                        statsRow
                        calendarGrid
                        legend
                    }
                    .padding(20)
                }
            }
        }
        .presentationBackground(Color.sysBG)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear { fetchLogs() }
        .sheet(item: Binding(
            get: { selectedDay.map { SelectedDay(log: $0.log, date: $0.date) } },
            set: { _ in selectedDay = nil }
        )) { selected in
            DayDetailView(log: selected.log, date: selected.date)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Header
    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("ACTIVITY LOG")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.sysBlue)
                    .tracking(3)
                Text("Last 35 days")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Color.sysCard2)
                    .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.sysPanel)
    }

    // MARK: - Stats row
    private var statsRow: some View {
        let activeDays = logs.filter { $0.completedCount > 0 }.count
        let perfectDays = logs.filter { $0.allComplete }.count
        let totalQuests = logs.reduce(0) { $0 + $1.completedCount }

        return HStack(spacing: 0) {
            statChip(value: "\(activeDays)", label: "ACTIVE DAYS")
            Rectangle().fill(Color.sysBorder).frame(width: 1)
            statChip(value: "\(perfectDays)", label: "PERFECT DAYS")
            Rectangle().fill(Color.sysBorder).frame(width: 1)
            statChip(value: "\(totalQuests)", label: "TOTAL QUESTS")
        }
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
    }

    private func statChip(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: - Calendar grid
    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Day headers
            HStack(spacing: 4) {
                ForEach(columns, id: \.self) { d in
                    Text(d)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 5 weeks
            let cells = buildCells()
            ForEach(0..<5, id: \.self) { week in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { day in
                        let cell = cells[week * 7 + day]
                        calendarCell(cell)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
    }

    private func calendarCell(_ cell: CalendarCell) -> some View {
        VStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 3)
                .fill(cellFill(cell))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(cell.isToday ? Color.sysCyan : Color.clear, lineWidth: 2)
                )
                .shadow(color: cell.isToday ? Color.sysCyan.opacity(0.6) : .clear, radius: 4)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .onTapGesture {
                    if let log = cell.log {
                        selectedDay = (log, cell.date)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if cell.hasData {
                        Circle()
                            .fill(Color.sysCyan.opacity(0.6))
                            .frame(width: 4, height: 4)
                            .padding(2)
                    }
                }

            // Completion dots for days with partial progress
            if cell.hasData && cell.completionRate < 1.0 {
                HStack(spacing: 1) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Double(i) / 5.0 < cell.completionRate ? Color.sysBlue : Color.sysBorder)
                            .frame(width: 3, height: 3)
                    }
                }
            }
        }
    }

    private func cellFill(_ cell: CalendarCell) -> Color {
        if cell.isFuture { return Color.sysBorder.opacity(0.2) }
        if !cell.hasData { return Color.sysBorder.opacity(0.4) }
        switch cell.completionRate {
        case 1.0:    return Color.sysBlue
        case 0.8...: return Color.sysBlue.opacity(0.75)
        case 0.6...: return Color.sysBlue.opacity(0.55)
        case 0.4...: return Color.sysBlue.opacity(0.35)
        default:     return Color.sysBlue.opacity(0.2)
        }
    }

    // MARK: - Legend
    private var legend: some View {
        HStack(spacing: 16) {
            Text("LESS")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color.textDim)
            HStack(spacing: 4) {
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { val in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(val == 0 ? Color.sysBorder.opacity(0.4) : Color.sysBlue.opacity(0.2 + val * 0.8))
                        .frame(width: 14, height: 14)
                }
            }
            Text("MORE")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color.textDim)
            Spacer()
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.sysCyan, lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                Text("TODAY")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.textDim)
            }
        }
    }

    // MARK: - Data
    struct CalendarCell {
        var isToday: Bool
        var isFuture: Bool
        var hasData: Bool
        var completionRate: Double
        var date: Date = .now
        var log: DailyLog? = nil
    }

    struct SelectedDay: Identifiable {
        let id = UUID()
        let log: DailyLog
        let date: Date
    }

    private func buildCells() -> [CalendarCell] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let logMap = Dictionary(grouping: logs) { cal.startOfDay(for: $0.date) }
            .mapValues { dayLogs in
                dayLogs.max(by: { $0.completedCount < $1.completedCount })!
            }

        var cells: [CalendarCell] = []
        for offset in stride(from: -34, through: 0, by: 1) {
            guard let date = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            let isToday = cal.isDateInToday(date)

            if let log = logMap[date] {
                cells.append(CalendarCell(
                    isToday: isToday, isFuture: false,
                    hasData: log.completedCount > 0,
                    completionRate: Double(log.completedCount) / 5.0
                ))
            } else {
                cells.append(CalendarCell(isToday: isToday, isFuture: false,
                                          hasData: false, completionRate: 0))
            }
        }
        while cells.count < 35 {
            cells.insert(CalendarCell(isToday: false, isFuture: true,
                                      hasData: false, completionRate: 0), at: 0)
        }
        return Array(cells.suffix(35))
    }

    private func fetchLogs() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -35, to: .now) ?? .now
        var desc = FetchDescriptor<DailyLog>(
            predicate: #Predicate { log in log.date >= cutoff },
            sortBy: [SortDescriptor(\.date)]
        )
        desc.fetchLimit = 36
        logs = (try? modelContext.fetch(desc)) ?? []
    }
}
