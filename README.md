# zolozkit

ZOLOZKit for HarmonyOS

## Background

This repository provides an example to help customers integrate the ZOLOZ SDK with ease.

## Getting Started

### Prerequisites

Before integrating the ZOLOZ HarmonyOS SDK, ensure that your DevEco Studio version is **5.0.5 or later**.

## SDK Integration

### Step 1: Download and Install SDK

Manual download and installation
1. Open the ZOLOZ HarmonyOS repository: https://github.com/zoloz-pte-ltd/zoloz-demo-harmonyOS
2. Select the desired ZOLOZKit version (it is recommended to use the latest version), and download the corresponding zolozkit.har package.
3. Drag the downloaded SDK file (.har) into the libs directory of your project.
4. Manually add the following dependency configuration in the oh-package.json file of the module directory that needs to call ZOLOZKit.
```json5
{
    "dependencies": {
      // ./libs/zolozkit.har should be replaced with the actual path of zolozkit.har
      "zolozkit": "file:./libs/zolozkit.har"
    }
}
```

### Step 2: Import and Use SDK
```arkts
//import zoloz
import {ZolozFacade,ZolozRequest,ZolozResponse} from "@zoloz/zolozkit"

//use
const request = new ZolozRequest(clientCfg, { rsaPubKey });
const response= await ZolozFacade.getInstance().startWithRequest(getContext(this),request);

```
