# Copyright 2017 Yoshihiro Tanaka
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

  # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Yoshihiro Tanaka <contact@cordea.jp>
# date  : 2018-02-03

import marshal
import bblock
import blockmanager
import wshandler
import asyncdispatch
import asynchttpserver

const
  WsPortNumber = 4000
  ApiPortNumber = 8080

proc initApi() {.async.} =
  proc cb(req: Request) {.async.} =
    case req.url.path
    of "/mine":
      if req.reqMethod == HttpPost:
        let res = $$manager.add(req.body)
        if res == nil:
          await req.respond(Http400, "")
        else:
          await req.respond(Http200, $$res)
          broadcast(responseLatest())
    of "/blocks":
      if req.reqMethod == HttpGet:
        await req.respond(Http200, $$manager.blocks)
    of "/peer":
      if req.reqMethod == HttpPost:
        asyncCheck connect(req.body, WsPortNumber)
        await req.respond(Http200, "")
  let server = newAsyncHttpServer()
  asyncCheck server.serve(Port(ApiPortNumber), cb)

asyncCheck initApi()
asyncCheck initWs(WsPortNumber)

runForever()
