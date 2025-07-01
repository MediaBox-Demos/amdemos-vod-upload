// VodDemo/src/main/ets/utils/DemoCryptoUtils.ets

import { util } from '@kit.ArkTS';
import cryptoFramework from '@ohos.security.cryptoFramework';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * Simplified cryptography utility for the Demo application.
 * Provides HMAC-SHA1 and Base64 encoding for signing the STS AssumeRole API call.
 */
export class DemoCryptoUtils {

  /**
   * Converts a string to a Uint8Array using UTF-8 encoding.
   * Uses util.TextEncoder.
   */
  private static stringToUint8Array(str: string): Uint8Array {
    return new util.TextEncoder('utf-8').encode(str);
  }

  /**
   * Calculates HMAC-SHA1 hash and returns it Base64 encoded.
   * Required for Aliyun API V1 Signatures.
   * Uses util.TextEncoder and util.Base64Helper.
   */
  static async hmacSha1(message: string, secret: string): Promise<string> {
    try {
      const mac = cryptoFramework.createMac('SHA1');
      const secretKeyBytes = DemoCryptoUtils.stringToUint8Array(secret);

      const symKeyGenerator = cryptoFramework.createSymKeyGenerator('HMAC');
      const secretKeyBlob: cryptoFramework.DataBlob = { data: secretKeyBytes };
      const symKey = await symKeyGenerator.convertKey(secretKeyBlob);

      await mac.init(symKey);

      const messageBytes = DemoCryptoUtils.stringToUint8Array(message);
      const messageDataBlob: cryptoFramework.DataBlob = { data: messageBytes };
      await mac.update(messageDataBlob);

      const resultDataBlob = await mac.doFinal();
      const rawHmacBytes = new Uint8Array(resultDataBlob.data);

      const base64Helper = new util.Base64Helper();
      return base64Helper.encodeToStringSync(rawHmacBytes);
    } catch (e) {
      const err = e as BusinessError; // Use direct cast
      const errorMessage = `HMAC-SHA1 calculation failed: ${err.message || String(err)}` + (err.code ? ` (Code: ${err.code})` : '');
      console.error(`[DemoCryptoUtils] ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * Percent-encodes a string according to RFC3986 for Aliyun V1 query parameters.
   */
  static encodeURIComponentRFC3986(str: string): string {
    let result = encodeURIComponent(str);
    result = result.replace(/[!'()*]/g, (c) => {
      return '%' + c.charCodeAt(0).toString(16).toUpperCase();
    });
    return result;
  }
}
