import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';
import { S_STATION_COMMAND_NONE } from '../common/constants';
import { SStationPage } from '../pages/main/SStationPage';

export class SStationNodeParams {
  command: number = S_STATION_COMMAND_NONE;
  commandVersion: number = 0;
  active: boolean = false;
  onDetailOpenChanged: (open: boolean) => void = (_open: boolean): void => {};
}

@Builder
function sStationNodeBuilder(params: SStationNodeParams): void {
  SStationPage({
    command: params.command,
    commandVersion: params.commandVersion,
    active: params.active,
    onDetailOpenChanged: params.onDetailOpenChanged,
  })
}

const S_STATION_NODE_BUILDER = wrapBuilder<SStationNodeParams[]>(sStationNodeBuilder);

/**
 * 在 HdsTabs 创建其惰性 TabContent 之前构建 S 站 Web 节点。
 * NodeContainer 首次出现时只挂载已有节点，不再从零创建 Web。
 */
export class SStationPreloadNodeController extends NodeController {
  private rootNode: BuilderNode<SStationNodeParams[]> | null = null;

  initialize(uiContext: UIContext, params: SStationNodeParams): void {
    if (this.rootNode) {
      this.rootNode.update(params);
      return;
    }
    this.rootNode = new BuilderNode<SStationNodeParams[]>(uiContext);
    this.rootNode.build(S_STATION_NODE_BUILDER, params);
  }

  update(params: SStationNodeParams): void {
    this.rootNode?.update(params);
  }

  makeNode(_uiContext: UIContext): FrameNode | null {
    return this.rootNode?.getFrameNode() ?? null;
  }
}
