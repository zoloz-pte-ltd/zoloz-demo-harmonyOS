# zolozkit

ZOLOZKit for HarmonyOS

## Background

This repository provides an example to help customers integrate the ZOLOZ SDK with ease.

## Getting Started

### Prerequisites

Before integrating the ZOLOZ HarmonyOS SDK, ensure that your DevEco Studio version is **5.0.5 or later**.

## SDK Integration

### Step 1: Download and Install SDK

Method 1: Install via command line from the third-party library repository
1. Open the [ZOLOZ HarmonyOS repository.](https://ohpm.openharmony.cn/)
2. Select the desired ZOLOZKit version (it is recommended to use the latest version).
3. In the root directory of the Hap/Har that needs to be integrated, install the SDK using the following command.

```bash
ohpm install @zoloz/zolozkit@<version>
```

4. Verify installation.
After installation, the dependencies section in the on-package.json file at the root directory should display zolozkit.

Method 2: Manual download and installation
1. Open the ZOLOZ HarmonyOS repository.https://github.com/ZOLOZ-HarmonyOS/zolozkit
2. Select the desired ZOLOZKit version (it is recommended to use the latest version), and download the corresponding zolozkit.har package.
3. Drag the downloaded SDK file (.har) into the libs directory of your project.
4. Manually add the following dependency configuration in the on-package.json file at the root directory of your project.

### Step 2: Import SDK
```arkts
//import zoloz
import {ZolozFacade,ZolozRequest,ZolozResponse} from "@zoloz/zolozkit"

//use
const request = new ZolozRequest(clientCfg, { rsaPubKey });
const response= await ZolozFacade.getInstance().startWithRequest(getContext(this),request);

```
