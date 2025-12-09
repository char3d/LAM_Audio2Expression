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

