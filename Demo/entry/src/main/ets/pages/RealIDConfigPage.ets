import {
  ZolozFacade, ZolozRequest, ZolozBizConfig, ZolozResponse, ZLZResponseCode,
} from "zolozkit"
import { http } from '@kit.NetworkKit';

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

export interface ProductConfig { // Fine-grained product configuration
  deeperMode?: string; // AIGC detection strength
  livenessMode?: string; // Liveness detection strength
  actionCheckItems?: string[]; // Action list
  actionRandom?: string; // Whether to randomize
  actionFrame?: string[]; // Extra capture frame types
  docType?: string
  docUiType?: string // Document capture mode: "2"=Deep Scan, "1"=Self Capture

}

export interface PageConfig { // Fine-grained product configuration
  urlFaceGuide?: string
}

export interface InitializeParams {
  host: string;
  api: string;
  metaInfo?: string;
  flowType: string;
  docType?: string;
  productConfig?: ProductConfig,
  pageConfig?: PageConfig,
}

@Entry
@Component
export struct RealIDConfigPage {
  @State hostValue: string = "http://30.96.104.147:8082";
  @State apiValue: string = "/api/realid/initialize";
  // Fixed to App SDK integration
  @State flowType: string = "REALIDLITE_KYC";
  // Document type
  @State docType: string = "00860000001";
  // "2"=Deep Scan, "1"=Self Capture
  @State docUiType: string = "2";

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
   */
  async initialize(initial: InitializeParams): Promise<InitializeResponse> {
    try {
      const finalMetaInfo: string = ZolozFacade.getMetaInfo()
      console.log("realid page metainfo" + finalMetaInfo)
      const requestData: InitializeParams = {
        host: this.hostValue, // Host from form input
        api: this.apiValue, // API path from form input
        flowType: this.flowType, // flowType from form input
        docType: this.docType,
        metaInfo: finalMetaInfo,
        productConfig: {
          docUiType: this.docUiType,
        },
        pageConfig: {
          // Custom face guide page URL - the example uses the HK site URL
          urlFaceGuide: 'https://hk-production-cdn.zoloz.net/page/realid-lite-fe/faceGuide.html?locale=zh-HK'
        }
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
              console.error('ZimInitUtil: HTTP request failed', err);
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
              resolve(response); // Return the raw structure directly
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
      rsaPubKey: rsaPubKey,
      // Language setting
      locale: 'en-US',
      // Chameleon UI config - path of the chameleon config file under resources/rawfile
      chameleonConfig: "config_realId_native.zip",
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

          // FlowType input
          Row() {
            Text("FlowType")
              .fontSize(16)
              .width("25%")
              .textAlign(TextAlign.Start)
            TextInput({
              placeholder: "REALIDLITE_KYC",
              text: this.flowType
            })
              .onChange((value: string) => {
                this.flowType = value;
              })
              .placeholderColor(0x999999)
              .height(40)
              .backgroundColor("#f0f0f0")
              .padding({ left: 10 })
              .width("70%")
          }
          .width("95%")
          .alignItems(VerticalAlign.Center)

          // DocType
          Row() {
            Text("DocType")
              .fontSize(16)
              .width("25%")
              .textAlign(TextAlign.Start)
            TextInput({
              placeholder: "00000001003",
              text: this.docType
            })
              .onChange((value: string) => {
                this.docType = value;
              })
              .placeholderColor(0x999999)
              .height(40)
              .backgroundColor("#f0f0f0")
              .padding({ left: 10 })
              .width("70%")
          }
          .width("95%")
          .alignItems(VerticalAlign.Center)

          // Document capture mode switch
          Row() {
            Text("Capture Mode")
              .fontSize(16)
              .width("25%")
              .textAlign(TextAlign.Start)
            Row({ space: 12 }) {
              Text("Deep Scan")
                .fontSize(14)
                .fontColor(this.docUiType === "2" ? Color.Blue : Color.Gray)
                .onClick(() => {
                  this.docUiType = "2";
                })
              Text("|")
                .fontSize(14)
                .fontColor(Color.Gray)
              Text("Self Capture")
                .fontSize(14)
                .fontColor(this.docUiType === "1" ? Color.Blue : Color.Gray)
                .onClick(() => {
                  this.docUiType = "1";
                })
            }
            .width("70%")
          }
          .width("95%")
          .alignItems(VerticalAlign.Center)

          // Start button
          Button("Start RealID")
            .width("80%")
            .height(50)
            .margin({ top: 30 })
            .onClick(async () => {
              console.log(
                `[RealID] Start config:\nHost: ${this.hostValue}\nAPI: ${this.apiValue}\nService: ${this.flowType}\nDocType: ${this.docType}`);

              // Build the full URL
              const fullUrl = `${this.hostValue}${this.apiValue}`;
              console.log(`Request URL: ${fullUrl}`);

              const init = await this.initialize({ host: this.hostValue, api: this.apiValue, flowType: this.flowType })
              if (init.transactionId) {
                console.log(`transactionId: ${init.transactionId}`)
                const response = await this.startZolozAuthentication(init.clientCfg, init.rsaPubKey);
                if (response.code === ZLZResponseCode.Interrupt) {
                  console.log('User interrupted the verification flow')
                } else {
                  console.log('User completed the verification flow')
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

