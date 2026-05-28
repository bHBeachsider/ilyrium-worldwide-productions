import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        navy: "#1F3A5F",
        accent: "#C8553D",
        muted: "#5C6770",
        border: "#E1E5EB",
        bg: "#F5F7FA",
        panel: "#FFFFFF",
        ok: "#4CAF50",
        amber: "#FF9800",
        danger: "#E53935",
      },
      fontFamily: {
        sans: ["-apple-system", "BlinkMacSystemFont", "Segoe UI", "Arial", "sans-serif"],
        mono: ["SF Mono", "Menlo", "Consolas", "monospace"],
      },
    },
  },
  plugins: [],
};

export default config;
