# Graduate Instructional Assistant for Microprocessors Lab 
**Microprocessors Laboratory (EE 3420), Ingram School of Engineering, Texas State University** | Aug 2022 - May 2024

I supported EE 3420: Microprocessors, a hands-on embedded systems lab where students write C for microcontroller and wire up real peripherals. Over four semesters I worked alongside the professor in the lab sessions, held office hours, signed off students demos, helped students debug their hardware and code, and graded their lab reports.

### At a glance 
---
|**Course**|EE 3420 Microprocessors(lab component)|
|---|---|
|**Duration**| 4 semsesters, Aug 2022 -  May 2024|
|**Platforms**| Semesters 1-2: Arduino Mega 2560. Semesters 3-4: Xilinx Zynq "Blackboard"(ARM Cortex-A9+FPGA)|
|**Interfaces covered**| G{IO, UART, SPI, I2C, PWM, timers and interrupts, ADC|
|**Languages and tools**| C, Arduino IDE, Xilinx Vitis|
|**My role**| Lab session support, office hours, demo sign-offs, debugging help, report grading|

### 1. The course and how it changed
The lab is a sequence of projects. Each is demonstrated live and followed by a written report. The platform and project list changed between the early and later semesters. 

| | Semesters 1-2 (Arduino)| Semesters (Blackboard)|
|---|---|---|
|**Hardware**|Arduino Mega 2560, bought by students as a starter kit | Zynq Blackboard(ARM + FPGA), loaned out and returned at semester end|
|**Programming model**|Arduino C, serial monitor over USB-UART| Bare -metal C in Vitis, accessing peripherals through memory-mapped registers|
|**Number of labs**| 9| 7|
|**Lab sequence**| UART prime finder, keypad and LCD, stepper motor, traffic control, PWM motors, ADC sensors, SPI, I2C, (RTC, EEPROM), weather station| LEDs and switches (with PWM RGB), 7-segment stopwatch(timer, interrupts), UART prime finder, inter-board communication(stoplight), SPI inertial sensor, I2C temperature sensor, PWM servo control.|

**Why this mattered for support:** moving from Arduino library calls to memory-mapped registers and hardware timers made problems harder to find. Students had to understand addresses, bit fields and interrupt flags, not just function calls, so the second half of my time involved more low-level debugging.

---
## 2. What I did

### Lab sessions and office hours
- Supported the two weekly lab sessions, normally alongside the professor, and ran the session myself whenever the professor could not attend.
- Held office hours so students working on their own between sessions had help available during the week.

### Demo sign-offs and checking results
- Every lab required a live demonstration to earn credit. I watched demos, checked that the results matched what the assignment asked for, and signed students off.

### Debugging and logic support
Students most often got stuck where hardware and software meet. My approach was to help them narrow the problem down themselves instead of handing over the answer.

| Interface | Typical problem | How I approached it |
|---|---|---|
| **UART** | Garbled or no output | Check COM port, baud rate and frame format (e.g. 115200, 8N1) match on both ends before touching the code |
| **SPI** | Sensor returns constant or wrong values | Check clock polarity and phase (mode), chip-select timing, and byte order against the datasheet |
| **I2C** | Device not found | Verify the device address, wiring, and pull-up resistors |
| **PWM** | LED or servo behaves oddly | Check the duty width never exceeds the period and cannot underflow below zero |
| **Timers and interrupts** | Stopwatch drifts or freezes | Check interval register values, that the interrupt is enabled, and that the flag is cleared |
| **Wiring** | Intermittent behavior | Re-check pin mapping, power and ground before blaming the code |

Note: The lab manuals, report template and lecture material were written by the course faculty. They are described here but not reproduced. 
