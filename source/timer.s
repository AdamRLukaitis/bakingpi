.global timer_address
.global timer_wait

.equ BCM2708_BASE,    0x20000000
.equ TIMER_BASE,      0x20003000

timer_address:
  ldr r0, =TIMER_BASE
  mov pc, lr


// r0 is the number of microseconds to wait (1MHz timer)
timer_wait:
  push {lr, r3}

  mov r1, r0                          // get the timeraddr and waittime
  bl timer_address

  timeraddr   .req r0
  waittime    .req r1
  currtime    .req r2

  ldrd r2, r3, [timeraddr, #4]        // load 8 bytes from timeraddr to r2,r3 - r2 has the lower 4 bytes, which is all that we need
  add waittime, currtime              // waittime now has the final time we have to wait for

timer_wait_loop$:
  ldrd currtime, r3, [timeraddr, #4]
  cmp waittime, currtime
  bhi timer_wait_loop$

  pop {r3, pc}