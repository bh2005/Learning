# How to Export a VM from Proxmox VE and Import it into VMware  
**Complete Step-by-Step Migration Guide (2025)**  

This document explains how to migrate a virtual machine from **Proxmox VE (KVM/QEMU)** to **VMware** products (ESXi, vSphere, Workstation, or Fusion) by converting the disk and recreating the VM manually.

Works with **QCOW2, RAW, LVM-thin, ZFS** disks and **Linux or Windows** guests.

---

### Important Warnings
- **Always stop the VM** in Proxmox before exporting (prevents data corruption)
- Create a **full backup** first (Proxmox GUI → Backup → Backup now)
- You need SSH/SCP access to both Proxmox and VMware hosts
- Required tools: `qemu-img` (pre-installed on Proxmox), WinSCP or SCP

---

## Step 1 – Prepare & Export Disk from Proxmox

1. **Stop the VM**  
   ```bash
   qm stop <VMID>
   # GUI: Select VM → Shutdown → Force stop if required
   ```

2. **Locate the disk**  
   ```bash
   qm config <VMID>
   ```

   | Storage Type      | Typical Path / Device                               | How to Find It                     |
   |-------------------|-----------------------------------------------------|------------------------------------|
   | Local (directory) | `/var/lib/vz/images/<VMID>/vm-<VMID>-disk-0.qcow2`  | `ls /var/lib/vz/images/<VMID>/`   |
   | LVM-thin          | `/dev/pve/vm-<VMID>-disk-0`                         | `lvs \| grep vm-<VMID>`           |
   | ZFS               | `/dev/zvol/pve/vm-<VMID>-disk-0`                    | `zfs list`                         |

3. **Copy the disk to a temporary location**  

   **File-based storage (qcow2/raw)**  
   ```bash
   cp /var/lib/vz/images/<VMID>/vm-<VMID>-disk-0.qcow2 /tmp/vm-export.qcow2
   ```

   **LVM or ZFS (block device)**  
   ```bash
   dd if=/dev/pve/vm-<VMID>-disk-0 of=/tmp/vm-export.raw bs=4M status=progress
   ```

---

## Step 2 – Convert Disk to VMware VMDK Format

Run on the **Proxmox host**:

```bash
# From QCOW2
qemu-img convert -f qcow2 -O vmdk -o compat6 /tmp/vm-export.qcow2 /tmp/vm-export.vmdk

# From RAW
qemu-img convert -f raw -O vmdk -o compat6 /tmp/vm-export.raw /tmp/vm-export.vmdk

# Optional: stream-optimized (recommended for ESXi)
qemu-img convert -f qcow2 -O vmdk -o subformat=streamOptimized /tmp/vm-export.qcow2 /tmp/vm-export.vmdk
```

Verify:
```bash
qemu-img info /tmp/vm-export.vmdk
```

---

## Step 3 – Transfer VMDK to VMware Datastore

### Option A – SCP (fastest)
```bash
scp /tmp/vm-export.vmdk root@<ESXI-IP>:/vmfs/volumes/datastore1/
```

### Option B – WinSCP (GUI)
1. Enable SSH on ESXi (Host → Manage → Services → TSM-SSH → Start)
2. Connect with WinSCP to ESXi IP (user: root)
3. Upload the `.vmdk` file to any datastore folder

---

## Step 4 – Create New VM in VMware and Attach the VMDK

1. **Create a new virtual machine**  
   - Choose **Create a new virtual machine**  
   - Set Name & Guest OS exactly like the original  
   - CPU, RAM, Network → match Proxmox settings  
   - **Do NOT create a new hard disk** (remove the default one)

2. **Add the converted disk**  
   - Edit VM → Add Hard Disk → **Existing Hard Disk**  
   - Browse and select your uploaded `.vmdk`  
   - Place it on **SCSI 0:0** (boot disk)  
   - Controller: **LSI Logic SAS** or **VMware Paravirtual** (recommended)

3. **Boot settings**  
   - VM Options → Boot Options → Firmware: **BIOS** or **EFI** (match original)  
   - Ensure the disk is first in boot order

4. **Power on the VM**

---

## Step 5 – Post-Migration Tasks

### Linux Guests
```bash
sudo apt update && sudo apt install open-vm-tools open-vm-tools-desktop -y
# or
sudo yum install open-vm-tools -y
```

### Windows Guests
- VM → Guest → Install VMware Tools  
- Run the installer → Reboot

### Common Issues & Fixes

| Symptom                        | Solution                                                                 |
|--------------------------------|--------------------------------------------------------------------------|
| No bootable device             | Temporarily change controller to **IDE** → boot → switch back to SCSI    |
| Kernel panic / black screen    | Boot from recovery ISO → edit `/etc/fstab` (remove virtio entries)      |
| Network not working            | Switch NIC to **VMXNET3**, install VMware Tools                          |
| Slow graphics / mouse lag      | Install `open-vm-tools-desktop` (Linux) or VMware Tools (Windows)       |

---

## Alternative Tools (when qemu-img fails)

| Tool                     | Description                                      |
|--------------------------|--------------------------------------------------|
| StarWind V2V Converter   | Free GUI tool – direct QCOW2 → VMDK conversion   |
| VMware vCenter Converter | Live P2V migration (run inside the running VM)   |
| OVF Tool (VMware)        | Advanced export (experimental with Proxmox)      |

---

**You’re done!**  
Your Proxmox VM is now running natively on VMware.

If you encounter any specific error (VMID, OS, storage type, etc.), feel free to share the details – I’ll give you the exact commands needed.  

Good luck with your migration! 🚀