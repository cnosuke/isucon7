## How to install zsh from source code

```
% unzip zsh-5.0.6.zip
% cd zsh-5.0.6
% ./configure
% make
% sudo make install
```

`/etc/shells` に `/usr/local/bin/zsh` を追記

```
chsh -s /usr/local/bin/zsh
```
