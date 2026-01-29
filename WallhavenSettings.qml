import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "wallhavenFetcher"
    
    StyledText {
        width: parent.width
        text: "Wallhaven Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }
    
    StyledText {
        width: parent.width
        text: "Configure wallpaper fetching options"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }
    
    ListSettingWithInput {
        settingKey: "searchQueries"
        label: "Tag Combinations"
        description: "Add sets of tags. The plugin picks one set at random. Separate tags with commas to require ALL of them (e.g., 'anime, nature, rain')."
        fields: [
            { id: "query", label: "Tags", placeholder: "e.g. anime, nature", width: 250, required: true }
        ]
        defaultValue: []
    }
    
    ToggleSetting {
        settingKey: "dailyUpdate"
        label: "Daily Wallpaper"
        description: "Automatically download and set a new wallpaper every day."
        defaultValue: false
    }

    StringSetting {
        settingKey: "updateTime"
        label: "Update Time"
        description: "Time to fetch new wallpaper (HH:MM, 24-hour format)."
        placeholder: "08:00"
        defaultValue: "08:00"
        // Only visible if daily update is enabled
        visible: {
            // We need to access the value of the toggle above.
            // PluginSettings doesn't expose values directly via id across siblings easily unless we peek into pluginData.
            // But waiting for save might be slow.
            // However, loadValue reads from pluginData via service.
            // Let's rely on pluginData injection or parent loadValue.
            const val = root.loadValue("dailyUpdate", false);
            return val === true || val === "true";
        }
    }
}
