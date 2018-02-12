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
# date  : 2018-02-12

import bblock
import message
import marshal

type
  MessageBuilder = object
    code: string
    blocks: seq[Block]

proc newMessageBuilder*(): MessageBuilder =
  result = MessageBuilder(
    code: "",
    blocks: @[]
  )

proc code*(builder: MessageBuilder, code: string): MessageBuilder =
  result = builder
  result.code = code

proc blocks*(builder: MessageBuilder, blocks: seq[Block]): MessageBuilder =
  result = builder
  result.blocks = blocks

proc build*(builder: MessageBuilder): Message =
  result = newMessage(builder.code, builder.blocks)

proc toJson*(message: Message): string =
  result = $$message
