## How it works

This project implements an SPI-controlled peripheral module that manages internal configuration and PWM registers.

## How to test

Drive the SPI lines (SCLK, COPI, nCS) via the dedicated inputs to send 16-bit commands.

## External hardware

* Microcontroller (e.g., Arduino or Raspberry Pi Pico) to act as SPI controller.