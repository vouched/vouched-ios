# Vouched iOS Example

## Features in the Example

**1st Screen** - Name Input (Optional)  
**2st Screen** - ID Detection  
**3nd Screen** - Face Detection  
**4th Screen** - ID Verification Results
**5th Screen** - Face Authenticaion (**Demo purposes only**)

When you finish, Vouched has performed the following features to verify your identity

- ID Card and Passport Detection
- Face Detection (w and w/o liveness)
- ID Verification
- Name Verification
- Face Authenticaion (**Demo purposes only**)

## Getting Started

### IDE

We suggest to use [Xcode](https://developer.apple.com/xcode/) to run and modify the Example.

### Environment

1. If necessary, navigate to your Vouched Dashboard and create a [Public Key](https://docs.vouched.id/#section/Dashboard/Manage-keys).
2. Create `Development.xcconfig`

```
API_KEY = <PUBLIC_KEY>
APP_NAME = Vouched Example
```

### Add Vouched Assets

1. Navigate to your Vouched Dashboard and download the iOS [Mobile Assets](https://docs.vouched.id/#section/Dashboard/Mobile-Assets).
2. Unzip and copy `inference_graph.tflite` and `labelmap_mobilenet_card.txt` to the `Vouched` directory. Ensure these files are in **Copy Bundle Resources**

### Install Pods

```
pod install
```

### Run

Unfortunately, cameras are not supported in simulators so the best way to run the example is on a real device. Once your device is plugged in, run the Example through Xcode
