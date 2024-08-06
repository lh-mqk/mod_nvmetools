```
 __         __  __     __    __     ______     __  __    
/\ \       /\ \_\ \   /\ "-./  \   /\  __ \   /\ \/ /    
\ \ \____  \ \  __ \  \ \ \-./\ \  \ \ \/\_\  \ \  _"-.  
 \ \_____\  \ \_\ \_\  \ \_\ \ \_\  \ \___\_\  \ \_\ \_\ 
  \/_____/   \/_/\/_/   \/_/  \/_/   \/___/_/   \/_/\/_/ 
```

# BA?NH NVMe Tools
[https://github.com/lh-mqk/mod_nvmetools](https://github.com/lh-mqk/mod_nvmetools)

## 1. Compare SSD Content

Run [GenerateContentKey.ps1](GenerateContentKey.ps1) to generate:

- **File hash**. Formated as: *"$($file.FullName) --- $hashString"*
- **File content**. Formated as: *"$($file.FullName) ___ $content"*

of all files in **C:** .

The generated result will be written in [.\Result_GenerateContentKey.txt](Result_GenerateContentKey.txt)

## 2. Monitor NVMe SSDs continuously

### 2.1 First run

Run [FirstRunMonitor.ps1](FirstRunMonitor.ps1) to:

1. Start a process as administrator
2. Installed required Python version: **3.9**. Remember to check "Add PATH" and "Disable Max Length" options
3. Installed require I/O interaction application: **fio**
4. Please make sure that you are using Python 3.9 added to PATH at this step
5. Create & Activate a virtual environment
6. Install main tool package & its dependencies: **nvmetools**
7. Start monitor process

The monitor process will:

1. Create a new folder named by current datetime
2. Perform read NVMe SSD and write result to the newly create folder
3. Loop the process every 5 minutes

### 2.2. From second run

Run [RunMonitor.ps1](RunMonitor.ps1) to:

1. Start a process as administrator
2. Activate the virtual environment
3. Start monitor process (as described in 2.1)

## 3. Test NVMe SSDs

> (Requirement: run monitor for at least 1 time)

Run [RunSelfTest.ps1](RunSelfTest.ps1) to:

1. Start a process as administrator
2. Activate the virtual environment
3. By default, it will perform short self-test & extended self-test
4. Write test results to "~/Users/username/Documents/nvmetools/results/..."

Consider other test cases in [./suites/](./suites/)