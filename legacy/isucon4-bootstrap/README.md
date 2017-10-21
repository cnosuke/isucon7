# Bootstrap for ISUCON4


### Install necessary applications
```bash
% yum install emacs zsh htop zip nginx tmux
```
もしzshが古すぎたら...
`install_zsh` のでインスコ

## Install dotfiles
```bash
$ ssh-keygen
$ cat ~/.ssh/id_rsa.pub # GitHub deploy keysに追加
$ git clone git@github.com:cnosuke/isucon4-bootstrap ~/isucon4-bootstrap
$ sh ~/isucon4-bootstrap/install.sh
```

## varnish
```bash
rpm --nosignature -i https://repo.varnish-cache.org/redhat/varnish-4.0.el6.rpm
yum install varnish
```

