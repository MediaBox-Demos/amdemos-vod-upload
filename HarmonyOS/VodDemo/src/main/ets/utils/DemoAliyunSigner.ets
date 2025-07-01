// VodDemo/src/main/ets/utils/DemoAliyunSigner.ets

import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { DemoCryptoUtils } from './DemoCryptoUtils';

/**
 * A simplified signer for demo purposes to create signed requests for Aliyun STS.
 * IMPORTANT: This is a basic implementation for demonstration. For production,
 * always use the official SDKs which handle edge cases and security more robustly.
 */
export class DemoAliyunSigner {

  /**
   * Signs the parameters for an STS AssumeRole request.
   * @param accessKeyId The permanent AccessKey ID.
   * @param accessKeySecret The permanent AccessKey Secret.
   * @param paramsToSign The specific parameters for the API action (e.g., RoleArn).
   * @returns A promise that resolves to the full set of signed parameters.
   */
  async signStsRequest(
    accessKeyId: string,
    accessKeySecret: string,
    paramsToSign: Record<string, string>
  ): Promise<Record<string, string>> {
    const allParams: Record<string, string> = {};

    // FIX: Replace Object.assign with a manual loop for ArkTS compatibility.
    const paramKeys = Object.keys(paramsToSign);
    for (let i = 0; i < paramKeys.length; i++) {
      const key = paramKeys[i];
      allParams[key] = paramsToSign[key];
    }

    // 1. Add common public request parameters
    allParams['Format'] = 'JSON';
    allParams['Version'] = '2015-04-01'; // STS API Version
    allParams['AccessKeyId'] = accessKeyId;
    allParams['SignatureMethod'] = 'HMAC-SHA1';
    allParams['Timestamp'] = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
    allParams['SignatureVersion'] = '1.0';
    allParams['SignatureNonce'] = this.generateNonce();

    // 2. Sort parameters by key alphabetically
    const sortedKeys = Object.keys(allParams).sort();

    // 3. Construct the canonicalized query string
    let canonicalizedQueryString = '';
    for (let i = 0; i < sortedKeys.length; i++) {
      const key = sortedKeys[i];
      const value = allParams[key];
      // Encode key and value according to RFC3986
      const encodedKey = this.encode(key);
      const encodedValue = this.encode(value);
      canonicalizedQueryString += `${encodedKey}=${encodedValue}`;
      if (i < sortedKeys.length - 1) {
        canonicalizedQueryString += '&';
      }
    }

    // 4. Construct the string-to-sign
    // The canonicalizedQueryString is NOT encoded as a whole, which was the primary bug.
    const stringToSign = `GET&${this.encode('/')}&${this.percentEncode(canonicalizedQueryString)}`;

    // 5. Calculate the signature
    try {
      const signature = await DemoCryptoUtils.hmacSha1(stringToSign, accessKeySecret + '&');
      allParams['Signature'] = signature;
      return allParams;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`[DemoAliyunSigner] Signature calculation failed: ${err.message}`);
      throw Error("${err}");
    }
  }

  /**
   * Percent-encodes a string according to Aliyun's requirements (RFC3986).
   */
  private encode(str: string): string {
    if (str === null || str === undefined || str === '') {
      return '';
    }
    let res = encodeURIComponent(str);
    // encodeURIComponent does not encode these characters, but Aliyun requires them to be.
    res = res.replace(/\!/g, '%21');
    res = res.replace(/\'/g, '%27');
    res = res.replace(/\(/g, '%28');
    res = res.replace(/\)/g, '%29');
    res = res.replace(/\*/g, '%2A');
    return res;
  }

  /**
   * Percent-encodes a string according to Aliyun's requirements for the query string part.
   * This is a more robust version compared to the simple encode.
   * @param str The string to encode.
   * @returns The encoded string.
   */
  public percentEncode(str: string): string {
    let result = encodeURIComponent(str);
    result = result.replace(/\+/g, '%20');
    result = result.replace(/\*/g, '%2A');
    result = result.replace(/%7E/g, '~');
    return result;
  }

  /**
   * Generates a unique nonce for each request.
   */
  private generateNonce(): string {
    return Math.random().toString(36).substring(2) + Date.now().toString(36);
  }
}
