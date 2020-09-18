# Raspberry Pi 1 Model B+ Setup for PS2 Controller

This guide will help you install software on your Pi that allows you to use
modern gaming controllers to play games on your PlayStation 2.

The Pi 1 B+ is targeted since it is cheaper than the newer revisions and will
remain in production until [at least January
2026.](https://www.raspberrypi.org/products/raspberry-pi-1-model-b-plus/)

## Prerequisite Hardware

- Raspberry Pi 1 Model B+
  - USB power cable with/without power brick
  - SD card (class 10 is recommended)
  - WiFi adapter/dongle (optional)
- Bluetooth adapter/dongle (optional)

## Installing Raspberry Pi OS

We will be using Raspberry Pi OS (previous known as Raspbian) as our OS. This
OS contains the required up-to-date software.

To get started, head on over to the [Pi downloads
website](https://www.raspberrypi.org/downloads/), click on the icon that takes
you to the download page, and download the version that says **Raspberry Pi OS
(32-bit) with desktop**. The desktop version will allow us to easily configure
the OS after installation. Follow the installation guide linked in the download
page if you are unsure on how to flash the image to an SD card.

After successfully booting into the OS for the first itime, enable network
connectivity, enable SSH, and change any other settings. The rest of this guide
will assume that you are able to access a relatively vanilla installation of
Rasp Pi OS using SSH or keyboard & mouse input.

## Install Prerequisite Software for Omnishock

The central piece of software we will be installing is
[omnishock](https://github.com/ticky/omnishock/). Omnishock will us to use any
controller supported by the [SDL game controller
database](https://github.com/gabomdq/SDL_GameControllerDB/) to play games on
the PS2.

Let's being by installing the prerequisite software for omnishock with
```sh
# Update the system
sudo apt-get update
sudo apt-get upgrade

# Install SDL2 dev package
sudo apt-get install libsdl2-dev
```

We will also need to install Rust to build omnishock. Follow the default options during the installation process.
```sh
# Create a directory to store downloads and keep things tidy
mkdir ~/dev
cd ~/dev

# Download installation script
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > ~/dev/rustup.sh
sh ~/dev/rustup.sh`
```

The Rust installation script will modify `~/.profile`. Log out and back in
for the changes to take effect. If unsure, a reboot will correctly apply the
changes.

## Installaing Bluetooth Software

A important, yet optional, program is
[bluetooth-disconnect.](https://github.com/jrouleau/bluetooth-autoconnect) This
program will allow the Pi to reconnect to Bluetooth controllers (and any other
Bluetooth devices) automatically **once they have been paired and trusted.**

Unfortunately, I am not the best person to show you how to pair your controller
to your Pi via Bluetooth. This process can vary from controller to controller
and can be confusing. However, I can point you to some resources that helped me
out and will hopefully help you. Here they are:
- https://wiki.gentoo.org/wiki/Sony_DualShock (this guide worked for my
  DualShock 3)
- https://wiki.archlinux.org/index.php/Bluetooth (handy for troubleshooting)
- [Omnishock repo](https://github.com/ticky/omnishock/)

Once you manage to pair and trust your Bluetooth controller, you can install
bluetooth-disconnect with the following commands:
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

After copying the service file, edit
`/etc/systemd/system/bluetooth-autoconnect.service` by replacingg the line
starting with `ExecStart` with
```
ExecStart=/home/pi/dev/repos/bluetooth-autoconnect/bluetooth-autoconnect -d
```

This change updates the location of the bluetooth-disconnect script. Make sure
to edit the service file with elevated privileges.

The final step is to enable the service with the command
```sh
# The --now option tells systemd to start the service right away
sudo systemctl enable --now bluetooth-autoconnect
```

Your controller should now automatically reconnect to your Pi when you turn it
on.

## Install Omnishock

With the prerequisites out of the way, we can now move on to compiling
omnishock. This actually one of the easiest parts of the entire process,
albeit, it takes the longest to complete.

We will first clone the [GitHub repository of
omnishock](https://github.com/ticky/omnishock/) and then use Rust tool named
cargo to compile it. Simply run the following commands.
```sh
cd ~/dev/repos

# Clone repo
git clone --recurse-submodules https://github.com/ticky/omnishock.git
cd omnishock

# Compile
cargo build --release
```

Be prepared to wait a while for the compilation to complete. I had to wait 2:45
hours last time I did it.

Now that we compiled omnishock, let's put in somewhere that the system can see
it.
```sh
# You can create this bin directory wherever you'd like, just remember where
# you put it.
mkdir ~/dev/bin
cp ~/dev/repos/omnishock/target/release/omnishock ~/dev/bin/

# Append bin directory to the PATH variable. Change the path accordingly if
# you put the bin directory somewhere else.
echo "export PATH=\"\$HOME/dev/bin:\$PATH" >> ~/.profile
```

Log out and back in for the changes to the PATH variable to take effect.

## That's all Folks!

If all went well, you can test your controller by connecting it via Bluetooth
or wired to your Pi and running `omnishock test`. The button presses should
start spewing out on your terminal.

All that remains is to install [Aaron Clovsky's or Johnny Chung Lee's Teensy
firmware.](https://github.com/ticky/omnishock/#supported-hardware)

## Todo

This list is a reminder of things I can do to improve this guide.

- Use the Lite image of Raspberry Pi OS
- Decrease the boot time of Pi
    - Remove networking and other services
    - Minimize/eliminate file corruption
    - Get OS boot time close to Aaron Clovsky's original version
- Cross-compile omnishock to avoid waiting such... a... long... time.