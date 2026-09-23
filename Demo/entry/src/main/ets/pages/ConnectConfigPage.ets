import {
  ZolozFacade, ZolozRequest, ZolozBizConfig, ZolozResponse, ZLZResponseCode,
} from "zolozkit"
import { http } from '@kit.NetworkKit';
import { promptAction } from '@kit.ArkUI';

export interface HttpHeaders {
  'Content-Type': string;
}

export interface ResultInfo {
  resultStatus: 'S' | 'F'; // Success or Fail
  resultCode: string;
  resultMessage: string;
}

export interface InitializeResponse {
  result: ResultInfo;
  clientCfg: string;
  transactionId: string;
  rsaPubKey: string;
}

interface InitializeRequestBody {
  metaInfo: string;
  userId?: string;
  serviceLevel?: string;
}

interface FaceCaptureCheckRequest {
  transactionId: string;
  isReturnImage: boolean;
}

interface ConnectEnrollRequest {
  userId: string;
  base64ImageContent: string;
}

interface FaceCaptureExtInfo {
  imageContent?: string;
}

interface FaceCaptureCheckResponse {
  result?: ResultInfo;
  extInfo?: FaceCaptureExtInfo;
}

@Entry
@Component
export struct ConnectConfigPage {
  // Enroll = facecapture flow (capture) + connect enroll API (register reference image);
  // Verify = connect initialize + SDK 1:1 compare. Two backends are involved.
  @State fcHostValue: string = "http://30.96.105.20:8081";
  @State connectHostValue: string = "http://30.96.105.20:8080";
  // Connect requires a real userId which has enrolled a face
  @State userId: string = "test_user_1";
  // Blink by default (the only option for enroll)
  @State serviceLevel: string = "CONNECT0002";
  // Fixed API paths of the example controllers (no form fields)
  private readonly fcInitApiPath: string = "/api/facecapture/initialize";
  private readonly fcCheckApiPath: string = "/api/facecapture/checkresult";
  private readonly connectEnrollApiPath: string = "/webapi/connectDemoService/enroll";
  private readonly connectInitApiPath: string = "/webapi/connectDemoService/initialize";

  /**
   * Enroll step 3: register the captured face (from facecapture checkresult)
   * as the reference image of userId via the connect enroll API.
   */
  private enrollFaceImage(faceImageBase64: string): Promise<boolean> {
    const httpRequest = http.createHttp();
    const url = `${this.connectHostValue}${this.connectEnrollApiPath}`;
    return new Promise<boolean>((resolve) => {
      httpRequest.request(
        url,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' } as HttpHeaders,
          extraData: JSON.stringify({
            userId: this.userId,
            base64ImageContent: faceImageBase64
          } as ConnectEnrollRequest)
        },
        (err, data) => {
          if (err) {
            console.error('[Connect] enroll HTTP failed', err);
            resolve(false);
            return;
          }
          console.info(`[Connect] enroll response: ${data.result}`);
          try {
            const response: InitializeResponse = JSON.parse(data.result as string);
            resolve(response.result?.resultStatus === 'S');
          } catch (e) {
            resolve(false);
          }
        }
      );
    });
  }

  /**
   * Enroll step 2: fetch the captured face image from the facecapture transaction
   * (checkresult with isReturnImage=true, image in extInfo.imageContent).
   */
  private fetchCapturedFace(transactionId: string): Promise<string> {
    const httpRequest = http.createHttp();
    const url = `${this.fcHostValue}${this.fcCheckApiPath}`;
    return new Promise<string>((resolve) => {
      httpRequest.request(
        url,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' } as HttpHeaders,
          extraData: JSON.stringify({
            transactionId: transactionId,
            isReturnImage: true
          } as FaceCaptureCheckRequest)
        },
        (err, data) => {
          if (err) {
            console.error('[Connect] facecapture checkresult HTTP failed', err);
            resolve('');
            return;
          }
          console.info(`[Connect] facecapture checkresult response: ${data.result}`);
          try {
            const response: FaceCaptureCheckResponse = JSON.parse(data.result as string);
            const image: string | undefined = response.extInfo?.imageContent;
            resolve(image && image.length > 0 ? image : '');
          } catch (e) {
            resolve('');
          }
        }
      );
    });
  }

  /**
   * Enroll step 1 / verify step 1: initialize (facecapture for enroll, connect for verify),
   * fetch clientCfg and transactionId only, no parsing.
   */
  async initialize(host: string, api: string, userId?: string, serviceLevel?: string): Promise<InitializeResponse> {
    try {
      const finalMetaInfo: string = ZolozFacade.getMetaInfo()
      console.log("connect page metainfo" + finalMetaInfo)
      const requestData: InitializeRequestBody = { metaInfo: finalMetaInfo };
      if (userId) {
        requestData.userId = userId;
      }
      if (serviceLevel) {
        requestData.serviceLevel = serviceLevel;
      }

      const httpRequest = http.createHttp();
      const url = host + api;
      const headers: HttpHeaders = { 'Content-Type': 'application/json' };

      return new Promise<InitializeResponse>((resolve) => {
        httpRequest.request(
          url,
          {
            method: http.RequestMethod.POST,
            header: headers,
            extraData: JSON.stringify(requestData)
          },
          (err, data) => {
            if (err) {
              console.error('HTTP request failed', err);
              resolve(this.createErrorResponse('F', 'Network error'));
              return;
            }

            try {
              console.info('Received raw response', data.result);
              const response: InitializeResponse = JSON.parse(data.result as string);

              if (response.result?.resultStatus !== 'S') {
                console.error('Server returned failure', response.result);
              }
              resolve(response);
            } catch (parseError) {
              console.error('Failed to parse initialize response', parseError);
              resolve(this.createErrorResponse('F', 'Parse error'));
            }
          }
        );
      });
    } catch (error) {
      console.error('Initialize exception', error);
      return this.createErrorResponse('F', 'Unexpected error');
    }
  }

  private createErrorResponse(
    resultStatus: 'F',
    resultMessage: string = "error",
    resultCode: string = '-1'
  ): InitializeResponse {
    return {
      result: { resultStatus, resultMessage, resultCode },
      clientCfg: '',
      transactionId: '',
      rsaPubKey: ''
    };
  }

  async startZolozAuthentication(clientCfg: string, rsaPubKey: string): Promise<ZolozResponse> {
    const bizConfig: ZolozBizConfig = {
      // rsaPubKey: rsaPubKey,
      locale: 'en-US',
      // No chameleonConfig here: SDK falls back to built-in default UI resources.
    };
    const request = new ZolozRequest(clientCfg, bizConfig);
    return await ZolozFacade.getInstance().startWithRequest(getContext(this), request);
  }

  /**
   * Enroll: facecapture initialize → SDK face capture → checkresult(isReturnImage)
   * → connect enroll API registers the captured face as the reference image of userId.
   */
  private async startEnrollFlow(): Promise<void> {
    console.log(
      `[Connect enroll] Start config:\nFaceCapture Host: ${this.fcHostValue}\nConnect Host: ${this.connectHostValue}\nUserId: ${this.userId}`);

    const init = await this.initialize(this.fcHostValue, this.fcInitApiPath)
    if (!init.clientCfg) {
      console.error('[Connect enroll] facecapture initialize failed, SDK not started')
      promptAction.showToast({
        message: `FaceCapture initialize failed: ${init.result?.resultCode ?? 'unknown'}`,
        duration: 3000
      });
      return;
    }
    console.log(`transactionId: ${init.transactionId}`)
    const response = await this.startZolozAuthentication(init.clientCfg, init.rsaPubKey);
    if (response.code === ZLZResponseCode.Interrupt) {
      console.log('User interrupted the enroll flow')
      promptAction.showToast({ message: 'Enroll: Interrupt', duration: 3000 });
      return;
    }
    console.log(`User completed the facecapture flow, code=${response.code}`)
    promptAction.showToast({ message: `Enroll: Captured (code=${response.code}), registering`, duration: 3000 });

    // Fetch the captured face image and register it.
    const faceImage = await this.fetchCapturedFace(init.transactionId);
    if (!faceImage) {
      console.error('[Connect enroll] no face image in facecapture checkresult')
      promptAction.showToast({ message: 'Enroll failed: no captured image', duration: 3000 });
      return;
    }
    const enrolled = await this.enrollFaceImage(faceImage);
    console.info(`[Connect enroll] register result: ${enrolled}`)
    promptAction.showToast({
      message: enrolled ? 'Enroll: Face registered' : 'Enroll register failed (see log)',
      duration: 3000
    });
  }

  /**
   * Verify: connect initialize → SDK 1:1 compare with the enrolled face.
   */
  private async startVerifyFlow(): Promise<void> {
    console.log(
      `[Connect verify] Start config:\nConnect Host: ${this.connectHostValue}\nUserId: ${this.userId}\nServiceLevel: ${this.serviceLevel}`);

    const init = await this.initialize(this.connectHostValue, this.connectInitApiPath, this.userId, this.serviceLevel)
    if (!init.clientCfg) {
      // Server initialize failed (e.g. UNABLE_GET_IMAGE: no readable enrolled reference image).
      console.error('[Connect verify] initialize failed, SDK not started')
      promptAction.showToast({
        message: `Initialize failed: ${init.result?.resultCode ?? 'unknown'}`,
        duration: 3000
      });
      return;
    }
    console.log(`transactionId: ${init.transactionId}`)
    const response = await this.startZolozAuthentication(init.clientCfg, init.rsaPubKey);
    if (response.code === ZLZResponseCode.Interrupt) {
      console.log('User interrupted the verify flow')
      promptAction.showToast({ message: 'Verify: Interrupt', duration: 3000 });
    } else {
      console.log(`User completed the verify flow, code=${response.code}`)
      promptAction.showToast({ message: `Verify: Completed (code=${response.code})`, duration: 3000 });
    }
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 20 }) {
          // FaceCapture host input (enroll capture flow)
          Row() {
            Text("FC HOST")
              .fontSize(16)
              .width("25%")
              .textAlign(TextAlign.Start)
            TextInput({
              placeholder: "facecapture host",
              text: this.fcHostValue
            })
              .onChange((value: string) => {
                this.fcHostValue = value;
              })
              .placeholderColor(0x999999)
              .height(40)
              .backgroundColor("#f0f0f0")
              .padding({ left: 10 })
              .width("70%")
          }
          .width("95%")
          .alignItems(VerticalAlign.Center)

          // Connect host input (enroll register API + verify initialize)
          Row() {
            Text("CT HOST")
              .fontSize(16)
              .width("25%")
              .textAlign(TextAlign.Start)
            TextInput({
              placeholder: "connect host",
              text: this.connectHostValue
            })
              .onChange((value: string) => {
                this.connectHostValue = value;
              })
              .placeholderColor(0x999999)
              .height(40)
              .backgroundColor("#f0f0f0")
              .padding({ left: 10 })
              .width("70%")
          }
          .width("95%")
          .alignItems(VerticalAlign.Center)

          // UserId input (required by connect server side)
          Row() {
            Text("UserId")
              .fontSize(16)
              .width("25%")
              .textAlign(TextAlign.Start)
            TextInput({
              placeholder: "user id (enrolled)",
              text: this.userId
            })
              .onChange((value: string) => {
                this.userId = value;
              })
              .placeholderColor(0x999999)
              .height(40)
              .backgroundColor("#f0f0f0")
              .padding({ left: 10 })
              .width("70%")
          }
          .width("95%")
          .alignItems(VerticalAlign.Center)

          // ServiceLevel input
          Row() {
            Text("ServiceLevel")
              .fontSize(16)
              .width("25%")
              .textAlign(TextAlign.Start)
            TextInput({
              placeholder: "CONNECT0002",
              text: this.serviceLevel
            })
              .onChange((value: string) => {
                this.serviceLevel = value;
              })
              .placeholderColor(0x999999)
              .height(40)
              .backgroundColor("#f0f0f0")
              .padding({ left: 10 })
              .width("70%")
          }
          .width("95%")
          .alignItems(VerticalAlign.Center)

          // Enroll: facecapture SDK flow + connect enroll API registration
          Button("Start Connect Enroll")
            .width("80%")
            .height(50)
            .margin({ top: 20 })
            .onClick(() => {
              this.startEnrollFlow();
            })

          // Verify: SDK face flow, 1:1 compare with the enrolled face
          Button("Start Connect Verify")
            .width("80%")
            .height(50)
            .margin({ top: 20 })
            .onClick(() => {
              this.startVerifyFlow();
            })
        }
        .padding({ top: 40, bottom: 40 })
        .width("100%")
      }
    }
    .width('100%')
    .height('100%')
  }
}
