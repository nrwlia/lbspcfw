# Linux BSP Case Folding Workaround for CS:S (daemonized)

#### 🖼️ Before/After
![image](https://github.com/user-attachments/assets/e8b1c04d-778d-42bf-83f6-a68c1d446c2d)
![image](https://github.com/user-attachments/assets/9acf4dcb-92d4-4e85-af89-8c2859777e0c)


## 📜 Overview
The Linux BSP Case Folding Workaround is a bash script designed to resolve client-side compatibility with maps (BSP) with case folding issues with custom content in Valve Source 1 engine games on Linux, such as Half-Life 2 Deathmatch, Counter-Strike: Source, Team Fortress 2, and many others. It addresses missing textures, models, and sounds due to case sensitivity mismatches by extracting and syncing assets to the game folder, from which they are then parsed properly by the game.<br/>
- No modification to any map or game files and is completely safe to use with secure servers (zero risk of VAC ban).
- Game stability restored, reducing map-related crashes since the assets will once again be available.

## ℹ️ Purpose
BSP map files reference assets (e.g., Materials/Walls/brick01.vtf) case-insensitively, which conflicts with Linux case-sensitive filesystem (e.g., materials/walls/brick01.vtf) since the February 2025 update. This script automates bulk asset extraction, merge, and placement to ensure proper map operation.

## 👨‍💻 Functionality
- I (author of fork) have modified this script to work with **only** CS:S. It is **heavily vibecoded** and I get rid of most of features that original repo had so don't expect anything much from this fork.

## 🚀 Usage
### Prerequisites
- Linux OS with bash
- Dependencies: **curl**, **unzip**, **rsync**, **parallel** (install via your distribution package manager, if needed)

Ubuntu/Debian-based (apt)
```
sudo apt update && sudo apt install curl unzip rsync parallel -y
```
Arch Linux-based (pacman)
```
sudo pacman -Sy --noconfirm curl unzip rsync parallel
```
Fedora-based (dnf)
```
sudo dnf makecache && sudo dnf install curl unzip rsync parallel -y
```

### Installation
1. Clone:
   ```
   git clone https://github.com/nrwlia/lbspcfw.git
   ```
2. Change to local repo folder
   ```
   cd lbspcfw
   ```
3. Set permissions:
   ```
   chmod +x install.sh
   ```
4. Run install script **as user**:
   ```
   ./install.sh
   ```
Alternatively, clone & run with one command:
```
git clone https://github.com/nrwlia/lbspcfw.git && cd lbspcfw && chmod +x install.sh && ./install.sh
```

## ⚠️ Backup Warning
To work properly, all assets (materials, models, sound) extracted are **required** to be inside the game download folder (alternatively, they can be placed in the game root folder). Placing custom assets into the `custom` folder does not work since it seems to suffer the same case folding issue. This is due to the functionality of the game itself, _not_ the script. If you require any existing custom content to be retained, please back up your existing materials/models/sound folders **_prior_** to running this script.

## 🚩 Known Issues
Multiple maps that use the same texture/model naming scheme but different versions can potentially [conflict with eachother](https://github.com/scorpius2k1/linux-bsp-casefolding-workaround/issues/7), causing them not to render properly. While rare, this is difficult to address directly since the way Valve's Source1 engine processes external data cumulatively (no per-map option), making it implausible to address via a workaround such as this script.

## 🗑 Removal
- Run uninstall script:
  ```bash
  ./uninstall.sh
  ```

## 👥 Support
- A ticket for this issue is open on Valve's official Github, please [follow there](https://github.com/ValveSoftware/Source-1-Games/issues/6868) for updated information.
- If you find this useful and it works well for you, please ⭐ this repository and share with others in the community.
- If you would like to support author's work and [servers](https://stats.scorpex.org/) he run in the community, consider [buying him a coffee](https://help.scorpex.org/) ☕

[Back to top](#top)
