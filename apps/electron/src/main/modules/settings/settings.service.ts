import { app, nativeTheme } from "electron";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { AppSettings, Theme } from "@mcp_router/shared";
import { SingletonService } from "../singleton-service";
import { SettingsRepository } from "./settings.repository";

/**
 * Service for managing application settings
 */
export class SettingsService extends SingletonService<
  AppSettings,
  string,
  SettingsService
> {
  /**
   * Constructor
   */
  protected constructor() {
    super();
  }

  /**
   * Get entity name
   */
  protected getEntityName(): string {
    return "Settings";
  }

  /**
   * Get singleton instance
   */
  public static getInstance(): SettingsService {
    return (this as any).getInstanceBase();
  }

  /**
   * Reset instance
   * Used when switching workspaces
   */
  public static resetInstance(): void {
    (this as any).resetInstanceBase(SettingsService);
  }

  /**
   * アプリケーション設定を取得
   */
  public getSettings(): AppSettings {
    try {
      return SettingsRepository.getInstance().getSettings();
    } catch (error) {
      return this.handleError("設定取得", error);
    }
  }

  /**
   * 全ての設定を一度に保存
   */
  public saveSettings(settings: AppSettings): boolean {
    try {
      const result = SettingsRepository.getInstance().saveSettings(settings);
      if (result) {
        applyLoginItemSettings(
          settings.launchAtLogin ?? true,
          settings.showWindowOnStartup ?? true,
        );
        applyThemeSettings(settings.theme);
      }
      return result;
    } catch (error) {
      return this.handleError("設定保存", error, false);
    }
  }
}

/**
 * SettingsServiceのシングルトンインスタンスを取得
 */
export function getSettingsService(): SettingsService {
  return SettingsService.getInstance();
}

/**
 * OS起動時のウィンドウ表示設定に応じてログイン項目設定を更新
 */
export function applyLoginItemSettings(
  launchAtLogin: boolean,
  showWindowOnStartup: boolean,
): void {
  if (process.platform === "linux") {
    applyLinuxAutostart(launchAtLogin, showWindowOnStartup);
    return;
  }

  try {
    const loginItemOptions: Electron.Settings = {
      openAtLogin: launchAtLogin,
    };

    if (process.platform === "darwin") {
      loginItemOptions.openAsHidden = !showWindowOnStartup;
    } else if (process.platform === "win32") {
      loginItemOptions.args = showWindowOnStartup ? [] : ["--hidden"];
    }

    app.setLoginItemSettings(loginItemOptions);
  } catch (error) {
    console.error("Failed to update login item settings:", error);
  }
}

/**
 * Linux: app.setLoginItemSettings is a no-op, so write an XDG autostart entry
 * (~/.config/autostart/mcp-router.desktop) instead.
 */
function applyLinuxAutostart(
  launchAtLogin: boolean,
  showWindowOnStartup: boolean,
): void {
  // Only packaged builds have a stable executable path worth registering
  if (!app.isPackaged) return;

  try {
    // When running from an AppImage, execPath points into a temporary mount
    const executable = process.env.APPIMAGE || process.execPath;
    const configHome =
      process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config");
    const autostartDir = path.join(configHome, "autostart");
    const entryPath = path.join(autostartDir, "mcp-router.desktop");

    if (!launchAtLogin) {
      fs.rmSync(entryPath, { force: true });
      return;
    }

    const args = showWindowOnStartup ? "" : " --hidden";
    // Some launchers don't unquote Exec, so only quote paths that need it
    const exec = executable.includes(" ") ? `"${executable}"` : executable;

    const entry = [
      "[Desktop Entry]",
      "Type=Application",
      "Name=MCP Router",
      `Exec=${exec}${args}`,
      "Icon=mcp-router",
      "Terminal=false",
      "X-GNOME-Autostart-enabled=true",
      "",
    ].join("\n");

    fs.mkdirSync(autostartDir, { recursive: true });
    fs.writeFileSync(entryPath, entry);
  } catch (error) {
    console.error("Failed to update Linux autostart entry:", error);
  }
}

/**
 * 設定のテーマに基づいてネイティブテーマを更新
 */
export function applyThemeSettings(theme?: Theme): void {
  try {
    nativeTheme.themeSource = theme ?? "system";
  } catch (error) {
    console.error("Failed to update native theme:", error);
  }
}
