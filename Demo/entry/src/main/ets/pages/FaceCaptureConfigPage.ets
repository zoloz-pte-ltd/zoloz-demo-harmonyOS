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

export interface InitializeParams {
  host: string;
  api: string;
  metaInfo?: string;
}

@Entry
@Component
export struct FaceCaptureConfigPage {
  @State hostValue: string = "http://30.96.105.20:8081";
  @State apiValue: string = "/api/facecapture/initialize";

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

  /**
   * Initialize: fetch clientCfg and transactionId only, no parsing.
   * FaceCapture has no flowType/docType (pure face product).
   */
  async initialize(initial: InitializeParams): Promise<InitializeResponse> {
    try {
      const finalMetaInfo: string = ZolozFacade.getMetaInfo()
      console.log("facecapture page metainfo" + finalMetaInfo)
      const requestData: InitializeParams = {
        host: this.hostValue,
        api: this.apiValue,
        metaInfo: finalMetaInfo,
      };

      const httpRequest = http.createHttp();
      const url = initial.host + initial.api;
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
              console.error('FaceCapture init: HTTP request failed', err);
              resolve(this.createErrorResponse('F', 'Network error'));
              return;
            }

            try {
              console.info('Received raw response', data.result);
              const response: InitializeResponse = JSON.parse(data.result as string);
              console.log('Parsed response keys:', Object.keys(response));

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

  async startZolozAuthentication(clientCfg: string, rsaPubKey: string): Promise<ZolozResponse> {
    const bizConfig: ZolozBizConfig = {
      locale: 'en-US',
      // No chameleonConfig here: SDK falls back to built-in default UI resources.
    };
    const request = new ZolozRequest(clientCfg, bizConfig);
    return await ZolozFacade.getInstance().startWithRequest(getContext(this), request);
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 20 }) {
          // Host input
          Row() {
            Text("HOST")
              .fontSize(16)
              .width("25%")
              .textAlign(TextAlign.Start)
            TextInput({
              placeholder: "https://example.com",
              text: this.hostValue
            })
              .onChange((value: string) => {
                this.hostValue = value;
              })
              .placeholderColor(0x999999)
              .height(40)
              .backgroundColor("#f0f0f0")
              .padding({ left: 10 })
              .width("70%")
          }
          .width("95%")
          .alignItems(VerticalAlign.Center)

          // API input
          Row() {
            Text("API")
              .fontSize(16)
              .width("25%")
              .textAlign(TextAlign.Start)
            TextInput({
              placeholder: "/api/path",
              text: this.apiValue
            })
              .onChange((value: string) => {
                this.apiValue = value;
              })
              .placeholderColor(0x999999)
              .height(40)
              .backgroundColor("#f0f0f0")
              .padding({ left: 10 })
              .width("70%")
          }
          .width("95%")
          .alignItems(VerticalAlign.Center)

          // Start button
          Button("Start FaceCapture")
            .width("80%")
            .height(50)
            .margin({ top: 30 })
            .onClick(async () => {
              console.log(
                `[FaceCapture] Start config:\nHost: ${this.hostValue}\nAPI: ${this.apiValue}`);

              const fullUrl = `${this.hostValue}${this.apiValue}`;
              console.log(`Request URL: ${fullUrl}`);

              const init = await this.initialize({ host: this.hostValue, api: this.apiValue })
              if (init.transactionId) {
                console.log(`transactionId: ${init.transactionId}`)
                const response = await this.startZolozAuthentication(init.clientCfg, init.rsaPubKey);
                if (response.code === ZLZResponseCode.Interrupt) {
                  console.log('User interrupted the verification flow')
                  promptAction.showToast({ message: 'Interrupt', duration: 3000 });
                } else {
                  console.log('User completed the verification flow')
                  promptAction.showToast({ message: `Completed (code=${response.code})`, duration: 3000 });
                }
              }
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
