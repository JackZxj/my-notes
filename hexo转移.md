Hexo 博客从一台电脑迁移到另一台电脑
---

## 安装 hexo

在新的电脑上安装好 hexo ，需要提前安装好 node.js、npm，过程略

## 拷贝

从原来的电脑上将 hexo 目录下的 `scaffolds`、`source`、`themes`、`.gitignore`、`_config.yml`、`package.json` 复制到新电脑的 hexo 目录下，覆盖原来的文件。

## 为新电脑配置 github ssh

1. 命令行 (git bash) 输入 `ls ~/.ssh` 查看是否已经有 ssh 了，有的话直接进入第3步；
2. git bash 执行 `ssh-keygen -t rsa -C "your_email@example.com"`，如果不添加密码的话直接回车3次生成密钥（如果是自己的电脑，一般不加密码就行，-t 表示加密类型，-C 为注释文字，一般写邮箱、签名之类的，-f 可以指定生成的密钥文件名）：id_rsa 和 id_rsa.pub，即公钥和私钥；
3. 将 id_rsa.pub 中的内容添加到 github-（头像下拉框）Settings-SSH and GPG keys-New SSH key-Key 中，其 Title 可以随意，填一个你能区别该 ssh 源的名称就行。

## 重建 hexo

git bash 进入 hexo 文件夹，执行 `hexo init` 进行初始化，加载先前安装的插件，然后分别使用 `hexo clean` `hexo g` `hexo s` 在本地测试是否成功，若成功了就可以使用 `hexo d` 重新部署到 git page。