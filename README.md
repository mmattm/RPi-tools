# RPi-tools

<aside>
➡️ Ne fonctionne que avec **ZSH**
</aside>

### Installer **SSHPass**

```bash
$ brew install sshpass
```

### Rendre les scripts executables

```bash
$ chmod +x run_syncplay.sh
$ chmod +x upload_videos.sh
```

### Executer les scripts

```bash
$ /run_syncplay.sh [folder_path]
$ /resume_videos.sh
```

```bash
$ /upload_videos.sh [videos_folder] [folder_path]
```

### Reboot

```bash
$ /reboot.sh [id]
```

### Configurer l'autolaunch

```bash
$ /autolaunch_setup.sh [--enable|--disable]
```

### Configurer le shutdown automatique

```bash
$ /schedule.sh [--shutdown-hour 16 --shutdown-minute 28 --wake-minutes 60|--disable]
# (Minimum 1 wake-minutes sinon boucle infinie)
```
