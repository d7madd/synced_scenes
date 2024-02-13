fx_version "cerulean"
games { "gta5" }

author "D7mad"
description "Sync Scenes DevTool"

lua54 "yes"

ui_page "web/ui.html"
files {
    "web/ui.html",
    "web/app.js",
    "web/style.css"
}

client_scripts {
    "client/cl_*.lua",
    "data/*",
}
