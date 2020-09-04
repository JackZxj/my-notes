# Play with Raspberry Pi zero W V1.1

## Device Info

| item | value |
| --- | --- |
| cpu | 1G (BCM2835) |
| arch | ARMv6l (32bit) |
| RAM | 512MB |
| ROM | 64GB (Depends on your TF card) |

## Install OS

### Choose OS

Because of low power, you had better not to install an OS with a desktop.

The official OS is the best (I think): [Raspberry Pi OS (32-bit) Lite](https://downloads.raspberrypi.org/raspios_lite_armhf_latest)

### Install

[Official Tools:](https://www.raspberrypi.org/downloads/)

> Raspberry Pi OS (previously called Raspbian) is our official operating system for all models of the Raspberry Pi.
>  
> Use Raspberry Pi Imager for an easy way to install Raspberry Pi OS and other operating systems to an SD card ready to use with your Raspberry Pi:
>  
> * [Raspberry Pi Imager for Windows](https://downloads.raspberrypi.org/imager/imager_1.4.exe)
> * [Raspberry Pi Imager for macOS](https://downloads.raspberrypi.org/imager/imager_1.4.dmg)
> * [Raspberry Pi Imager for Ubuntu](https://downloads.raspberrypi.org/imager/imager_1.4_amd64.deb)

Select your OS image and write it to the TF card.

### No Screen Initialization

Add two files into root of TF card:

* `ssh`
  + The `ssh` file is an empty file used to enable remote login of raspberrypi.
* `wpa_supplicant.conf` :

``` conf
country=CN
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="name of your wifi"    # 2.4G wifi only
    psk="password of your wifi"
    key_mgmt=WPA-PSK            # Whether WPA-PSK or WPA2-PSK, it's always WPA-PSK
}
```

Put the TF card into device. Plug in and wait for initialization.

If you can get the raspberry pi device in your router manager, congratulations! Then you can enjoy your raspberry pi zero!
