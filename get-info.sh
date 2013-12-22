# Get list of CPUFreq modules
/sbin/modinfo /lib/modules/$(uname -r)/kernel/drivers/cpufreq/* | grep "^[fd]"  

# Check how CPU is configured
cpufreq-info

# List all modules installed
ls -R /lib/modules/`uname -r`/kernel/



