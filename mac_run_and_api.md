好消息：我已用一键脚本把服务跑起来了，当前本机预览地址是

- http://127.0.0.1:7860
提示：浏览器的字体资源报错是无关紧要的，不影响页面功能。

如何一键运行

- 在项目根目录执行： bash scripts/run_mac.sh
- 脚本会自动：
  - 检测系统 Python，找不到 3.10 就自动安装 Miniconda；
  - 非交互接受 Conda ToS，创建并激活本地环境 lam_a2e ；
  - 安装项目依赖与本地 WebGL 渲染控件；
  - 安装 macOS 的 PyTorch CPU/MPS 版本；
  - 启动 Gradio 服务并打开本地地址。
- 完成后在终端会看到“Running on local URL: http://127.0.0.1:7860 ”，点击即可访问。
是否必须虚拟环境

- 从严格意义上讲，不“必须”。不过项目的 requirements.txt 限定 Python 版本在 >=3.10,<3.14 ，且依赖较多，在系统 Python 下容易发生版本冲突。
- 我的一键脚本会自动建立本地 Conda 环境，只在项目目录内生效，不污染系统。你无需手工处理虚拟环境，直接跑脚本即可。
日常使用

- 再次启动： bash scripts/run_mac.sh
- 停止服务：在运行脚本的终端按 Ctrl + C
- 修改端口：可在 app_lam_audio2exp.py 的 launch() 里增加 server_port=xxxx （如 server_port=7861 ）
- 外网分享：在 launch() 里加 share=True （或运行后终端提示也会给分享选项）
设备与性能说明

- 我已把推理流程改为设备自适应：优先使用 mps （Apple GPU），否则回退 cpu 。
- macOS 上（尤其是 CPU 模式）速度会比 CUDA 慢，这是正常现象。Apple Silicon 推荐设置环境变量 PYTORCH_ENABLE_MPS_FALLBACK=1 以提升稳定性。
如果你想命令行推理（非 UI）

- 可执行： python inference_streaming_audio.py （同样在脚本创建的环境里）
- 权重已按脚本下载并放到 pretrained_models/lam_audio2exp_streaming.tar （Gradio 也使用该权重）




---------------------

API（Gradio v5 命名空间）

- 基础路径：`http://127.0.0.1:7860/gradio_api`（不是旧版的 `/api`）
- 端点信息：`GET /gradio_api/info`（其中包含 `named_endpoints`，可见 `"/a2e_predict"`）
- 命名端点（已在 Blocks 中注册）：`api_name="a2e_predict"`
  - 同步预测：`POST /gradio_api/run/a2e_predict`
  - 异步预测：`POST /gradio_api/call/a2e_predict`
- 静态文件下载：`GET /gradio_api/file=assets/...` 或 `GET /gradio_api/file/{path}`

- 请求与响应

- 请求体（JSON）：
  - `data` : 数组，按顺序传入
    1. `image_path` : 输入角色图像的本地路径（例如 `assets/sample_input/james.png`）。如果使用 ZIP（LAM 的输出包），此项可留空字符串 `""`。
    2. `audio_path` : 输入音频的本地路径，例如 `assets/sample_audio/BarackObama_english.wav`
    3. `input_zip_path` : LAM 生成的 ZIP 本地路径（可选），传了 ZIP 则会自动解压并使用其中的 `arkitWithBSData` 作为工作目录
- 同步响应（`/run`）：
  - 成功时返回选中的音频与渲染压缩包的路径，形如 `gradio_api/file=assets/...`，前端需拼接为 `{{host}}/gradio_api/file=assets/...` 直接下载或播放。
  - 失败时返回 500，可查看服务端日志定位问题（如权重路径、工作目录、MPS 回退等）。
- 异步响应（`/call`）：
  - 返回 `{"event_id":"..."}`；随后前端通过 `GET /gradio_api/stream/{event_id}` 订阅 SSE 流读取过程与结果（`Accept: text/event-stream`）。

- 调用示例

- curl 同步示例：
  - `curl -X POST http://127.0.0.1:7860/gradio_api/run/a2e_predict -H 'Content-Type: application/json' -d '{"data": ["assets/sample_input/james.png", "assets/sample_audio/BarackObama_english.wav", ""]}'`
- curl 异步示例：
  - `curl -X POST http://127.0.0.1:7860/gradio_api/call/a2e_predict -H 'Content-Type: application/json' -d '{"data": ["assets/sample_input/james.png", "assets/sample_audio/BarackObama_english.wav", ""]}'`
  - 说明：拿到 `event_id` 后在前端用 `EventSource` 订阅 `GET /gradio_api/stream/{event_id}`。
- JS/前端（fetch，同步）：
  - `fetch("http://127.0.0.1:7860/gradio_api/run/a2e_predict",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({data:["assets/sample_input/james.png","assets/sample_audio/BarackObama_english.wav",""]})})`
- 文件下载示例：
  - `GET http://127.0.0.1:7860/gradio_api/file=assets/james_BarackObama_english.zip`

- 使用建议

- 路径使用相对项目根目录的本地路径即可（如 `assets/...` ），服务会将 ZIP 自动解压并组织输出。
- 如果你只想要 `bsData.json` ，可以在拿到 `selected_render_file` 后解压并读取 `arkitWithBSData/bsData.json`。
- 设备选择当前默认是 CPU，Apple Silicon 支持 MPS；已对 `NotImplementedError` 做自动回退处理。

- 若仍遇到错误

- 若返回 500，请贴出服务端终端的完整栈；我会根据报错继续完善接口或参数校验。
- 若返回 `Too many arguments provided for the endpoint`，请确认 `data` 数组按上面三项顺序传，并且第三项为空字符串而不是省略（有些前端封装会丢第三个参数导致形参错位）。




