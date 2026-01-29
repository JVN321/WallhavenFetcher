import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    
    property bool isLoading: false
    
    // UI for Horizontal Bars (Top/Bottom)
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS
            
            DankActionButton {
                iconName: "image_search" // Material icon
                tooltipText: "Fetch Random Wallpaper"
                enabled: !root.isLoading
                
                onClicked: {
                    ToastService.showInfo("Wallhaven", "Fetching wallpaper...")
                    root.fetchWallpaper()
                }
            }
        }
    }

    // UI for Vertical Bars (Left/Right)
    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS
            
            DankActionButton {
                iconName: "image_search"
                tooltipText: "Fetch Random Wallpaper"
                enabled: !root.isLoading
                anchors.horizontalCenter: parent.horizontalCenter
                
                onClicked: {
                    ToastService.showInfo("Wallhaven", "Fetching wallpaper...")
                    root.fetchWallpaper()
                }
            }
        }
    }
    
    function fetchWallpaper() {
        if (isLoading) return;
        isLoading = true;
        
        // Handle multiple query sets
        var queries = pluginData.searchQueries || [];
        var selectedQuery = "";
        
        // If it's a list (ListSettingWithInput saves array of objects), pick one
        if (Array.isArray(queries) && queries.length > 0) {
            var randomIndex = Math.floor(Math.random() * queries.length);
            var item = queries[randomIndex];
            // Format is { "query": "text" } based on fields config in settings
            if (item && item.query) {
                selectedQuery = item.query;
            }
        } 
        // Fallback for legacy "tags" string setting if user hasn't updated yet
        else if (pluginData.tags && typeof pluginData.tags === "string") {
            selectedQuery = pluginData.tags;
        }
        
        console.info("Wallhaven: Raw query selected: " + (selectedQuery || "RANDOM"));
        
        var queryStr = "sorting=random&purity=100";
        if (selectedQuery) {
            // User input: "tag1, tag2, tag3"
            // Wallhaven strict AND: "+tag1 +tag2 +tag3"
            var parts = selectedQuery.split(",");
            var formattedParts = [];
            for (var i = 0; i < parts.length; i++) {
                var t = parts[i].trim();
                if (t) {
                    // Check if user already added operators, if not, prepend +
                    if (t.charAt(0) !== "+" && t.charAt(0) !== "-") {
                        formattedParts.push("+" + t);
                    } else {
                        formattedParts.push(t);
                    }
                }
            }
            var finalQuery = formattedParts.join(" ");
            console.info("Wallhaven: Formatted API query: " + finalQuery);
            queryStr += "&q=" + encodeURIComponent(finalQuery);
        }
        
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText);
                        if (json.data && json.data.length > 0) {
                            var wallpaper = json.data[0];
                            startDownload(wallpaper.path, wallpaper.id);
                        } else {
                            ToastService.showError("Wallhaven", "No wallpapers found for query: " + selectedQuery);
                            isLoading = false;
                        }
                    } catch (e) {
                         ToastService.showError("Wallhaven", "Failed to parse API response.");
                         isLoading = false;
                    }
                } else {
                     ToastService.showError("Wallhaven", "API Request failed: " + xhr.status);
                     isLoading = false;
                }
            }
        }
        xhr.open("GET", "https://wallhaven.cc/api/v1/search?" + queryStr);
        xhr.send();
    }
    
    function startDownload(url, id) {
        var ext = url.split('.').pop();
        var filename = "wallhaven_" + id + "." + ext;
        var home = Quickshell.env("HOME");
        var targetDir = home + "/Pictures/Wallpapers/Wallhaven";
        var targetPath = targetDir + "/" + filename;
        
        // Pass to process
        downloadProcess.targetPath = targetPath;
        downloadProcess.command = ["curl", "-L", "-o", targetPath, "--create-dirs", url];
        downloadProcess.running = true;
    }
    
    Timer {
        interval: 60000 // Check every minute
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var daily = pluginData.dailyUpdate === true || pluginData.dailyUpdate === "true";
            if (!daily) return;
            
            var targetTimeStr = pluginData.updateTime || "08:00";
            var parts = targetTimeStr.split(":");
            var targetHour = parseInt(parts[0]) || 8;
            var targetMinute = parseInt(parts[1]) || 0;
            
            var now = new Date();
            var currentHour = now.getHours();
            var currentMinute = now.getMinutes();
            
            // Check if we passed the target time today
            if (currentHour > targetHour || (currentHour === targetHour && currentMinute >= targetMinute)) {
                
                var today = now.toISOString().slice(0, 10);
                var last = pluginData.lastUpdateDate || "";
                
                if (today !== last) {
                     console.info("Wallhaven: Daily update trigger! Target: " + targetTimeStr + ", Now: " + currentHour + ":" + currentMinute + ", Last: " + last);
                     
                     // If last date is in the future (corruption?), reset it.
                     if (last > today) {
                         console.info("Wallhaven: Resetting invalid future date.");
                         // Proceed to update
                     }
                     
                     // Optimization: check if we ALREADY called fetch recently to avoid double trigger if fetch takes long
                     if (!root.isLoading) {
                         root.fetchWallpaper();
                     }
                }
            }
        }
    }
    
    Process {
        id: downloadProcess
        property string targetPath: ""
        
        // Curl is silent usually, but we can capture errors
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() && downloadProcess.exitCode !== 0) {
                     console.error("Wallhaven Download Error: " + text.trim());
                }
            }
        }

        onExited: (exitCode) => {
            if (exitCode === 0 && targetPath !== "") {
                // If the file is the exact same path, SessionData might not signal a change.
                // We should ideally ensure uniqueness or force update. 
                // However, since ID is in filename, a NEW wallpaper will have a new path.
                // The issue might be if the same wallpaper is downloaded again, but that's unlikely with random.
                
                // Explicitly clear first to ensure change if needed? No, that causes flash.
                // Let's just set it. If it fails, maybe we need to be more aggressive.
                
                SessionData.setWallpaper(targetPath);
                
                // Save last update date if it was a daily update (or just always save it on success)
                var today = new Date().toISOString().slice(0, 10);
                pluginService.savePluginData(pluginId, "lastUpdateDate", today);
                
                ToastService.showInfo("Wallhaven", "Wallpaper set successfully.");
            } else {
                ToastService.showError("Wallhaven", "Download failed (Exit code: " + exitCode + ")");
            }
            isLoading = false;
            targetPath = "";
        }
    }
}
