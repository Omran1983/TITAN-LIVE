import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tsconfigPaths from "vite-tsconfig-paths";
export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  server: { host: "127.0.0.1", port: 4028, strictPort: true, hmr: { host: "127.0.0.1", protocol: "ws", port: 4028 } },
  preview:{ host:"127.0.0.1", port:4028 }
});