# -----------------------------------------------------
# Name: Joshua Erwin
# Title: Security Audit Script
# Purpose: Performs a comprehensive local security audit on a Windows system.
# Outputs audit results to a timestamped text report.
# Created: April 2025
# -----------------------------------------------------

# Function to gather system inventory from a given computer (local or remote)
function Get-SystemInventory {
    param (
        [string]$ComputerName = 'localhost'
    )

    try {
        $osInfo   = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName
        $csInfo   = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $ComputerName
        $cpuInfo  = Get-CimInstance -ClassName Win32_Processor -ComputerName $ComputerName
        $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $ComputerName
        $ipConfig = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'" -ComputerName $ComputerName

        # IP and MAC handling (safe against nulls)
        $ipAddresses = $ipConfig | ForEach-Object {
            $_.IPAddress | Where-Object { $_ -match '\d{1,3}(\.\d{1,3}){3}' }
        } | Select-Object -Unique

        $macAddresses = $ipConfig | ForEach-Object {
            $_.MACAddress
        } | Where-Object { $_ } | Select-Object -Unique

        return [PSCustomObject]@{
            ComputerName   = $ComputerName
            Manufacturer   = $csInfo.Manufacturer
            Model          = $csInfo.Model
            OS             = $osInfo.Caption
            OSVersion      = $osInfo.Version
            Architecture   = $osInfo.OSArchitecture
            UptimeHours    = [math]::Round((New-TimeSpan -Start $osInfo.LastBootUpTime).TotalHours, 1)
            CPU            = $cpuInfo.Name
            TotalRAM_GB    = [math]::Round($csInfo.TotalPhysicalMemory / 1GB, 2)
            DiskSpace_GB   = [math]::Round(($diskInfo | Measure-Object -Property Size -Sum).Sum / 1GB, 2)
            FreeSpace_GB   = [math]::Round(($diskInfo | Measure-Object -Property FreeSpace -Sum).Sum / 1GB, 2)
            IPAddress      = $ipAddresses -join ', '
            MACAddress     = $macAddresses -join ', '
        }
    }
    catch {
        Write-Warning "Failed to collect data from ${ComputerName}: $_"
        return $null
    }
}

# Output file path
$outputPath = ".\SystemInventory_Report.csv"
$computerList = @()

# Ask user if scanning multiple machines
$useRemote = Read-Host "Do you want to scan multiple systems from a file? (y/n)"
if ($useRemote -eq 'y') {
    $filePath = Read-Host "Enter path to computer list (one computer name per line)"
    if (Test-Path $filePath) {
        $computerList = Get-Content $filePath
    } else {
        Write-Error "File not found: $filePath"
        exit
    }
} else {
    $computerList = @('localhost')
}

# Gather data
$results = @()
foreach ($computer in $computerList) {
    Write-Host "Collecting data from $computer..."
    $info = Get-SystemInventory -ComputerName $computer
    if ($info) { $results += $info }
}

# Export to CSV
if ($results.Count -gt 0) {
    $results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Inventory complete. Report saved to: $outputPath"
} else {
    Write-Warning "No data collected. Nothing to export."
}

