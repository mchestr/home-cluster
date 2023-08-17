module.exports = {
    delay: 30,

    torznab: [
      "http://prowlarr.default.svc.cluster.local:9696/25/api?apikey={{ .PROWLARR_API_KEY }}",
      "http://prowlarr.default.svc.cluster.local:9696/30/api?apikey={{ .PROWLARR_API_KEY }}",
      "http://prowlarr.default.svc.cluster.local:9696/31/api?apikey={{ .PROWLARR_API_KEY }}",
      "http://prowlarr.default.svc.cluster.local:9696/33/api?apikey={{ .PROWLARR_API_KEY }}",
    ],

    action: "inject",
    matchMode: "safe",
    skipRecheck: true,
    includeEpisodes: true,
    includeNonVideos: true,
    duplicateCategories: true,
    outputDir: "/config/xseeds",
    torrentDir: "/config/qBittorrent/BT_backup",
    qbittorrentUrl: "http://localhost:8080",
    rssCadence: "15 minutes", // autobrr doesnt get every announcement
};
