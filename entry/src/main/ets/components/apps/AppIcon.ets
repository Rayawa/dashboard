import { appIconPath } from '../../domain/apps/AppIconQuery';
import { SAPIBaseURL } from '../../config/constants';

@Component
export struct AppIcon {
    @Prop appId: string = '';
    @Prop packageName: string = '';
    @Prop iconUrl: string = '';
    @Prop iconSize: number = 44;
    private source(): ResourceStr {
        if (this.iconUrl?.trim()) return this.iconUrl;
        const path = appIconPath(this.appId, this.packageName);
        return path ? `${SAPIBaseURL.toString()}${path}` : $r('app.media.startIcon');
    }
    build() {
        Image(this.source()).width(this.iconSize).height(this.iconSize).borderRadius(12)
            .objectFit(ImageFit.Cover).alt($r('app.media.startIcon'))
            .backgroundColor($r('app.color.v3_surface_alt')).clip(true).accessibilityLevel('no')
    }
}
