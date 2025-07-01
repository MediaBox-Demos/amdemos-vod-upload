// VodDemo/src/main/ets/pages/Index.ets

import {
  VODUploadClient,
  VODUploadClientImpl,
  VodInfo,
  UploadFileInfo,
  VodUploadResult,
  VodUploadStateType,
  VodHttpClientConfig,
  UploadStateType as SDKUploadStateType,
  VODUploadCallback,
  FileUtils
} from '@aliyun_video_cloud/vod-upload-sdk';
import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { PreferencesStorage } from '@aliyun_video_cloud/vod-upload-sdk/src/main/ets/storage/PreferencesStorage';
import { StsApiClient } from '../service/StsApiClient';
// Import i18n resources
import { IAppStrings } from '../i18n/IAppStrings';
import { enStrings } from '../i18n/en';
import { zhStrings } from '../i18n/zh';

// Demo internal file status (language-neutral keys)
enum DemoFileStatus {
  READY = 'READY',
  UPLOADING = 'UPLOADING',
  PAUSED = 'PAUSED',
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
  CANCELED = 'CANCELED'
}

// Authentication modes for the demo
enum AuthMode {
  STS = 'STS Token模式',
  AK = 'AK/SK模式',
  CREDENTIAL = '凭证模式',
}

// For simulating server responses (UploadAddress/UploadAuth)
interface MockAddressInfo {
  Endpoint: string;
  Bucket: string;
  FileName: string;
  Region?: string;
}

interface MockAuthInfo {
  AccessKeyId: string;
  AccessKeySecret: string;
  SecurityToken: string;
  Expiration: string;
  Region?: string;
}

// UI representation of a file
interface UploadFileInfoUI {
  filePath: string; // Local cache path
  originalUri?: string;
  fileName: string;
  status: DemoFileStatus;
  progress: number;
  errorMessage: string;
  videoId: string; // VOD VideoId or ImageUrl
  totalBytes: number;
  objectKey?: string; // OSS Object Key
  postUploadInstruction?: string;
}

interface SpeedSample {
  time: number;
  bytes: number;
}

// Preference Keys
const PREF_AUTH_MODE = 'pref_auth_mode';
const PREF_AK_ID = 'pref_ak_id_v2';
const PREF_AK_SECRET = 'pref_ak_secret_v2';
const PREF_STS_AK_ID = 'pref_sts_ak_id_v2';
const PREF_STS_AK_SECRET = 'pref_sts_ak_secret_v2';
const PREF_STS_TOKEN = 'pref_sts_token_v2';
const PREF_STS_EXPIRE = 'pref_sts_expire_v2';
const PREF_VOD_REGION = 'pref_vod_region';
const PREF_PART_SIZE = 'pref_part_size';
const PREF_TRANSCODE_ENABLED = 'pref_transcode_enabled';
const PREF_STORAGE_LOCATION = 'pref_storage_location';
const PREF_TEMPLATE_GROUP_ID = 'pref_template_group_id';
const PREF_WORKFLOW_ID = 'pref_workflow_id';
const PREF_APP_ID = 'pref_app_id';
const PREF_RECORD_PROGRESS = 'pref_record_progress';
const PREF_DISABLE_MULTIPART = 'pref_disable_multipart';
const PREF_PAUSE_ON_CELLULAR = 'pref_pause_on_cellular';
const PREF_MD5_CHECK_ENABLED = 'pref_md5_check_enabled';
const PREF_MOCK_AUTH = 'pref_mock_auth';
const PREF_MOCK_ADDRESS = 'pref_mock_address';
const PREF_STS_GEN_AK = 'pref_sts_gen_ak';
const PREF_STS_GEN_SK = 'pref_sts_gen_sk';
const PREF_STS_GEN_ARN = 'pref_sts_gen_arn';
const PREF_CRED_GEN_BUCKET = 'pref_cred_gen_bucket';
const PREF_CRED_GEN_REGION = 'pref_cred_gen_region';


class DemoVodUploadCallbackImpl implements VODUploadCallback {
  private demoPage: Index;

  constructor(demoPageInstance: Index) {
    this.demoPage = demoPageInstance;
  }

  onUploadStarted(uploadFileInfo: UploadFileInfo): void {
    this.demoPage.updateFileUIState(uploadFileInfo, SDKUploadStateType.UPLOADING, 0);
    this.demoPage.uploadStatusText = `Starting credential acquisition for: ${uploadFileInfo.getFileName()}`;
    this.demoPage.currentSdkStatus = this.demoPage.vodClient?.getStatus() || VodUploadStateType.INIT;
    this.demoPage.startProgressUpdateTimer();
    console.info(`[Demo] onUploadStarted: ${uploadFileInfo.getFileName()}`);

    if (this.demoPage.authMode === AuthMode.CREDENTIAL) {
      if (this.demoPage.mockServerUploadAuthBase64 && this.demoPage.mockServerUploadAddressBase64) {
        console.info(`[Demo] CREDENTIAL Mode: Setting mock UploadAuth/Address for ${uploadFileInfo.getFileName()}`);
        try {
          const base64 = new util.Base64Helper();
          const decoder = new util.StringDecoder('utf-8');
          const decodedAddrBytes = base64.decodeSync(this.demoPage.mockServerUploadAddressBase64);
          const decodedAddr = decoder.write(decodedAddrBytes) + decoder.end();
          const addrInfo: MockAddressInfo = JSON.parse(decodedAddr) as MockAddressInfo;
          this.demoPage.updateFileUIObjectKey(uploadFileInfo.getFilePath(), addrInfo.FileName);
        } catch (error) {
          const err = error as Error;
          console.error("[Demo] Error parsing mock UploadAddress for UI update:", err.message);
        }
        this.demoPage.vodClient?.setUploadAuthAndAddress(uploadFileInfo, this.demoPage.mockServerUploadAuthBase64, this.demoPage.mockServerUploadAddressBase64);
      } else {
        const errMsg = "Error: Mock server credentials (mockServerUploadAuth/Address) are empty in credential mode.";
        console.error(`[Demo] ${errMsg}`);
        this.demoPage.uploadStatusText = errMsg;
        this.demoPage.updateFileUIState(uploadFileInfo, SDKUploadStateType.FAILED, 0, errMsg);
      }
    }
  }

  onUploadSucceed(info: UploadFileInfo, result: VodUploadResult): void {
    let postUploadInstruction: string | undefined = undefined;
    if (this.demoPage.authMode === AuthMode.CREDENTIAL) {
      postUploadInstruction = `OSS OK. Server must call RegisterMedia for object: ${info.getObject()}`;
      console.info(`[Demo] Credential Mode Success for ${info.getObject()}. Instructing user about next step.`);
    }

    this.demoPage.updateFileUIState(info, SDKUploadStateType.SUCCESS, 100, undefined, result.getVideoId() || result.getImageUrl(), postUploadInstruction);
    this.demoPage.uploadStatusText = `Success: ${info.getFileName()}`;
    this.demoPage.currentSdkStatus = this.demoPage.vodClient?.getStatus() || VodUploadStateType.INIT;
    this.demoPage.checkIfAllUploadsDone();
    console.info(`[Demo] onUploadSucceed: ${info.getFileName()}, VideoId: ${result.getVideoId()}, ImageUrl: ${result.getImageUrl()}`);
  }

  onUploadFailed(info: UploadFileInfo, code: string, message: string): void {
    this.demoPage.updateFileUIState(info, SDKUploadStateType.FAILED, info.getProgressPercentage(), `${code}: ${message}`);
    this.demoPage.uploadStatusText = `Failed: ${info.getFileName()} - ${code}`;
    this.demoPage.errorMessageText = `${info.getFileName()}: ${message}`;
    this.demoPage.currentSdkStatus = this.demoPage.vodClient?.getStatus() || VodUploadStateType.INIT;
    this.demoPage.checkIfAllUploadsDone();
    console.error(`[Demo] onUploadFailed: ${info.getFileName()}, Code: ${code}, Message: ${message}`);
  }

  onUploadProgress(info: UploadFileInfo, uploadedSizeNum: number, totalSizeNum: number): void {
    const progressPercent = totalSizeNum > 0 ? (uploadedSizeNum / totalSizeNum) * 100 : 0;
    this.demoPage.updateFileUIState(info, SDKUploadStateType.UPLOADING, progressPercent);
    this.demoPage.uploadedSizeText = this.demoPage.formatBytes(this.demoPage.calculateTotalUploadedBytes());
    this.demoPage.totalSizeText = this.demoPage.formatBytes(this.demoPage.calculateTotalBytesForAllFiles());
    this.demoPage.recordSpeedSamplePoint(this.demoPage.calculateTotalUploadedBytes());
    this.demoPage.uploadStatusText = `Uploading: ${info.getFileName()} ${progressPercent.toFixed(1)}%`;
    this.demoPage.currentSdkStatus = this.demoPage.vodClient?.getStatus() || VodUploadStateType.INIT;
  }

  onUploadTokenExpired(): void {
    this.demoPage.uploadStatusText = 'Upload token expired. Please update credentials in Advanced Config, then click "Apply Config" and "Resume".';
    this.demoPage.currentSdkStatus = this.demoPage.vodClient?.getStatus() || VodUploadStateType.INIT;
    this.demoPage.isPausedOverall = true;
    this.demoPage.isUploadingOverall = false;
    console.warn("[Demo] onUploadTokenExpired. SDK should be in PAUSED state.");
  }

  onUploadRetry(code: string, message: string): void {
    this.demoPage.uploadStatusText = `VOD API call retrying: ${code} - ${message}`;
    console.warn(`[Demo] onUploadRetry (VOD API): Code: ${code}, Message: ${message}`);
  }

  onUploadRetryResume(): void {
    this.demoPage.uploadStatusText = 'VOD API retry resumed.';
    console.info("[Demo] onUploadRetryResume (VOD API).");
  }
}

@Entry
@Component
struct Index {
  @State currentStrings: IAppStrings = enStrings;
  @State currentLanguage: 'en' | 'zh' = 'en';

  @State message: string = 'Aliyun VOD HarmonyOS Upload SDK Demo';
  @State uploadProgress: number = 0;
  @State uploadStatusText: string = 'Please select files to start upload';
  @State currentSdkStatus: VodUploadStateType = VodUploadStateType.INIT;
  @State uploadFileInfosUI: Array<UploadFileInfoUI> = [];

  @State isUploadingOverall: boolean = false;
  @State isPausedOverall: boolean = false;
  @State isProcessingFiles: boolean = false;

  @State networkStatusText: string = 'Checking network...';
  @State uploadSpeedText: string = '0 B/s';
  @State remainingTimeText: string = 'Unknown';
  @State uploadedSizeText: string = '0 B';
  @State totalSizeText: string = '0 B';

  @State errorMessageText: string = '';
  @State showAdvancedConfig: boolean = false;
  @State isConfigApplied: boolean = false;

  @State authMode: AuthMode = AuthMode.CREDENTIAL;
  @State akAccessKeyIdInput: string = '';
  @State akAccessKeySecretInput: string = '';
  @State stsAccessKeyIdInput: string = '';
  @State stsAccessKeySecretInput: string = '';
  @State securityTokenInput: string = '';
  @State expireTimeInput: string = '';

  @State stsGenPermanentAkIdInput: string = '';
  @State stsGenPermanentAkSecretInput: string = '';
  @State stsGenRoleArnInput: string = '';
  @State stsGenStatusText: string = 'Enter permanent AK/SK and RoleArn to generate STS token.';
  @State isGeneratingSts: boolean = false;

  @State stsCredentialGenBucket: string = '';
  @State stsCredentialGenRegion: string = 'cn-shanghai';
  @State isGeneratingCreds: boolean = false;
  @State credGenStatusText: string = 'Enter permanent AK/SK, RoleARN, and target Bucket/Region to generate credentials.';


  @State vodRegionInput: string = 'cn-shanghai';
  @State partSizeInput: string = (1 * 1024 * 1024).toString();
  @State transcodeModeEnabled: boolean = false; // Changed from true to false
  @State storageLocationInput: string = '';
  @State templateGroupIdInput: string = '';
  @State workflowIdInput: string = '';
  @State appIdInput: string = '';
  @State recordUploadProgressEnabled: boolean = true; // Kept true
  @State md5CheckEnabled: boolean = false; // Changed from true to false
  @State disableMultipartUpload: boolean = false; // Kept false
  @State pauseOnCellularActive: boolean = false; // Kept false

  @State mockServerUploadAuthBase64: string = '';
  @State mockServerUploadAddressBase64: string = '';

  public vodClient: VODUploadClient | null = null;
  private uiAbilityContext: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private progressUpdateTimer: number | null = null;
  public speedSamplePoints: Array<SpeedSample> = [];
  private netConnectionMonitor: connection.NetConnection | null = null;
  private preferencesStorage: PreferencesStorage | null = null;
  private stsApiClient: StsApiClient | null = null;

  async aboutToAppear(): Promise<void> {
    this.preferencesStorage = new PreferencesStorage(this.uiAbilityContext);
    this.stsApiClient = new StsApiClient(); // Initialize STS client
    await this.loadConfigurations();
    this.uploadStatusText = 'Welcome! Please review and apply configuration before starting.';
    this.showAdvancedConfig = true; // Show config panel on first launch
    this.initializeNetworkMonitoring();
  }

  aboutToDisappear(): void {
    this.stopProgressUpdateTimer();
    this.cleanupNetworkMonitoring();
    this.vodClient?.release().catch((error: Error) => {
      console.error("Error releasing VOD client", error);
    });
  }

  private toggleLanguage(): void {
    if (this.currentLanguage === 'en') {
      this.currentStrings = zhStrings;
      this.currentLanguage = 'zh';
    } else {
      this.currentStrings = enStrings;
      this.currentLanguage = 'en';
    }
  }


  private async loadConfigurations(): Promise<void> {
    if (!this.preferencesStorage) return;
    try {
      this.authMode = await this.preferencesStorage.getString(PREF_AUTH_MODE, AuthMode.CREDENTIAL) as AuthMode;
      this.akAccessKeyIdInput = await this.preferencesStorage.getString(PREF_AK_ID, '');
      this.akAccessKeySecretInput = await this.preferencesStorage.getString(PREF_AK_SECRET, '');
      this.stsAccessKeyIdInput = await this.preferencesStorage.getString(PREF_STS_AK_ID, '');
      this.stsAccessKeySecretInput = await this.preferencesStorage.getString(PREF_STS_AK_SECRET, '');
      this.securityTokenInput = await this.preferencesStorage.getString(PREF_STS_TOKEN, '');
      this.expireTimeInput = await this.preferencesStorage.getString(PREF_STS_EXPIRE, '');

      this.vodRegionInput = await this.preferencesStorage.getString(PREF_VOD_REGION, 'cn-shanghai');
      this.partSizeInput = await this.preferencesStorage.getString(PREF_PART_SIZE, (1 * 1024 * 1024).toString());
      this.transcodeModeEnabled = await this.preferencesStorage.getBoolean(PREF_TRANSCODE_ENABLED, false); // Changed default
      this.storageLocationInput = await this.preferencesStorage.getString(PREF_STORAGE_LOCATION, '');
      this.templateGroupIdInput = await this.preferencesStorage.getString(PREF_TEMPLATE_GROUP_ID, '');
      this.workflowIdInput = await this.preferencesStorage.getString(PREF_WORKFLOW_ID, '');
      this.appIdInput = await this.preferencesStorage.getString(PREF_APP_ID, '');
      this.recordUploadProgressEnabled = await this.preferencesStorage.getBoolean(PREF_RECORD_PROGRESS, true);
      this.md5CheckEnabled = await this.preferencesStorage.getBoolean(PREF_MD5_CHECK_ENABLED, false); // Changed default
      this.disableMultipartUpload = await this.preferencesStorage.getBoolean(PREF_DISABLE_MULTIPART, false);
      this.pauseOnCellularActive = await this.preferencesStorage.getBoolean(PREF_PAUSE_ON_CELLULAR, false);
      this.mockServerUploadAuthBase64 = await this.preferencesStorage.getString(PREF_MOCK_AUTH, '');
      this.mockServerUploadAddressBase64 = await this.preferencesStorage.getString(PREF_MOCK_ADDRESS, '');
      this.stsGenPermanentAkIdInput = await this.preferencesStorage.getString(PREF_STS_GEN_AK, '');
      this.stsGenPermanentAkSecretInput = await this.preferencesStorage.getString(PREF_STS_GEN_SK, '');
      this.stsGenRoleArnInput = await this.preferencesStorage.getString(PREF_STS_GEN_ARN, '');
      this.stsCredentialGenBucket = await this.preferencesStorage.getString(PREF_CRED_GEN_BUCKET, '');
      this.stsCredentialGenRegion = await this.preferencesStorage.getString(PREF_CRED_GEN_REGION, 'cn-shanghai');


      console.info('[Demo] Configurations loaded from preferences.');
    } catch (error) {
      const err = error as Error;
      console.error('[Demo] Failed to load configurations:', err.message);
    }
  }

  private async saveConfigurations(): Promise<void> {
    if (!this.preferencesStorage) return;
    try {
      await this.preferencesStorage.putString(PREF_AUTH_MODE, this.authMode);
      await this.preferencesStorage.putString(PREF_AK_ID, this.akAccessKeyIdInput);
      await this.preferencesStorage.putString(PREF_AK_SECRET, this.akAccessKeySecretInput);
      await this.preferencesStorage.putString(PREF_STS_AK_ID, this.stsAccessKeyIdInput);
      await this.preferencesStorage.putString(PREF_STS_AK_SECRET, this.stsAccessKeySecretInput);
      await this.preferencesStorage.putString(PREF_STS_TOKEN, this.securityTokenInput);
      await this.preferencesStorage.putString(PREF_STS_EXPIRE, this.expireTimeInput);

      await this.preferencesStorage.putString(PREF_VOD_REGION, this.vodRegionInput);
      await this.preferencesStorage.putString(PREF_PART_SIZE, this.partSizeInput);
      await this.preferencesStorage.putBoolean(PREF_TRANSCODE_ENABLED, this.transcodeModeEnabled);
      await this.preferencesStorage.putString(PREF_STORAGE_LOCATION, this.storageLocationInput);
      await this.preferencesStorage.putString(PREF_TEMPLATE_GROUP_ID, this.templateGroupIdInput);
      await this.preferencesStorage.putString(PREF_WORKFLOW_ID, this.workflowIdInput);
      await this.preferencesStorage.putString(PREF_APP_ID, this.appIdInput);
      await this.preferencesStorage.putBoolean(PREF_RECORD_PROGRESS, this.recordUploadProgressEnabled);
      await this.preferencesStorage.putBoolean(PREF_MD5_CHECK_ENABLED, this.md5CheckEnabled);
      await this.preferencesStorage.putBoolean(PREF_DISABLE_MULTIPART, this.disableMultipartUpload);
      await this.preferencesStorage.putBoolean(PREF_PAUSE_ON_CELLULAR, this.pauseOnCellularActive);
      await this.preferencesStorage.putString(PREF_MOCK_AUTH, this.mockServerUploadAuthBase64);
      await this.preferencesStorage.putString(PREF_MOCK_ADDRESS, this.mockServerUploadAddressBase64);
      await this.preferencesStorage.putString(PREF_STS_GEN_AK, this.stsGenPermanentAkIdInput);
      await this.preferencesStorage.putString(PREF_STS_GEN_SK, this.stsGenPermanentAkSecretInput);
      await this.preferencesStorage.putString(PREF_STS_GEN_ARN, this.stsGenRoleArnInput);
      await this.preferencesStorage.putString(PREF_CRED_GEN_BUCKET, this.stsCredentialGenBucket);
      await this.preferencesStorage.putString(PREF_CRED_GEN_REGION, this.stsCredentialGenRegion);

      console.info('[Demo] Configurations saved to preferences.');
    } catch (error) {
      const err = error as Error;
      console.error('[Demo] Failed to save configurations:', err.message);
    }
  }

  private async handleGenerateStsToken(): Promise<void> {
    if (this.isGeneratingSts) {
      return;
    }
    const permanentAkId = this.stsGenPermanentAkIdInput.trim();
    const permanentAkSecret = this.stsGenPermanentAkSecretInput.trim();
    const roleArn = this.stsGenRoleArnInput.trim();

    if (!permanentAkId || !permanentAkSecret || !roleArn) {
      this.stsGenStatusText = "Error: Permanent AK/SK and Role ARN must be provided.";
      return;
    }

    this.isGeneratingSts = true;
    this.stsGenStatusText = "Generating STS Token...";

    try {
      if (!this.stsApiClient) {
        throw new Error("STS API Client not initialized.");
      }
      const response = await this.stsApiClient.assumeRole(
        permanentAkId,
        permanentAkSecret,
        roleArn,
        `vod-harmony-demo-sts-${Date.now()}`
      );

      this.stsAccessKeyIdInput = response.Credentials.AccessKeyId;
      this.stsAccessKeySecretInput = response.Credentials.AccessKeySecret;
      this.securityTokenInput = response.Credentials.SecurityToken;
      this.expireTimeInput = response.Credentials.Expiration;

      this.stsGenStatusText = `Success! Token generated, expires at ${response.Credentials.Expiration}. Applied to STS inputs.`;
      console.info('[Demo] STS Token generated and applied successfully.');

      this.showAdvancedConfig = false;
      setTimeout(() => {
        this.showAdvancedConfig = true;
      }, 50);

    } catch (error) {
      const err = error as Error;
      this.stsGenStatusText = `Error generating token: ${err.message}`;
      console.error('[Demo] STS Token generation failed:', err.message);
    } finally {
      this.isGeneratingSts = false;
    }
  }

  private async handleGenerateVodCredentials(): Promise<void> {
    if (this.isGeneratingCreds) return;

    const permanentAkId = this.stsGenPermanentAkIdInput.trim();
    const permanentAkSecret = this.stsGenPermanentAkSecretInput.trim();
    const roleArn = this.stsGenRoleArnInput.trim();
    const bucket = this.stsCredentialGenBucket.trim();
    const region = this.stsCredentialGenRegion.trim();

    if (!permanentAkId || !permanentAkSecret || !roleArn || !bucket || !region) {
      this.credGenStatusText = "Error: All fields (AK/SK, ARN, Bucket, Region) are required.";
      return;
    }

    this.isGeneratingCreds = true;
    this.credGenStatusText = "Generating credentials...";

    try {
      if (!this.stsApiClient) {
        throw new Error("STS API Client not initialized.");
      }
      const stsResponse = await this.stsApiClient.assumeRole(
        permanentAkId, permanentAkSecret, roleArn, `vod-harmony-credential-gen-${Date.now()}`
      );

      const mockAuth: MockAuthInfo = {
        AccessKeyId: stsResponse.Credentials.AccessKeyId,
        AccessKeySecret: stsResponse.Credentials.AccessKeySecret,
        SecurityToken: stsResponse.Credentials.SecurityToken,
        Expiration: stsResponse.Credentials.Expiration,
        Region: region
      };

      const uniqueFileSuffix = `${Date.now()}_${Math.random().toString(16).substring(2, 8)}`;
      const mockAddress: MockAddressInfo = {
        Endpoint: `oss-${region}.aliyuncs.com`,
        Bucket: bucket,
        FileName: `demo/credential-mode/upload-${uniqueFileSuffix}.mp4`
      };

      const base64 = new util.Base64Helper();
      const textEncoder = new util.TextEncoder();
      const authString = JSON.stringify(mockAuth);
      const addressString = JSON.stringify(mockAddress);

      this.mockServerUploadAuthBase64 = base64.encodeToStringSync(textEncoder.encode(authString));
      this.mockServerUploadAddressBase64 = base64.encodeToStringSync(textEncoder.encode(addressString));

      this.credGenStatusText = "Success! Credentials generated and applied.";
      console.info('[Demo] VOD credentials for Credential Mode generated and applied successfully.');

      this.showAdvancedConfig = false;
      setTimeout(() => {
        this.showAdvancedConfig = true;
      }, 50);

    } catch (e) {
      const err = e as Error;
      this.credGenStatusText = `Error generating credentials: ${err.message}`;
      console.error('[Demo] VOD credential generation failed:', err.message);
    } finally {
      this.isGeneratingCreds = false;
    }
  }


  private async initializeSDK(): Promise<void> {
    if (!this.vodClient) {
      this.vodClient = new VODUploadClientImpl(this.uiAbilityContext);
    }
    this.applyConfigurationsToSDK();

    const vodUploadCb = this.createVodUploadCallback();

    try {
      switch (this.authMode) {
        case AuthMode.CREDENTIAL:
          await this.vodClient.init(vodUploadCb);
          this.uploadStatusText = "Credential mode initialized. Waiting for operation.";
          break;
        case AuthMode.AK:
          if (!this.akAccessKeyIdInput || !this.akAccessKeySecretInput) {
            this.uploadStatusText = "Error: AccessKeyId and Secret cannot be empty in AK mode.";
            console.error(this.uploadStatusText);
            this.isConfigApplied = false; // Mark config as invalid
            return;
          }
          await this.vodClient.init(this.akAccessKeyIdInput, this.akAccessKeySecretInput, vodUploadCb);
          this.uploadStatusText = "AK/SK mode initialized.";
          break;
        case AuthMode.STS:
          if (!this.stsAccessKeyIdInput || !this.stsAccessKeySecretInput || !this.securityTokenInput || !this.expireTimeInput) {
            this.uploadStatusText = "Error: All credential fields must be non-empty in STS mode.";
            console.error(this.uploadStatusText);
            this.isConfigApplied = false; // Mark config as invalid
            return;
          }
          await this.vodClient.init(this.stsAccessKeyIdInput, this.stsAccessKeySecretInput, this.securityTokenInput, this.expireTimeInput, vodUploadCb);
          this.uploadStatusText = "STS mode initialized.";
          break;
      }
      this.currentSdkStatus = this.vodClient.getStatus();
      console.info(`[Demo] VOD Client initialized in ${this.authMode}. SDK Status: ${this.currentSdkStatus}`);
    } catch (error) {
      const err = error as Error;
      this.uploadStatusText = `SDK initialization failed: ${err.message}`;
      console.error("[Demo] SDK Initialization error: ", err);
      this.isConfigApplied = false; // Mark config as invalid on error
    }
  }

  private applyConfigurationsToSDK(): void {
    if (!this.vodClient) return;
    this.vodClient.setRegion(this.vodRegionInput);
    const partSizeBytes = parseInt(this.partSizeInput);
    if (!isNaN(partSizeBytes) && partSizeBytes > 0) {
      this.vodClient.setPartSize(partSizeBytes);
    } else {
      this.vodClient.setPartSize(1 * 1024 * 1024);
    }
    this.vodClient.setTranscodeMode(this.transcodeModeEnabled);
    if (this.storageLocationInput) this.vodClient.setStorageLocation(this.storageLocationInput);
    if (this.templateGroupIdInput) this.vodClient.setTemplateGroupId(this.templateGroupIdInput);
    if (this.workflowIdInput) this.vodClient.setWorkflowId(this.workflowIdInput);
    if (this.appIdInput) this.vodClient.setAppId(this.appIdInput);
    this.vodClient.setRecordUploadProgressEnabled(this.recordUploadProgressEnabled);
    this.vodClient.setMd5CheckEnabled(this.md5CheckEnabled);
    this.vodClient.setDisableMultiPart(this.disableMultipartUpload);
    this.vodClient.setPauseOnCellular(this.pauseOnCellularActive);

    const httpCfg = new VodHttpClientConfig();
    this.vodClient.setVodHttpClientConfig(httpCfg);
    console.info("[Demo] SDK configurations applied from UI.");
  }

  private createVodUploadCallback(): VODUploadCallback {
    return new DemoVodUploadCallbackImpl(this);
  }

  public checkIfAllUploadsDone(): void {
    if (this.vodClient?.listFiles().every(f =>
    f.getStatus() === SDKUploadStateType.SUCCESS ||
      f.getStatus() === SDKUploadStateType.FAILED ||
      f.getStatus() === SDKUploadStateType.CANCELED
    )) {
      this.isUploadingOverall = false;
      this.isPausedOverall = false;
      this.stopProgressUpdateTimer();
      this.uploadStatusText = "All tasks processed.";
    }
  }

  public updateFileUIState(fileInfoFromSDK: UploadFileInfo, sdkStatus: SDKUploadStateType, progress: number, errorMsg?: string, videoIdUrl?: string, postUploadInstruction?: string): void {
    const index = this.uploadFileInfosUI.findIndex(f => f.filePath === fileInfoFromSDK.getFilePath());
    if (index !== -1) {
      let demoStatus: DemoFileStatus;
      switch (sdkStatus) {
        case SDKUploadStateType.READY:
          demoStatus = DemoFileStatus.READY;
          break;
        case SDKUploadStateType.UPLOADING:
          demoStatus = DemoFileStatus.UPLOADING;
          break;
        case SDKUploadStateType.PAUSED:
          demoStatus = DemoFileStatus.PAUSED;
          break;
        case SDKUploadStateType.SUCCESS:
          demoStatus = DemoFileStatus.SUCCESS;
          break;
        case SDKUploadStateType.FAILED:
          demoStatus = DemoFileStatus.FAILED;
          break;
        case SDKUploadStateType.CANCELED:
          demoStatus = DemoFileStatus.CANCELED;
          break;
        default:
          demoStatus = DemoFileStatus.READY;
      }
      this.uploadFileInfosUI[index].status = demoStatus;
      this.uploadFileInfosUI[index].progress = progress;
      this.uploadFileInfosUI[index].errorMessage = errorMsg || '';
      this.uploadFileInfosUI[index].videoId = videoIdUrl || this.uploadFileInfosUI[index].videoId || '';
      this.uploadFileInfosUI[index].postUploadInstruction = postUploadInstruction || '';
      this.uploadFileInfosUI[index].objectKey = fileInfoFromSDK.getObject() || this.uploadFileInfosUI[index].objectKey;
      this.uploadFileInfosUI[index].totalBytes = fileInfoFromSDK.getFileSize();
      this.uploadFileInfosUI = [...this.uploadFileInfosUI]; // Trigger UI update
    }
    this.updateOverallProgressUI();
  }


  public updateFileUIObjectKey(filePath: string, objectKey: string): void {
    const index = this.uploadFileInfosUI.findIndex(f => f.filePath === filePath);
    if (index !== -1) {
      this.uploadFileInfosUI[index].objectKey = objectKey;
      this.uploadFileInfosUI = [...this.uploadFileInfosUI];
    }
  }

  public calculateTotalUploadedBytes(): number {
    return this.uploadFileInfosUI.reduce((acc, curr) => {
      const fileTotal = curr.totalBytes || 0;
      return acc + (fileTotal * (curr.progress / 100));
    }, 0);
  }

  public calculateTotalBytesForAllFiles(): number {
    return this.uploadFileInfosUI.reduce((acc, curr) => acc + (curr.totalBytes || 0), 0);
  }

  public recordSpeedSamplePoint(currentTotalUploadedBytes: number): void {
    const now = Date.now();
    this.speedSamplePoints.push({ time: now, bytes: currentTotalUploadedBytes });
    if (this.speedSamplePoints.length > 20) {
      this.speedSamplePoints.shift();
    }
  }

  private calculateUploadSpeedAndRemainingTime(): void {
    if (!this.speedSamplePoints || this.speedSamplePoints.length < 2) {
      this.uploadSpeedText = '0 B/s';
      this.remainingTimeText = 'Unknown';
      return;
    }

    const samplesToUse = this.speedSamplePoints.slice(-10);
    const latestSample = samplesToUse[samplesToUse.length - 1];
    const earliestSample = samplesToUse[0];

    const timeDifferenceSeconds = (latestSample.time - earliestSample.time) / 1000;
    const bytesDifference = latestSample.bytes - earliestSample.bytes;

    if (timeDifferenceSeconds > 0.1) {
      const speed = bytesDifference / timeDifferenceSeconds;
      this.uploadSpeedText = this.formatSpeed(speed);

      const totalBytesOverall = this.calculateTotalBytesForAllFiles();
      const uploadedBytesOverall = this.calculateTotalUploadedBytes();
      const remainingBytesOverall = totalBytesOverall - uploadedBytesOverall;

      if (speed > 0 && remainingBytesOverall > 0) {
        const remainingSeconds = remainingBytesOverall / speed;
        this.remainingTimeText = this.formatDuration(remainingSeconds);
      } else if (remainingBytesOverall <= 0 && totalBytesOverall > 0) {
        this.remainingTimeText = 'Completed';
      } else {
        this.remainingTimeText = 'Unknown';
      }
    } else if (this.isUploadingOverall) {
      this.uploadSpeedText = 'Calculating...';
      this.remainingTimeText = 'Unknown';
    } else {
      this.uploadSpeedText = '0 B/s';
      this.remainingTimeText = this.uploadFileInfosUI.length > 0 && !this.uploadFileInfosUI.every(f => f.status === DemoFileStatus.SUCCESS) ? 'Unknown' : 'Completed';
    }
  }


  public startProgressUpdateTimer(): void {
    if (this.progressUpdateTimer === null) {
      this.speedSamplePoints = [];
      this.progressUpdateTimer = setInterval(() => {
        this.calculateUploadSpeedAndRemainingTime();
      }, 1000);
    }
  }

  private stopProgressUpdateTimer(): void {
    if (this.progressUpdateTimer !== null) {
      clearInterval(this.progressUpdateTimer);
      this.progressUpdateTimer = null;
      this.uploadSpeedText = '0 B/s';
    }
  }

  public formatBytes(bytes: number, decimals: number = 2): string {
    if (bytes < 0) return '0 B';
    if (bytes === 0 && this.uploadFileInfosUI.length === 0) return '0 B';
    if (bytes === 0 && this.uploadFileInfosUI.length > 0 && !this.isUploadingOverall && !this.isPausedOverall) return '0 B';
    if (bytes === 0 && (this.isUploadingOverall || this.isPausedOverall)) return 'Calculating...';

    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    const unitIndex = Math.min(i, sizes.length - 1);

    return parseFloat((bytes / Math.pow(k, unitIndex)).toFixed(dm)) + ' ' + sizes[unitIndex];
  }


  private formatSpeed(bytesPerSecond: number): string {
    if (bytesPerSecond < 0) return '0 B/s';
    return this.formatBytes(bytesPerSecond) + '/s';
  }

  private formatDuration(seconds: number): string {
    if (seconds < 0 || !isFinite(seconds)) return 'Unknown';
    if (seconds === 0 && this.uploadProgress < 100 && this.isUploadingOverall) return 'Calculating...';
    if (seconds === 0 && (this.uploadProgress >= 100 || !this.isUploadingOverall)) return 'Completed';


    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.ceil(seconds % 60);
    let timeStr = "";
    if (h > 0) timeStr += `${h}h`;
    if (m > 0 || h > 0) timeStr += `${m}m`;
    timeStr += `${s}s`;
    return timeStr;
  }


  private async selectFilesFromPicker(): Promise<void> {
    this.isProcessingFiles = true;
    try {
      const docPicker = new picker.DocumentViewPicker();
      const selectOptions: picker.DocumentSelectOptions = {
        maxSelectNumber: 10,
      };
      const resultsUriStrings = await docPicker.select(selectOptions);

      if (resultsUriStrings && resultsUriStrings.length > 0) {
        this.uploadStatusText = `Selected ${resultsUriStrings.length} files, preparing...`;
        this.errorMessageText = '';

        for (const originalFileUri of resultsUriStrings) {
          const originalFileName: string = FileUtils.getFileName(originalFileUri);
          console.info(`[Demo] Preparing ${originalFileUri}: ${originalFileName}`);
          const tempFileName = `${Date.now()}_${Math.random().toString(36).substring(2, 8)}_${originalFileName}`;
          const cacheDirectory = this.uiAbilityContext.cacheDir;
          const localTempFilePath = `${cacheDirectory}/${tempFileName}`;

          try {
            await FileUtils.copyUriToFile(this.uiAbilityContext, originalFileUri, localTempFilePath);
            let fileSize = 0;
            try {
              fileSize = await FileUtils.getFileSize(localTempFilePath);
            } catch (error) {
              const err = error as Error;
              console.error(`[Demo] Failed to get local file size for ${localTempFilePath}: ${err.message}`);
            }

            const newFileUI: UploadFileInfoUI = {
              filePath: localTempFilePath,
              originalUri: originalFileUri,
              fileName: originalFileName,
              status: DemoFileStatus.READY,
              progress: 0,
              errorMessage: '',
              videoId: '',
              totalBytes: fileSize,
              objectKey: ''
            };
            this.uploadFileInfosUI.push(newFileUI);

            const vodInformation = new VodInfo();
            vodInformation.setTitle(originalFileName);
            vodInformation.setFileName(originalFileName);
            this.vodClient?.addFile(localTempFilePath, vodInformation);
            this.uploadStatusText = `File ${originalFileName} prepared.`;

          } catch (copyError) {
            const err = copyError as BusinessError;
            const errorDetail = `Failed to copy file ${originalFileName} to cache: ${err.message} (Code: ${err.code})`;
            console.error(`[Demo] ${errorDetail}`);
            this.uploadFileInfosUI.push({
              filePath: localTempFilePath,
              originalUri: originalFileUri,
              fileName: originalFileName,
              status: DemoFileStatus.FAILED,
              progress: 0,
              errorMessage: errorDetail,
              videoId: '',
              totalBytes: 0,
              objectKey: ''
            });
          }
        }
        this.uploadFileInfosUI = [...this.uploadFileInfosUI];
        this.totalSizeText = this.formatBytes(this.calculateTotalBytesForAllFiles());
        if (resultsUriStrings.length > 0) {
          this.uploadStatusText = `Added ${resultsUriStrings.length} files to queue.`;
        }
      } else {
        this.uploadStatusText = "No files selected.";
      }
    } catch (e) {
      const err = e as BusinessError;
      this.uploadStatusText = 'File selection failed.';
      this.errorMessageText = `Code: ${err.code}, Message: ${err.message}`;
      console.error("[Demo] File selection error: ", JSON.stringify(err));
    } finally {
      this.isProcessingFiles = false;
    }
  }

  private updateOverallProgressUI(): void {
    if (this.uploadFileInfosUI.length === 0) {
      this.uploadProgress = 0;
      return;
    }
    let totalUploaded = 0;
    let totalSizeForProgressCalc = 0;
    this.uploadFileInfosUI.forEach(file => {
      if (file.totalBytes > 0) {
        totalUploaded += (file.progress / 100) * file.totalBytes;
        totalSizeForProgressCalc += file.totalBytes;
      }
    });
    this.uploadProgress = totalSizeForProgressCalc > 0 ? (totalUploaded / totalSizeForProgressCalc) * 100 : 0;
  }


  private handleStartUpload(): void {
    if (!this.vodClient) {
      this.uploadStatusText = 'SDK not initialized. Please apply config first.';
      return;
    }
    const filesToUpload = this.uploadFileInfosUI.filter(f =>
    f.status === DemoFileStatus.READY ||
      f.status === DemoFileStatus.FAILED ||
      f.status === DemoFileStatus.CANCELED ||
      f.status === DemoFileStatus.PAUSED
    );

    if (filesToUpload.length === 0) {
      if (this.uploadFileInfosUI.length > 0 && this.uploadFileInfosUI.every(f => f.status === DemoFileStatus.SUCCESS)) {
        this.uploadStatusText = 'All files have been successfully uploaded.';
      } else if (this.uploadFileInfosUI.length > 0 && this.uploadFileInfosUI.some(f => f.status === DemoFileStatus.UPLOADING)) {
        this.uploadStatusText = 'Some files are already uploading.';
      } else {
        this.uploadStatusText = 'No files to upload or resume.';
      }
      return;
    }

    this.applyConfigurationsToSDK();
    this.vodClient.start();
    this.isUploadingOverall = true;
    this.isPausedOverall = false;
    this.uploadStatusText = 'Starting upload queue...';
    this.errorMessageText = '';
    this.currentSdkStatus = this.vodClient.getStatus();
    this.startProgressUpdateTimer();
  }

  private handlePauseUpload(): void {
    if (this.vodClient && (this.isUploadingOverall || this.vodClient.getStatus() === VodUploadStateType.STARTED) && !this.isPausedOverall) {
      this.vodClient.pause();
      this.isPausedOverall = true;
      this.isUploadingOverall = false;
      this.uploadStatusText = 'Upload queue paused.';
      this.currentSdkStatus = this.vodClient.getStatus();
      this.stopProgressUpdateTimer();
    }
  }

  private handleResumeUpload(): void {
    if (this.vodClient && this.isPausedOverall) {
      if (this.currentSdkStatus === VodUploadStateType.PAUSED && this.uploadStatusText.includes("Upload token expired")) {
        this.uploadStatusText = "Error: Token expired. Please update credentials in Advanced Config, click 'Apply Config' and then 'Resume'.";
        return;
      }
      this.applyConfigurationsToSDK();
      this.vodClient.resume();
      this.isPausedOverall = false;
      this.isUploadingOverall = true;
      this.uploadStatusText = 'Upload queue resumed.';
      this.currentSdkStatus = this.vodClient.getStatus();
      this.startProgressUpdateTimer();
    }
  }

  private async handleCancelAllUploads(): Promise<void> {
    if (this.vodClient) {
      const files = this.vodClient.listFiles();
      // Use Promise.all to wait for all async cancel operations
      const cancelPromises = files.map((file, index) => {
        const sdkFileStatus = file.getStatus();
        if (sdkFileStatus === SDKUploadStateType.READY ||
          sdkFileStatus === SDKUploadStateType.UPLOADING ||
          sdkFileStatus === SDKUploadStateType.PAUSED) {
          return this.vodClient!.cancelFile(index);
        }
        return Promise.resolve(); // Return a resolved promise for files not being cancelled
      });

      await Promise.all(cancelPromises);

      this.uploadStatusText = 'All active uploads cancelled.';
      this.isUploadingOverall = false;
      this.isPausedOverall = false;
      this.stopProgressUpdateTimer();
      this.currentSdkStatus = this.vodClient.getStatus();
    }
  }


  private async handleClearFiles(): Promise<void> {
    if (this.vodClient) {
      await this.vodClient.clearFiles();
    }
    // Asynchronously delete all cached files
    const deletionPromises = this.uploadFileInfosUI.map(async (fileUiInfo) => {
      if (fileUiInfo.filePath && fileUiInfo.filePath.startsWith(this.uiAbilityContext.cacheDir)) {
        try {
          await FileUtils.deleteFile(fileUiInfo.filePath);
          console.info(`[Demo] Deleted cached file: ${fileUiInfo.filePath}`);
        } catch (error) {
          const err = error as Error;
          console.warn(`[Demo] Failed to delete cached file: ${fileUiInfo.filePath}, Error: ${err.message}`);
        }
      }
    });

    await Promise.all(deletionPromises);


    this.uploadFileInfosUI = [];
    this.uploadStatusText = 'File list cleared.';
    this.uploadProgress = 0;
    this.errorMessageText = '';
    this.isUploadingOverall = false;
    this.isPausedOverall = false;
    this.currentSdkStatus = this.vodClient?.getStatus() || VodUploadStateType.INIT;
    this.totalSizeText = "0 B";
    this.uploadedSizeText = "0 B";
    this.remainingTimeText = "Unknown";
    this.uploadSpeedText = "0 B/s";
    this.stopProgressUpdateTimer();
  }


  private getStatusTextForFileUI(status: DemoFileStatus): string {
    switch (status) {
      case DemoFileStatus.READY:
        return this.currentStrings.statusReady;
      case DemoFileStatus.UPLOADING:
        return this.currentStrings.statusUploading;
      case DemoFileStatus.PAUSED:
        return this.currentStrings.statusPaused;
      case DemoFileStatus.SUCCESS:
        return this.currentStrings.statusSuccess;
      case DemoFileStatus.FAILED:
        return this.currentStrings.statusFailed;
      case DemoFileStatus.CANCELED:
        return this.currentStrings.statusCanceled;
      default:
        return status;
    }
  }

  private getStatusColorForFileUI(status: DemoFileStatus): Color {
    switch (status) {
      case DemoFileStatus.READY:
        return Color.Gray;
      case DemoFileStatus.UPLOADING:
        return Color.Blue;
      case DemoFileStatus.PAUSED:
        return Color.Orange;
      case DemoFileStatus.SUCCESS:
        return Color.Green;
      case DemoFileStatus.FAILED:
        return Color.Red;
      case DemoFileStatus.CANCELED:
        return Color.Brown;
      default:
        return Color.Black;
    }
  }

  private async initializeNetworkMonitoring(): Promise<void> {
    try {
      if (!this.netConnectionMonitor) {
        this.netConnectionMonitor = connection.createNetConnection();
      }
      await new Promise<void>((resolve, reject) => {
        if (!this.netConnectionMonitor) {
          reject(new Error("NetConnectionMonitor is null after creation"));
          return;
        }
        this.netConnectionMonitor.register((error: BusinessError) => {
          if (error && error.code) {
            console.error('[Demo] Failed to register network listener:', JSON.stringify(error));
            this.networkStatusText = "Network listener registration failed.";
            reject(error);
            return;
          }
          console.info('[Demo] Network listener registered successfully.');
          resolve();
        });
      });

      if (!this.netConnectionMonitor) return;

      this.netConnectionMonitor.on('netAvailable', (netHandle: connection.NetHandle) => {
        this.updateNetworkStatusText(netHandle, true);
      });
      this.netConnectionMonitor.on('netUnavailable', () => {
        this.networkStatusText = 'Network disconnected.';
      });
      this.netConnectionMonitor.on('netLost', (netHandle: connection.NetHandle) => {
        this.networkStatusText = `Specific network lost (ID: ${netHandle.netId}).`;
      });
      this.netConnectionMonitor.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
        if (data && data.netCap) {
          this.updateNetworkStatusText(data.netHandle, true);
        }
      });

      const currentNetHandle = await connection.getDefaultNet();
      this.updateNetworkStatusText(currentNetHandle, !!currentNetHandle && currentNetHandle.netId !== 0);

    } catch (e) {
      const err = e as BusinessError;
      this.networkStatusText = 'Network status unknown (initialization failed).';
      console.error('[Demo] Network monitoring initialization failed:', JSON.stringify(err));
    }
  }

  private async updateNetworkStatusText(netHandle: connection.NetHandle | null, isAvailable: boolean): Promise<void> {
    if (!isAvailable || !netHandle || netHandle.netId === 0) {
      this.networkStatusText = 'Network unavailable.';
      return;
    }
    try {
      const netCapabilities = await connection.getNetCapabilities(netHandle);
      if (netCapabilities) {
        if (netCapabilities.bearerTypes?.includes(connection.NetBearType.BEARER_WIFI)) {
          this.networkStatusText = 'Network: WiFi';
        } else if (netCapabilities.bearerTypes?.includes(connection.NetBearType.BEARER_CELLULAR)) {
          this.networkStatusText = 'Network: Cellular Data';
        } else if (netCapabilities.bearerTypes?.includes(connection.NetBearType.BEARER_ETHERNET)) {
          this.networkStatusText = 'Network: Ethernet';
        } else {
          this.networkStatusText = 'Network connected (type unknown).';
        }
      } else {
        this.networkStatusText = 'Network capabilities acquisition failed.';
      }
    } catch (e) {
      const err = e as BusinessError;
      console.error('[Demo] Failed to get network capabilities:', JSON.stringify(err));
      this.networkStatusText = 'Network status unknown (failed to get capabilities).';
    }
  }

  private cleanupNetworkMonitoring(): void {
    if (this.netConnectionMonitor) {
      this.netConnectionMonitor.unregister((error: BusinessError) => {
        if (error && error.code) {
          console.error('[Demo] Failed to unregister network listener:', JSON.stringify(error));
        } else {
          console.info('[Demo] Network listener unregistered successfully.');
        }
      });
      this.netConnectionMonitor = null;
    }
  }

  build() {
    Column() {
      this.buildHeader();

      Scroll() {
        Column({ space: 16 }) {
          this.buildNetworkStatusCard();
          this.buildConfigCard();
          this.buildOverallStatusCard();

          if (!this.isConfigApplied) {
            Column() {
              Text(this.currentStrings.pleaseApplyConfigTitle)
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.Orange)
                .margin({ bottom: 5 })
              Text(this.currentStrings.pleaseApplyConfigDesc)
                .fontSize(12).fontColor(Color.Gray).textAlign(TextAlign.Center)
            }.padding(15).backgroundColor('#FFF8E1').borderRadius(12).width('100%')
          }

          this.buildFileOperationCard();
          if (this.isProcessingFiles) {
            this.buildProcessingIndicator();
          }
          this.buildUploadControlCard();
          this.buildFileListCard();
        }
        .padding({ left: 16, right: 16, top: 32, bottom: 128 })
      }
      .backgroundColor('#F0F2F5')
      .width('100%')
      .height('100%')
    }
    .backgroundColor('#FFFFFF')
    .width('100%')
    .height('100%')
  }

  @Builder
  buildHeader() {
    Row() {
      Column() {
        Text(this.currentStrings.headerTitle)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        Text(this.currentStrings.headerSubtitle)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row({ space: 8 }) {
        Button(this.currentStrings.langSwitchButton)
          .onClick(() => this.toggleLanguage())
          .height(48)
          .fontSize(14)
          .borderRadius(24)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .padding({ left: 16, right: 16 })

        Button() {
          Image($r('app.media.ic_settings'))
            .width(24)
            .height(24)
            .fillColor(this.showAdvancedConfig ? '#007AFF' : '#666666')
        }
        .width(48)
        .height(48)
        .backgroundColor(this.showAdvancedConfig ? '#E3F2FD' : '#F5F5F5')
        .borderRadius(24)
        .onClick(() => {
          this.showAdvancedConfig = !this.showAdvancedConfig;
        })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  buildInputField(label: string, value: string, onChange: (value: string) => void, isPassword: boolean = false, inputType: InputType = InputType.Normal, maxLines: number = 1, placeholder: string = '', enabled: boolean = true) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(enabled ? '#333333' : '#BDBDBD') // Dim text when disabled
        .alignSelf(ItemAlign.Start)

      TextInput({
        placeholder: placeholder,
        text: value
      })
        .type(inputType)
        .height(maxLines === 1 ? 36 : (20 * maxLines + 16))
        .fontSize(12)
        .backgroundColor(enabled ? '#F8F9FA' : '#EEEEEE') // Change background when disabled
        .borderRadius(8)
        .border({ width: 1, color: '#E5E5E5' })
        .focusOnTouch(true)
        .enableKeyboardOnFocus(false)
        .onChange(onChange)
        .maxLines(maxLines)
        .enabled(enabled) // Apply the enabled state
    }
    .width('100%')
    .opacity(enabled ? 1.0 : 0.6) // Make the whole component look disabled
  }

  @Builder
  buildConfigCard() {
    if (this.showAdvancedConfig) {
      Column({ space: 12 }) {
        Text(this.currentStrings.configTitle).fontSize(16).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start)

        Text(this.currentStrings.authModeTitle).fontSize(13).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start)
        Flex({ justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
          ForEach([AuthMode.STS, AuthMode.AK, AuthMode.CREDENTIAL], (modeItem: AuthMode) => {
            Button(modeItem === AuthMode.STS ? this.currentStrings.stsMode : (modeItem === AuthMode.AK ? this.currentStrings.akMode : this.currentStrings.credentialMode))
              .type(ButtonType.Capsule)
              .backgroundColor(this.authMode === modeItem ? Color.Blue : Color.Gray)
              .fontColor(Color.White).fontSize(11).padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .onClick(() => {
                this.authMode = modeItem;
              })
              .margin({ right: 5 })
          })
        }.width('100%').margin({ bottom: 10 })

        if (this.authMode === AuthMode.AK) {
          Text(this.currentStrings.akCredentialsTitle).fontSize(14).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start).margin({ top: 10 })
          this.buildInputField(this.currentStrings.accessKeyId, this.akAccessKeyIdInput, (val) => this.akAccessKeyIdInput = val)
          this.buildInputField(this.currentStrings.accessKeySecret, this.akAccessKeySecretInput, (val) => this.akAccessKeySecretInput = val, true)
        }

        if (this.authMode === AuthMode.STS) {
          Column({ space: 10 }) {
            Text(this.currentStrings.stsTokenGenTitle).fontSize(14).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start).margin({ top: 15 })
            Text(this.currentStrings.stsTokenGenDesc).fontSize(11).fontColor(Color.Gray).alignSelf(ItemAlign.Start)
            this.buildInputField(this.currentStrings.stsPermanentAk, this.stsGenPermanentAkIdInput, (val) => this.stsGenPermanentAkIdInput = val)
            this.buildInputField(this.currentStrings.stsPermanentSk, this.stsGenPermanentAkSecretInput, (val) => this.stsGenPermanentAkSecretInput = val, true)
            this.buildInputField(this.currentStrings.roleArn, this.stsGenRoleArnInput, (val) => this.stsGenRoleArnInput = val)
            Button(this.currentStrings.generateApplyStsButton)
              .onClick(() => this.handleGenerateStsToken())
              .enabled(!this.isGeneratingSts)
              .backgroundColor(this.isGeneratingSts ? Color.Gray : '#2196F3')
              .margin({ top: 5 })
            Text(this.stsGenStatusText).fontSize(11).fontColor(this.stsGenStatusText.startsWith('Error') ? Color.Red : Color.Green).margin({ top: 5 })
          }.padding(10).border({ width: 1, color: '#E0E0E0', radius: 8 }).width('100%')

          Text(this.currentStrings.stsCredentialsTitle).fontSize(14).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start).margin({ top: 15 })
          this.buildInputField(this.currentStrings.accessKeyId, this.stsAccessKeyIdInput, (val) => this.stsAccessKeyIdInput = val)
          this.buildInputField(this.currentStrings.accessKeySecret, this.stsAccessKeySecretInput, (val) => this.stsAccessKeySecretInput = val, true)
          this.buildInputField(this.currentStrings.securityToken, this.securityTokenInput, (val) => this.securityTokenInput = val, true, InputType.Normal, 3)
          this.buildInputField(this.currentStrings.expireTime, this.expireTimeInput, (val) => this.expireTimeInput = val)
        }

        if (this.authMode === AuthMode.CREDENTIAL) {
          Column({ space: 10 }) {
            Text(this.currentStrings.credentialGenTitle).fontSize(14).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start).margin({ top: 15 })
            Text(this.currentStrings.credentialGenDesc).fontSize(11).fontColor(Color.Gray).alignSelf(ItemAlign.Start)
            this.buildInputField(this.currentStrings.stsPermanentAk, this.stsGenPermanentAkIdInput, (val) => this.stsGenPermanentAkIdInput = val)
            this.buildInputField(this.currentStrings.stsPermanentSk, this.stsGenPermanentAkSecretInput, (val) => this.stsGenPermanentAkSecretInput = val, true)
            this.buildInputField(this.currentStrings.roleArn, this.stsGenRoleArnInput, (val) => this.stsGenRoleArnInput = val)
            this.buildInputField(this.currentStrings.targetOssBucket, this.stsCredentialGenBucket, (val) => this.stsCredentialGenBucket = val)
            this.buildInputField(this.currentStrings.targetOssRegion, this.stsCredentialGenRegion, (val) => this.stsCredentialGenRegion = val)
            Button(this.currentStrings.generateVodCredsButton)
              .onClick(() => this.handleGenerateVodCredentials())
              .enabled(!this.isGeneratingCreds)
              .backgroundColor(this.isGeneratingCreds ? Color.Gray : '#2196F3')
              .margin({ top: 5 })
            Text(this.credGenStatusText).fontSize(11).fontColor(this.credGenStatusText.startsWith('Error') ? Color.Red : Color.Green).margin({ top: 5 })
          }.padding(10).border({ width: 1, color: '#E0E0E0', radius: 8 }).width('100%')

          Text(this.currentStrings.sdkCredentialsTitle).fontSize(14).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start).margin({ top: 15 })
          this.buildInputField(this.currentStrings.uploadAuthBase64, this.mockServerUploadAuthBase64, (value: string) => this.mockServerUploadAuthBase64 = value, false, InputType.Normal, 2)
          this.buildInputField(this.currentStrings.uploadAddressBase64, this.mockServerUploadAddressBase64, (value: string) => this.mockServerUploadAddressBase64 = value, false, InputType.Normal, 2)
        }

        Text(this.currentStrings.uploadParamsTitle).fontSize(13).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start).margin({ top: 10 })
        this.buildInputField(this.currentStrings.vodRegion, this.vodRegionInput, (value: string) => this.vodRegionInput = value || 'cn-shanghai')
        this.buildInputField(this.currentStrings.partSize, this.partSizeInput, (value: string) => this.partSizeInput = value, false, InputType.Number)

        Row({ space: 5 }) {
          Toggle({ type: ToggleType.Switch, isOn: this.transcodeModeEnabled }).onChange(val => {
            this.transcodeModeEnabled = val;
            this.showAdvancedConfig = false;
            setTimeout(() => {
              this.showAdvancedConfig = true;
            }, 50);
          }).selectedColor(Color.Blue).height(20)
          Text(this.currentStrings.enableTranscoding).fontSize(12)
        }.margin({ top: 5 })

        // Apply dependency logic here
        this.buildInputField(this.currentStrings.templateGroupId, this.templateGroupIdInput, (value: string) => this.templateGroupIdInput = value, false, InputType.Normal, 1, '', this.transcodeModeEnabled)
        this.buildInputField(this.currentStrings.workflowId, this.workflowIdInput, (value: string) => this.workflowIdInput = value, false, InputType.Normal, 1, '', this.transcodeModeEnabled)

        // These are not dependent on transcoding
        this.buildInputField(this.currentStrings.storageLocation, this.storageLocationInput, (value: string) => this.storageLocationInput = value)
        this.buildInputField(this.currentStrings.appId, this.appIdInput, (value: string) => this.appIdInput = value)


        Row({ space: 5 }) {
          Toggle({ type: ToggleType.Switch, isOn: this.recordUploadProgressEnabled }).onChange(val => {
            this.recordUploadProgressEnabled = val;
            this.vodClient?.setRecordUploadProgressEnabled(val);
          }).selectedColor(Color.Blue).height(20)
          Text(this.currentStrings.enableResumable).fontSize(12)
        }.margin({ top: 5 })

        Row({ space: 5 }) {
          Toggle({ type: ToggleType.Switch, isOn: this.md5CheckEnabled })
            .onChange(val => {
              this.md5CheckEnabled = val;
              this.vodClient?.setMd5CheckEnabled(val);
            })
            .enabled(this.recordUploadProgressEnabled)
            .selectedColor(Color.Blue).height(20)
          Text(this.currentStrings.enableMd5)
            .fontColor(this.recordUploadProgressEnabled ? '#000000' : '#CCCCCC').fontSize(12)
        }.margin({ top: 5 })

        Row({ space: 5 }) {
          Toggle({ type: ToggleType.Switch, isOn: this.disableMultipartUpload }).onChange(val => {
            this.disableMultipartUpload = val;
            this.vodClient?.setDisableMultiPart(val);
          }).selectedColor(Color.Blue).height(20)
          Text(this.currentStrings.disableMultipart).fontSize(12)
        }.margin({ top: 5 })

        Row({ space: 5 }) {
          Toggle({ type: ToggleType.Switch, isOn: this.pauseOnCellularActive })
            .onChange(val => {
              this.pauseOnCellularActive = val;
              this.vodClient?.setPauseOnCellular(val);
            })
            .selectedColor(Color.Blue).height(20)
          Text(this.currentStrings.pauseOnCellular).fontSize(12)
        }.margin({ top: 5 })

        Button(this.currentStrings.applyConfigButton)
          .onClick(async () => {
            await this.saveConfigurations();
            this.isConfigApplied = true;
            this.showAdvancedConfig = false;
            this.initializeSDK();
            this.uploadStatusText = "Configuration applied and saved, SDK reset.";
          })
          .margin({ top: 15 }).type(ButtonType.Capsule).backgroundColor(Color.Blue).fontColor(Color.White)
          .height(36).width('100%')

      }.padding(15).backgroundColor(Color.White).borderRadius(12).shadow({ color: '#E0E0E0', radius: 6, offsetY: 2 }).width('100%')
    }
  }

  @Builder
  buildNetworkStatusCard() {
    Column() {
      Text(this.currentStrings.networkStatusTitle + this.networkStatusText)
        .fontSize(14)
        .fontColor(this.networkStatusText.includes('unavailable') || this.networkStatusText.includes('disconnected') ? Color.Red : Color.Green)
    }
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ color: '#E0E0E0', radius: 6, offsetY: 2 })
    .width('100%')
  }

  @Builder
  buildOverallStatusCard() {
    Column({ space: 8 }) {
      Text(this.currentStrings.overviewTitle).fontSize(16).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start)
      Text(this.uploadStatusText).fontSize(13).fontColor(Color.Gray).alignSelf(ItemAlign.Start)
      // MODIFICATION: Removed maxLines and textOverflow
      if (this.errorMessageText) {
        Text('❗ ' + this.errorMessageText).fontSize(12).fontColor(Color.Red).alignSelf(ItemAlign.Start)
        // MODIFICATION: Removed maxLines and textOverflow
      }
      if (this.uploadFileInfosUI.length > 0) {
        Progress({ value: this.uploadProgress, total: 100, type: ProgressType.Linear })
          .width('100%').height(8).color(Color.Blue)
        Row({ space: 5 }) {
          Text(`${this.uploadProgress.toFixed(1)}%`).fontSize(12).fontWeight(FontWeight.Medium)
          Text(`(${this.uploadedSizeText} / ${this.totalSizeText})`).fontSize(12).fontColor(Color.Gray)
          Blank()
          Text(this.currentStrings.speedLabel + this.uploadSpeedText).fontSize(12).fontColor(Color.Gray)
          Text(this.currentStrings.remainingLabel + this.remainingTimeText).fontSize(12).fontColor(Color.Gray)
        }.width('100%')
      }
    }
    .padding(15).backgroundColor(Color.White).borderRadius(12).shadow({ color: '#E0E0E0', radius: 6, offsetY: 2 }).width('100%')
  }

  @Builder
  buildFileOperationCard() {
    Column({ space: 10 }) {
      Text(this.currentStrings.fileOpsTitle).fontSize(16).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start)
      Row({ space: 10 }) {
        Button(this.currentStrings.selectFilesButton)
          .onClick(() => this.selectFilesFromPicker())
          .enabled(this.isConfigApplied && !this.isUploadingOverall && !this.isPausedOverall && !this.isProcessingFiles)
          .type(ButtonType.Capsule).backgroundColor('#4CAF50').fontColor(Color.White)
          .height(36).layoutWeight(1)
        Button(this.currentStrings.clearListButton)
          .onClick(async () => await this.handleClearFiles())
          .type(ButtonType.Capsule).backgroundColor('#FF9800').fontColor(Color.White)
          .height(36).layoutWeight(1)
      }.width('100%')
      if (this.uploadFileInfosUI.length > 0) {
        Text(this.currentStrings.selectedFilesLabel(this.uploadFileInfosUI.length)).fontSize(12).fontColor(Color.Blue)
          .margin({ top: 5 }).alignSelf(ItemAlign.Start)
      }
    }
    .padding(15).backgroundColor(Color.White).borderRadius(12).shadow({ color: '#E0E0E0', radius: 6, offsetY: 2 }).width('100%')
  }

  @Builder
  buildProcessingIndicator() {
    Column() {
      Progress({ value: 0, total: 100, type: ProgressType.Capsule })
        .width(40).height(40)
      Text(this.currentStrings.processingFiles)
        .fontSize(14).fontColor(Color.Gray).margin({ top: 8 })
    }
    .padding(15).backgroundColor(Color.White).borderRadius(12).shadow({ color: '#E0E0E0', radius: 6, offsetY: 2 }).width('100%')
  }

  @Builder
  buildUploadControlCard() {
    Column({ space: 10 }) {
      Text(this.currentStrings.uploadControlsTitle).fontSize(16).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start)
      GridRow({ columns: 2, gutter: { x: 10, y: 10 } }) {
        GridCol() {
          Button(this.currentStrings.startRetryAllButton)
            .onClick(() => this.handleStartUpload())
            .enabled(this.isConfigApplied && this.uploadFileInfosUI.some(f => f.status !== DemoFileStatus.SUCCESS) && !this.isUploadingOverall)
            .type(ButtonType.Normal).backgroundColor(Color.Green).fontColor(Color.White)
            .width('100%').height(40)
        }
        GridCol() {
          Button(this.currentStrings.pauseAllButton)
            .onClick(() => this.handlePauseUpload())
            .enabled(this.isConfigApplied && this.isUploadingOverall && !this.isPausedOverall)
            .type(ButtonType.Normal).backgroundColor(Color.Orange).fontColor(Color.White)
            .width('100%').height(40)
        }
        GridCol() {
          Button(this.currentStrings.resumeAllButton)
            .onClick(() => this.handleResumeUpload())
            .enabled(this.isConfigApplied && this.isPausedOverall)
            .type(ButtonType.Normal).backgroundColor(Color.Blue).fontColor(Color.White)
            .width('100%').height(40)
        }
        GridCol() {
          Button(this.currentStrings.cancelAllButton)
            .onClick(async () => await this.handleCancelAllUploads())
            .enabled(this.isConfigApplied && (this.isUploadingOverall || this.isPausedOverall || this.uploadFileInfosUI.some(f => [DemoFileStatus.UPLOADING, DemoFileStatus.PAUSED, DemoFileStatus.READY].includes(f.status))))
            .type(ButtonType.Normal).backgroundColor(Color.Red).fontColor(Color.White)
            .width('100%').height(40)
        }
      }.width('100%')
    }
    .padding(15).backgroundColor(Color.White).borderRadius(12).shadow({ color: '#E0E0E0', radius: 6, offsetY: 2 }).width('100%')
  }

  @Builder
  buildFileListCard() {
    if (this.uploadFileInfosUI.length > 0) {
      Column({ space: 10 }) {
        Text(this.currentStrings.queueTitle).fontSize(16).fontWeight(FontWeight.Medium).alignSelf(ItemAlign.Start)
        List({ space: 10 }) {
          ForEach(this.uploadFileInfosUI, (item: UploadFileInfoUI, index: number) => {
            ListItem() {
              Column({ space: 6 }) {
                Row() {
                  Text(item.fileName).fontSize(14).fontWeight(FontWeight.Medium)
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
                  Text(this.formatBytes(item.totalBytes)).fontSize(11).fontColor(Color.Gray).margin({ left: 8 })
                }
                if (item.objectKey) {
                  Text(this.currentStrings.ossKeyLabel + item.objectKey).fontSize(10).fontColor(Color.Gray)
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                Row() {
                  Text(this.currentStrings.statusLabel + this.getStatusTextForFileUI(item.status))
                    .fontSize(12).fontColor(this.getStatusColorForFileUI(item.status))
                  if (item.status === DemoFileStatus.UPLOADING || item.status === DemoFileStatus.PAUSED) {
                    Text(`- ${item.progress.toFixed(1)}%`).fontSize(12).margin({ left: 5 })
                  }
                  Blank()
                  if ([DemoFileStatus.UPLOADING, DemoFileStatus.PAUSED, DemoFileStatus.READY].includes(item.status)) {
                    Button(this.currentStrings.cancelButton)
                      .onClick(async () => await this.vodClient?.cancelFile(index))
                      .type(ButtonType.Capsule).backgroundColor(Color.Orange).fontColor(Color.White)
                      .height(24).fontSize(10).padding({ left: 8, right: 8 }).margin({right: 5})
                  }
                  Button() {
                    Image($r('app.media.ic_delete')).width(16).height(16).fillColor('#FF3B30')
                  }
                  .onClick(async () => {
                    await this.vodClient?.deleteFile(index);
                    this.uploadFileInfosUI.splice(index, 1);
                    this.uploadFileInfosUI = [...this.uploadFileInfosUI];
                    if(this.uploadFileInfosUI.length === 0){
                      this.handleClearFiles();
                    }
                  })
                  .type(ButtonType.Circle).backgroundColor('#FFE5E5')
                  .width(24).height(24)

                }
                if (item.status === DemoFileStatus.UPLOADING || item.status === DemoFileStatus.PAUSED || item.status === DemoFileStatus.FAILED) {
                  Progress({ value: item.progress, total: 100 }).width('100%').height(5)
                    .color(this.getStatusColorForFileUI(item.status === DemoFileStatus.FAILED ? DemoFileStatus.FAILED : DemoFileStatus.UPLOADING))
                }
                if (item.videoId) {
                  Text(item.videoId.startsWith('http') ? this.currentStrings.imageUrlLabel + item.videoId : this.currentStrings.videoIdLabel + item.videoId)
                    .fontSize(11).fontColor(Color.Green)
                    // MODIFICATION: Removed maxLines and textOverflow
                    .onClick(() => {
                      console.info("Item Clicked: " + item.videoId)
                    })
                } else if (item.postUploadInstruction) {
                  Text('💡 ' + item.postUploadInstruction).fontSize(11).fontColor('#007AFF').margin({ top: 4 })
                  // MODIFICATION: Removed maxLines and textOverflow
                }
                if (item.errorMessage) {
                  Text(this.currentStrings.errorLabel + item.errorMessage).fontSize(11).fontColor(Color.Red)
                  // MODIFICATION: Removed maxLines and textOverflow
                }
              }
              .padding(12).backgroundColor('#FAFAFA').borderRadius(8).border({ width: 1, color: '#EEEEEE' }).width('100%')
            }
          })
        }.width('100%')
      }
      .padding(15).backgroundColor(Color.White).borderRadius(12).shadow({ color: '#E0E0E0', radius: 6, offsetY: 2 }).width('100%')
      .margin({ bottom: 20 })
    }
  }
}
