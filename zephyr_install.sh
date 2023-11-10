#!/usr/bin/env bash

# Halt on error
set -e

# Zephyr SDK version to install: change as needed.
Z_SDKVER=0.16.3

# Zephyr Project location; no changes recommended.
Z_INSTALL="${HOME}/zephyrproject"
Z_SDK_PATH="${HOME}/zephyr-sdk-${Z_SDKVER}"
Z_VENV="${Z_INSTALL}/.zephyr-env"

DIR="$(pwd $(dirname "${BASH_SOURCE[0]}"))"

# Check if Ubuntu release is valid
if [[ $(lsb_release -rs) != "22.04" ]]; then 
	echo "Please run this script on Ubuntu 22.04"
	exit 1
fi

# Check if folders are already present
if [[ -d ${Z_INSTALL} || -d ${Z_SDK_PATH} ]]; then
	echo "Zephyr already installed, to reinstall remove:"
	echo "1. ${Z_INSTALL}"
	echo "2. ${Z_SDK_PATH}"
	exit 1
fi

echo "--------------------------------------------------------------"
echo "Install Zephyr Project with Zephyr SDK and Python Virtual Env."
echo
echo "Zephyr Project latest version at: ${Z_INSTALL}"
echo "Zephyr SDK version ${Z_SDKVER} at: ${Z_SDK_PATH}"
echo "--------------------------------------------------------------"

# Do not modify
Z_SDKRUNSCRIPT="zephyr-sdk-${Z_SDKVER}-linux-x86_64-setup.run"

mkdir -p ${Z_INSTALL}

sudo apt update
sudo apt install --no-install-recommends --yes \
	git cmake ninja-build gperf \
	ccache dfu-util device-tree-compiler wget \
	python3-dev python3-pip python3-setuptools python3-tk python3-wheel python3-venv \
	xz-utils file gcc gcc-multilib g++-multilib libsdl2-dev libmagic1

# Verify versions  
echo "--------------------------------------------------------------"
echo "Check installed tool versions."
echo "--------------------------------------------------------------"
cmake --version
python3 --version
dtc --version

echo "--------------------------------------------------------------"
echo "Install Python virtual environment."
echo "--------------------------------------------------------------"
python3 -m venv "${Z_VENV}"
source "${Z_VENV}/bin/activate"

echo "--------------------------------------------------------------"
echo "Install Zephyr and dependencies."
echo "--------------------------------------------------------------"
# In virtual environment
pip install west
west init ${Z_INSTALL}
cd ${Z_INSTALL}
west update
west zephyr-export
pip install -r "${Z_INSTALL}/zephyr/scripts/requirements.txt"

echo "--------------------------------------------------------------"
echo "Download and install Zephyr SDK."
echo "--------------------------------------------------------------"
cd ~
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${Z_SDKVER}/zephyr-sdk-${Z_SDKVER}_linux-x86_64.tar.xz
wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${Z_SDKVER}/sha256.sum | shasum --check --ignore-missing
tar xvf zephyr-sdk-${Z_SDKVER}_linux-x86_64.tar.xz
rm zephyr-sdk-${Z_SDKVER}_linux-x86_64.tar.xz

cd zephyr-sdk-${Z_SDKVER}
bash setup.sh -t all -h -c

sudo cp ~/zephyr-sdk-${Z_SDKVER}/sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d
sudo udevadm control --reload

cd ${DIR}
cp zephyr_enable.sh "${Z_INSTALL}"

echo "--------------------------------------------------------------"
echo "Done!"
echo ""
echo "Activate the Zephyr working environment by: "
echo "source ${Z_INSTALL}/zephyr_enable.sh"
echo "--------------------------------------------------------------"
