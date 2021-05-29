# Raspberry Pi 1 Model B+ Setup for PS2 Controller

This guide will help you install software on your Pi that allows you to use modern gaming controllers to play games on your PlayStation 2.

The Pi 1 B+ is targeted since it is cheaper than the newer revisions and will remain in production until [at least January 2026.](https://www.raspberrypi.org/products/raspberry-pi-1-model-b-plus/)

## Prerequisite Hardware

- Raspberry Pi 1 Model B+
  - USB power cable with/without power brick
  - SD card (class 10 is recommended)
  - WiFi adapter/dongle (optional)
- Bluetooth adapter/dongle (optional)

## Installing Raspberry Pi OS

We will be using Raspberry Pi OS (previous known as Raspbian) as our OS. This OS contains the required up-to-date software.

To get started, head on over to the [Pi downloads website](https://www.raspberrypi.org/downloads/), click on the icon that takes you to the download page, and download the version that says **Raspberry Pi OS (32-bit) with desktop**. The desktop version will allow us to easily configure the OS after installation. Follow the installation guide linked in the download page if you are unsure on how to flash the image to an SD card.

**Note:** For advanced users, I would recommned using the lite OS installation.

After successfully booting into the OS for the first itime, enable network connectivity, enable SSH, and change any other settings. The rest of this guide will assume that you are able to access a relatively vanilla installation of Rasp Pi OS using SSH or keyboard & mouse input.

## Installing Bluetooth Software (Optional)

A important, yet optional, program is [bluetooth-disconnect.](https://github.com/jrouleau/bluetooth-autoconnect) This program will allow the Pi to reconnect to Bluetooth controllers (and any other Bluetooth devices) automatically **once they have been paired and trusted.**

Unfortunately, I am not the best person to show you how to pair your controller to your Pi via Bluetooth. This process can vary from controller to controller and can be confusing. However, I can point you to some resources that helped me out and will hopefully help you. Here they are:
- https://wiki.gentoo.org/wiki/Sony_DualShock (this guide worked for my
  DualShock 3)
- https://wiki.archlinux.org/index.php/Bluetooth (handy for troubleshooting)
- [Omnishock repo](https://github.com/ticky/omnishock/)

Once you manage to pair and trust your Bluetooth controller, you can install bluetooth-disconnect with the following commands:
```sh
# Keep things tidy
mkdir -p ~/dev/repos
cd ~/dev/repos

# Install dependencies
sudo apt-get install python3 python-prctl python-dbus bluez

# Clone repo
git clone https://github.com/jrouleau/bluetooth-autoconnect.git
cd bluetooth-autoconnect

# Copy systemd service file to its appropriate folder
sudo cp bluetooth-autoconnect.service /etc/systemd/system/
```

After copying the service file, edit `/etc/systemd/system/bluetooth-autoconnect.service` by replacing the line starting with `ExecStart` with
```
ExecStart=/home/pi/dev/repos/bluetooth-autoconnect/bluetooth-autoconnect -d
```

This change updates the location of the bluetooth-disconnect script. Make sure to edit the service file with elevated privileges.

The final step is to enable the service with the command
```sh
# The --now option tells systemd to start the service right away
sudo systemctl enable --now bluetooth-autoconnect
```

Your controller should now automatically reconnect to your Pi when you turn it on.

## Install Omnishock

The central piece of software we will be installing is [omnishock](https://github.com/ticky/omnishock/). Omnishock will allow us to use any controller supported by the [SDL game controller database](https://github.com/gabomdq/SDL_GameControllerDB/) to play games on the PS2.

Follow the guide over at [my fork of the omnishock repo.](https://github.com/ejuarezg/omnishock/#building-for-the-raspberry-pi-1-b) My fork contains a Dockerfile for an easier compilation process.

Place the binary somewhere that the system can see it. For example, in `~/dev/bin`. Then
```sh
# Append bin directory to the PATH variable. Change the path accordingly if
# you put the bin directory somewhere else.
echo 'export PATH="$HOME/dev/bin:$PATH"' >> ~/.profile
```

Log out and back in for the changes to the PATH variable to take effect.

## Install SDL2

We'll be using the omnishock container to build a recent version of SDL2. Recent versions of SDL2 are not provided by Raspberry Pi OS. These recent versions allow us to use newer hardware, like the Xbox Series and PS5 controllers.

**Note:** Complete this only after creating the omnishock container in the previous section.

While in the directory of this file, download the tar file for the SDL source code from https://www.libsdl.org/download-2.0.php or https://github.com/libsdl-org/SDL/releases and place it in this directory. Build SDL using
```sh
podman run -it --rm -v $PWD:/mnt raspi1-bplus-gnu-omnishock bash /mnt/raspberrypi-buildbot.sh
```

An installable tar file and `.deb` file will be placed in this directory and will be called `sdl-raspberrypi.tar.xz` and `libsdl2-2.0-0.deb`, respectively. Official precompiled binaries are provided at https://buildbot.libsdl.org/sdl-builds/sdl-raspberrypi/?C=M;O=D if you wish to avoid this compilation process.

I recommend installing the `.deb` file instead of the tar file. It is able to be removed and updated more easily. Run `sudo dpkg -i libsdl2-2.0-0.deb` on the Pi to install it.

To install the tar file of SDL2, extract it into the root folder of the Pi with the following commands:
```sh
sudo tar xf /path/to/sdl-raspberrypi.tar.xz -C /
echo "/usr/local/lib" | sudo tee -a /etc/ld.so.conf.d/usr-local.conf
sudo ldconfig
```
The last two commands are so that the shared libraries in `/usr/local/lib` are detected by the system.

## That's All Folks!

If all went well, you can test your controller by connecting it via Bluetooth or wire to your Pi and running `omnishock test`. The button presses should start spewing out on your terminal.

All that remains is to install [Aaron Clovsky's or Johnny Chung Lee's Teensy firmware.](https://github.com/ticky/omnishock/#supported-hardware)

## Todo

This list is a reminder of things I can do to improve this guide.

- Follow the packaging guidelines of a `.deb` file more closely
- Optimize OS
    - Remove networking and other services
    - Minimize/eliminate file corruption
    - Get OS boot time close to Aaron Clovsky's original version

