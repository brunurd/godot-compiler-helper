#!/usr/bin/env bash

set -x ; set -e ; cd "$(dirname "${BASH_SOURCE[0]}")/.."

# .env file management
test -f .env || cp .env.example .env
test -f .env && { set -a ; . .env ; set +a ; }

# Set or reset needed variables
GODOT_HOME="${GODOT_HOME:-$HOME/opt/godot}"
OS_DESKTOP_FOLDER=${OS_DESKTOP_FOLDER:-/usr/share}

# Go to godot repository folder
cd $GODOT_HOME || exit 1

# Update the project from remote git: origin/master
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "master" ]]; then
  branches=$(git branch | xargs echo)
  if [[ $branches == *"master"* ]]; then
    git branch -D master
  fi
  git checkout -b master
  git pull origin master -f
  git checkout $current_branch
  git branch -D master
else
  git add -A
  git stash
  git pull origin master -f
fi

# Generate the mono glue
scons tools=yes module_mono_enabled=yes mono_glue=no
./bin/godot.linuxbsd.tools.64.mono --generate-mono-glue modules/mono/glue

# Generate the editor
scons tools=yes module_mono_enabled=yes mono_glue=yes
cp -vf bin/godot.linuxbsd.tools.64.mono bin/godot.linuxbsd.tools.64.mono-latest

# Generate the debug version
scons tools=no module_mono_enabled=yes mono_glue=yes

# Generate system shortcut into /usr/bin PATH and in the Desktop laucher
sudo rm -rfv /usr/bin/godot
sudo ln -s $GODOT_HOME/bin/godot.linuxbsd.tools.64.mono-latest /usr/bin/godot
sudo cp -vf $GODOT_HOME/misc/dist/linux/org.godotengine.Godot.desktop $OS_DESKTOP_FOLDER/applications
sudo rm -rfv $OS_DESKTOP_FOLDER/icons/godot
sudo mkdir -p $OS_DESKTOP_FOLDER/icons/godot
sudo cp -vf $GODOT_HOME/icon.png $OS_DESKTOP_FOLDER/icons/godot
sudo cp -vf $GODOT_HOME/icon.png $OS_DESKTOP_FOLDER/icons/godot/org.godotengine.Godot.png
sudo cp -vf $GODOT_HOME/icon.png $OS_DESKTOP_FOLDER/icons/godot/org.godotengine.Godot
sudo cp -vf $GODOT_HOME/icon.png $OS_DESKTOP_FOLDER/icons/godot/godot.png
sudo cp -vf $GODOT_HOME/icon.png $OS_DESKTOP_FOLDER/icons/godot/godot

# Generate the Android version
scons tools=no platform=android

cd -

