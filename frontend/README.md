# Frontend

天人律 Flutter 移动端，包含 Android 与 iOS 平台工程。

## 本地运行

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Android 模拟器通过 `10.0.2.2` 访问宿主机；真机调试时请将地址替换为开发机可访问的
局域网地址。生产构建必须显式传入 HTTPS API 地址。

## 当前功能

- 出生日期、时间、地点、经纬度和 IANA 时区录入
- 后端生命档案生成接口对接
- 星座和五运六气结果展示
- 按日期查看每日生命建议，支持下拉刷新和失败重试
- 请求失败、输入校验、节气边界与健康免责声明提示
