``` BASH
# 持续监控日志 follow
journalctl -u kubelet -n 100 --no-pager -f
```
