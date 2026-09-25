# Bonsai 2 27B · NInfer on RTX 5060 Ti（Ubuntu / Linux）

基于 **[CraneBW/ninfer-ternary-bonsai-ada](https://github.com/CraneBW/ninfer-ternary-bonsai-ada)**
在 **Ubuntu + RTX 5060 Ti（Blackwell, sm_120a, 16 GB）** 上编译并跑通。

结构与用法对齐 [yutils/ninfer-Bonsai-2-5070](https://github.com/yutils/ninfer-Bonsai-2-5070)（Windows / 5070），本仓面向 Linux。

> 上游引擎参考架构就是 `sm_120a`。本机缺的是 `device.h` 的 Blackwell SM 计数分支（5060 Ti = **36 SM**），
> 以及本机 CUDA 为 **13.0**（上游默认门槛 13.1）—— 见「四、适配」。

---

## 权重 / 制品来源（重要）

本仓 **不发布** `.ninfer` / `.gguf` 权重。制品由下列 GGUF **打包** 得到：

| 项 | 值 |
|---|---|
| GGUF 源 | [nuottroisaoduoc/Bonsai-2-27B-Ternary-CRACK-GGUF](https://huggingface.co/nuottroisaoduoc/Bonsai-2-27B-Ternary-CRACK-GGUF)（`Bonsai-2-27B-PQ2_0-CRACK.gguf` / PQ2_0） |
| 打包器 | [shensanshu/ninfer-ada-ternary](https://www.modelscope.cn/models/shensanshu/ninfer-ada-ternary) 的 `tools/pack.py` |
| 模板制品 | 任意 `weights_id=groupwise-int` 的 `qwen3.8-27b` `.ninfer`（借 vision / MTP / frontend） |
| 输出制品 | **`Bonsai-2-27B-PQ2_0-CRACK.ninfer`**（约 7.8 GiB；文本 6.70 GiB + MTP/vision 借用） |
| 成品下载 | [mengyou6688/Bonsai-2-27B-PQ2_0-CRACK-NInfer](https://www.modelscope.cn/models/mengyou6688/Bonsai-2-27B-PQ2_0-CRACK-NInfer)（ModelScope） |

打包命令见 `scripts/pack-ternary.sh`。也可直接拉成品：

```bash
# 需已登录 modelscope / 安装 ms CLI
ms download mengyou6688/Bonsai-2-27B-PQ2_0-CRACK-NInfer \
  --local_dir artifacts
# 或放到本机默认路径：
#   /f/Bonsai-2-27B-PQ2_0-CRACK.ninfer
```

制品自检：

```
model_id: qwen3.8-27b
weights_id: groupwise-int
objects: 1126
formats: PQ2_0_G128×322, BF16, Q4G64_F16S, …
```

---

## 省流说明

1. `bash scripts/build.sh`（约数分钟～十分钟）→ 出现 `build/apps/ninfer-serve`
2. 放入制品：从 [ModelScope](https://www.modelscope.cn/models/mengyou6688/Bonsai-2-27B-PQ2_0-CRACK-NInfer) 下载到 `artifacts/`（或 `/f/Bonsai-2-27B-PQ2_0-CRACK.ninfer`）
3. `bash start-server.sh` 启动服务（`127.0.0.1:8080`）
4. `bash chat.sh` 多轮聊天验证
5. 再接 opencode / Claude Code 等（见 `接入指南.md`）

---

## 一、一键启动

| 想做的事 | 命令 | 说明 |
|---|---|---|
| **启动服务** | `bash start-server.sh` | 先开它，等 `listening on …` |
| **开始聊天** | `bash chat.sh` | 终端多轮，每轮打印 tok/s |
| 复跑 PPL | `bash run-ppl.sh` | 怀疑权重跑偏时用 |
| 重新编译 | `bash scripts/build.sh` | 改了 C++ 源码后才需要 |
| 重新打包 | `bash scripts/pack-ternary.sh` | 从 CRACK GGUF 再打 `.ninfer` |

`chat.py` 命令：`/clear` · `/think` · `/temp 0.8` · `/max 4096` · `/stats` · `/exit`

---

## 二、本机环境（实测）

| 项 | 值 |
|---|---|
| OS | Ubuntu 24.04 LTS（`Linux … 6.8.0-…-generic x86_64`） |
| GPU | **NVIDIA GeForce RTX 5060 Ti**，16311 MiB，compute capability **12.0**，**36 SMs** |
| CUDA | **13.0.88**（`/usr/local/cuda`） |
| 编译器 | g++ **13.3.0**，CMake **3.28.3**，Ninja |
| FFmpeg | 系统包可用（`libavformat` 60.x），**未**关 media |
| Python（打包） | ComfyUI venv：`numpy` + `torch 2.13+cu130`（`pack.py` 依赖） |
| 工作目录 | `/f/ninfer-Bonsai-2-5060` |

引擎路径：`CMAKE_CUDA_ARCHITECTURES=120a`，`-DNINFER_SM120=1`，`kTargetSmCount=36`。

---

## 三、验收（5060 Ti）

| 判据 | 结果 |
|---|---|
| 编译 | ✅ 352/352 `BUILD OK` |
| `engine ready` | ✅ `qwen3.8-27b/groupwise-int`，weights **7.12 GiB**（MTP 开） |
| HTTP `/v1/models` | ✅ `{"id":"bonsai2-27b","max_model_len":32768}` |
| 制品体积 | ✅ 7.736 GiB 文件（文本 6.696 GiB） |

> 16 GB 卡上官方 `qwen3_8_27b.ninfer` / min-Q4（~15–17 GiB）会因「weights 后剩余显存 < runtime 预留 + 1 GiB headroom」起不来；**必须用三元 PQ2_0 制品**。

---

## 四、目录结构

```
ninfer-Bonsai-2-5060/          ← 本 Git 仓库（脚本与补丁）
  patches/rtx5060ti-sm120a.patch
  scripts/build.sh             编译 CraneBW 上游
  scripts/pack-ternary.sh      GGUF → .ninfer
  start-server.sh / chat.sh / run-ppl.sh / chat.py
  eval/ppl_sample.txt
  接入指南.md
  BUILDINFO.txt

/f/ninfer-Bonsai-2-5060/       ← 本机实装（不进 Git）
  repo/                        CraneBW/ninfer-ternary-bonsai-ada（已打 patch）
  packer/                      ModelScope shensanshu/ninfer-ada-ternary
  build/apps/ninfer-serve
/f/Bonsai-2-27B-PQ2_0-CRACK.gguf
/f/Bonsai-2-27B-PQ2_0-CRACK.ninfer   ★ 运行制品
  （也可从 ModelScope mengyou6688/Bonsai-2-27B-PQ2_0-CRACK-NInfer 下载）
```

---

## 五、我为 5060 Ti 做的适配

| # | 问题 | 改动 |
|---|---|---|
| 1 | `device.h` 无 `NINFER_SM120`，`120a` 编译 `#error` | 加分支，`kTargetSmCount = **36**`（5060 Ti） |
| 2 | 根 `CMakeLists.txt` 不对 `120*` 定义宏 | `MATCHES "^120"` → `NINFER_SM120=1` |
| 3 | 本机 CUDA 13.0 < 上游 13.1 门槛 | 门槛放宽为 **13.0**（仅本环境） |

Linux 有系统 FFmpeg，**不需要** `NINFER_DISABLE_MEDIA`（与 Windows 5070 仓不同）。

补丁：`patches/rtx5060ti-sm120a.patch`。

---

## 六、调参数

`start-server.sh` 顶部：

```bash
CTX=32768            # 上下文上限
MODELID=bonsai2-27b  # 客户端 model 必须一致
KVTYPE=fp8           # bf16 | fp8 | int8 | nvfp4 | k8v4
PORT=8080
DRAFT=3              # MTP；0 = 关
ARTIFACT=.../Bonsai-2-27B-PQ2_0-CRACK.ninfer
```

16 GB 账（MTP 开、权重 ~7.12 GiB）：`--kv-capacity auto` + `fp8` 下 **32768 稳**；可试 65536。更大优先 `nvfp4` 或关 MTP。

---

## 七、HTTP

Base URL：`http://127.0.0.1:8080/v1`（OpenAI） / `http://127.0.0.1:8080`（Anthropic）。

```bash
curl -s http://127.0.0.1:8080/v1/models
curl -s http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"bonsai2-27b","messages":[{"role":"user","content":"你好"}],"max_tokens":200}'
```

---

## 八、排错

| 现象 | 处理 |
|---|---|
| chat 连不上 | 先 `start-server.sh`，等 `listening` |
| `model_not_found` | `model` 写成 `bonsai2-27b` |
| 显存不足 / after weights | 降 `CTX`、关 MTP（`DRAFT=0`）、换更小 KV |
| 重编译 LNK/占用 | 先停掉正在跑的 `ninfer-serve` |
| pack `unmapped gdn` | 模板必须是 **groupwise-int**，不能用 nvfp4 |

---

## 许可

- 引擎 / 本仓脚本：沿用上游 Apache-2.0 声明。
- **权重与 `.ninfer`**：版权与许可以 PrismML / Qwen / CRACK 发布方及 [HF 页面](https://huggingface.co/nuottroisaoduoc/Bonsai-2-27B-Ternary-CRACK-GGUF) 为准；本仓不重新授权。
