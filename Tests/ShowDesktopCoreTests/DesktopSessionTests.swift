import Testing
@testable import ShowDesktopCore

@Suite("Stacking order")
struct StackingOrderTests {
    @Test func putsTheFrontAppLast() {
        let windows = [
            WindowEntry(ownerPID: 30, layer: 0),
            WindowEntry(ownerPID: 10, layer: 0),
            WindowEntry(ownerPID: 20, layer: 0),
        ]
        #expect(StackingOrder.backToFront([10, 20, 30], windows: windows) == [20, 10, 30])
    }

    @Test func usesEachAppsFrontmostWindow() {
        let windows = [
            WindowEntry(ownerPID: 10, layer: 0),
            WindowEntry(ownerPID: 20, layer: 0),
            WindowEntry(ownerPID: 10, layer: 0),
        ]
        #expect(StackingOrder.backToFront([20, 10], windows: windows) == [20, 10])
    }

    @Test func ignoresMenusAndPanels() {
        let windows = [
            WindowEntry(ownerPID: 20, layer: 25),
            WindowEntry(ownerPID: 10, layer: 0),
            WindowEntry(ownerPID: 20, layer: 0),
        ]
        #expect(StackingOrder.backToFront([10, 20], windows: windows) == [20, 10])
    }

    @Test func putsAppsWithoutWindowsFirstInTheirOriginalOrder() {
        let windows = [WindowEntry(ownerPID: 10, layer: 0)]
        #expect(StackingOrder.backToFront([10, 40, 30], windows: windows) == [40, 30, 10])
    }

    @Test func handlesNoApps() {
        #expect(StackingOrder.backToFront([], windows: []).isEmpty)
    }
}

@Suite("Desktop session")
struct DesktopSessionTests {
    @Test func restoresWhatItHidInTheSameOrder() {
        var session = DesktopSession()
        session.begin(hiding: [20, 10, 30])
        session.recordMinimizedFinderWindows([7, 9])
        #expect(session.isShowingDesktop)

        let restore = session.end(stillRunning: [10, 20, 30, 99])
        #expect(restore.apps == [20, 10, 30])
        #expect(restore.front == 30)
        #expect(restore.finderWindows == [7, 9])
        #expect(!session.isShowingDesktop)
    }

    @Test func leavesOutAppsThatQuit() {
        var session = DesktopSession()
        session.begin(hiding: [20, 10, 30])
        let restore = session.end(stillRunning: [20, 10])
        #expect(restore.apps == [20, 10])
        #expect(restore.front == 10)
    }

    @Test func neverUnhidesAppsItDidntHide() {
        var session = DesktopSession()
        session.begin(hiding: [10])
        let restore = session.end(stillRunning: [10, 20, 30])
        #expect(restore.apps == [10])
    }

    @Test func forgetsEverythingAfterRestoring() {
        var session = DesktopSession()
        session.begin(hiding: [10])
        session.recordMinimizedFinderWindows([4])
        _ = session.end(stillRunning: [10])
        #expect(session == DesktopSession())
        #expect(session.end(stillRunning: [10]) == .init(apps: [], front: nil, finderWindows: []))
    }

    @Test func ignoresFinderWindowsReportedAfterRestoring() {
        var session = DesktopSession()
        session.begin(hiding: [10])
        _ = session.end(stillRunning: [10])
        session.recordMinimizedFinderWindows([4])
        #expect(session.minimizedFinderWindows.isEmpty)
    }
}
