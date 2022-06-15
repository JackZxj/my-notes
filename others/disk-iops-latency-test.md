# test

一、Linux系统：
时延：
fio --filename=改成待测试文件路径+名称 --ioengine=libaio --rw=randread  --bs=4k --size=40G --iodepth=1  --numjobs=1 --direct=1 --name=4klat_randread   --group_reporting --runtime=120
fio --filename=改成待测试文件路径+名称 --ioengine=libaio --rw=randwrite --bs=4k --size=40G --iodepth=1  --numjobs=1 --direct=1 --name=4klat_randwrite  --group_reporting --runtime=120

IOPS：
fio --filename=改成待测试文件路径+名称 --ioengine=libaio --rw=randread  --bs=4k --size=40G --iodepth=64 --numjobs=4 --direct=1 --name=4kiops_randread  --group_reporting --runtime=120 
fio --filename=改成待测试文件路径+名称 --ioengine=libaio --rw=randwrite --bs=4k --size=40G --iodepth=64 --numjobs=4 --direct=1 --name=4kiops_randwrite --group_reporting --runtime=120

吞吐量：
fio --filename=改成待测试文件路径+名称 --ioengine=libaio --rw=randread  --bs=4M --size=40G --iodepth=64 --numjobs=1 --direct=1 --name=4kio_randread    --group_reporting --runtime=120
fio --filename=改成待测试文件路径+名称 --ioengine=libaio --rw=randwrite --bs=4M --size=40G --iodepth=64 --numjobs=1 --direct=1 --name=4kio_randwrite   --group_reporting --runtime=120



二、windows系统：
时延：
fio --filename=改成待测试文件路径+名称 --ioengine=windowsaio --rw=randread  --bs=4k --size=10G --iodepth=1  --numjobs=1 --direct=1 --name=4klat_randread   --group_reporting --runtime=120
fio --filename=改成待测试文件路径+名称 --ioengine=windowsaio --rw=randwrite --bs=4k --size=10G --iodepth=1  --numjobs=1 --direct=1 --name=4klat_randwrite  --group_reporting --runtime=120

IOPS：
fio --filename=改成待测试文件路径+名称 --ioengine=windowsaio --rw=randread  --bs=4k --size=10G --iodepth=64 --numjobs=4 --direct=1 --name=4kiops_randread  --group_reporting --runtime=120 
fio --filename=改成待测试文件路径+名称 --ioengine=windowsaio --rw=randwrite --bs=4k --size=10G --iodepth=64 --numjobs=4 --direct=1 --name=4kiops_randwrite --group_reporting --runtime=120

吞吐量：
fio --filename=改成待测试文件路径+名称 --ioengine=windowsaio --rw=randread  --bs=4M --size=10G --iodepth=64 --numjobs=1 --direct=1 --name=4kio_randread    --group_reporting --runtime=120
fio --filename=改成待测试文件路径+名称 --ioengine=windowsaio --rw=randwrite --bs=4M --size=10G --iodepth=64 --numjobs=1 --direct=1 --name=4kio_randwrite   --group_reporting --runtime=120



三、dd测试（根据盘类型选测）：
sata盘：dd if=/dev/zero of=改成待测试文件路径+名称 bs=4k count=10k oflag=sync,direct
ssd盘： dd if=/dev/zero of=改成待测试文件路径+名称 bs=4k count=50k oflag=sync,direct

以上，filename是要创建的文件名称，比如：/mnt/test.txt或者 G:\11\test.txt 如果待测试的盘剩余容量大小小于40G或者windows文件系统不允许写入过大文件时，
可以将size的大小调小一些。dd测试需要根据磁盘类型调整count参数。

注意：如果是有业务的虚机，filename选型不要直接填盘符，会把磁盘文件系统写坏。