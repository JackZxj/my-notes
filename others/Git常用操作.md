## normal operation
``` bash
git init    # 初始化代码仓库，用于在新文件夹内执行
git remote add <orginName> <http://xxxxxxxx.git>    # 添加源并为该源取名为orginName
git remote rm <orginName>    # 删除某个源
git remote -v    # 查看所有远程仓库
git clone <path>    # 从代码仓库复制一份拷贝到本地，path可以是html/filepath/ftp……
git branch <branchName>    # 创建一个名为branchName的分支
git branch -d [-r] <branchName>    # 删除[远程]分支
git branch -a    # 显示所有分支

git checkout [-b] <branchName>    # (-b表示如果不存在则创建)切换到branchName分支
git checkout -b <localBranch> <origin/originBranch>    # 切换到远程分支

# git checkout -b <dev_new> <otherOrigin/otherOriginBranch>
# 报错：不能同时更新路径并切换到分支'dev_new'
# 可能是没有把远程更新到本地，需要运行 git fetch otherOrigin 然后再重新运行

git fetch <orginName>    # 这个命令将某个远程主机的更新全部取回本地
git fetch origin <branchName>    # 从远程主机的branchName分支拉取最新内容 
git log -p FETCH_HEAD    # 查看拉下来的分支与当前分支的区别
git merge FETCH_HEAD    # 将拉取下来的最新内容合并到当前所在的分支中
# pull = fetch + merge
git pull <orginName> <originBranch>:<localBranch>    # 将远程分支与本地分支合并

git log    # 查看 commit 日志
git reset --hard <commit_id>    # 如果只是本地 commit 还没有提交到远程仓库，可以使用 reset 来取消一些错误的 commit, 若回退到的版本老于远程库，则需要使用 git push -f 强制推送
git revert -n <commit_id>    # 相当于提交一个新的 commit， commit的内容是反做 commit_id 提交的改动
# 可以看看这个关于高级合并的说明： https://git-scm.com/book/zh/v2/Git-%E5%B7%A5%E5%85%B7-%E9%AB%98%E7%BA%A7%E5%90%88%E5%B9%B6

git push <orginName> <localBranch>:<originBranch>    # 将本地分支推送到源，若 localBranch 为空，则删除远程 originBranch

# 远程分支已删除，本地还能看到被删除的远程分支
git remote show <orginName>     # 查看本地分支和远程分支的关系，如果有已被删除的远程分支会显示 stale
git remote prune <orginName>    # 清除本地缓存中已删除的远程分支
```

``` mermaid
graph LR
A[Remote] -->|fetch/clone| B[Repository]
B -->|push| A
C[Index] -->|commit| B
A -->|pull| D(Workspace)
B -->|checkout| D(Workspace)
D -->|add| C
E[git operation ]
```

## git commit

feat：新功能（feature）
fix：修补bug
docs：文档（documentation）
style： 格式（不影响代码运行的变动）
refactor：重构（即不是新增功能，也不是修改bug的代码变动）
test：增加测试
chore：构建过程或辅助工具的变动