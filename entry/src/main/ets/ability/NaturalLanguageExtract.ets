import { textProcessing, EntityType } from '@kit.NaturalLanguageKit';

// ========== 类型定义 ==========
export interface HuaweiLinkParseResult {
  packageName: string;
}

export interface HuaweiLinkInfo {
  url: string;
  packageName: string;
  charOffset: number;
}

export interface AppInfo {
  link: string | null;
  packageName: string | null;
  appID: string | null;
  date: string | null;
  isValid: boolean;
}

// ========== 自然语言提取器类 ==========
export class NaturalLanguageExtractor {

  // 主提取方法
  static async extractAppInfoFromText(inputText: string): Promise<AppInfo[]> {
    // 1. 输入验证
    if (!inputText || inputText.trim().length === 0) {
      console.log('错误：请输入文本');
      return [];
    }

    if (inputText.length > 1000) {
      console.log(`错误：文本长度${inputText.length}超过1000字符限制`);
      return [];
    }

    try {
      // 2. 使用文档中的实体抽取API - 明确指定需要的实体类型
      const entities = await textProcessing.getEntity(inputText, {
        entityTypes: [EntityType.URL, EntityType.DATETIME]
      });

      // 3. 处理URL实体 - 提取华为应用链接和包名
      const huaweiLinks: HuaweiLinkInfo[] = [];
      entities.forEach(entity => {
        if (entity.type === EntityType.URL) {
          const linkInfo = NaturalLanguageExtractor.parseHuaweiLink(entity.text);
          if (linkInfo) {
            huaweiLinks.push({
              url: entity.text,
              packageName: linkInfo.packageName,
              charOffset: entity.charOffset
            });
          }
        }
      });

      // 4. 使用正则表达式提取AppID（C开头+数字）
      const appIDs = NaturalLanguageExtractor.extractAppIDs(inputText);

      // 5. 提取所有日期实体
      const dates = entities
        .filter(e => e.type === EntityType.DATETIME)
        .map(e => e.text);

      // 6. 智能匹配应用信息
      const extractedApps = NaturalLanguageExtractor.matchAppInfo(
        inputText,
        huaweiLinks,
        appIDs,
        dates
      );

      console.log(`提取完成，找到 ${extractedApps.length} 个应用`);
      return extractedApps;

    } catch (error) {
      console.error('实体抽取失败:', error);
      return [];
    }
  }

  // 解析华为应用链接
  private static parseHuaweiLink(url: string): HuaweiLinkParseResult | null {
    const huaweiPrefix = 'https://appgallery.huawei.com/app/detail?id=';

    if (!url.startsWith(huaweiPrefix)) {
      return null;
    }

    // 提取id参数值
    const idPart = url.substring(huaweiPrefix.length);

    // 创建结束字符数组
    const endChars = ['&', '?', '#', ' ', '，', ',', '。'];
    let endIndex = idPart.length; // 默认结束位置为字符串末尾

    // 找到最早出现的结束字符位置
    for (const char of endChars) {
      const index = idPart.indexOf(char);
      if (index !== -1 && index < endIndex) {
        endIndex = index;
      }
    }

    // 包名中应该包含点，但不以点开头或结尾
    // 查找最后一个点号的位置
    const lastDotIndex = idPart.lastIndexOf('.');
    if (lastDotIndex !== -1 && lastDotIndex < endIndex) {
      // 如果最后一个点号在结束字符之前，确保点号后还有字符
      const afterDot = idPart.substring(lastDotIndex + 1, endIndex);
      if (afterDot.length === 0) {
        // 点号后面没有字符，说明点号可能是结束字符
        endIndex = lastDotIndex;
      }
    }

    const packageName = idPart.substring(0, endIndex);

    // 验证包名格式（至少包含一个点且不以点开头或结尾）
    if (packageName.includes('.') &&
      !packageName.startsWith('.') &&
      !packageName.endsWith('.')) {
      return { packageName };
    }

    return null;
  }

  // 提取AppID - C开头 + 数字
  private static extractAppIDs(text: string): string[] {
    // 匹配C开头，后面跟着8-12位数字
    const appIDPattern = /C\d{8,12}/g;
    const matches = text.match(appIDPattern);
    return matches ? Array.from(new Set(matches)) : [];
  }

  // 匹配应用信息
  private static matchAppInfo(
    fullText: string,
    links: HuaweiLinkInfo[],
    appIDs: string[],
    dates: string[]
  ): AppInfo[] {
    const apps: AppInfo[] = [];

    // 处理每个链接
    links.forEach(link => {
      // 在链接周围寻找AppID（50字符范围内）
      const nearbyAppID = NaturalLanguageExtractor.findNearbyText(
        fullText,
        link.charOffset,
        appIDs,
        50
      );

      // 在链接周围寻找日期（100字符范围内）
      const nearbyDate = NaturalLanguageExtractor.findNearbyText(
        fullText,
        link.charOffset,
        dates,
        100
      );

      apps.push({
        link: link.url,
        packageName: link.packageName,
        appID: nearbyAppID,
        date: nearbyDate,
        isValid: !!(link.packageName && nearbyAppID)
      });
    });

    // 为没有链接的AppID创建记录
    const usedAppIDs = new Set(apps.map(app => app.appID).filter(Boolean));
    const unusedAppIDs = appIDs.filter(id => !usedAppIDs.has(id));

    unusedAppIDs.forEach(appID => {
      const appIDIndex = fullText.indexOf(appID);
      if (appIDIndex !== -1) {
        // 尝试在AppID附近找包名（可能是文本形式）
        const nearbyPackage = NaturalLanguageExtractor.findPackageNearby(fullText, appIDIndex);
        const nearbyDate = NaturalLanguageExtractor.findNearbyText(fullText, appIDIndex, dates, 100);

        apps.push({
          link: null,
          packageName: nearbyPackage,
          appID: appID,
          date: nearbyDate,
          isValid: !!nearbyPackage
        });
      }
    });

    return apps;
  }

  // 在指定位置附近查找文本
  private static findNearbyText(
    fullText: string,
    position: number,
    candidates: string[],
    radius: number
  ): string | null {
    const start = Math.max(0, position - radius);
    const end = Math.min(fullText.length, position + radius);
    const context = fullText.substring(start, end);

    for (const candidate of candidates) {
      if (context.includes(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  // 在位置附近查找包名（文本形式的）
  private static findPackageNearby(fullText: string, position: number): string | null {
    const radius = 30;
    const start = Math.max(0, position - radius);
    const end = Math.min(fullText.length, position + radius);
    const context = fullText.substring(start, end);

    // 包名通常的格式
    const packagePattern = /[a-zA-Z][a-zA-Z0-9_]*(?:\.[a-zA-Z][a-zA-Z0-9_]*)+/;
    const match = context.match(packagePattern);

    return match ? match[0] : null;
  }


}