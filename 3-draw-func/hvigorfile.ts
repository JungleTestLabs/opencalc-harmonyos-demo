// Workaround: HarmonyOS 6.0.2 SDK 嵌套布局 (<sdk>/default/openharmony/<comp>)
// 触发不到 _parsingPlatforms，因为 pathVersionMapper["6.0.2"]="" 是 falsy。
// 这里在插件加载前用绝对路径预热 module cache 并把映射改成非空。
try {
  const hosConst = require(
    '/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor-ohos-plugin/' +
    'node_modules/@ohos/hos-sdkmanager-common/build/src/hos/const/hos-component-constants.js'
  );
  const pvm = hosConst && hosConst.HOS_CONFIG && hosConst.HOS_CONFIG.pathVersionMapper;
  if (pvm && !pvm['6.0.2']) {
    pvm['6.0.2'] = 'HarmonyOS-6.0.2';
  }
} catch (e) {
  console.warn('[hvigorfile] SDK pathVersionMapper patch skipped:', (e as Error).message);
}

export { appTasks } from '@ohos/hvigor-ohos-plugin';
