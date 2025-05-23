#!/bin/bash

# Create required directories
mkdir -p ~/.config

# Create symlinks
echo "Creating symlinks..."
ln -sf $(pwd)/bash/.bashrc ~/.bashrc
ln -sf $(pwd)/starship/starship.toml ~/.config/starship.toml
ln -sf $(pwd)/git/.gitconfig ~/.gitconfig

echo "Symlinks created successfully!"