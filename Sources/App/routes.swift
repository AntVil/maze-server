import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        let mazeRequest = try req.query.decode(MazeRequest.self)

        let maze = Maze(
            width: mazeRequest.width,
            height: mazeRequest.height
        )

        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>maze</title>
        </head>
        <body>
            <pre>\(maze.description)</pre>
            <style></style>
        </body>
        </html>
        """

        return Response(
            status: .ok,
            headers: .init([("contentType", "test/html")]),
            body: .init(string: html)
        )
    }
}

struct MazeRequest: Decodable {
    let width: Int
    let height: Int

    enum CodingKeys: String, CodingKey {
        case width
        case height
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.width = try container.decode(forKey: .width, default: 10) { (key, value) in
            try ensureInRange(key: key, value: value, range: 3 ... 50)
        }
        self.height = try container.decode(forKey: .height, default: 10) { (key, value) in
            try ensureInRange(key: key, value: value, range: 3 ... 50)
        }
    }
}

extension KeyedDecodingContainer {
    /// Decodes a value of the given type for the given key and validates it.
    /// - Parameters:
    ///   - key: The key that the decoded value is associated with.
    ///   - default: The default value if the value is not present.
    ///   - constrain: The constrain which has to be met to ensure a correct value.
    /// - Returns: A value of the requested type, if present for the given key and convertible to the requested type with the provided constrain.
    func decode<T: Decodable>(
        forKey key: Key,
        default: T,
        constrain: (Key, T) throws -> Void = {_,_ in }
    ) throws -> T {
        guard self.contains(key) else {
            return `default`
        }

        return try decodePresent(forKey: key, constrain: constrain)
    }

    /// Decodes a value of the given type for the given key and validates it.
    /// - Parameters:
    ///   - key: The key that the decoded value is associated with.
    ///   - constrain: The constrain which has to be met to ensure a correct value.
    /// - Returns: A value of the requested type, if present for the given key and convertible to the requested type with the provided constrain.
    func decode<T: Decodable>(
        forKey key: Key,
        constrain: (Key, T) throws -> Void = {_,_ in }
    ) throws -> T {
        guard self.contains(key) else {
            throw Abort(.badRequest, reason: "value '\(key.stringValue)' was not provided")
        }

        return try decodePresent(forKey: key, constrain: constrain)
    }

    private func decodePresent<T: Decodable>(forKey key: Key, constrain validate: (Key, T) throws -> Void) throws -> T {
        guard let value = try? self.decode(T.self, forKey: key) else {
            throw Abort(.badRequest, reason: "value '\(key.stringValue)' was not a valid \(T.self)")
        }

        try validate(key, value)

        return value
    }
}

func ensureInRange(key: CodingKey, value: Int, range: ClosedRange<Int>) throws {
    guard range.contains(value) else {
        throw Abort(.badRequest, reason: "value '\(key.stringValue)' was not between \(range.lowerBound) and \(range.upperBound), got \(value)")
    }
}
