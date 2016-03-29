using HttpServer
using WebSockets

static = HttpHandler() do req, res
  root = joinpath(pwd(), "public")
  path = req.resource == "/" ? "index.html" : req.resource[2:end]
  path = normpath(root, path)
  startswith(path, root) ? HttpServer.FileResponse(path) : Response(404)
end

ws = WebSocketHandler() do req, client
  while true
    msg = utf8(read(client))
    println(msg)
    write(client, msg)
  end
end

server = Server(static, ws)
run(server, 31337)
