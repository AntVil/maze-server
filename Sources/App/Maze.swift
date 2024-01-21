import Vapor

struct Maze: CustomStringConvertible {
    static let startPosition = Position(x: 0, y: 0)

    let grid: MazeGrid

    var description: String { self.grid.description }

    init(width: Int, height: Int) {
        var grid = MazeGrid(width: width, height: height)
        grid.visit(position: Self.startPosition)

        var stack = [Self.startPosition]

        while let current = stack.last {
            let options = grid.getMovementOptions(for: current)

            guard let selectedOption = options.randomElement() else {
                let _ = stack.popLast()
                continue
            }

            let next: Position

            switch selectedOption {
            case .top(let top):
                grid.removeWallsBetween(top: top, bottom: current)
                next = top
            case .right(let right):
                grid.removeWallsBetween(left: current, right: right)
                next = right
            case .bottom(let bottom):
                grid.removeWallsBetween(top: current, bottom: bottom)
                next = bottom
            case .left(let left):
                grid.removeWallsBetween(left: left, right: current)
                next = left
            }

            grid.visit(position: next)
            stack.append(next)
        }

        self.grid = grid
    }
}

enum DirectionOption {
    case top(next: Position)
    case right(next: Position)
    case bottom(next: Position)
    case left(next: Position)
}

struct MazeGrid: CustomStringConvertible {
    let width: Int
    let height: Int

    var grid: [MazeCell]

    var description: String {
        var result = ""

        for y in 0...height {
            for x in 0...width {
                result += MazeWall(
                    topLeft: self[y - 1, x - 1],
                    topRight: self[y - 1, x],
                    bottomLeft: self[y, x - 1],
                    bottomRight: self[y, x]
                )
            }
            result += "\n"
        }

        return result
    }

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.grid = Array(repeating: .init(), count: width * height)
    }

    subscript(_ position: Position) -> MazeCell? {
        get {
            guard
                position.x >= 0,
                position.x < self.width,
                position.y >= 0,
                position.y < self.height
            else {
                return nil
            }

            return self.grid[position.y * self.width + position.x]
        }
        set(newValue) {
            self.grid[position.y * self.width + position.x] = newValue!
        }
    }

    subscript(_ y: Int, _ x: Int) -> MazeCell? {
        guard
            x >= 0,
            x < self.width,
            y >= 0,
            y < self.height
        else {
            return nil
        }

        return self.grid[y * self.width + x]
    }

    func getMovementOptions(for position: Position) -> [DirectionOption] {
        var options = [DirectionOption]()
        options.reserveCapacity(4)

        let above = position.above
        if let cell = self[above], !cell.isVisited { options.append( .top(next: above) ) }

        let right = position.right
        if let cell = self[right], !cell.isVisited { options.append( .right(next: right) ) }

        let below = position.below
        if let cell = self[below], !cell.isVisited { options.append( .bottom(next: below) ) }

        let left = position.left
        if let cell = self[left], !cell.isVisited { options.append( .left(next: left) ) }

        return options
    }

    mutating func removeWallsBetween(left: Position, right: Position) {
        self[left]?.removeWallRight()
        self[right]?.removeWallLeft()
    }

    mutating func removeWallsBetween(top: Position, bottom: Position) {
        self[top]?.removeWallBottom()
        self[bottom]?.removeWallTop()
    }

    mutating func visit(position: Position) {
        self[position]?.visit()
    }
}

struct Position {
    let x: Int
    let y: Int

    var above: Position { Position(x: x, y: y - 1) }
    var right: Position { Position(x: x + 1, y: y) }
    var below: Position { Position(x: x, y: y + 1) }
    var left: Position { Position(x: x - 1, y: y) }
}

typealias MazeCell = UInt8
extension MazeCell {
    static let wallTopMask: UInt8 = 1 << 0
    static let wallRightMask: UInt8 = 1 << 1
    static let wallBottomMask: UInt8 = 1 << 2
    static let wallLeftMask: UInt8 = 1 << 3
    static let visitedMask: UInt8 = 1 << 4

    var hasWallTop: Bool { self & Self.wallTopMask == 0 }
    var hasWallRight: Bool { self & Self.wallRightMask == 0 }
    var hasWallBottom: Bool { self & Self.wallBottomMask == 0 }
    var hasWallLeft: Bool { self & Self.wallLeftMask == 0 }
    var isVisited: Bool { self & Self.visitedMask != 0 }

    /// Initialize an unvisited MazeCell with all walls
    init() {
        self = 0
    }

    mutating func removeWallTop() {
        self |= Self.wallTopMask
    }

    mutating func removeWallRight() {
        self |= Self.wallRightMask
    }

    mutating func removeWallBottom() {
        self |= Self.wallBottomMask
    }

    mutating func removeWallLeft() {
        self |= Self.wallLeftMask
    }

    mutating func visit() {
        self |= Self.visitedMask
    }
}

extension UInt8 {
    init(bool: Bool) {
        self = bool ? 1 : 0
    }
}

typealias MazeWall = String
extension MazeWall {
    init(topLeft: MazeCell?, topRight: MazeCell?, bottomLeft: MazeCell?, bottomRight: MazeCell?) {
        let topWall = UInt8(bool: topLeft?.hasWallRight ?? topRight?.hasWallLeft ?? false) << 3
        let rightWall = UInt8(bool: topRight?.hasWallBottom ?? bottomRight?.hasWallTop ?? false) << 2
        let bottomWall = UInt8(bool: bottomLeft?.hasWallRight ?? bottomRight?.hasWallLeft ?? false) << 1
        let leftWall = UInt8(bool: topLeft?.hasWallBottom ?? bottomLeft?.hasWallTop ?? false) << 0

        let wallCombination = topWall | rightWall | bottomWall | leftWall

        switch wallCombination {
        case 0b0000: self = "  "
        case 0b0001: self = "╴ "
        case 0b0010: self = "╷ "
        case 0b0011: self = "┐ "
        case 0b0100: self = "╶─"
        case 0b0101: self = "──"
        case 0b0110: self = "┌─"
        case 0b0111: self = "┬─"
        case 0b1000: self = "╵ "
        case 0b1001: self = "┘ "
        case 0b1010: self = "│ "
        case 0b1011: self = "┤ "
        case 0b1100: self = "└─"
        case 0b1101: self = "┴─"
        case 0b1110: self = "├─"
        case 0b1111: self = "┼─"
        default: fatalError()
        }
    }
}
