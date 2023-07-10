# Nerves_rpi4
## rpi4 on ttyAMA4(UART5)
NervesでUART5を使いたい。  
config.txtやconfig.exsやfwup.confを使用する。  

#### config.txt
```
dtoverlay=uart5
```
#### config.exs
```
config :nerves, :firmware, rootfs_overlay: "rootfs_overlay", fwup_conf: "config/fwup.conf"
```
#### fwup.conf
```
file-resource uart5.dtbo {
    host-path = "${NERVES_SYSTEM}/images/rpi-firmware/overlays/uart5.dtbo"
}

    on-resource uart5.dtbo { fat_write(${BOOT_A_PART_OFFSET}, "overlays/uart5.dtbo") }

    on-resource uart5.dtbo { fat_write(${BOOT_A_PART_OFFSET}, "overlays/uart5.dtbo") }

    on-resource uart5.dtbo { fat_write(${BOOT_B_PART_OFFSET}, "overlays/uart5.dtbo") }
```

#### Circuits.UART.enumerate
SSHでログインしてCircuits.UART.enumerateで確かめる。  
ttyAMA4(UART5)が増えた。  
```
iex(1)> Circuits.UART.enumerate
%{
  "ttyAMA0" => %{},
  "ttyAMA1" => %{},
  "ttyAMA2" => %{},
  "ttyAMA3" => %{},
  "ttyAMA4" => %{},
  "ttyS0" => %{}
}
```