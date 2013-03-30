.global gpio_address
.global gpio_set_function
.global gpio_set_value

.equ BCM2708_BASE,    0x20000000
.equ GPIO_BASE,       0x20200000

gpio_address:
  ldr r0, =GPIO_BASE
  mov pc, lr

gpio_set_function:
  pinnum .req r0
  pinfun .req r1

  cmp pinnum, #53            // compare r0 to 53
  cmpls pinfun, #7            // if less or equal (suffix -ls), compare r1 to #7
  movhi pc, lr                // if greater than (suffix -hi), mov lr to pc (return)

  push {lr,r3}                // push lr onto the stack so we can call another function, and r3 because we need to save anything above r2 due to the ABI
  mov r3, pinnum             // functions return in r0, so preserve the current value for reference
  bl gpio_address             // call gpio_address

  .unreq pinnum

  gpioaddr .req r0
  pinnum .req r3

// the function select on the gpio is broken up into 5 registers, each addressing 10 pins.
//
//    while(pinnum > 9)
//      pinnum -= 10
//      registeraddr += 4bytes
//

_gpio_set_function_loop1$:        
  cmp pinnum, #9            // if greater than 9
  subhi pinnum, #10         //      sub 10 from r3 (19 -> 9)
  addhi gpioaddr, #4        //      add 4 to r0 (0x20200000 -> 0x20200004)
  bhi _gpio_set_function_loop1$        //      run again

// now we know the register to write to (gpioaddr), now we just have to get 
// the function value to the correct place in the register. since there's 3bits
// of function value, we jump into the register by pinnum * 3, and then shift
// the function value that far, and finally write it into the register.

  add pinnum, pinnum, lsl #1   // offset = pin * 3
  lsl pinfun, pinnum           // funval = funval << offset
  str pinfun, [gpioaddr]       // register@gpioaddr = funval

  .unreq pinnum
  .unreq pinfun
  .unreq gpioaddr

  pop {r3, pc}

gpio_set_value:
  pinnum .req r0
  pinval .req r1

  cmp pinnum, #53            // pinnum ?= 53
  movhi pc, lr                // if greater than, mov lr to pc (return)

  push {lr, r3, r4}           // prep to call
  mov r3, pinnum             // move pinnum to r3 and fix the alias       

  .unreq pinnum
  pinnum .req r3

  bl gpio_address             // get the address and alias it
  gpioaddr .req r0      

  pinbank .req r4             // refer to r4 as pinbank
  lsr pinbank, pinnum, #5   // pinbank = pin / 32               if < 32, = 0, if > 32, = 1      1|10101 (53)
  lsl pinbank, #2            // pinbank = pinbank * 4            either 0, or 4
  add gpioaddr, pinbank     // gpioaddr = gpioaddr + pinbank    either x20200000 or x20200004

  .unreq pinbank
  setbit .req r4

  and pinnum, #31            // the specific pin in the pinbank
  mov setbit, #1
  lsl setbit, pinnum        // b<31,0>1 << pinnum               the specific bit for the pin

  .unreq pinnum

  teq pinval, #0                   // are we setting the pin = 0
  .unreq pinval

  streq setbit, [gpioaddr, #40]   // if == 0, store the bit in gpio + 40 (off)
  strne setbit, [gpioaddr, #28]   // if != 0, store the bit in gpio + 28 (on)

  .unreq setbit
  .unreq gpioaddr

  pop {r4, r3, pc}