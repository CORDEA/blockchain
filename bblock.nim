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

import times
import sha256

type
  Block* = ref BlockObj
  BlockObj = object
    depth*: int
    timestamp: float
    data: string
    hash*: string
    previousHash*: string

proc getCalcString(depth: int, timestamp: float, data: string, prevHash: string): string =
  result = $depth & $timestamp & data & prevHash

proc calcHash*(blk: Block): string =
  result = calcHash(getCalcString(blk.depth, blk.timestamp, blk.data, blk.previousHash))

proc newBlock*(depth: int, data: string, prevHash: string): Block =
  let timestamp = epochTime()
  result = Block(
    depth: depth,
    timestamp: timestamp,
    data: data,
    hash: calcHash(getCalcString(depth, timestamp, data, prevHash)),
    previousHash: prevHash
  )

proc getGenesisBlock*(): Block =
  result = Block(
    depth: 0,
    timestamp: 1518413918.591908,
    data: "genesis block",
    hash: "406D15347591941A9B025DAB641156008A51569731776DA2808F2E3C01D42E17",
    previousHash: "0"
  )
