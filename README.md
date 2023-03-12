# epGB - Game Boy / Game Boy Color Emulator on an FPGA

epGB is an implementation of Nintendo's __Game Boy__ (__GB__) and __Game Boy Color__ (__GBC__) written in SystemVerilog.
It works on an FPGA board with a board for connection to GB/GBC cartridges.

It has no built-in MBCs, and can basically only operate in real-time communication with cartridges.

The system automatically detects whether the cartridge is "for GB", "GB/GBC dual compatible" or "for GBC only" and starts up in GB mode or GBC mode accordingly.
In the case of a "GB/GBC dual compatible" cartridge, it is also possible to force startup in GB mode.

By using an expansion board equipped with a link port, it is possible to communicate with an actual GB/GBC device via a Nintendo __Game Link Cable__.

The operation has been confirmed with Terasic DE0-CV Board.

---
Demo Video:  
<https://youtu.be/pQHvBj9nH0k>

---

<br>

![Playing Kirby's Dream Land](images/playing_kirby.png "Playing Kirby's Dream Land (1992, HAL Laboratory)")

![Playing Pokémon Crystal](images/playing_poke_crystal.png "Playing Pokémon Crystal (2000, Game Freak)")

![Terasic DE0-CV and my own board for connecting the FPGA and GB/GBC cartridges](images/board.jpg "Terasic DE0-CV and my own board for connecting the FPGA and GB/GBC cartridges")
