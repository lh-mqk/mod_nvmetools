import subprocess
import ctypes

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def executeKhaiScript():
    try:
        if not is_admin():
            return False, {'Result': 'NotAdmin'}

        ps_command = '''
        Set-Location "C:\\nvmetools\\"

        if (-Not (Test-Path ".venv")) {
            Start-Process ".\required_apps\python-3.9.0-amd64.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
            & "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python39\python.exe" -m venv .venv
            & ".\.venv\Scripts\Activate.ps1"
            pip install --no-index --find-links=./packages_src nvmetools
        } else {
            & ".\.venv\Scripts\Activate.ps1"
        }

        $monitorPath = "C:\nvmetools\monitor\"
        if (-Not (Test-Path $monitorPath)) {
            New-Item -ItemType Directory -Path $monitorPath
        }

        Set-Location $monitorPath
        
        while ($true) {
            $current_time = Get-Date -Format "yyyyMMdd_HHmmss"
            $newDir = New-Item -ItemType Directory -Path $current_time -Force
            Push-Location $newDir
            viewnvme
            Pop-Location
            Start-Sleep -Seconds 300
        }
        '''

        subprocess.Popen(["powershell.exe", "-Command", ps_command], shell=True)

        return True, {'Result': 'True'}

    except Exception as e:
        return False, {'Result': 'Exception', 'Error': str(e)}