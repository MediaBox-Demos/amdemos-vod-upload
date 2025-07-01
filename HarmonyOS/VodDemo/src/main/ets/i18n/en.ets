// VodDemo/src/main/ets/i18n/en.ts

import { IAppStrings } from './IAppStrings';

export const enStrings: IAppStrings = {
  headerTitle: 'VOD Media Upload',
  headerSubtitle: 'HarmonyOS Mobile SDK Demo',
  langSwitchButton: '中文',

  // Configuration Card
  configTitle: '⚙️ Configuration',
  authModeTitle: 'Authentication Mode:',
  stsMode: 'STS Token',
  akMode: 'AK/SK',
  credentialMode: 'Credential',
  akCredentialsTitle: 'AK/SK Credentials (Permanent)',
  accessKeyId: 'AccessKeyId',
  accessKeySecret: 'AccessKeySecret',

  // STS Generator
  stsTokenGenTitle: 'STS Token Generation (For Demo)',
  stsTokenGenDesc: 'Enter permanent RAM credentials and Role ARN to generate a temporary token.',
  stsPermanentAk: 'Permanent AccessKeyId',
  stsPermanentSk: 'Permanent AccessKeySecret',
  roleArn: 'Role ARN to Assume',
  generateApplyStsButton: 'Generate & Apply STS Token',

  // STS Credentials
  stsCredentialsTitle: 'STS Credentials (to be used by SDK)',
  securityToken: 'SecurityToken',
  expireTime: 'ExpireTime (YYYY-MM-DDTHH:mm:ssZ)',

  // Credential Generator
  credentialGenTitle: 'Credential Generation (For Demo)',
  credentialGenDesc: 'Simulates App Server. Generates `uploadAuth` and `uploadAddress` using STS.',
  targetOssBucket: 'Target OSS Bucket',
  targetOssRegion: 'Target OSS Region',
  generateVodCredsButton: 'Generate VOD Credentials',

  // SDK Credentials
  sdkCredentialsTitle: 'SDK Credentials (from server or generator)',
  uploadAuthBase64: 'UploadAuth (Base64)',
  uploadAddressBase64: 'UploadAddress (Base64)',

  // Upload Parameters
  uploadParamsTitle: 'Upload Parameters:',
  vodRegion: 'VOD Region (Default cn-shanghai)',
  partSize: 'Part Size (bytes, Default 1MB)',
  enableTranscoding: 'Enable Transcoding',
  storageLocation: 'Storage Location (Optional)',
  templateGroupId: 'Template Group ID (Optional)',
  workflowId: 'Workflow ID (Optional)',
  appId: 'AppId (Optional)',
  enableResumable: 'Enable Resumable Upload',
  enableMd5: 'Enable MD5 Check (for Resumable)',
  disableMultipart: 'Disable Multipart Upload (for small files)',
  pauseOnCellular: 'Policy: Pause on Cellular Network',
  applyConfigButton: '✅ Apply Config & Reset SDK',

  // Status & Overview
  networkStatusTitle: '🌐 Network Status: ',
  overviewTitle: '📊 Upload Overview',
  speedLabel: 'Speed: ',
  remainingLabel: 'Remaining: ',
  pleaseApplyConfigTitle: '☝️ Please Apply Configuration',
  pleaseApplyConfigDesc: 'Open the configuration panel and click "Apply Config & Reset SDK" to begin.',

  // File Operations
  fileOpsTitle: '📁 File Operations',
  selectFilesButton: 'Select Files',
  clearListButton: 'Clear List',
  selectedFilesLabel: (count: number) => `Selected ${count} files`,
  processingFiles: 'Processing files, please wait...',

  // Upload Controls
  uploadControlsTitle: '🚀 Upload Controls',
  startRetryAllButton: '▶️ Start/Retry All',
  pauseAllButton: '⏸️ Pause All',
  resumeAllButton: '⏯️ Resume All',
  cancelAllButton: '⏹️ Cancel All',

  // File List
  queueTitle: '📜 Upload Queue',
  ossKeyLabel: 'OSS Key: ',
  statusLabel: 'Status: ',
  cancelButton: 'Cancel',
  imageUrlLabel: 'Image URL: ',
  videoIdLabel: 'Video ID: ',
  errorLabel: 'Error: ',

  // File Statuses
  statusReady: 'Ready',
  statusUploading: 'Uploading',
  statusPaused: 'Paused',
  statusSuccess: 'Success',
  statusFailed: 'Failed',
  statusCanceled: 'Canceled',
};
