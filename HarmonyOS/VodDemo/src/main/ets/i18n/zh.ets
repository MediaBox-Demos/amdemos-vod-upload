// VodDemo/src/main/ets/i18n/zh.ts

import { IAppStrings } from './IAppStrings';

export const zhStrings: IAppStrings = {
  headerTitle: 'VOD 媒体上传',
  headerSubtitle: '鸿蒙移动端 SDK 演示',
  langSwitchButton: 'EN',

  // Configuration Card
  configTitle: '⚙️ 配置',
  authModeTitle: '认证模式:',
  stsMode: 'STS令牌',
  akMode: 'AK/SK',
  credentialMode: '凭证',
  akCredentialsTitle: 'AK/SK 凭证 (永久)',
  accessKeyId: 'AccessKeyId',
  accessKeySecret: 'AccessKeySecret',

  // STS Generator
  stsTokenGenTitle: 'STS令牌生成 (演示用)',
  stsTokenGenDesc: '输入永久RAM凭证和角色ARN以生成临时令牌。',
  stsPermanentAk: '永久 AccessKeyId',
  stsPermanentSk: '永久 AccessKeySecret',
  roleArn: '扮演的角色ARN',
  generateApplyStsButton: '生成并应用STS令牌',

  // STS Credentials
  stsCredentialsTitle: 'STS凭证 (SDK使用)',
  securityToken: 'SecurityToken',
  expireTime: '过期时间 (YYYY-MM-DDTHH:mm:ssZ)',

  // Credential Generator
  credentialGenTitle: '凭证生成 (演示用)',
  credentialGenDesc: '模拟应用服务器。使用STS生成`uploadAuth`和`uploadAddress`。',
  targetOssBucket: '目标OSS存储桶',
  targetOssRegion: '目标OSS区域',
  generateVodCredsButton: '生成VOD凭证',

  // SDK Credentials
  sdkCredentialsTitle: 'SDK凭证 (来自服务器或生成器)',
  uploadAuthBase64: '上传凭证 (Base64)',
  uploadAddressBase64: '上传地址 (Base64)',

  // Upload Parameters
  uploadParamsTitle: '上传参数:',
  vodRegion: 'VOD区域 (默认 cn-shanghai)',
  partSize: '分片大小 (字节, 默认 1MB)',
  enableTranscoding: '开启转码',
  storageLocation: '存储地址 (可选)',
  templateGroupId: '模板组ID (可选)',
  workflowId: '工作流ID (可选)',
  appId: '应用ID (可选)',
  enableResumable: '开启断点续传',
  enableMd5: '开启MD5校验 (用于断点续传)',
  disableMultipart: '禁用分片上传 (用于小文件)',
  pauseOnCellular: '策略: 蜂窝网络暂停',
  applyConfigButton: '✅ 应用配置并重置SDK',

  // Status & Overview
  networkStatusTitle: '🌐 网络状态: ',
  overviewTitle: '📊 上传总览',
  speedLabel: '速度: ',
  remainingLabel: '剩余时间: ',
  pleaseApplyConfigTitle: '☝️ 请应用配置',
  pleaseApplyConfigDesc: '打开配置面板, 点击 "应用配置并重置SDK" 开始。',

  // File Operations
  fileOpsTitle: '📁 文件操作',
  selectFilesButton: '选择文件',
  clearListButton: '清空列表',
  selectedFilesLabel: (count: number) => `已选择 ${count} 个文件`,
  processingFiles: '处理文件中, 请稍候...',

  // Upload Controls
  uploadControlsTitle: '🚀 上传控制',
  startRetryAllButton: '▶️ 开始/重试全部',
  pauseAllButton: '⏸️ 暂停全部',
  resumeAllButton: '⏯️ 恢复全部',
  cancelAllButton: '⏹️ 取消全部',

  // File List
  queueTitle: '📜 上传队列',
  ossKeyLabel: 'OSS路径: ',
  statusLabel: '状态: ',
  cancelButton: '取消',
  imageUrlLabel: '图片URL: ',
  videoIdLabel: '视频ID: ',
  errorLabel: '错误: ',

  // File Statuses
  statusReady: '准备就绪',
  statusUploading: '上传中',
  statusPaused: '已暂停',
  statusSuccess: '成功',
  statusFailed: '失败',
  statusCanceled: '已取消',
};
