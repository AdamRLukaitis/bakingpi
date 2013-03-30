.section .init

.global _start

_start:
  b main

.section .text

main:
  // relocate stack
  mov sp, #0x8000

  // set pin function to output
  mov r0, #16
  mov r1, #1    
  bl gpio_set_function

main_loop$:

  ldr r0, =250000
  ldr r1, =80000
  bl blink$
  bl blink$
  bl blink$

  ldr r0, =125000
  bl blink$
  bl blink$
  bl blink$

  ldr r0, =250000
  bl blink$
  bl blink$
  bl blink$

  ldr r0, =500000
  bl timer_wait

  // keep blinking
  b main_loop$


blink$:
  push {lr, r3, r4}

  mov r3, r0
  mov r4, r1

  // drop pin - led on
  mov r0, #16
  mov r1, #0
  bl gpio_set_value

  // sleep for some time
  mov r0, r3
  bl timer_wait

  // pull up pin - led off
  mov r0, #16
  mov r1, #1
  bl gpio_set_value

  // sleep for half the time
  ldr r0, r4
  bl timer_wait

  pop {r4, r3, pc}