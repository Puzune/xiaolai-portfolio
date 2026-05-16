# 部署前清单

当前 GitHub Pages 地址：

```text
https://puzune.github.io/xiaolai-portfolio/
```

## 需要确认

1. 作品集署名：现在使用 `Xiaolai Portfolio`，上线前建议替换成你的真实姓名或希望被看到的设计师名。
2. 作品集标题：现在是 `陶瓷与视觉设计作品集`，也可以改成更聚焦的 `陶瓷产品与文创设计作品集`。
3. 精选项目顺序：目前按视觉完整度和简历展示价值排序，仍需要你最终确认。
4. 线上平台：推荐优先用 Vercel 或 GitHub Pages。Vercel 更新更省心，GitHub Pages 更稳定朴素。
5. 简历二维码文字：建议用 `作品集 Portfolio`，下方可加 `Ceramic / Product / Visual`。

## 推荐部署方式

### Vercel

1. 把项目上传到 GitHub。
2. 在 Vercel 导入仓库。
3. Framework Preset 选择 `Other`。
4. Root Directory 选择 `portfolio`。
5. Build Command 留空。
6. Output Directory 留空或使用 `.`。

### GitHub Pages

1. 把 `portfolio` 目录作为站点根目录发布，或把里面的文件复制到 `docs` 目录。
2. Pages Source 选择对应分支和目录。
3. 发布后用线上地址生成二维码。

## 每次上线前运行

```powershell
.\portfolio\scripts\validate-portfolio.ps1
```

如果新增或替换了原图，先运行：

```powershell
.\portfolio\scripts\build-assets.ps1
.\portfolio\scripts\validate-portfolio.ps1
```
