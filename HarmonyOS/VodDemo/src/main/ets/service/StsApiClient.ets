// VodDemo/src/main/ets/service/StsApiClient.ets

import { http } from '@kit.NetworkKit';
import { JSON } from '@kit.ArkTS';
import { DemoAliyunSigner } from '../utils/DemoAliyunSigner';
import { BusinessError } from '@kit.BasicServicesKit';

// Interface for the temporary credentials returned by STS.
interface StsCredentials {
  AccessKeyId: string;
  AccessKeySecret: string;
  SecurityToken: string;
  Expiration: string;
}
interface AssumedRoleUser {
  Arn: string;
  AssumedRoleId: string;
}
interface AssumeRoleResponse {
  Credentials: StsCredentials;
  AssumedRoleUser: AssumedRoleUser;
  RequestId: string;
}

export class StsApiClient {
  private signer: DemoAliyunSigner;
  private readonly stsEndpoint = 'https://sts.aliyuncs.com';

  constructor() {
    this.signer = new DemoAliyunSigner();
  }

  async assumeRole(
    permanentAccessKeyId: string,
    permanentAccessKeySecret: string,
    roleArn: string,
    roleSessionName: string
  ): Promise<AssumeRoleResponse> {

    const paramsForSigner: Record<string, string> = {};
    paramsForSigner['Action'] = 'AssumeRole';
    paramsForSigner['RoleArn'] = roleArn;
    paramsForSigner['RoleSessionName'] = roleSessionName;
    paramsForSigner['DurationSeconds'] = '3600';

    try {
      const signedParams = await this.signer.signStsRequest(
        permanentAccessKeyId,
        permanentAccessKeySecret,
        paramsForSigner
      );

      // Construct the URL with a correctly encoded query string.
      const queryString = this.buildQueryString(signedParams);
      const url = `${this.stsEndpoint}/?${queryString}`;

      console.info(`[StsApiClient] Calling AssumeRole with URL: ${url}`);

      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 15000
      });

      if (response.responseCode >= 200 && response.responseCode < 300) {
        const result = JSON.parse(response.result as string) as AssumeRoleResponse;
        if (result.Credentials) {
          console.info('[StsApiClient] AssumeRole successful.');
          return result;
        } else {
          const errorResponse = response.result as string;
          console.error(`[StsApiClient] AssumeRole API returned an error in a 200 OK response: ${errorResponse}`);
          throw new Error(`AssumeRole API error: ${errorResponse}`);
        }
      } else {
        console.error(`[StsApiClient] AssumeRole HTTP Error ${response.responseCode}: ${response.result}`);
        throw new Error(`HTTP Error ${response.responseCode}: ${response.result}`);
      }
    } catch (e) {
      const err = e as Error;
      let errorMessage = `Failed to assume role: ${err.message}`;
      if ((err as BusinessError).code !== undefined) {
        errorMessage += ` (Code: ${(err as BusinessError).code})`;
      }
      console.error(`[StsApiClient] ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * Builds a URL query string from a record of parameters.
   * This method ensures all keys and values are properly URL-encoded.
   * @param params The parameters to include in the query string.
   * @returns A URL-encoded query string.
   */
  private buildQueryString(params: Record<string, string>): string {
    return Object.keys(params)
      .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
      .join('&');
  }
}
