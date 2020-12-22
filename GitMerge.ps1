cd "D:\AartenHetty\OneDrive\ADHC Development\Powershell.git"                                    # TO
& git remote add mytemp 'D:\AartenHetty\OneDrive\ADHC Development\WindowsPowershell.git'        # FROM
& git fetch mytemp 
& git merge --allow-unrelated-histories mytemp/master 
& git remote remove mytemp