# Runpod_Init_Manager_2026
Scripts to automate initial Runpod essentials post-post initialization

## RunPod SSH Manager:
A lightweight interactive Bash utility for managing SSH access on RunPod containers.
The manager handles SSH server installation, SSH key management, cleanup, and displays the current RunPod connection information.

### Features

- Install and start `openssh-server`
- Add an SSH public key for `root`
- Remove authorized SSH keys
- Remove the SSH server
- Display the current RunPod public IP and SSH port
- Display a ready-to-use SSH command
- Uses RunPod's dynamically assigned `PUBLIC_IP` and SSH port

---

### Usage

#### CURL down the script on your Pod:
```bash
curl -fsSL https://raw.githubusercontent.com/nithyanandhm/Runpod_Init_Manager_2026/refs/heads/main/runpod_init_manager.sh > PodSetup.sh
```
#### Make the script executable:
```bash
chmod +x PodSetup.sh
```
#### Run your Manager:
```bash
./PodSetup.sh
```
<img width="589" height="322" alt="image" src="https://github.com/user-attachments/assets/a1ba8249-9570-4e7a-80d0-99f34d2ac3a2" />
