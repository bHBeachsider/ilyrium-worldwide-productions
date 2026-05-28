import "./globals.css";
import type { Metadata } from "next";
import Sidebar from "@/components/Sidebar";
import Topbar from "@/components/Topbar";

export const metadata: Metadata = {
  title: "Ilyrium · Studio OS",
  description: "Control Panel for the Ilyrium agentic production studio.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <div className="flex min-h-screen">
          <Sidebar />
          <main className="flex-1 flex flex-col min-w-0">
            <Topbar />
            <div className="p-6 flex-1">{children}</div>
          </main>
        </div>
      </body>
    </html>
  );
}
