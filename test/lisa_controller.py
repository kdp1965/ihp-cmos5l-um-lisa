# SPDX-License-Identifier: Apache2.0
# Copyright (C) 2025 Ken Pettit

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import time
import sys
import select

REG_EXEC = 0
REG_ACC = 1
REG_PC = 2
REG_SP = 3
REG_RA = 4
REG_IX = 5
REG_RAM = 6
REG_BREAK = 8
REG_IO = 0x1b
REG_UIO = 0x1c
REG_SPI_QSPI = 0x17
REG_CACHE = 0x1d
REG_SPI_MODE = 0x1e

class LisaController:
  def __init__(self, dut):
    self.halted = True
    self.dut = dut

  # ==================================================
  # Write a byte to the UART
  # ==================================================
  async def send_tx_byte(self, data):
     count = 0

     # Wait for the UART TX to be ready 
     while not self.dut.tx_buf_empty.value and count < 80000:
        await ClockCycles(self.dut.clk, 1)
        count = count + 1

     # Test for timeout
     assert count != 20000

     # Configure the write
     self.dut.tx_d.value = data
     self.dut.tx_wr.value = 1
     await ClockCycles(self.dut.clk, 2)

     self.dut.tx_wr.value = 0
     await ClockCycles(self.dut.clk, 2)

  # ==================================================
  # Read a byte from the UART
  # ==================================================
  async def read_rx_byte(self):
     count = 0

     # Wait for the UART TX to be ready 
     while not self.dut.rx_avail.value and count < 80000:
        await ClockCycles(self.dut.clk, 1)
        count = count + 1

     # Test for timeout
     assert count != 20000

     # Perform a read
     retval = self.dut.rx_d.value
     self.dut.rx_rd.value = 1
     await ClockCycles(self.dut.clk, 1)

     self.dut.rx_rd.value = 0
     await ClockCycles(self.dut.clk, 1)
     return retval

  async def writeStr(self, s):
    for ch in s:
      await self.send_tx_byte(ord(ch))

  async def readLine(self, timeout_ms=100):
    line = ''
    start = int(time.perf_counter() * 1000)
    while True:
      c = await self.read_rx_byte()
      line += chr(c)
      if c == ord('\r'):
        break
      if c == ord('s') and line != 'lis':
        self.halted = True
        break

    return line.strip('\n\r')
#    return line.decode('utf-8').strip('\n\r')

  async def get_ver(self):
    for x in range(5):
      await self.writeStr('\n')
      s = await self.readLine()
      s = await self.readLine()
    await self.writeStr('v')
    ver = await self.readLine()
    return ver

  async def write_reg(self, reg: int, value: int):
    await self.writeStr(f'w{reg:02x}{value:04x}\n\n')
    s = await self.readLine()

  async def read_reg(self, reg: int):
    await self.writeStr(f'r{reg:02x}\n')
    s = await self.readLine()
    try:
      val = int(s, 16)
    except:
      val = 0xDEAD

    return val

  async def reset(self):
    await self.writeStr('t')

  async def step(self):
    await self.write_reg(REG_EXEC, 5)

  async def cont(self, run_delay=0.0):
    await self.writeStr(f'w000000\n')
    self.halted = False
    if run_delay > 0.0:
      time.sleep(run_delay)

  async def set_breakpoint(self, n, addr):
    await self.write_reg(REG_BREAK + n, 0x8000 | addr)

  async def clear_breakpoint(self, n):
    await self.write_reg(REG_BREAK + n, 0)

  async def await_break(self, timeout = 1.0):
    if self.halted:
      return

    start = int(time.perf_counter() * 1000)
    while True:
      c = await self.read_rx_byte(dut)
      if c == b's':
        self.halted = True
        break

      if time.ticks_diff(int(time.perf_counter() * 1000), start) > timeout * 1000:
        print("LISA did not halt")
        break

  async def get_pc(self):
    return await self.read_reg(REG_PC)

  async def set_pc(self, value: int):
    await self.write_reg(REG_PC, value)

  async def get_sp(self):
    return await self.read_reg(REG_SP)

  async def set_sp(self, value: int):
    await self.write_reg(REG_SP, value)

  async def get_ix(self):
    return await self.read_reg(REG_IX)

  async def set_ix(self, value: int):
    await self.write_reg(REG_IX, value)

  async def get_acc(self):
    return await self.read_reg(REG_ACC) & 0xFF

  async def set_acc(self, value: int):
    acc = await self.read_reg(REG_ACC) & 0xFF00;
    await self.write_reg(REG_ACC, acc | value)

  async def get_ram(self, addr, len):
    d = []
    ix = await self.get_ix()
    for i in range(len):
      await self.set_ix(addr + i)
      d.append(self.read_reg(REG_RAM))
    await self.set_ix(ix)
    return d

  async def dump_ram(self):
  # Dump the final contents of DFFRAM
    print("DFFRAM Contents:")
    d = await self.get_ram(0, 128)
    inrow = 0
    addr = 0
    for b in d:
      if inrow == 0:
        print(f'0x{addr:02x}  ', end='')
      print(f'{b:02x} ', end='')
      inrow += 1
      if inrow == 16:
        print('')
        inrow = 0
      addr += 1

# vim: sw=2 ts=2 et
