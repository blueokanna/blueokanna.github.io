### Github 仓库： blueokanna.github.io
### Dynadot 域名: blueokanna.gay

----
# 自定义：
> (国内加载这个会比较慢，有梯子加载会比较快)
>
> 目前设计的 HTML + CSS 在 Safari 浏览器会有一定的显示问题，Chrome 和 Firefox 的朋友都没有问题

## 自定义个人博客网页
> 你可以自己添加关于 **Markdown** 的 JavaScript 的脚本
```
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
```
当然你也可以自己写一个关于Markdown的 JS 文件放进自己的静态 **index.html** 的项目里面

## 经验分享&调试步骤

1. 这里踩过的坑有很多，首先是个人创建静态网页是用于给类似于博客，个人主页这样的使用。动态的网页不适合在这里搞
2. 自定义的域名要会搞，比如在腾讯，阿里等域名的购买网站要先了解如何添加CNAME，A，AAAA这些type
3. 创建个人的仓库这里最好使用 **name.github.io** 这样的仓库名字，比如我的名字叫做blueokanna，那么仓库的名字就要设置为**blueokanna.github.io**
4. 仓库创建的时候可以点击ReadME，这个都没有关系，后期都可以调整。请注意，要选择 **Public** ,不要选择 **Private**
5. 创建好后，在中间的偏右上方有个 Setting，点击 Setting -> Pages（这里要注意，不要点击头像去了）
6. 在 **Branch** 里面的 None 选择 **main** 或者其他的比如 Master 这样（一般都是 main）,后面选择 **/root**，完成后选择保存
7. 保存成功后会出现，底下会出现 Custom domain 的填写栏，你把你的域名放进去，点击保存。
8. 这时候，前往你购买域名的网站去进行填写你的域名 config（参数），参考链接如下 ： [Github domain 调试参考说明](https://docs.github.com/zh/pages/configuring-a-custom-domain-for-your-github-pages-site/about-custom-domains-and-github-pages)
9. 完成后，**等待！等待！等待！** 多等几分钟，然后回到 Pages，点击 **verify** 进行验证，如果出现红色的提示，那么要注意你的 domain 调试有问题，如果为绿色，那么恭喜你成功一大半了。
10. 回到 **code** 目录，选择绿色按钮的 **code**，然后复制你的 https，在你的桌面上打开 cmd 命令行（Windows），Mac/Linux用户可以打开 Terminal，输入git clone + 你复制的 https 地址。
    
![2023-09-23 02-24-23屏幕截图](https://github.com/blueokanna/blueokanna.github.io/assets/56761243/41d7a037-da98-4699-b196-428eadee246a)

11. 下载到你的目录后，将你的文件放进去，然后在那个目录里面输入 **git status** 他会呈现出你所有改变的文件，再点击 **git add .**，此时的改变文件就是绿色的了
12. 接下来是比较复杂的一个步骤，首先如果你从来没有认证你的Github在你的命令行里面，请自行认证，认证方法为 **git config --global user.name username** 后面的 username 改为你自己在 Github 上的名字，也可以使用email，例如 **git config --global user.email username@email.com**，认证过得朋友直接输入 **git commit -m 'Initial commit'**
13. 最后直接 **git push** 上去就好了 😆

----
# 小编结言
以上的所有经验全部是作者我走过的坑，我花过最长的时间就是 **Pages** 的那个参数调节，大家不要害怕失败，毕竟自己多尝试几次就慢慢有经验了。如果喜欢我的内容的话，可以给我点上 **Star**，让更多的人看到我的内容。最后祝大家都能给自己部署上喜欢的个人博客！😄
