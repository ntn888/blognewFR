---
title: "TI CC1101: sub GHz, low power wireless"
description: "Gander at a sub GHz, low power wireless radio module - CC1101, for implementing wireless sensor networks"
date: 2026-06-02T07:30:00
draft: false
category: ["cc1101"]
tags: ["wsn", "sub-ghz", "low-power wireless"]
---

Over the years, in our blog, we've seen applications for standard BLE and Thread wireless. Here we'll look at a simple low cost sub 1GHz radio module, the [TI CC1101](https://www.ti.com/product/CC1101). Simple means more power efficient. It needs a controller for operation - any MCU would do. We'll reach for TI's own MSPM0 - value line, general purpose cortex-M0 mcu.

This radio module is ideally suited for low-power wireless sensor networks, with a central coordinator (ideally a Linux soc). This coordinator can then relay data to a MQTT broker or cloud server.

We'll tackle the setup in stages. This is more important since the module only provides the physical layer (PHY), and we need to implement packet acks, collision detection (in our multi-transmitter topology) in application. (Technically acknowledgement is implemented in radio, but we could make use of more sleep times if implemented in application.)

The module supports a range of frequencies under the GHz spectrum - 315/433/868/915 MHz. The [Aliexpress kit](https://www.aliexpress.com/item/1005003781140201.html) we'll be using has been designed to operate at 433MHz.

