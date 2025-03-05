# PVE Template Creator

This project automates the creation of Proxmox VE templates using cloud images. It customizes the images with specified packages, commands, and first boot scripts, and then deploys them as virtual machines (VMs) or templates.

## Prerequisites

Ensure the following tools are installed on your system:

- `pvesh`
- `qm`
- `virt-edit`
- `virt-customize`
- `curl`
- `wget`
- `paste`
- `jq`

## Usage

1. Clone the repository:
    ```sh
    git clone https://github.com/yourusername/pve-template-creator.git
    cd pve-template-creator
    ```

2. Prepare your configuration file. Example configuration files are provided in the  directory:
    - 
    - 
    - 

3. Run the  script with the desired configuration file:
    ```sh
    ./spawn.sh basetemplate/basenoble.ini
    ```

## Configuration File Structure

The configuration files are in INI format and contain the following sections:

### `[main]` Section

- `name`: The name of the template.
- `description`: A description of the template.
- `cloudimage`: URL of the cloud image to be used.
- `version`: Version of the template.

### `[config]` Section

- `storagepool`: The storage pool where the VM will be deployed.
- `networkbridge`: The network bridge to be used.
- `disksize`: Size of the disk.
- `id`: ID of the VM.
- `user`: Username for the VM.
- `publickeyfile`: Path to the public SSH key file.
- `astemplate`: Whether to convert the VM to a template (`true` or `false`).
- `packages`: Path to the file containing the list of packages to be installed.
- `commands`: Path to the file containing the list of commands to be executed.
- `firstbootscript`: Path to the first boot script.

## Example Configuration

Here is an example configuration file (`basetemplate/basenoble.ini`):

```ini
[main]
name=template-ubuntu-noble
description="Ubuntu Noble"
cloudimage=https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
version=1.0

[config]
storagepool="local-zfs"
networkbridge=vmbr0
disksize=10G
id=904
user=pve
publickeyfile=~/.ssh/id_rsa.pub
astemplate=true

packages=./packagelist
commands=./commandlist
firstbootscript=firstbootscript.sh
