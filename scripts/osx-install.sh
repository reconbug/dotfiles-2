#!/usr/bin/env bash

# Install command line tools
xcode-select -p
if [[ $? -ne 0 ]]; then
    xcode-select --install
fi

# A full installation of Xcode.app is required to compile macvim.
# Installing just the Command Line Tools is not sufficient.
xcodebuild -version
if [[ $? -ne 0 ]]; then
    # TODO: find a way to install Xcode.app automatticaly
    # See: http://stackoverflow.com/a/18244349

    # Accept Xcode license
    sudo xcodebuild -license
fi

# Update all OSX packages
sudo softwareupdate -i -a

# Install Homebrew if not found
brew --version
if [[ $? -ne 0 ]]; then
    # Clean-up failed Homebrew install
    rm -rf /usr/local/Cellar /usr/local/.git
    # Install Homebrew
    ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
fi
brew update
brew upgrade

# Include duplicates packages
brew tap homebrew/dupes

# Install Cask
brew tap phinze/homebrew-cask
brew install brew-cask

# Install OSX system requirements
installcask x-quartz

# Install a brand new Python
brew install python --with-brewed-openssl
brew link --overwrite python

# Install common packages
brew install $COMMON_PACKAGES

# Install OSX only packages
brew install findutils bash ack grep rename tree webkit2png osxutils p7zip faad2 bash-completion md5sha1sum ssh-copy-id

# htop-osx requires root privileges to correctly display all running processes.
sudo chown root:wheel /usr/local/bin/htop
sudo chmod u+s /usr/local/bin/htop

# Install binary apps
for PACKAGE in $BIN_PACKAGES
do
   brew cask install $PACKAGE
done
brew cask install dropbox
brew cask install f-lux
brew cask install gitx
brew cask install insync
brew cask install chromium
brew cask install libre-office
brew cask install tunnelblick

# Install vim
brew install lua --completion
brew install cscope
VIM_FLAGS="--with-python --with-lua --with-cscope --override-system-vim"
brew install macvim $VIM_FLAGS
brew install vim $VIM_FLAGS
# Patch the font defined by default for Terminale (Monaco, 11pt) for Vim's Airline plugin
# See: https://powerline.readthedocs.org/en/latest/fontpatching.html
brew install fontforge
mkdir ./powerline-fontconfig
curl -fsSL https://github.com/Lokaltog/powerline/tarball/develop | tar -xvz --strip-components 2 --include "*/font/*" --directory ./powerline-fontconfig -f -
fontforge -script ./powerline-fontconfig/fontpatcher.py /System/Library/Fonts/Monaco.dfont
sudo mv ./Monaco\ for\ Powerline.otf /System/Library/Fonts/
rm -rf ./powerline-fontconfig

# Install custom bootloader
curl -O http://kent.dl.sourceforge.net/project/refind/0.7.4/refind-bin-0.7.4.zip
unzip ./refind-bin-0.7.4.zip
./refind-bin-0.7.4/install.sh --yes
rm -rf ./refind-bin-0.7.4*
# Adjust refind config
sudo sed -i "" -e "s/timeout 20/timeout 1/" /EFI/refind/refind.conf

# Install steam in a case-insensitive disk image
# Source: http://blog.andersonshatch.com/2010/05/13/using-steam-on-mac-with-case-sensitive-drive/
installcask steam
hdiutil create -size 30G -fs HFS+ -layout NONE -type SPARSEBUNDLE -volname steam ~/steam
hdiutil mount ./steam.sparsebundle
cp -av /opt/homebrew-cask/Caskroom/steam/stable/Steam.app /Volumes/steam/
mkdir /Volumes/steam/steam\ library /Volumes/steam/steam\ content
ln -s /Volumes/steam/steam\ library ~/Library/Application\ Support/Steam
sudo ln -s /Volumes/ /volumes
brew cask uninstall steam
# TODO: Find a way to create OSX alias to /Applications (to get automount)
# See: https://en.wikipedia.org/wiki/Alias_(Mac_OS)

# Clean things up
brew linkapps
brew doctor
brew cleanup
