# windows bugs

## 任务栏图标取消固定后留下空占位

打开 `C:\Users\__Windows_User_Name__\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar` 删除要去掉的快捷方式

点击任务栏要删除的图标， windows 提示找不到目标是否删除，选择删除

## 无法开热点或者热点连接后无网络

进入 `控制面板\网络和 Internet\网络连接` 查看是否存在 `Microsoft Wi-Fi Direct Virtual Adapter` 的本地连接设备，一般名为 `本地连接*n`

如果存在，则右键状态查看其是否网络连接，否的话关闭当前状态，选择可用的网络连接，右键 属性 - 共享 - 允许其他网络用户通过此计算机的Internet连接来连接 - 选择Virtual Adapter对应的设备名 确定后保存

如果不存在，则管理员模式运行 cmd，然后执行 `netsh wlan set hostednetwork mode=allow`，然后重启，再查看上述的 `Virtual Adapter` 是否存在
