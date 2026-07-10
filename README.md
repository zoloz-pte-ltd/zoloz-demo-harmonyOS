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
2. Select the desired ZOLOZKit version (the latest version is recommended), and download the corresponding zolozkit.har package.
3. Drag the downloaded SDK file (.har) into the `libs` directory of your project.
4. Add the following dependency configuration in the `oh-package.json5` file of the module that needs to integrate the ZOLOZKit SDK.
```json5
{
    "dependencies": {
      // ./libs/zolozkit.har should be replaced with the actual path of zolozkit.har
      "zolozkit": "file:./libs/zolozkit.har"
    }
}
```

### Step 2: Verify HAR Integration

After configuring the dependency in `oh-package.json5` and syncing the project, it is recommended to add the following test code to your project. If the `metainfo` string can be obtained successfully, the SDK has been correctly integrated.

```arkts
// Import ZOLOZ
import { ZolozFacade } from "zolozkit";

// Test calling ZolozFacade getMetaInfo
const metainfo = ZolozFacade.getMetaInfo();
```

### Step 3: Import and Use SDK
```arkts
// Import ZOLOZ
import { ZolozFacade, ZolozRequest, ZolozResponse, ZLZResponseCode } from "zolozkit";

// Build request
const request = new ZolozRequest(clientCfg, { rsaPubKey });

// Start SDK
const response: ZolozResponse = await ZolozFacade.getInstance().startWithRequest(getContext(this), request);

// Handle result based on response code
if (response.code === ZLZResponseCode.Interrupt) {
  // User exited or system interrupted; the SDK has already shown a prompt internally
} else {
  // The flow completed normally; call the backend checkResult API to obtain the transaction result (the backend service is the source of truth)
}
```
