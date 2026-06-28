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

    // Real calendar state
    @State private var displayedMonth: Date = {
        Calendar.current.startOfDay(for: Date())
            .apply { Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: $0)) ?? $0 }
    }()
    @State private var logs: [DailyLog] = []
    @State private var selectedDay: SelectedDay? = nil

    private let cal = Calendar.current
    private let weekdayLabels = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    var body: some View {
        ZStack {
            Color.sysBG.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    sheetHeader
                    LinearGradient(colors: [.clear, .sysBlue.opacity(0.5), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(height: 1)
                    VStack(spacing: 14) {
                        statsRow
                        monthNavigator
                        weekdayHeader
                        calendarGrid
                        legend
                    }
                    .padding(16)
                }
            }
        }
        .presentationBackground(Color.sysBG)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear { fetchLogs() }
        .onChange(of: displayedMonth) { _, _ in fetchLogs() }
        .sheet(item: $selectedDay) { selected in
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
                Text(monthYearString(displayedMonth))
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

    // MARK: - Month Navigator
    private var monthNavigator: some View {
        HStack {
            // Prev month button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.sysBlue)
                    .frame(width: 36, height: 36)
                    .background(Color.sysCard2)
                    .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(monthString(displayedMonth))
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text(yearString(displayedMonth))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            // Next month button — disabled if we're already at current month
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    let next = cal.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    if next <= currentMonthStart {
                        displayedMonth = next
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isCurrentMonth ? Color.textDim : Color.sysBlue)
                    .frame(width: 36, height: 36)
                    .background(Color.sysCard2)
                    .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isCurrentMonth)
        }
    }

    // MARK: - Weekday header
    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(weekdayLabels, id: \.self) { day in
                Text(day)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar grid
    private var calendarGrid: some View {
        let cells = buildMonthCells()
        let weeks = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<min($0+7, cells.count)]) }

        return VStack(spacing: 4) {
            ForEach(weeks.indices, id: \.self) { weekIdx in
                HStack(spacing: 4) {
                    ForEach(weeks[weekIdx].indices, id: \.self) { dayIdx in
                        let cell = weeks[weekIdx][dayIdx]
                        calendarCell(cell)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
    }

    private func calendarCell(_ cell: MonthCell) -> some View {
        VStack(spacing: 3) {
            if cell.isEmpty {
                // Empty padding cell
                Color.clear
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(cellFill(cell))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(cell.isToday ? Color.sysCyan : Color.clear, lineWidth: 2)
                        )

                    VStack(spacing: 2) {
                        Text("\(cell.dayNumber)")
                            .font(.system(size: 11, weight: cell.isToday ? .bold : .regular, design: .monospaced))
                            .foregroundStyle(cellTextColor(cell))

                        // Quest dots row
                        if let log = cell.log, log.completedCount > 0 {
                            HStack(spacing: 1.5) {
                                questDot(done: log.workoutDone, color: .sysRed)
                                questDot(done: log.nutritionDone, color: .sysGreen)
                                questDot(done: log.studyDone, color: .sysBlue)
                                questDot(done: log.readingDone, color: .sysPurple)
                                questDot(done: log.recoveryDone, color: Color(hex: "#5B8CFF"))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let log = cell.log, !cell.isFuture {
                        selectedDay = SelectedDay(log: log, date: cell.date)
                    }
                }
            }
        }
    }

    private func questDot(done: Bool, color: Color) -> some View {
        Circle()
            .fill(done ? color : Color.sysBorder.opacity(0.4))
            .frame(width: 4, height: 4)
    }

    private func cellFill(_ cell: MonthCell) -> Color {
        if cell.isFuture || cell.isEmpty { return Color.sysBorder.opacity(0.1) }
        guard let log = cell.log, log.completedCount > 0 else {
            return Color.sysBorder.opacity(0.25)
        }
        if log.allComplete { return Color.sysBlue.opacity(0.35) }
        let ratio = Double(log.completedCount) / 5.0
        return Color.sysBlue.opacity(0.12 + ratio * 0.2)
    }

    private func cellTextColor(_ cell: MonthCell) -> Color {
        if cell.isFuture { return Color.textDim }
        if cell.isToday { return Color.sysCyan }
        if let log = cell.log, log.completedCount > 0 { return .white }
        return Color.textSecondary
    }

    // MARK: - Legend
    private var legend: some View {
        VStack(spacing: 8) {
            // Quest color key
            HStack(spacing: 12) {
                ForEach([
                    ("WRK", Color.sysRed),
                    ("NUT", Color.sysGreen),
                    ("STU", Color.sysBlue),
                    ("LRN", Color.sysPurple),
                    ("REC", Color(hex: "#5B8CFF"))
                ], id: \.0) { item in
                    HStack(spacing: 4) {
                        Circle().fill(item.1).frame(width: 6, height: 6)
                        Text(item.0)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
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
    }

    // MARK: - Month cell builder
    struct MonthCell {
        var isEmpty: Bool = false
        var dayNumber: Int = 0
        var date: Date = .now
        var isToday: Bool = false
        var isFuture: Bool = false
        var log: DailyLog? = nil
    }

    struct SelectedDay: Identifiable {
        let id = UUID()
        let log: DailyLog
        let date: Date
    }

    private func buildMonthCells() -> [MonthCell] {
        let today = cal.startOfDay(for: Date())
        let logMap = Dictionary(grouping: logs) { cal.startOfDay(for: $0.date) }
            .mapValues { $0.max(by: { $0.completedCount < $1.completedCount })! }

        // First day of displayed month
        guard let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)),
              let range = cal.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }

        // Weekday offset (0 = Sunday)
        let firstWeekday = cal.component(.weekday, from: firstOfMonth) - 1 // 0-indexed

        var cells: [MonthCell] = []

        // Leading empty cells
        for _ in 0..<firstWeekday {
            cells.append(MonthCell(isEmpty: true))
        }

        // Actual day cells
        for day in range {
            guard let date = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) else { continue }
            let isToday = cal.isDateInToday(date)
            let isFuture = date > today
            let log = logMap[date]
            cells.append(MonthCell(
                isEmpty: false,
                dayNumber: day,
                date: date,
                isToday: isToday,
                isFuture: isFuture,
                log: log
            ))
        }

        // Trailing empty cells to complete last row
        let remainder = cells.count % 7
        if remainder != 0 {
            for _ in 0..<(7 - remainder) {
                cells.append(MonthCell(isEmpty: true))
            }
        }

        return cells
    }

    // MARK: - Data
    private func fetchLogs() {
        guard let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)),
              let lastOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth) else {
            return
        }
        var desc = FetchDescriptor<DailyLog>(
            predicate: #Predicate { log in log.date >= firstOfMonth && log.date <= lastOfMonth },
            sortBy: [SortDescriptor(\.date)]
        )
        desc.fetchLimit = 32
        logs = (try? modelContext.fetch(desc)) ?? []
    }

    // MARK: - Helpers
    private var currentMonthStart: Date {
        cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
    }

    private var isCurrentMonth: Bool {
        cal.isDate(displayedMonth, equalTo: currentMonthStart, toGranularity: .month)
    }

    private func monthString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: date).uppercased()
    }

    private func yearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f.string(from: date)
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }
}

// MARK: - Date apply helper
extension Date {
    func apply(_ transform: (Date) -> Date) -> Date {
        transform(self)
    }
}
