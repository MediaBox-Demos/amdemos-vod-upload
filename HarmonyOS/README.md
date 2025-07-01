# Alibaba Cloud VOD Upload SDK - HarmonyOS Demo Application

[**English**](#english) | [**中文**](#中文)

---

## 中文

### 项目概览

本项目是**阿里云视频点播（VOD）鸿蒙上传 SDK** 的官方演示应用（Demo）。它旨在提供一个功能完整、交互式的示例，帮助开发者快速理解和集成 VOD 上传 SDK。

通过这个 Demo，您可以：
*   **直观体验所有核心功能：** 无需编写一行代码，即可测试不同的认证方式、文件管理、上传控制和高级配置。
*   **学习 SDK 的最佳实践：** 查看 Demo 源码，了解如何在真实应用中初始化 SDK、处理回调以及管理上传生命周期。
*   **快速调试和验证：** 使用您自己的阿里云凭证和配置，快速验证上传流程，为您的项目集成铺平道路。

**重要提示：** 这个应用是一个**演示工具**，而非 SDK 本身。要将上传功能集成到您的应用中，请参考[主 SDK 的 README 文档](https://ohpm.openharmony.cn/#/cn/detail/@aliyun_video_cloud%2fvod-upload-sdk)。

### 演示功能

本 Demo 全面展示了 VOD 上传 SDK 的强大功能，包括：

*   **多认证模式切换：**
    *   **凭证模式 (Credential)：** 在 UI 中模拟应用服务器，生成临时的 `UploadAuth` 和 `UploadAddress`。
    *   **AK/SK 模式：** 直接输入您的永久 AccessKey 进行认证。
    *   **STS Token 模式：** 输入临时 STS 令牌进行安全认证，并可通过 Demo 内置的生成器快速生成（仅用于测试）。

*   **完整的上传控制：**
    *   通过 “▶️ 开始/重试全部”、“⏸️ 暂停全部”、“⏯️ 恢复全部” 和 “⏹️ 取消全部” 按钮，对整个上传队列进行宏观控制。
    *   对队列中的单个文件，可以独立进行“取消”或“删除”操作。

*   **实时状态监控：**
    *   **全局状态栏：** 显示总体上传进度、实时速度、剩余时间以及已上传/总大小。
    *   **文件列表：** 每个文件都清晰地展示其当前状态（准备就绪、上传中、暂停、成功、失败、已取消）、上传进度条、最终的 `VideoId` 或 `ImageUrl`，以及详细的错误信息。

*   **高级配置面板：**
    *   一个可展开的配置面板，允许您动态调整 SDK 的各项参数，如：
        *   分片大小 (`PartSize`)
        *   是否开启转码 (`TranscodeMode`)
        *   VOD 区域 (`Region`)
        *   工作流、模板组和存储位置
        *   断点续传与 MD5 校验的开关
        *   小文件强制简单上传 (`DisableMultipart`)

*   **智能网络感知：**
    *   UI 顶部实时显示当前网络状态（WiFi, 蜂窝数据, 无网络）。
    *   当开启“蜂窝网络暂停”策略时，SDK 会在网络切换到蜂窝数据时自动暂停上传，并在 Demo 界面上反映出来。

*   **后台上传支持：**
    *   Demo 已配置 `dataTransfer` 后台模式，确保当应用退至后台时，正在进行的上传任务可以继续，符合鸿蒙系统的后台运行规范。

### 环境要求

*   **HarmonyOS API 等级：** API 12 或更高版本。
*   **DevEco Studio：** Version 5.0.3.900 或更高版本。
*   **HarmonyOS 设备：** HarmonyOS NEXT 5.0.0.102 或更高版本，具备音视频能力并能连接互联网。
*   **阿里云账号：** 已开通阿里云点播服务的阿里云账号。

### 如何运行

1.  **克隆仓库**
    ```bash
    git clone <本仓库地址>
    ```

2.  **在 DevEco Studio 中打开项目**
    启动 DevEco Studio，选择 `File > Open...`，然后选择本README所在根目录。

3.  **配置签名**
    在运行应用前，您需要配置自己的调试签名。
    *   打开 `build-profile.json5` 文件。
    *   找到 `signingConfigs` 部分。
    *   将其中的 `certpath`, `profile`, `storeFile` 等路径替换为您自己的签名文件路径。
    *   关于如何创建和配置签名，请参考[鸿蒙官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)。

4.  **构建并运行**
    *   在 DevEco Studio 顶部的构建目标下拉菜单中，选择 `VodDemo`。
    *   点击 `Run` 按钮或使用快捷键 `Shift+F10`，将应用安装并运行到连接的真机或模拟器上。

### 界面与功能指南

![Demo UI Screenshot][ScreenShotZh]




Demo 应用的界面分为几个核心区域，旨在提供清晰的交互流程：

1.  **配置面板 (⚙️ 配置)**
    *   这是您开始使用的第一站。点击右上角的设置图标可以展开或收起此面板。
    *   **认证模式：** 首先选择您想测试的认证模式。
        *   如果您选择 **凭证模式**，可以使用“凭证生成”部分来模拟服务器行为。
        *   如果您选择 **AK/SK** 或 **STS**，请确保填写正确的凭证信息。
    *   **上传参数：** 根据您的测试需求调整分片大小、转码等设置。
    *   **应用配置：** 点击 `✅ 应用配置并重置SDK` 按钮。此操作会保存您的配置，并使用这些新配置重新初始化 SDK。**这是开始上传前的必需步骤。**

2.  **状态总览 (📊 上传总览)**
    *   此区域提供整个上传队列的宏观视图，包括总进度条、实时速度和预计剩余时间。
    *   `上传状态文本`会显示 SDK 当前的总体状态或最近的操作信息。
    *   `错误信息文本`会显示最近一次发生的严重错误。

3.  **文件操作 (📁 文件操作)**
    *   **选择文件：** 点击此按钮会打开系统文件选择器，让您选择要上传的视频、音频或图片。
    *   **清空列表：** 从队列和 UI 中移除所有文件，并取消所有正在进行的上传。

4.  **上传控制 (🚀 上传控制)**
    *   这些按钮用于控制整个上传队列。它们只有在“应用配置”后且队列中有文件时才可用。
    *   **开始/重试全部：** 启动所有处于“准备就绪”、“已暂停”、“失败”或“已取消”状态的文件。
    *   **暂停/恢复/取消：** 对所有活跃的上传任务执行相应的操作。

5.  **上传队列 (📜 上传队列)**
    *   这里列出了所有已添加的文件。
    *   每个文件卡片都显示了文件名、大小、**状态**（带有颜色标识）、进度条以及操作按钮。
    *   上传成功后，这里会显示返回的 `VideoId` 或 `ImageUrl`。
    *   如果上传失败，会显示具体的错误码和错误信息。

---

## English

### Project Overview

This project is the official **Demo Application** for the **Alibaba Cloud VOD Upload SDK for HarmonyOS**. It is designed to provide a fully functional, interactive example to help developers quickly understand and integrate the VOD Upload SDK.

With this demo, you can:
*   **Visually experience all core features:** Test different authentication methods, file management, upload controls, and advanced configurations without writing a single line of code.
*   **Learn SDK best practices:** Examine the demo's source code to see how to initialize the SDK, handle callbacks, and manage the upload lifecycle in a real application.
*   **Quickly debug and validate:** Use your own Alibaba Cloud credentials and configurations to rapidly validate the upload flow, paving the way for your project's integration.

**Important:** This application is a **demonstration tool**, not the SDK library itself. To integrate the upload functionality into your own application, please refer to the [main SDK README documentation](https://ohpm.openharmony.cn/#/en/detail/@aliyun_video_cloud%2fvod-upload-sdk).

### Features Demonstrated

This demo comprehensively showcases the powerful features of the VOD Upload SDK, including:

*   **Multiple Authentication Modes:**
    *   **Credential Mode:** Simulate an app server by generating temporary `UploadAuth` and `UploadAddress` directly within the UI.
    *   **AK/SK Mode:** Directly input your permanent AccessKey for authentication.
    *   **STS Token Mode:** Input temporary STS tokens for secure authentication, with a built-in generator for quick testing.

*   **Complete Upload Control:**
    *   Control the entire upload queue with master buttons: "▶️ Start/Retry All," "⏸️ Pause All," "⏯️ Resume All," and "⏹️ Cancel All."
    *   Perform "Cancel" or "Delete" operations on individual files within the queue.

*   **Real-time Status Monitoring:**
    *   **Global Status Bar:** Displays overall upload progress, real-time speed, estimated time remaining, and uploaded/total size.
    *   **File List:** Each file clearly shows its current status (Ready, Uploading, Paused, Success, Failed, Canceled), a progress bar, the final `VideoId` or `ImageUrl`, and detailed error messages.

*   **Advanced Configuration Panel:**
    *   An expandable configuration panel allows you to dynamically adjust various SDK parameters, such as:
        *   Part Size
        *   Transcoding enabled/disabled
        *   VOD Region
        *   Workflow, Template Group, and Storage Location
        *   Toggles for Resumable Upload and MD5 Check
        *   Forcing simple PUT (`DisableMultipart`)

*   **Intelligent Network Awareness:**
    *   The UI displays the current network status (WiFi, Cellular, None) in real-time.
    *   When the "Pause on Cellular" policy is enabled, the SDK automatically pauses uploads when switching to a cellular network, and this is reflected in the demo UI.

*   **Background Upload Support:**
    *   The demo is configured with the `dataTransfer` background mode, ensuring that ongoing uploads can reliably continue when the app is moved to the background, adhering to HarmonyOS system guidelines.

### Environment Requirements

*   **HarmonyOS API Level:** API 12 or higher.
*   **DevEco Studio:** Version 5.0.3.900 or later.
*   **HarmonyOS Device:** A HarmonyOS NEXT 5.0.0.102 or higher device with audio/video capabilities and internet connectivity.
*   **Alibaba Cloud Account:** An Alibaba Cloud account with the VOD service enabled.

### How to Run

1.  **Clone the Repository**
    ```bash
    git clone <this_repo_address>
    ```

2.  **Open in DevEco Studio**
    Launch DevEco Studio, select `File > Open...`, and choose the root directory where this README.md in.

3.  **Configure Signing**
    Before running the app, you must configure your own debug signature.
    *   Open the `build-profile.json5` file.
    *   Locate the `signingConfigs` section.
    *   Replace the paths for `certpath`, `profile`, `storeFile`, etc., with the paths to your own signing files.
    *   For information on creating and configuring signatures, refer to the [official HarmonyOS documentation](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ide-signing).

4.  **Build and Run**
    *   In the build targets dropdown menu at the top of DevEco Studio, select `VodDemo`.
    *   Click the `Run` button or use the shortcut `Shift+F10` to install and run the application on a connected device or emulator.

### UI and Functionality Guide


The demo application's UI is divided into several core sections to provide a clear and interactive workflow:

1.  **Configuration Panel (⚙️ Configuration)**
    *   This is your starting point. Click the settings icon in the top-right corner to expand or collapse this panel.
    *   **Authentication Mode:** First, select the authentication mode you want to test.
        *   If you choose **Credential Mode**, you can use the "Credential Generation" section to simulate server behavior.
        *   If you choose **AK/SK** or **STS**, ensure you fill in the correct credentials.
    *   **Upload Parameters:** Adjust settings like part size, transcoding, etc., to match your testing needs.
    *   **Apply Config:** Click the `✅ Apply Config & Reset SDK` button. This action saves your configuration and re-initializes the SDK with these new settings. **This is a mandatory step before starting any upload.**

2.  **Status Overview (📊 Upload Overview)**
    *   This section provides a macro view of the entire upload queue, including a total progress bar, real-time speed, and estimated time remaining.
    *   The `Upload Status Text` displays the SDK's current overall state or recent operation info.
    *   The `Error Message Text` will show the last critical error that occurred.

3.  **File Operations (📁 File Operations)**
    *   **Select Files:** Clicking this opens the system's file picker, allowing you to choose videos, audio, or images to upload.
    *   **Clear List:** Removes all files from the queue and the UI, canceling any active uploads.

4.  **Upload Controls (🚀 Upload Controls)**
    *   These buttons control the entire upload queue and are enabled only after applying a configuration and adding files.
    *   **Start/Retry All:** Begins uploading all files that are in "Ready," "Paused," "Failed," or "Canceled" state.
    *   **Pause/Resume/Cancel:** Performs the respective action on all currently active upload tasks.

5.  **Upload Queue (📜 Upload Queue)**
    *   This is where all added files are listed.
    *   Each file card shows its name, size, **status** (with a color indicator), progress bar, and action buttons.
    *   Upon successful upload, the returned `VideoId` or `ImageUrl` will be displayed here.
    *   If an upload fails, the specific error code and message will be shown.

---

感谢使用阿里云VOD上传SDK for HarmonyOS！

Thank you for using Alibaba Cloud VOD Upload SDK for HarmonyOS！


[ScreenShotZh]: data:image/webp;base64,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

