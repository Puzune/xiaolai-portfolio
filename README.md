# Portfolio Prototype

这是给简历二维码使用的静态作品集原型。页面入口是 `portfolio/index.html`，内容配置集中在 `portfolio/data.js`。

线上地址：

```text
https://puzune.github.io/xiaolai-portfolio/
```

## 本地预览

在项目根目录运行：

```powershell
python -m http.server 8080
```

然后打开：

```text
http://localhost:8080/portfolio/
```

## 上线前校验

```powershell
.\portfolio\scripts\validate-portfolio.ps1
```

## 更新作品

1. 把新作品原图放进项目根目录现有分类文件夹，例如 `海报设计作品` 或 `产品效果设计作品`。
2. 运行：

```powershell
.\portfolio\scripts\build-assets.ps1
```

3. 在 `portfolio/data.js` 中新增或调整项目、归档条目、标签和排序。
4. 再运行校验脚本，确认没有缺图或脚本错误。
5. 部署 `portfolio` 目录，简历二维码保持指向同一个线上地址。

更多部署细节见 `portfolio/DEPLOY.md`。
