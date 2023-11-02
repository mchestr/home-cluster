module.exports = {
  qbittorrentUrl: "http://localhost:8080",
  delay: 20,
  torznab: [
    "http://prowlarr.default.svc.cluster.local:9696/25/api?apikey={{ .PROWLARR_API_KEY }}",
    "http://prowlarr.default.svc.cluster.local:9696/30/api?apikey={{ .PROWLARR_API_KEY }}",
    "http://prowlarr.default.svc.cluster.local:9696/31/api?apikey={{ .PROWLARR_API_KEY }}",
    "http://prowlarr.default.svc.cluster.local:9696/33/api?apikey={{ .PROWLARR_API_KEY }}",
    "http://prowlarr.default.svc.cluster.local:9696/34/api?apikey={{ .PROWLARR_API_KEY }}",
    "http://prowlarr.default.svc.cluster.local:9696/35/api?apikey={{ .PROWLARR_API_KEY }}",
  ],

  action: "inject",
  includeEpisodes: false,
  includeSingleEpisodes: true,
  includeNonVideos: true,
  duplicateCategories: true,
  matchMode: "safe",
  skipRecheck: true,
  linkType: "hardlink",
  linkDir: "/media/downloads/torrents/complete/cross-seed",
  dataDirs: [
    "/media/downloads/torrents/complete/prowlarr",
    "/media/downloads/torrents/complete/radarr",
    "/media/downloads/torrents/complete/sonarr",
  ],
  outputDir: "/config/xseeds",
  torrentDir: "/config/qBittorrent/BT_backup",
}
