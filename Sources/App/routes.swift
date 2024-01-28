import Vapor

func routes(_ app: Application) throws {
    app.get("index.html") { req async throws in
        return req.redirect(to: "./", redirectType: .permanent)
    }

    app.get { req async throws -> View in
        let mazeRequest = try req.query.decode(MazeRequest.self)

        let maze = Maze(
            width: mazeRequest.width,
            height: mazeRequest.height
        )

        return try await req.view.render(
            "index",
            [
                "maze": maze.description,
                "mazeWidth": "\(mazeRequest.width)",
                "mazeHeight": "\(mazeRequest.height)"
            ]
        )
    }
}
