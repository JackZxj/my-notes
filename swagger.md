## what is swagger?

swagger 是一个可交互式 api 文档。开发文档对于前后端的对接工作具有相当重要的地位，一个合理的开发流程应当是前后端协商好 api 接口的形式，然后再各自分工实现。而 swagger 可以帮助后端开发者迅速生成一个接口明确、能够直接对已经开发好的接口进行测试的交互式文档（基于 html ）。

## how to use?

### swagger-editor

用于可视化生成 swagger-ui 的界面，并不一定需要安装，可以 [在线进行编写](https://swagger.io/tools/swagger-editor/) 然后将文本拷贝到本地保存或者直接导出保存。

### swagger-ui

api 测试的主要工具。

1. 下载 [swagger-ui github](https://github.com/swagger-api/swagger-ui/releases)
2. 解压到 web 服务器的静态文件中
3. 将编写好的 swagger api 文件拷贝到 swagger 解压目录的 dist 目录下
4. 启动 web 服务器，访问对应的 ip:port/..../dist/index.html

eg: (win10 环境，web 服务器使用 node.js 平台的 http-server，需要提前安装好 nodejs、npm、http-server, http-server 需要全局安装)
1. 下载 `swagger-ui-3.23.5.zip` 到 Desktop
2. 解压得到 swagger-ui-3.23.5 文件夹
3. 通过命令行进入该文件夹，执行 `http-server -p 8080` （-p 指定端口号，不制定默认8080）
4. 访问 `127.0.0.1:8080/dist/index.html` 即可访问到页面
5. 将已经写好的 swagger.yaml 放入 dist 文件夹内，在 index.html 页面的框中填入 `http://127.0.0.1:8080/dist/swagger.yaml` 即可访问到你的 api 文档
6. 需要注意的是，如果 api 接口与该 web 服务器不同域，回有跨域问题无法检测 api 是否可用，需要将你的 api 设置为该源可访问才行。
