@testable import App
import XCTVapor

final class MazeCellTests: XCTestCase {
    func testVisited() throws {
        var cell = MazeCell()
        XCTAssertFalse(cell.isVisited)

        cell.visit()
        XCTAssertTrue(cell.isVisited)

        // visiting a cell twice is ok
        cell.visit()
        XCTAssertTrue(cell.isVisited)
    }

    func testWalls() throws {
        var cell = MazeCell()

        XCTAssertTrue(cell.hasWallTop)
        cell.removeWallTop()
        XCTAssertFalse(cell.hasWallTop)

        XCTAssertTrue(cell.hasWallRight)
        cell.removeWallRight()
        XCTAssertFalse(cell.hasWallRight)

        XCTAssertTrue(cell.hasWallBottom)
        cell.removeWallBottom()
        XCTAssertFalse(cell.hasWallBottom)

        XCTAssertTrue(cell.hasWallLeft)
        cell.removeWallLeft()
        XCTAssertFalse(cell.hasWallLeft)
    }
}
