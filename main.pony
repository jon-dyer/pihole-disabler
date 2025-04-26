use "assert"
use "collections"
use "encode/base64"
use "files"
use "http"
use "net_ssl"
use "net"
use "json"

actor Main
  """
  Fetch data from URLs on the command line.
  """
  new create(env: Env) =>
    var env_pass: String = ""
    var env_base: String = ""
    var timer: U64 = 120
    for plop in env.vars.values() do
      try
        let sploots = plop.split_by("=")
        let key = sploots(0)?
        let value = sploots(1)?
        match key
        | "PIHOLE_BASE_URL" => env_base = value
        | "PIHOLE_PASS" => env_pass = value
        | "PIHOLE_TIMER_SEC" =>
          try
            let t = value.u64(10)?
            if t <= 300 then
              timer = t
            else
              env.out.print("PHILE_TIMER_SEC too high, I am opinionatedly capping it at 5 minutes.")
              timer = 300
            end
          else
            env.err.print("Hey dude, your $PIHOLE_TIMER_SEC is in an invalid form. please check it.")
          end
        end
      else
        env.out.print("environment variable '" + plop + "' doesn't have left and right of = somehow")
      end
    end
    /*
    let url = try
      URL.valid(env_base)?
    else
      env.out.print("Invalid URL: " + env_base)
      env.exitcode(1)
      return
    end
    */
    let timeout = U64(200)

    // Start the actor that does the real work.
    GetAuth.create(env, env_base, env_pass, timer, timeout)

actor GetAuth
  """
  Do the work of fetching a resource
  """
  let _env: Env
  let _base_url: String
  let _timer: U64
  let _timeout: U64

  new create(env: Env, base_url: String, pass: String, timer: U64, timeout: U64)
    =>
    """
    Create the worker actor.
    """
    _env = env
    _base_url = base_url
    _timeout = timeout
    _timer = timer


    this.auth_me(pass)

  be send_post(url: URL, body: String) =>
    // Get certificate for HTTPS links.
     let ssl_context =
      recover
        SSLContext
          .>set_client_verify(false)
          // .>set_authority(FilePath(FileAuth(env.root), "cacert.pem"))?
      end
    /*
    else
      env.out.print("Unable to create cert.")
      env.exitcode(1)
    end
    */
    // The Notify Factory will create HTTPHandlers as required.  It is
    // done this way because we do not know exactly when an HTTPSession
    // is created - they can be re-used.
    let dumpMaker = recover val NotifyFactory.create(this) end

    // The Client manages all links.
    let client = HTTPClient(
      TCPConnectAuth(_env.root),
      dumpMaker,
      consume ssl_context
      where keepalive_timeout_secs = _timeout.u32()
    )

    let req = Payload.request("POST", url)
    req("User-Agent") = "Pony httpget"
    req("Content-Type") = "application/json"
    req.add_chunk(body)

    try
      // Submit the request
      let sentreq = client(consume req)?
      sentreq.finish()
      // Could send body data via `sentreq`, if it was a POST
    else
      try _env.out.print("Malformed URL: " + _env.args(1)?) end
      _env.exitcode(1)
    end

  be auth_me(pass: String) =>
    let body : String= "{\"password\":\"" + pass + "\"}"
    let url =  mk_url(_env, _base_url, "/auth")
    send_post(url, body)

  be block_off(sid: String) =>
    let body : String = "{\"blocking\": false, \"timer\": " + _timer.string() + ", \"sid\": \"" + sid + "\"}"
    let url =  mk_url(_env, _base_url, "/dns/blocking")
    send_post(url, body)

  be cancelled() =>
    """
    Process cancellation from the server end.
    """
    _env.out.print("-- response cancelled --")

  be failed(reason: HTTPFailureReason) =>
    match reason
    | AuthFailed =>
      _env.err.print("-- auth failed --")
    | ConnectFailed =>
      _env.err.print("-- connect failed --")
    | ConnectionClosed =>
      _env.err.print("-- connection closed --")
    end
    _env.exitcode(1)

  be have_response(response: Payload val) =>
    """
    Process return the the response message.
    """
    if response.status == 0 then
      _env.out.print("Failed")
      _env.exitcode(1)
      return
    end

    // Print the status and method
    /*
    _env.out.print(
      "Response " +
      response.status.string() + " " +
      response.method)
      */

    // Print all the headers
    /*
    for (k, v) in response.headers().pairs() do
      _env.out.print(k + ": " + v)
    end
    */

    // _env.out.print("")

    // Print the body if there is any.  This will fail in Chunked or
    // Stream transfer modes.
    try
      var body = response.body()?

      var bodyVal = ""
      for piece in body.values() do
         bodyVal = match piece
         | let a: Array[U8 val] val => String.from_array(consume a)
         | let s: String => s
         end
      end
      let jsBod = JsonDoc
      try
        jsBod.parse(bodyVal)?
      else
        _env.out.print("zorpzorp parsing bodyVal")
        _env.exitcode(1)
        return
      end
      let json: JsonObject = jsBod.data as JsonObject
      let mappy = json.data
      if mappy.contains("session") then
        let session: JsonObject = json.data("session")? as JsonObject
        let sid = session.data("sid")? as String
        this.block_off(sid)
      end
    else
      _env.out.print("no body, or parse error")
    end

  be have_body(data: ByteSeq val)
    =>
    """
    Some additional response data.
    """
    _env.out.write(data)

  be finished() =>
    """
    End of the response data.
    """
    _env.out.print("-- end of body --")

  fun mk_url(e: Env, base: String, path: String): URL
    =>
    let whole: String = base + path
    try
      return URL.valid(whole)?
    else
      e.out.print("Invalid URL")
      e.exitcode(1)
      return URL.create()
    end

class NotifyFactory is HandlerFactory
  """
  Create instances of our simple Receive Handler.
  """
  let _main: GetAuth

  new iso create(main': GetAuth) =>
    _main = main'

  fun apply(session: HTTPSession): HTTPHandler ref^ =>
    HttpNotify.create(_main, session)

class HttpNotify is HTTPHandler
  """
  Handle the arrival of responses from the HTTP server.  These methods are
  called within the context of the HTTPSession actor.
  """
  let _main: GetAuth
  let _session: HTTPSession

  new ref create(main': GetAuth, session: HTTPSession) =>
    _main = main'
    _session = session

  fun ref apply(response: Payload val) =>
    """
    Start receiving a response.  We get the status and headers.  Body data
    *might* be available.
    """
    _main.have_response(response)

  fun ref chunk(data: ByteSeq val) =>
    """
    Receive additional arbitrary-length response body data.
    """
    _main.have_body(data)

  fun ref finished() =>
    """
    This marks the end of the received body data.  We are done with the
    session.
    """
    _main.finished()
    _session.dispose()

  fun ref cancelled() =>
    _main.cancelled()

  fun ref failed(reason: HTTPFailureReason) =>
    _main.failed(reason)
