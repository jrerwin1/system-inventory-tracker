# System Inventory Tracker (PowerShell)

A PowerShell script that collects detailed system information (hardware, OS, network, and disk stats) from a local or remote Windows machine and exports the data to a CSV file.

---

## Features

  - Collects key inventory data:
  - Hostname, OS version, architecture
  - CPU model, total RAM, disk space (used/free)
  - IP and MAC addresses
  - System manufacturer and model
  - System uptime (hours)
  - Supports single-machine or batch remote scans
  - Outputs results to `.csv` for easy auditing
  - Works with domain and workgroup environments

---

## How to Use

###  1. Run the Script

Open **PowerShell as Administrator**, then run:

```powershell
.\SystemInventory.ps1

