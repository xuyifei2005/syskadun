## 我想要系统更换软件不受太大影响！
npm 安装的东西是不是默认在 c 盘，能改到其他盘符吗，请你给我列出所有我重装系统不影响现在电脑使用的方案包含常用的各类软件，我的意思是我C盘系统如果重装了还更换了不要影响我电脑软件的使用


### 关于你问的 npm
是的，npm 默认 全局安装目录和缓存都在 C 盘 ：

- 全局包： C:\Users\xuyif\AppData\Roaming\npm
- 缓存： C:\Users\xuyif\AppData\Local\npm-cache



两行命令就能改到 D 盘：
```
npm config set prefix D:\DevTools\npm-global
npm config set cache D:\DevTools\npm-cache
```


---
## D:\AppData_Migrate 这个路径！
D:\AppData_Migrate


## C:\Users\xuyif\AppData\Local\Programs   D:\AppData_Migrate\Programs
C:\Users\xuyif\AppData\Local\Programs    