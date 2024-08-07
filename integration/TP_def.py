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
        & ".\.venv\Scripts\Activate.ps1"
        Set-Location "C:\\nvmetools\\monitor\\"
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