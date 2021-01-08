# NATS demo

Origin: [https://github.com/nats-io/kubecon2020](https://github.com/nats-io/kubecon2020)

## Deploy demo locally

``` BASH
# Installing NSC
$ curl -LO https://raw.githubusercontent.com/nats-io/nsc/master/install.sh
$ less install.sh
$ sh ./install.sh
$ nsc --version
nsc version 0.5.0

# Initialize NSC
$ curl -fSl https://nats-io.github.io/k8s/setup/nsc-setup.sh | sh
$ source .nsc.env

# Inspect NSC objects
$ tree nsc/ | less
$ nsc describe jwt -f nsc/accounts/nats/KO/KO.jwt

# Creating the accounts
# We will separate the system into two accounts:
# - An ADMIN account for management of users (create/revoke)
# - An CHAT account for the users to interact with each other.
# We need 3 users at least:
#   Admin User
#       Credentials Provisioner and revocation
#   Chat User
#       Dynamically generated
#   Bootstrap User
#       Chat Credentials Requestor
$ nsc add account --name CHAT
$ nsc add account --name ADMIN
$ nsc list accounts
$ nsc describe jwt -f ./nsc/accounts/nats/KO/accounts/CHAT/CHAT.jwt
$ nsc describe jwt -f ./nsc/accounts/nats/KO/accounts/ADMIN/ADMIN.jwt

# Add a new signing key for CHAT and ADMIN accounts
#   This is needed to be able to create users dynamically by the credentials provisioner.
$ nsc generate nkey --account CHAT --store
AB6OZPLYWRUYDDYRNCI37IY3AW7CWUBSJT7GZSERMEENMMCDKXZHH6SG
account key stored /root/nsc/nkeys/keys/A/B6/AB6OZPLYWRUYDDYRNCI37IY3AW7CWUBSJT7GZSERMEENMMCDKXZHH6SG.nk

$ nsc edit account -n CHAT --sk AB6OZPLYWRUYDDYRNCI37IY3AW7CWUBSJT7GZSERMEENMMCDKXZHH6SG
[ OK ] added signing key "AB6OZPLYWRUYDDYRNCI37IY3AW7CWUBSJT7GZSERMEENMMCDKXZHH6SG"
[ OK ] edited account "CHAT"

$ nsc generate nkey --account ADMIN --store
AAKKCUNMCNYPJQQ3U67TK7E44P6X4AGDSDQPCB457TGVNIJAYSDONOMZ
account key stored /root/nsc/nkeys/keys/A/AK/AAKKCUNMCNYPJQQ3U67TK7E44P6X4AGDSDQPCB457TGVNIJAYSDONOMZ.nk

$ nsc edit account -n ADMIN --sk AAKKCUNMCNYPJQQ3U67TK7E44P6X4AGDSDQPCB457TGVNIJAYSDONOMZ
[ OK ] added signing key "AAKKCUNMCNYPJQQ3U67TK7E44P6X4AGDSDQPCB457TGVNIJAYSDONOMZ"
[ OK ] edited account "ADMIN"

$ nsc describe jwt -f ./nsc/accounts/nats/KO/accounts/CHAT/CHAT.jwt | grep Signing
│ Signing Keys              │ AB6OZPLYWRUYDDYRNCI37IY3AW7CWUBSJT7GZSERMEENMMCDKXZHH6SG │

$ nsc describe jwt -f ./nsc/accounts/nats/KO/accounts/ADMIN/ADMIN.jwt | grep Signing
│ Signing Keys              │ AAKKCUNMCNYPJQQ3U67TK7E44P6X4AGDSDQPCB457TGVNIJAYSDONOMZ │

# Create user for the credentials provisioner
#   This is in the ADMIN account, a user that is able to provision credentials.
$ nsc add user -a ADMIN chat-access \
   -K /root/nsc/nkeys/keys/A/AK/AAKKCUNMCNYPJQQ3U67TK7E44P6X4AGDSDQPCB457TGVNIJAYSDONOMZ.nk \
   --allow-sub 'chat.req.access' \
   --allow-sub 'chat.KUBECON.online' \
   --allow-pubsub 'chat.req.provisioned' \
   --allow-pubsub 'chat.req.provisioned.updates' \
   --allow-pubsub 'chat.req.revoke' \
   --allow-pubsub '_INBOX.>' \
   --allow-pubsub '_R_.>' \
   --allow-pub-response
[ OK ] generated and stored user key "UAGVRUHF3ODJB2NYQTHWUGWCBAI2JONLFDGYIPUGUK5EXWR46UCJ5IPG"
[ OK ] generated user creds file `~/nsc/nkeys/creds/KO/ADMIN/chat-access.creds`
[ OK ] added user "chat-access" to account "ADMIN"

$ nsc describe jwt -f $NKEYS_PATH/creds/KO/ADMIN/chat-access.creds

# Create user for the credentials request
#   This is a bootstrapping user shared by everyone, like a guest user.
$ nsc add user -a ADMIN chat-creds-request \
   -K /root/nsc/nkeys/keys/A/AK/AAKKCUNMCNYPJQQ3U67TK7E44P6X4AGDSDQPCB457TGVNIJAYSDONOMZ.nk \
   --allow-pubsub '_INBOX.>' \
   --allow-pubsub '_R_.>' \
   --allow-pub 'chat.req.access'
[ OK ] generated and stored user key "UC5MAJPZAB6KULNUGSMNJKIDJRMHY6RGQLNZK6QWCMBZ2RZHFYEWR73I"
[ OK ] generated user creds file `~/nsc/nkeys/creds/KO/ADMIN/chat-creds-request.creds`
[ OK ] added user "chat-creds-request" to account "ADMIN"

$ nsc describe jwt -f $NKEYS_PATH/creds/KO/ADMIN/chat-creds-request.creds

# Add the export and import
$ nsc add export -a ADMIN --service -n chat-access  -s chat.req.access
[ OK ] added public service export "chat-access"
$ nsc add export -a CHAT  -n chat-online  -s chat.KUBECON.online
[ OK ] added public stream export "chat-online"

$ rm ./nsc/accounts/nsc.json

$ nsc add import -a CHAT  --service --src-account $(nsc list accounts 2>&1 | grep ADMIN | awk '{print $4}') -n chat-access --remote-subject chat.req.access   -s chat.req.access
[ OK ] added service import "chat.req.access"
$ nsc add import -a ADMIN -n chat-online \
    --src-account $(nsc list accounts 2>&1 | grep CHAT | awk '{print $4}') \
    --remote-subject chat.KUBECON.online
[ OK ] added stream import "chat.KUBECON.online"

# Setting up the NATS Server locally
#   Generate the NATS configuration.
$ source .nsc.env
$ nsc list accounts
$ mkdir conf jwt
$ nsc generate config --sys-account SYS --mem-resolver --config-file conf/resolver.conf
Success!! - generated `~/conf/resolver.conf`
$ cat conf/resolver.conf

#   Start the NATS Server:
$ wget https://github.com/nats-io/nats-server/releases/download/v2.1.9/nats-server-v2.1.9-linux-amd64.tar.gz
$ tar -zxvf nats-server-v2.1.9-linux-amd64.tar.gz
$ mv nats-server-v2.1.9-linux-amd64/nats-server /usr/local/bin/ && rm -rf nats-server-v2.1.9-linux-amd64/
# Run nats-server(on Terminal 0):
$ nats-server -c /root/conf/resolver.conf
[7669] 2020/12/03 17:35:19.244941 [INF] Starting nats-server version 2.1.9
[7669] 2020/12/03 17:35:19.245055 [INF] Git commit [7c76626]
[7669] 2020/12/03 17:35:19.245061 [INF] Trusted Operators
[7669] 2020/12/03 17:35:19.245064 [INF]   System  : ""
[7669] 2020/12/03 17:35:19.245067 [INF]   Operator: "KO"
[7669] 2020/12/03 17:35:19.245103 [INF]   Issued  : 2020-11-27 17:19:17 +0800 CST
[7669] 2020/12/03 17:35:19.245111 [INF]   Expires : 1970-01-01 08:00:00 +0800 CST
[7669] 2020/12/03 17:35:19.248611 [INF] Listening for client connections on 0.0.0.0:4222
[7669] 2020/12/03 17:35:19.248622 [INF] Server id is NAXGLNBOBMFMPWHHXAVMR7TPLCH7LXP7EQ772IXTW37PM2IJQVS7F6SM
[7669] 2020/12/03 17:35:19.248648 [INF] Server is ready

# Before smoke test
#   Golang install
$ wget https://studygolang.com/dl/golang/go1.15.5.linux-amd64.tar.gz
$ tar -C /usr/local -xzf go1.15.5.linux-amd64.tar.gz
$ echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile
$ source /etc/profile
$ go version
go version go1.15.5 linux/amd64

#   download tools
$ mkdir -p /root/go/src/github.com/nats-io/
$ cd /root/go/src/github.com/nats-io/
$ git clone https://github.com/nats-io/nats-box.git
$ git clone https://github.com/nats-io/stan.go.git

$ go env -w GOPROXY=https://goproxy.cn,direct
$ go get github.com/nats-io/nats-top
$ GO111MODULE=on go get -u -ldflags "-X main.version=0.4.10" github.com/nats-io/nsc@0.4.10
$ GO111MODULE=on go get -u -ldflags "-X main.version=0.0.18" github.com/nats-io/jetstream/nats@v0.0.18

#   install tools
$ cd nats-box/
$ go install
$ cd ../stan.go/examples/stan-pub/
$ go install
$ cd ../stan-sub/
$ go install

$ ls /root/go/bin -lh
总用量 54M
-rwxr-xr-x. 1 root root 6.8M 12月  3 17:13 nats-box
-rwxr-xr-x. 1 root root  11M 12月  3 16:44 nats-top
-rwxr-xr-x. 1 root root  18M 12月  3 16:47 nsc
-rwxr-xr-x. 1 root root 9.4M 12月  3 17:18 stan-pub
-rwxr-xr-x. 1 root root 9.4M 12月  3 17:18 stan-sub

$ mv /root/go/bin/nats* /usr/local/bin/ && mv /root/go/bin/stan* /usr/local/bin/
$ cd /usr/local/bin/ && ln -s nats-box nats-pub && ln -s nats-box nats-sub && ln -s nats-box nats-req && ln -s nats-box nats-rply
$ ls -lh
总用量 46M
-rwxr-xr-x. 1 root root 6.8M 12月  3 17:13 nats-box
lrwxrwxrwx. 1 root root    8 12月  3 17:31 nats-pub -> nats-box
lrwxrwxrwx. 1 root root    8 12月  3 17:31 nats-req -> nats-box
lrwxrwxrwx. 1 root root    8 12月  3 17:31 nats-rply -> nats-box
-rwxrwxr-x. 1 2000 2000 9.7M 11月  3 01:25 nats-server
lrwxrwxrwx. 1 root root    8 12月  3 17:31 nats-sub -> nats-box
-rwxr-xr-x. 1 root root  11M 12月  3 16:44 nats-top
-rwxr-xr-x. 1 root root 9.4M 12月  3 17:18 stan-pub
-rwxr-xr-x. 1 root root 9.4M 12月  3 17:18 stan-sub

# Smoke test
#   Create a mock admin responder(on Terminal 1):
$ nats-rply -creds ~/nsc/nkeys/creds/KO/ADMIN/chat-access.creds chat.req.access example
#   Try to make a request(on Terminal 2):
$ nats-req -creds ~/nsc/nkeys/creds/KO/ADMIN/chat-creds-request.creds chat.req.access example
$ nats-req -creds ~/nsc/nkeys/creds/KO/ADMIN/chat-creds-request.creds chat.req.access "《荷塘月色》
这几天心里颇不宁静。今晚在院子里坐着乘凉，忽然想起日日走过的荷塘，在这满月的光里，总该另有一番样子吧。月亮渐渐地升高了，墙外马路上孩子们的欢笑，已经听不见了；妻在屋里拍着闰儿⑴，迷迷糊糊地哼着眠歌。我悄悄地披了大衫，带上门出去。
沿着荷塘，是一条曲折的小煤屑路。这是一条幽僻的路；白天也少人走，夜晚更加寂寞。荷塘四面，长着许多树，蓊蓊郁郁⑵的。路的一旁，是些杨柳，和一些不知道名字的树。没有月光的晚上，这路上阴森森的，有些怕人。今晚却很好，虽然月光也还是淡淡的。
路上只我一个人，背着手踱⑶着。这一片天地好像是我的；我也像超出了平常的自己，到了另一个世界里。我爱热闹，也爱冷静；爱群居，也爱独处。像今晚上，一个人在这苍茫的月下，什么都可以想，什么都可以不想，便觉是个自由的人。白天里一定要做的事，一定要说的话，现 在都可不理。这是独处的妙处，我且受用这无边的荷塘月色好了。
曲曲折折的荷塘上面，弥望⑷的是田田⑸的叶子。叶子出水很高，像亭亭的舞女的裙。层层的叶子中间，零星地点缀着些白花，有袅娜⑹地开着的，有羞涩地打着朵儿的；正如一粒粒的明珠，又如碧天里的星星，又如刚出浴的美人。微风过处，送来缕缕清香，仿佛远处高楼上渺茫的歌声似的。这时候叶子与花也有一丝的颤动，像闪电般，霎时传过荷塘的那边去了。叶子本是肩并肩密密地挨着，这便宛然有了一道凝碧的波痕。叶子底下是脉脉⑺的流水，遮住了，不能见一些颜色；而叶子却更见风致⑻了。
月光如流水一般，静静地泻在这一片叶子和花上。薄薄的青雾浮起在荷塘里。叶子和花仿佛在牛乳中洗过一样；又像笼着轻纱的梦。虽然是满月，天上却有一层淡淡的云，所以不能朗照；但我以为这恰是到了好处——酣眠固不可少，小睡也别有风味的。月光是隔了树照过来的，高处丛生的灌木，落下参差的斑驳的黑影，峭楞楞如鬼一般；弯弯的杨柳的稀疏的倩影，却又像是画在荷叶上。塘中的月色并不均匀；但光与影有着和谐的旋律，如梵婀玲⑼上奏着的名曲。
荷塘的四面，远远近近，高高低低都是树，而杨柳最多。这些树将一片荷塘重重围住；只在小路一旁，漏着几段空隙，像是特为月光留下的。树色一例是阴阴的，乍看像一团烟雾；但杨柳的丰姿⑽，便在烟雾里也辨得出。树梢上隐隐约约的是一带远山，只有些大意罢了。树缝里也漏着一两点路灯光，没精打采的，是渴睡⑾人的眼。这时候最热闹的，要数树上的蝉声与水里的蛙声；但热闹是它们的，我什么也没有。
忽然想起采莲的事情来了。采莲是江南的旧俗，似乎很早就有，而六朝时为盛；从诗歌里可以约略知道。采莲的是少年的女子，她们是荡着小船，唱着艳歌去的。采莲人不用说很多，还有看采莲的人。那是一个热闹的季节，也是一个风流的季节。梁元帝《采莲赋》里说得好：
于是妖童媛女⑿，荡舟心许；鷁首⒀徐回，兼传羽杯⒁；棹⒂将移而藻挂，船欲动而萍开。尔其纤腰束素⒃，迁延顾步⒄；夏始春余，叶嫩花初，恐沾裳而浅笑，畏倾船而敛裾⒅。
可见当时嬉游的光景了。这真是有趣的事，可惜我们现 在早已无福消受了。
于是又记起，《西洲曲》里的句子：
采莲南塘秋，莲花过人头；低头弄莲子，莲子清如水。
今晚若有采莲人，这儿的莲花也算得“过人头”了；只不见一些流水的影子，是不行的。这令我到底惦着江南了。——这样想着，猛一抬头，不觉已是自己的门前；轻轻地推门进去，什么声息也没有，妻已睡熟好久了。
一九二七年七月，北京清华园。

1、闰儿：指朱闰生，朱自清第二子。
2、蓊蓊（wěng）郁郁：树木茂盛的样子。
3、踱（duó）：慢慢地走
4、弥望：满眼。弥，满。
5、田田：形容荷叶相连的样子。古乐府《江南曲》中有“莲叶何田田”之句。
6、袅娜（niǎo nuó）：柔美的样子。
7、脉脉（mò）：这里形容水没有声音，好像饱含深情的样子。
8、风致：美的姿态。
9、梵婀玲：violin，小提琴的音译。
10、丰姿：风度，仪态，一般指美好的姿态。也写作“风姿”
11、渴睡：也写作“瞌睡”。 [2] 
12、妖童媛女：俊俏的少年和美丽的少女。妖，艳丽。媛，女子。
13、鷁首（yì shǒu）：船头。古代画鷁鸟于船头。
14、羽杯：古代饮酒用的耳杯。又称羽觞、耳杯。
15、棹（zhào）：船桨。
16、纤腰束素：腰如束素，齿如含贝（宋玉《登徒子好色赋》），形容女子腰肢细柔
17、迁延顾步：形容走走退退不住回视自己动作的样子，有顾影自怜之意。
18、敛裾（jū）：这里是提着衣襟的意思。裾，衣襟。 [3]"
#   Create another one mock admin responder(on Terminal 3):
$ nats-rply -creds ~/nsc/nkeys/creds/KO/ADMIN/chat-access.creds chat.req.access example
# If you continue to request, the load balance on rply will be displayed
```

## Deploy demo on k8s (Bare-metal)

### prepare for certificate

``` BASH
# Generate certificate
$ mkdir -p /root/encrypt/demo.nats.chat
$ cd /root/encrypt/demo.nats.chat

# generate private-key
$ openssl genrsa -des3 -out privkey.pem 2048
Generating RSA private key, 2048 bit long modulus
.......................................+++
.........................................+++
e is 65537 (0x10001)
Enter pass phrase for privkey.pem:
Verifying - Enter pass phrase for privkey.pem:
# generate csr
$ openssl req -new -key privkey.pem -out privkey.csr
Enter pass phrase for privkey.pem:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:CN
State or Province Name (full name) []:Beijing
Locality Name (eg, city) [Default City]:Beijing
Organization Name (eg, company) [Default Company Ltd]:chats-demo
Organizational Unit Name (eg, section) []:info technology
Common Name (eg, your name or your server\'s hostname) []:demo.nats.chat
Email Address []:gytfdw7y@powerencry.com

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:

# remove the password form private-key
$ cp privkey.pem privkey.pem.org
$ openssl rsa -in privkey.pem.org -out privkey.pem
Enter pass phrase for privkey.pem.org:
writing RSA key

# generate certificate
$ openssl x509 -req -days 365 -in privkey.csr -signkey privkey.pem -out fullchain.pem
Signature ok
subject=/C=CN/ST=Beijing/L=Beijing/O=chats-demo/OU=info technology/CN=demo.nats.chat/emailAddress=gytfdw7y@powerencry.com
Getting Private key

$ ls 
fullchain.pem  privkey.csr  privkey.pem  privkey.pem.org
$ cat privkey.pem
-----BEGIN RSA PRIVATE KEY-----
MIIEpgIBAAKCAQEAsivXY7fSWV4Y2m7Kpp3tTJvPH2AotXGJQKFlMlUSz4AXU61S
TOGM6q1e8JMps5T9UU5OaRDZs4M5JyILhv3EvgtGkAxn4Zt/COHOioti8dXEVpJA
J8thuwiAToRDe4YNMtDGbqqLT/qOZDzL6/l/CjPJG9BD58SyqaPc65WphoipmAaJ
yL1FfL4NcUMMG3OmAtYzLUa9UAoH/W4pfeN69k479BXVwlK6/St3p2AlGoSTwqzV
VKXUiQkMf3g0Ocf9RTBrcmETCMw1aO8zFm1cSLKRgUpZAXLChr8XAPwgW7X0sNYY
qGmEczDdPxws/MGD+E17V4qLtfAfPKVFTTe20QIDAQABAoIBAQCEFFoEszV9SHM2
ImGaKILMgsiFYtxqvXLY9Yw2Rri+GB+yyU60bZPwOHuj7gRA+1bamikoW/R2zfVl
XCiddqwNkgBKMtgjeAkxRWu+atv7mNOGtb5Xgb6+TuwGyKfZ/yLzo68mRMknjf9W
sXceRIN3xbH1K2vbeYZUmYPhJL5aWuI+TFH7GdeF1sIP1iGVL/Em1b/Nw8vVCcsW
xlOSfwphtmGZXvrbQQOCJspU5pf2j6/9daLJDl7uY2W5wmwQBx5bXzb7ViF3OA5q
nlg+H5izkJ4drOl8yq+RvCpTwj+3U81vPWkyJvbrkzn/+RDcMA9lAHXFjGt7wszx
NUYG6X3BAoGBAN1BOat+F35AZDazI/nd1lUjzLmmi2z4l59GyMQzMa2umQdrVbRd
2Pdhio4y4+z4W+RbN0szcUKQUqhd3pmVchyx3/QHTFW1LbN56bp+bzMLIO/by+ic
ejFiE5+mYzsmD7ey9SefhzSLJDsZh4chziGvFcffvLXomTt9vBk0X72JAoGBAM4m
l+usaRJ/0sE23KIfl6Tx0pzBHNyiGCD+rlHxl5fFdjK6ZSYg3ZJgLFCalTkUwsdU
1tuK4uKT6eX0zKN0hUSBeYCOw6wCgBQ+YlFEJz873X2My+BVGUxULJn38nCcrDGg
I1fnqPiLF59He7LOU2jAS3OinyNe+h0yfhUVu2UJAoGBANL30J9++bO+fk/R/KnS
Jv7Dxf/3l9ZuK1UKT4EVN3deljgG1o/HNIydi1oPmFlqb2SMvWqNQJ+xsb8s0oYr
g8VsrhinpNfMjCkoQ/85c5p+MAfF0uaX3cOcuw1twAy0PCRzFWOUr30gd4mKzDnD
uCNSKTiOVAg4I3Qgbeyyjd/RAoGBAJwRLaxW30kJCjYKYag/QJ+4D5lqvX3vHVNF
XBVfUEOvUxd+c3sVIIljU8lF7jjDld4wRWT51WBxWH8mABKy8P13A9QmwM4lKm+o
9ufNL+U4Xithfyt7YWaexxFdW+aTRe1f7cHr+MkJDD4icOxiNVU1VynY8J9nlPSr
uDYgOLl5AoGBAIAcPd6TccDj2FwpjyWlftlHpAB0htakX73r4vQMcwyBNkPiIzQ5
HNDfItBJnSDwsgkgY+vXbp50WDWR8LpnrpaS44C6BzMzDMy026L4q1fH5N27xk0s
R7uEgOR8SGyfbXqKQGN/5KygtaXtFNts4UQ8aA2B5+HwKaVhVgSI+fpj
-----END RSA PRIVATE KEY-----
$ cat fullchain.pem
-----BEGIN CERTIFICATE-----
MIIDwDCCAqgCCQCxgo9sGKN/+zANBgkqhkiG9w0BAQsFADCBoTELMAkGA1UEBhMC
Q04xEDAOBgNVBAgMB0JlaWppbmcxEDAOBgNVBAcMB0JlaWppbmcxEzARBgNVBAoM
CmNoYXRzLWRlbW8xGDAWBgNVBAsMD2luZm8gdGVjaG5vbG9neTEXMBUGA1UEAwwO
ZGVtby5uYXRzLmNoYXQxJjAkBgkqhkiG9w0BCQEWF2d5dGZkdzd5QHBvd2VyZW5j
cnkuY29tMB4XDTIwMTIwNzA3MTU1OFoXDTIxMTIwNzA3MTU1OFowgaExCzAJBgNV
BAYTAkNOMRAwDgYDVQQIDAdCZWlqaW5nMRAwDgYDVQQHDAdCZWlqaW5nMRMwEQYD
VQQKDApjaGF0cy1kZW1vMRgwFgYDVQQLDA9pbmZvIHRlY2hub2xvZ3kxFzAVBgNV
BAMMDmRlbW8ubmF0cy5jaGF0MSYwJAYJKoZIhvcNAQkBFhdneXRmZHc3eUBwb3dl
cmVuY3J5LmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALIr12O3
0lleGNpuyqad7Uybzx9gKLVxiUChZTJVEs+AF1OtUkzhjOqtXvCTKbOU/VFOTmkQ
2bODOSciC4b9xL4LRpAMZ+GbfwjhzoqLYvHVxFaSQCfLYbsIgE6EQ3uGDTLQxm6q
i0/6jmQ8y+v5fwozyRvQQ+fEsqmj3OuVqYaIqZgGici9RXy+DXFDDBtzpgLWMy1G
vVAKB/1uKX3jevZOO/QV1cJSuv0rd6dgJRqEk8Ks1VSl1IkJDH94NDnH/UUwa3Jh
EwjMNWjvMxZtXEiykYFKWQFywoa/FwD8IFu19LDWGKhphHMw3T8cLPzBg/hNe1eK
i7XwHzylRU03ttECAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAGnfZ5teXu3XFUbUM
Exo+/PZddN1zgnRC4u4N4jaVymnJ11lUqGuPfiMabEf4vKB7uigFcboKcKRhiZuM
lW3iV9Nn7s6Kmz79EMbMkF4cLCLweVWKicHTvHkA/0SuBPgy10Lp2bwiOAkBhIRZ
DcuAdTn9DlYoe9TLi0jklYpx1k1D0x7seYIuxlimakUBuD28b3VkpGF6R23RHMId
ph9gH68zXrOkeXo8zNki9xVEJprKEkrSt7JHZeD2PzpAZcFkaVPiXrvlrSZvjIfn
CnBRUROWj03AtcQ++mcWz6maxodKEMih9CIPaVqp8YpbeBPO0S+bZh7JwAHAmPKy
dSQ3LA==
-----END CERTIFICATE-----

##################### do that again for nats.chat ######################

$ mkdir -p /root/encrypt/nats.chat
$ cd /root/encrypt/nats.chat
$ openssl genrsa -des3 -out privkey.pem 2048
# remember to change the hostname to nats.chat
$ openssl req -new -key privkey.pem -out privkey.csr 
$ cp privkey.pem privkey.pem.org
$ openssl rsa -in privkey.pem.org -out privkey.pem
$ openssl x509 -req -days 365 -in privkey.csr -signkey privkey.pem -out fullchain.pem

```

### prepare for ingress

> ref:
> https://metallb.universe.tf/installation/

``` BASH
# env
$ kubectl get no -o wide
NAME            STATUS                     ROLES    AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION           CONTAINER-RUNTIME
10.110.26.178   Ready,SchedulingDisabled   master   32d   v1.18.3   10.110.26.178     <none>        CentOS Linux 7 (Core)   3.10.0-957.el7.x86_64    docker://19.3.0
centos78-0      Ready                      <none>   32d   v1.18.3   192.168.122.148   <none>        CentOS Linux 7 (Core)   3.10.0-1127.el7.x86_64   docker://19.3.0
centos78-1      Ready                      <none>   32d   v1.18.3   192.168.122.242   <none>        CentOS Linux 7 (Core)   3.10.0-1127.el7.x86_64   docker://19.3.0

$ helm version
version.BuildInfo{Version:"v3.4.1", GitCommit:"c4e74854886b2efe3321e185578e6db9be0a6e29", GitTreeState:"clean", GoVersion:"go1.14.11"}

# deploy metallb
# check proxy mode
$ kubectl get configmap kube-proxy -n kube-system -o yaml | grep mode
# if in IPVS mode, you should enable the strictAPR
# # see what changes would be made, returns nonzero returncode if different
# $ kubectl get configmap kube-proxy -n kube-system -o yaml | \
# sed -e "s/strictARP: false/strictARP: true/" | \
# kubectl diff -f - -n kube-system

# # actually apply the changes, returns nonzero returncode on errors only
# $ kubectl get configmap kube-proxy -n kube-system -o yaml | \
# sed -e "s/strictARP: false/strictARP: true/" | \
# kubectl apply -f - -n kube-system

$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
$ wegt https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
$ sed -i "s/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g" metallb.yaml
$ kubectl apply -f metallb.yaml
# On first install only
$ kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
$ kubectl get po -n metallb-system -o wide
NAME                          READY   STATUS             RESTARTS   AGE     IP                NODE            NOMINATED NODE   READINESS GATES
controller-57fd7f8f54-kcl84   1/1     Running            0          7m52s   10.253.2.33       centos78-0      <none>           <none>
speaker-gt4ml                 0/1     CrashLoopBackOff   6          7m52s   10.110.26.178     10.110.26.178   <none>           <none>
speaker-js5qh                 1/1     Running            0          7m52s   192.168.122.242   centos78-1      <none>           <none>
speaker-mfjtf                 1/1     Running            0          7m52s   192.168.122.148   centos78-0      <none>           <none>
# one failed is for master, so just forget it...
$ kubectl describe  pod/speaker-gt4ml  -n metallb-system | grep Tolerations
Tolerations:     node-role.kubernetes.io/master:NoSchedule

# config for metallb
# It seems that any unused range of private IP addresses will be ok...
# https://metallb.universe.tf/configuration/#layer-2-configuration
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.122.100-192.168.122.120
EOF

# for test
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metallb-test-nginx
spec:
  selector:
    matchLabels:
      app: metallb-test-nginx
  template:
    metadata:
      labels:
        app: metallb-test-nginx
    spec:
      containers:
      - name: metallb-test-nginx
        image: nginx:alpine
        ports:
        - name: http
          containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: metallb-test-nginx
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: metallb-test-nginx
  type: LoadBalancer
EOF

$ kubectl get po -o wide | grep metallb-test-nginx
metallb-test-nginx-74c6f467c5-w8rwp   1/1     Running   0          9m32s   10.253.2.41   centos78-0   <none>           <none>
$ kubectl get svc metallb-test-nginx -o wide
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)        AGE     SELECTOR
metallb-test-nginx   LoadBalancer   10.103.247.98   192.168.122.100   80:30796/TCP   9m35s   app=metallb-test-nginx

# Normal
$ curl 10.253.2.41
$ curl centos78-0:30796
# Super slow
$ curl 10.103.247.98
$ curl 192.168.122.100
# I don't know why they are so slow(about one minute...)
# Maybe it's the issue like this(https://github.com/kubernetes/kubernetes/issues/87233#issue-550046098) or not...

# ############################################## UPDATE: May be useful: ##############################################
# https://github.com/kubernetes/kubernetes/issues/88986
# https://github.com/coreos/flannel/issues/1268
# https://github.com/coreos/flannel/issues/1243
# https://github.com/coreos/flannel/issues/1245
# https://www.cnblogs.com/lnlvinso/p/9775484.html
# https://mozillazg.com/2020/04/use-tcpdump-for-a-container-but-outside-container.html
# https://blog.csdn.net/u011125324/article/details/80814646
######################################################################################################################
# Network
# IN:   Wire -> NIC -> tcpdump -> netfilter/iptables 
# OUT:  iptables -> tcpdump -> NIC -> Wire

# It shows like issue: https://github.com/coreos/flannel/issues/1268
# retry for 1s, 2s, 4s, 8s, 16s, 32s and then get success...
$ curl 192.168.122.100 # on Terminal 0
$ date; tcpdump -i any host 10.253.2.41 # on Terminal 1
Tue Dec 15 10:00:37 CST 2020
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on any, link-type LINUX_SLL (Linux cooked), capture size 262144 bytes
10:00:38.038093 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [S], seq 2898731580, win 29200, options [mss 1460,sackOK,TS val 382891153 ecr 0,nop,wscale 7], length 0
10:00:39.040179 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [S], seq 2898731580, win 29200, options [mss 1460,sackOK,TS val 382892156 ecr 0,nop,wscale 7], length 0
10:00:41.044194 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [S], seq 2898731580, win 29200, options [mss 1460,sackOK,TS val 382894160 ecr 0,nop,wscale 7], length 0
10:00:45.052190 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [S], seq 2898731580, win 29200, options [mss 1460,sackOK,TS val 382898168 ecr 0,nop,wscale 7], length 0
10:00:53.060187 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [S], seq 2898731580, win 29200, options [mss 1460,sackOK,TS val 382906176 ecr 0,nop,wscale 7], length 0
10:01:09.092200 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [S], seq 2898731580, win 29200, options [mss 1460,sackOK,TS val 382922208 ecr 0,nop,wscale 7], length 0
10:01:41.124197 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [S], seq 2898731580, win 29200, options [mss 1460,sackOK,TS val 382954240 ecr 0,nop,wscale 7], length 0
10:01:41.124734 IP 10.253.2.41.http > 10.110.26.178.11199: Flags [S.], seq 392411908, ack 2898731581, win 28960, options [mss 1460,sackOK,TS val 382928795 ecr 382954240,nop,wscale 7], length 0
10:01:41.124770 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [.], ack 1, win 229, options [nop,nop,TS val 382954240 ecr 382928795], length 0
10:01:41.124881 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [P.], seq 1:80, ack 1, win 229, options [nop,nop,TS val 382954240 ecr 382928795], length 79: HTTP: GET / HTTP/1.1
10:01:41.126107 IP 10.253.2.41.http > 10.110.26.178.11199: Flags [.], ack 80, win 227, options [nop,nop,TS val 382928797 ecr 382954240], length 0
10:01:41.126300 IP 10.253.2.41.http > 10.110.26.178.11199: Flags [P.], seq 1:239, ack 80, win 227, options [nop,nop,TS val 382928797 ecr 382954240], length 238: HTTP: HTTP/1.1 200 OK
10:01:41.126313 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [.], ack 239, win 237, options [nop,nop,TS val 382954242 ecr 382928797], length 0
10:01:41.126486 IP 10.253.2.41.http > 10.110.26.178.11199: Flags [P.], seq 239:851, ack 80, win 227, options [nop,nop,TS val 382928797 ecr 382954242], length 612: HTTP
10:01:41.126497 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [.], ack 851, win 247, options [nop,nop,TS val 382954242 ecr 382928797], length 0
10:01:41.126639 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [F.], seq 80, ack 851, win 247, options [nop,nop,TS val 382954242 ecr 382928797], length 0
10:01:41.128128 IP 10.253.2.41.http > 10.110.26.178.11199: Flags [F.], seq 851, ack 81, win 227, options [nop,nop,TS val 382928799 ecr 382954242], length 0
10:01:41.128145 IP 10.110.26.178.11199 > 10.253.2.41.http: Flags [.], ack 852, win 247, options [nop,nop,TS val 382954243 ecr 382928799], length 0
^C
18 packets captured
19 packets received by filter
0 packets dropped by kernel

# They said that change flannel backend from xvlan to host-gw may solve the problem.
# But, it shows that host-gw was not suitable for me in this page: https://www.cnblogs.com/sandshell/p/11769642.html
# host-gw was only for layer2 networking which means all nodes are in the same network segment
# Finally, directrouting solve the problem!!
# Add Directrouting to Backend of flannel config like this:
$ kubectl edit cm kube-flannel-cfg -n kube-system
  ...
  net-conf.json: |
    {
      "Network": "10.253.0.0/16",
      "Backend": {
        "Type": "vxlan",
        "Directrouting": true
      }
    }
  ...
# Update flannel pod
$ kubectl delete po -l app=flannel -n kube-system
# Then wait for all the flannel pods to restart.
# For testing, run all commands on each node and each command will return immediately
$ time curl 10.253.2.41
$ time curl centos78-0:30796
$ time curl 10.103.247.98
$ time curl 192.168.122.100

$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
$ helm repo update
# $ helm install my-release ingress-nginx/ingress-nginx --set-string controller.image.digest=''
$ helm install ingress /root/charts/ingress-nginx-3.13.0.tgz --set-string controller.image.digest=''
# make sure that the ingress is ok
$ kubectl get all
```

### install demo

``` BASH
$ pwd 
/root
$ git clone https://github.com/nats-io/kubecon2020.git
$ cd kubecon2020

# Create NodePort service to create A records for each server
#   This NodePort is required in order to be able to expose the host ports.
# kubectl apply -f k8s/node-port.yaml
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nats-nodeport
  labels:
    app: nats
spec:
  type: NodePort
  selector:
    app: nats
  externalTrafficPolicy: Local
  ports:
  - name: client
    port: 4222
    nodePort: 30222
    targetPort: 4222
  - name: websocket
    port: 443
    nodePort: 30223
    targetPort: 443
EOF

# Create load balancer for the websockets port
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nats-lb
spec:
  type: LoadBalancer
  selector:
    app: nats-chat-frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
      name: websocket
EOF


# Deploying NATS to a K8S Cluster
#   Add Helm NATS repos
$ helm repo add nats https://nats-io.github.io/k8s/helm/charts/
$ helm repo update

#   Upload the NATS Accounts bootstrap file
kubectl create cm nats-accounts --from-file /root/conf/resolver.conf


# Setup TLS
#   We will need TLS for the websockets:
$ kubectl create secret generic nats-tls \
        --from-file=/root/encrypt/demo.nats.chat/fullchain.pem \
        --from-file=/root/encrypt/demo.nats.chat/privkey.pem

$ kubectl create secret generic nats-frontend-tls \
        --from-file=/root/encrypt/nats.chat/fullchain.pem \
        --from-file=/root/encrypt/nats.chat/privkey.pem


# Create the secrets
#   Secrets for the provisioner:
$ nsc describe jwt -f ./nsc/accounts/nats/KO/accounts/CHAT/CHAT.jwt | grep Signing
│ Signing Keys              │ AB6OZPLYWRUYDDYRNCI37IY3AW7CWUBSJT7GZSERMEENMMCDKXZHH6SG │
nsc describe jwt -f ./nsc/accounts/nats/KO/accounts/CHAT/CHAT.jwt | grep Issuer
│ Issuer ID                 │ ODLDEOHCCTXHZJIMWETE5TYRUUSXMXZHHTZ74ILFGJLX7GCWPSPMXVN4 │
$ cd /root
$ mkdir creds
$ cp ./nsc/nkeys/keys/A/B6/AB6OZPLYWRUYDDYRNCI37IY3AW7CWUBSJT7GZSERMEENMMCDKXZHH6SG.nk creds/sk.nk
$ cp ./nsc/nkeys/keys/O/DL/ODLDEOHCCTXHZJIMWETE5TYRUUSXMXZHHTZ74ILFGJLX7GCWPSPMXVN4.nk creds/osk.nk
$ kubectl create secret generic nats-admin-creds \
        --from-file=./nsc/accounts/nats/KO/accounts/CHAT/CHAT.jwt \
        --from-file=./creds/osk.nk \
        --from-file=./creds/sk.nk \
        --from-file=./nsc/nkeys/creds/KO/SYS/sys.creds \
        --from-file=./nsc/nkeys/creds/KO/ADMIN/chat-access.creds
#   Generic bootstrap credentials for users:
$ kubectl create secret generic nats-bootstrap-creds \
        --from-file=bootstrap-creds=./nsc/nkeys/creds/KO/ADMIN/chat-creds-request.creds

# $ helm install nats nats/nats -f k8s/sfo-nats-server.yaml
$ helm install nats /root/charts/nats-0.7.5.tgz -f k8s/sfo-nats-server.yaml
# Running on nodes
$ mkdir /data/nats
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: centos78-0-pv0
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /data/nats
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - centos78-0
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: centos78-1-pv0
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /data/nats
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - centos78-1
EOF

$ kubectl create secret generic ingress-nats-tls \
        --from-file=tls.crt=/root/encrypt/demo.nats.chat/fullchain.pem \
        --from-file=tls.key=/root/encrypt/demo.nats.chat/privkey.pem \
        --type=kubernetes.io/tls
$ kubectl create secret generic ingress-nats-frontend-tls \
        --from-file=tls.crt=/root/encrypt/nats.chat/fullchain.pem \
        --from-file=tls.key=/root/encrypt/nats.chat/privkey.pem \
        --type=kubernetes.io/tls

# https://blog.csdn.net/cds992/article/details/106246616/
# Error from server (InternalError): 
#   error when creating "../test/ingress-nats.yaml": Internal error occurred: failed calling webhook "validate.nginx.ingress.kubernetes.io": Post https://ingress-ingress-nginx-controller-admission.default.svc:443/networking/v1beta1/ingresses?timeout=10s: context deadline exceeded
# kubectl edit ValidatingWebhookConfiguration <Helm-release-name>-ingress-nginx-admission
# failurePolicy: Fail # ----> Ignore
$ kubectl apply -f - << EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-tls
  namespace: default
spec:
  tls:
  - hosts:
    - demo.nats.chat
    secretName: ingress-nats-tls
  - hosts:
    - nats.chat
    secretName: ingress-nats-frontend-tls
  rules:
  - host: demo.nats.chat
    http:
      paths:
      - backend:
          serviceName: nats-nodeport
          servicePort: 4222
        path: /
      - backend:
          serviceName: nats-nodeport
          servicePort: 443
        path: /
  - host: nats.chat
    http:
      paths:
      - backend:
          serviceName: nats-lb
          servicePort: 80
        path: /
EOF



# kubectl apply -f k8s/creds-provisioner.yaml
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nats-creds-provisioner
  labels:
    app: nats-creds-provisioner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nats-creds-provisioner
  template:
    metadata:
      labels:
        app: nats-creds-provisioner
    spec:
      volumes:
      - name: nats-admin-creds
        secret:
         secretName: nats-admin-creds
      containers:
      - name: nats-creds-provisioner
        image: synadia/nats-creds-provisioner:0.1.0
        imagePullPolicy: IfNotPresent
        command:
        - /usr/local/bin/chat-access
        - -s=tls://demo.nats.chat:4222
        - -acc=/etc/nats/creds/CHAT.jwt
        - -sk=/etc/nats/creds/sk.nk
        - -osk=/etc/nats/creds/osk.nk
        - -creds=/etc/nats/creds/chat-access.creds
        - -syscreds=/etc/nats/creds/sys.creds
        volumeMounts:
        - mountPath: /etc/nats/creds
          name: nats-admin-creds
EOF

# kubectl apply -f k8s/chat-frontend-deploy.yaml
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nats-chat-frontend
  labels:
    app: nats-chat-frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nats-chat-frontend
  template:
    metadata:
      labels:
        app: nats-chat-frontend
    spec:
      containers:
      - name: nats-chat-frontend
        image: synadia/nats-chat-frontend:1.0.6
        env:
        - name: WEBPACK_MODE
          value: production
        - name: NATS_SERVER_URL
          value: wss://demo.nats.chat:443
        - name: NATS_BOOTSTRAP_CREDS
          valueFrom:
            secretKeyRef:
              name: nats-bootstrap-creds
              key: bootstrap-creds
        imagePullPolicy: IfNotPresent
        command:
        - make
        - start
EOF
```
