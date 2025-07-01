// VodDemo/src/main/ets/i18n/IAppStrings.ets

/**
 * Defines the keys for all UI strings to ensure type safety for internationalization.
 */
export interface IAppStrings {
  headerTitle: string;
  headerSubtitle: string;
  langSwitchButton: string;

  // Configuration Card
  configTitle: string;
  authModeTitle: string;
  stsMode: string;
  akMode: string;
  credentialMode: string;
  akCredentialsTitle: string;
  accessKeyId: string;
  accessKeySecret: string;

  // STS Generator
  stsTokenGenTitle: string;
  stsTokenGenDesc: string;
  stsPermanentAk: string;
  stsPermanentSk: string;
  roleArn: string;
  generateApplyStsButton: string;

  // STS Credentials
  stsCredentialsTitle: string;
  securityToken: string;
  expireTime: string;

  // Credential Generator
  credentialGenTitle: string;
  credentialGenDesc: string;
  targetOssBucket: string;
  targetOssRegion: string;
  generateVodCredsButton: string;

  // SDK Credentials
  sdkCredentialsTitle: string;
  uploadAuthBase64: string;
  uploadAddressBase64: string;

  // Upload Parameters
  uploadParamsTitle: string;
  vodRegion: string;
  partSize: string;
  enableTranscoding: string;
  storageLocation: string;
  templateGroupId: string;
  workflowId: string;
  appId: string;
  enableResumable: string;
  enableMd5: string;
  disableMultipart: string;
  pauseOnCellular: string;
  applyConfigButton: string;

  // Status & Overview
  networkStatusTitle: string;
  overviewTitle: string;
  speedLabel: string;
  remainingLabel: string;
  pleaseApplyConfigTitle: string;
  pleaseApplyConfigDesc: string;

  // File Operations
  fileOpsTitle: string;
  selectFilesButton: string;
  clearListButton: string;
  selectedFilesLabel: (count: number) => string; // Function for dynamic strings
  processingFiles: string;

  // Upload Controls
  uploadControlsTitle: string;
  startRetryAllButton: string;
  pauseAllButton: string;
  resumeAllButton: string;
  cancelAllButton: string;

  // File List
  queueTitle: string;
  ossKeyLabel: string;
  statusLabel: string;
  cancelButton: string;
  imageUrlLabel: string;
  videoIdLabel: string;
  errorLabel: string;

  // File Statuses
  statusReady: string;
  statusUploading: string;
  statusPaused: string;
  statusSuccess: string;
  statusFailed: string;
  statusCanceled: string;
}
