# Linux 升级 git

ref: 
* https://github.com/git/git/blob/master/INSTALL
* https://blog.csdn.net/qq_575775600/article/details/120997367
* https://www.codeleading.com/article/82883680357/

```BASH
$ mkdir git
$ cd git
$ wget https://github.com/git/git/archive/refs/tags/v2.37.2.tar.gz -O git-v2.37.2.tar.gz
$ tar -zxvf git-v2.37.2.tar.gz
$ cd git-2.37.2/

# remove git from yum
$ yum remove git -y

# update config
$ which openssl
/usr/bin/openssl
$ make configure
$ ./configure --with-openssl=/usr/bin/openssl --prefix=/usr/local
# install
$ make all doc
$ make install install-doc

# done
$ git version
git version 2.37.2
```

**Some errors:**

```BASH
$ make prefix=/usr/local all doc info
...
    CC imap-send.o
    LINK git-imap-send
imap-send.o: In function `sk_GENERAL_NAME_num':
/usr/local/include/openssl/x509v3.h:166: undefined reference to `OPENSSL_sk_num'
imap-send.o: In function `sk_GENERAL_NAME_value':
/usr/local/include/openssl/x509v3.h:166: undefined reference to `OPENSSL_sk_value'
imap-send.o: In function `sk_GENERAL_NAME_pop_free':
/usr/local/include/openssl/x509v3.h:166: undefined reference to `OPENSSL_sk_pop_free'
/usr/local/include/openssl/x509v3.h:166: undefined reference to `OPENSSL_sk_pop_free'
imap-send.o: In function `ssl_socket_connect':
/root/git/git-2.37.2/imap-send.c:277: undefined reference to `OPENSSL_init_ssl'
/root/git/git-2.37.2/imap-send.c:278: undefined reference to `OPENSSL_init_ssl'
/root/git/git-2.37.2/imap-send.c:280: undefined reference to `TLS_method'
/root/git/git-2.37.2/imap-send.c:293: undefined reference to `SSL_CTX_set_options'
collect2: error: ld returned 1 exit status
make: *** [git-imap-send] Error 1
# need to update openssl's path like above

# error
$ make configure
    GEN configure
/bin/sh: autoconf: command not found
make: *** [configure] Error 127
# solution
$ yum install autoconf -y

# error
$ make all doc
...
make[2]: `GIT-VERSION-FILE' is up to date.
make[2]: Leaving directory `/root/git/git-2.37.2'
    * new asciidoc flags
    ASCIIDOC git-archive.html
/bin/sh: asciidoc: command not found
make[1]: *** [git-archive.html] Error 127
make[1]: Leaving directory `/root/git/git-2.37.2/Documentation'
make: *** [doc] Error 2
# solution
$ yum install asciidoc -y
# continue
$ make all doc
...
/bin/sh: xmlto: command not found
make[1]: *** [git-receive-pack.1] Error 127
make[1]: Leaving directory `/root/git/git-2.37.2/Documentation'
make: *** [doc] Error 2
$ yum install xmlto -y
# continue
$ make all doc

# error
$ git clone https://github.com/kubevirt/kubevirt.git /root/go/src/github.com/kubevirt/kubevirt --depth=1
Cloning into '/root/go/src/github.com/kubevirt/kubevirt'...
git: 'remote-https' is not a git command. See 'git --help'.
# solution
$ yum install libcurl-devel -y
# rebuild
```

**some other dependents may you need:**
I didnot install them this time, maybe they are not dependents, or maybe I have already installed them before.

```BASH
# Comes form https://blog.csdn.net/qq_575775600/article/details/120997367
$ yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel gcc perl-ExtUtils-MakeMaker
```
