# Copyright 2017 Yoshihiro Tanaka
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

  # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software # distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Yoshihiro Tanaka <contact@cordea.jp>
# date  : 2018-02-04

import websocket
import asynchttpserver
import asyncnet
import asyncdispatch
import marshal
import sequtils
import bblock
import message
import messagebuilder
import blockmanager
import times

var manager* {.threadvar.}: BlockManager
var clients {.threadvar.}: seq[AsyncSocket]

const
  RequestAll = "requestall"
  ResponseAll = "responseall"
  RequestLatest = "requestlatest"
  ResponseLatest = "responselatest"

proc log(log: string) =
  echo "[", $epochTime(), "] ", log

proc broadcast*(data: string) =
  log "Broadcast to " & $clients.len & " clients"
  for client in clients:
    waitFor client.sendText(data, false)

proc getLatestRequest*(): string =
  log "Request latest block"
  result = newMessageBuilder()
    .code(RequestLatest)
    .build()
    .toJson()

proc getLatestResponse*(): string =
  let latest = manager.latestBlock()
  result = newMessageBuilder()
    .code(ResponseLatest)
    .blocks(@[latest])
    .build()
    .toJson()

proc onReceivedLatestResponse(data: seq[Block]) =
  let latest = manager.latestBlock()
  if latest.depth < data[0].depth:
    if latest.hash == data[0].previousHash:
      log "Got the latest block"
      manager.blocks.add(data[0])
      broadcast(getLatestResponse())
    else:
      broadcast(
        newMessageBuilder()
          .code(RequestAll)
          .build()
          .toJson()
      )

proc onReceivedAllResponse(data: seq[Block]) =
  if manager.tryReplace(data):
    broadcast(getLatestResponse())

proc call(sock: AsyncSocket) {.async.} =
  waitFor sock.sendText(getLatestRequest(), false)
  while true:
    try:
      let f = await sock.readData(false)
      if f.opcode == Opcode.Text:
        let msg = to[Message](f.data)
        case msg.code
        of RequestLatest:
          log "Received request of latest block"
          waitFor sock.sendText(getLatestResponse(), false)
        of RequestAll:
          log "Received request of all blocks"
          let response = newMessageBuilder()
            .code(ResponseAll)
            .blocks(manager.blocks)
            .build()
            .toJson()
          waitFor sock.sendText(response, false)
        of ResponseAll:
          log "Received all blocks"
          onReceivedAllResponse(msg.blocks)
        of ResponseLatest:
          log "Received latest block"
          onReceivedLatestResponse(msg.blocks)
    except:
      echo getCurrentExceptionMsg()
      # clients.delete(req.client)
      break

proc connect*(address: string, number: int) {.async.} =
  log "Connect to " & address
  let ws = await newAsyncWebsocket(address, Port number, "/?encoding=text", ssl = false)
  clients.add(ws.sock)
  asyncCheck call(ws.sock)

proc initWs*(number: int) {.async.} =
  clients = @[]
  proc cb(req: Request) {.async.} =
    let (success, _) = await verifyWebsocketRequest(req)
    if success:
      clients.add(req.client)
      asyncCheck call(req.client)
  manager = newBlockManager()
  let server = newAsyncHttpServer()
  asyncCheck server.serve(Port(number), cb)
