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
import blockmanager

var manager* {.threadvar.}: BlockManager
var clients {.threadvar.}: seq[AsyncSocket]

const
  RequestAll = "requestall"
  ResponseAll = "responseall"
  RequestLatest = "requestlatest"
  ResponseLatest = "responselatest"

proc requestAll(): string =
  result = $$newMessage(RequestAll, @[])

proc requestLatest*(): string =
  echo "Request all blocks"
  result = $$newMessage(RequestLatest, @[])

proc responseLatest*(): string =
  echo "Request latest block"
  let latest = manager.latestBlock()
  result = $$newmessage(ResponseLatest, @[latest])

proc responseAll(): string =
  result = $$newMessage(ResponseAll, manager.blocks)

proc broadcast*(data: string) =
  for client in clients:
    waitFor client.sendText(data, false)

proc processResponseLatest(data: seq[Block]) =
  let latest = manager.latestBlock()
  if latest.depth < data[0].depth:
    if latest.hash == data[0].previousHash:
      echo "Got the latest block"
      manager.blocks.add(data[0])
    else:
      broadcast(requestAll())

proc processResponseAll(data: seq[Block]) =
  manager.replace(data)

proc call(sock: AsyncSocket) {.async.} =
  await sock.sendText(requestLatest(), false)
  while true:
    try:
      let f = await sock.readData(false)
      if f.opcode == Opcode.Text:
        let msg = to[Message](f.data)
        case msg.code
        of RequestLatest:
          echo "Received request of latest block"
          waitFor sock.sendText(responseLatest(), false)
        of RequestAll:
          echo "Received request of all blocks"
          waitFor sock.sendText(responseAll(), false)
        of ResponseAll:
          echo "Received all blocks"
          processResponseAll(msg.blocks)
        of ResponseLatest:
          echo "Received latest block"
          processResponseLatest(msg.blocks)
    except:
      echo getCurrentExceptionMsg()
      # clients.delete(req.client)
      break

proc connect*(address: string, number: int) {.async.} =
  echo "Connect to " & address
  let ws = await newAsyncWebsocket(address, Port number, "/?encoding=text", ssl = false)
  clients.add(ws.sock)
  asyncCheck call(ws.sock)

proc initWs*(number: int) {.async.} =
  clients = @[]
  proc cb(req: Request) {.async.} =
    let (success, error) = await verifyWebsocketRequest(req)
    if success:
      clients.add(req.client)
      asyncCheck call(req.client)
  manager = newBlockManager()
  let server = newAsyncHttpServer()
  asyncCheck server.serve(Port(number), cb)