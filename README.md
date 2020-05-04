# Centipede

FPGA implementation by lisper of [Centipede](https://github.com/lisper/arcade-centipede "Centipede") arcade game 
Port to MiSTer by Alan Steremberg

# Keyboard inputs :
```
   F1          : Coin + Start 1P
   F2          : Coin + Start 2P
   LEFT,RIGHT,UP,DOWN  arrows : Steering
   Space,Ctrl  : Fire

   MAME/IPAC/JPAC Style Keyboard inputs:
     5           : Coin 1
     6           : Coin 2
     1           : Start 1 Player
     2           : Start 2 Players
     R,F,D,G     : Player 2 Movements
     A           : Player 2 Fire
   

 Joystick support. 
```

# Known Problems

Not sure the colors are quite right.
 
# ROMs
```
                                *** Attention ***

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip

