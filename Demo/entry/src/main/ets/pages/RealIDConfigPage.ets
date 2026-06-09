import { router } from '@kit.ArkUI';
import {
  ZolozFacade,
  ZolozRequest,
  ZolozBizConfig,
  ZolozResponse,
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
export interface ProductConfig{           // 细粒度产品配置（重点！）
  deeperMode?: string;          // AIGC 检测强度
  livenessMode?: string;        // 活体检测强度
  actionCheckItems?: string[];  // 动作列表
  actionRandom?: string;        // 是否随机
  actionFrame?: string[];       // 额外采集帧类型
  docType?:string
  docUiType?: string            // 证件采集模式: "2"=扫描版(Deep Scan), "1"=手拍版(Self Capture)
};
export interface InitializeParams {
  host: string;
  api: string;
  metaInfo?: string;
  flowType: string;
  docType?: string;
  productConfig ?: ProductConfig,
}
// export interface InitializeParamsRaw {
// response:InitializeResponse
// }
@Entry
@Component
export struct RealIDConfigPage {

  // 默认值来自 Java 配置
  @State hostValue: string = "http://30.96.104.239:8082"; // 可根据环境调整
  @State apiValue: string = "/api/realid/initialize";                  // 对应 /zeta/demo/init 的简化
  @State flowType: string = "REALIDLITE_KYC";                // ← 关键默认值
  @State docType: string = "00860000001";         // 固定值，不暴露给 UI
  @State docUiType: string = "2"; // "2"=扫描版, "1"=手拍版
  private transactionId:string="default transactionId"

  private createErrorResponse(
    resultStatus: 'F',
    resultMessage: string="error",
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
   * 初始化：仅获取 clientCfg 和 transactionId，不做任何解析
   */
  async initialize(initial: InitializeParams): Promise<InitializeResponse> {
    try {
      const finalMetaInfo:string = ZolozFacade.getMetaInfo()
      console.log("realid page metainfo"+finalMetaInfo)
      const requestData: InitializeParams = {
        host: this.hostValue,       // 使用表单输入的host
        api: this.apiValue,         // 使用表单输入的API路径
        flowType: this.flowType, // 使用表单输入的flowType
        docType:this.docType,
        metaInfo: finalMetaInfo,
        productConfig: {
          docUiType: this.docUiType,
        },
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
              console.error('ZimInitUtil: HTTP 请求失败', err);
              resolve(this.createErrorResponse('F', 'Network error'));
              return;
            }

            try {
              console.info('收到原始响应', data.result);
              const response: InitializeResponse = JSON.parse(data.result as string);
              console.log('解析后的响应:', Object.keys(response));

              if (response.result?.resultStatus !== 'S') {
                console.error('服务端返回失败', response.result);
                // resolve(this.createErrorResponse('F', 'Server returned failure'));
                //return;
              }

              // 只取 clientCfg 和 transactionId
              // if (!response.clientCfg || !response.transactionId) {
              //   console.error(' 缺少 clientCfg 或 transactionId');
              //   resolve(this.createErrorResponse('F', 'Missing clientCfg or transactionId'));
              //   return;
              // }
              // const clientCfg = response.clientCfg;
              // const bizConfig:ZolozBizConfig = {
              //   rsaPubKey:response.rsaPubKey
              // };
              // const request = new ZolozRequest(clientCfg, bizConfig);
              // const facade = ZolozFacade.getInstance();
              // const zolozResponse = await facade.startWithRequest(request);
              resolve(response); // 直接返回原始结构
            } catch (parseError) {
              console.error('初始化解析响应失败', parseError);
              resolve(this.createErrorResponse('F', 'Parse error'));
            }
          }
        );
      });
    } catch (error) {
      console.error('初始化异常', error);
      return this.createErrorResponse('F', 'Unexpected error');
    }
  }
  async startZolozAuthentication(clientCfg: string, rsaPubKey: string): Promise<ZolozResponse> {
    const bizConfig:ZolozBizConfig = {
      rsaPubKey:rsaPubKey
    };
    const request = new ZolozRequest(clientCfg, bizConfig);
    return await ZolozFacade.getInstance().startWithRequest(getContext(this),request);
  }
  build() {
    Stack() {
      Scroll() {
        Column({ space: 20 }) {
          // Host 输入
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

          // API 输入
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

          // FlowType 输入
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

          // 证件采集模式切换
          Row() {
            Text("采集模式")
              .fontSize(16)
              .width("25%")
              .textAlign(TextAlign.Start)
            Row({ space: 12 }) {
              Text("扫描版")
                .fontSize(14)
                .fontColor(this.docUiType === "2" ? Color.Blue : Color.Gray)
                .onClick(() => { this.docUiType = "2"; })
              Text("|")
                .fontSize(14)
                .fontColor(Color.Gray)
              Text("手拍版")
                .fontSize(14)
                .fontColor(this.docUiType === "1" ? Color.Blue : Color.Gray)
                .onClick(() => { this.docUiType = "1"; })
            }
            .width("70%")
          }
          .width("95%")
          .alignItems(VerticalAlign.Center)

          // 开始按钮
          Button("开始 RealID 验证")
            .width("80%")
            .height(50)
            .margin({ top: 30 })
            .onClick(async() => {
              console.log(`[RealID] 启动配置:\nHost: ${this.hostValue}\nAPI: ${this.apiValue}\nService: ${this.flowType}\nDocType: ${this.docType}`);

              // 示例：拼接完整 URL
              const fullUrl = `${this.hostValue}${this.apiValue}`;
              console.log(`请求地址: ${fullUrl}`);

              const init= await this.initialize({ host: this.hostValue, api: this.apiValue, flowType: this.flowType })
              if (init.transactionId) {
                const ret = await this.startZolozAuthentication(init.clientCfg, init.rsaPubKey);
                console.log('ekyc结果：', ret);
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

