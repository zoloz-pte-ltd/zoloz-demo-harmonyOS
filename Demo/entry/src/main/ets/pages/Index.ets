import router from '@ohos.router';
@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Column() {
      Button("RealId")
        .width('80%')
        .height(60)
        .fontWeight(FontWeight.Bold)
        .fontSize(20)
        .margin({ top: 20 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/RealIDConfigPage'
          });
        })
    }
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .width('100%')
  }
}