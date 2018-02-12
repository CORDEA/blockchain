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

import bblock

type
  BlockManager* = object
    blocks*: seq[Block]

proc newBlockManager*(): BlockManager =
  result = BlockManager(
    blocks: @[getGenesisBlock()]
  )

proc latestBlock*(manager: BlockManager): Block =
  result = manager.blocks[manager.blocks.len - 1]

proc isValid(blks: seq[Block]): bool =
  for i in 1..(blks.len - 1):
    if not isValid(blks[i], blks[i - 1]):
      return false
  return true

proc add(manager: var BlockManager, blk: Block): Block =
  if isValid(blk, manager.latestBlock()):
    manager.blocks.add(blk)
    return blk
  return nil

proc add*(manager: var BlockManager, data: string): Block =
  let blk = manager.latestBlock()
  let newBlk = newBlock(
    blk.depth + 1,
    data,
    blk.hash
  )
  result = manager.add(newBlk)

proc replace*(manager: var BlockManager, blks: seq[Block]) =
  if isValid(blks):
    if manager.blocks.len < blks.len:
      manager.blocks = blks
