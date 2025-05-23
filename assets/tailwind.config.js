// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/cen_web.ex",
    "../lib/cen_web/**/*.*ex"
  ],
  theme: {
    container: {
      padding: {
        DEFAULT: '1.25rem',
        lg: '2.5rem',
      },
    },
    extend: {
      colors: {
        brand: "#FD4F00",
        accent: "#A2C7E0",
        text: "#666666",
        background: "#FCFCFC",
        regulargray: "#1F1F1F",
        navbargray: "#1F1F1F",
        footergray: "#1F1F1F",
        "title-text": "#3E3E3E",
        "accent-hover": "#dfebf4"
      },
      boxShadow: {
        "navbar": "0 0 15px 0 rgba(0, 0, 0, 0.15)",
        "default-convexity": "inset -3px 4px 8px 0px rgba(0, 0, 0, 0.09)",
        "input": "2px 2px 5px 0px rgba(0, 0, 0, 0.09), inset -3px 4px 8px 0px rgba(0, 0, 0, 0.09)",
        "icon": "inset 2px 2px 6px 0px rgba(0, 0, 0, 0.25)",
        "default-1": "0px 4px 10px 0px rgba(0, 0, 0, 0.25)",
        "footer": "15px -10px 20px 0px rgba(202, 202, 202, 0.3)",
        "textcard": "2px 2px 5px 0px rgba(0, 0, 0, 0.09)",
        "home-card": "15px -10px 20px 0px rgba(202, 202, 202, 0.3), -15px 10px 25px 0px rgba(163, 163, 163, 0.16)",
        "notification-card": "2px 2px 10px 0px rgba(0, 0, 0, 0.1)"
      },

    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, {values})
    })
  ]
}
