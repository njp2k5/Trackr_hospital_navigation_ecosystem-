import { useAlerts } from "@/hooks/useHospitalData";
import { Alert } from "@/lib/api";
import { cn } from "@/lib/utils";
import { AlertTriangle, Bell, Info, XCircle } from "lucide-react";
import { ScrollArea } from "@/components/ui/scroll-area";

const alertConfig = {
  critical: {
    icon: XCircle,
    bg: "bg-destructive/10",
    border: "border-destructive/30",
    text: "text-destructive",
    iconBg: "bg-destructive",
  },
  warning: {
    icon: AlertTriangle,
    bg: "bg-warning/10",
    border: "border-warning/30",
    text: "text-warning",
    iconBg: "bg-warning",
  },
  info: {
    icon: Info,
    bg: "bg-accent",
    border: "border-primary/20",
    text: "text-primary",
    iconBg: "bg-primary",
  },
};

function AlertItem({ alert }: { alert: Alert }) {
  const config = alertConfig[alert.level];
  const Icon = config.icon;

  return (
    <div
      className={cn(
        "flex items-start gap-3 rounded-lg border p-4 transition-all duration-200 hover:shadow-sm",
        config.bg,
        config.border
      )}
    >
      <div
        className={cn(
          "flex h-8 w-8 shrink-0 items-center justify-center rounded-lg",
          config.iconBg
        )}
      >
        <Icon className="h-4 w-4 text-primary-foreground" />
      </div>
      <div className="flex-1 space-y-1">
        <p className="text-sm font-medium text-foreground">{alert.message}</p>
        {alert.timestamp && (
          <p className="text-xs text-muted-foreground">
            {new Date(alert.timestamp).toLocaleTimeString()}
          </p>
        )}
      </div>
    </div>
  );
}

export function AlertsPanel() {
  const { data, isLoading, isError, error } = useAlerts();

  const criticalCount =
    data?.alerts.filter((a) => a.level === "critical").length || 0;
  const warningCount =
    data?.alerts.filter((a) => a.level === "warning").length || 0;

  return (
    <div className="rounded-xl border bg-card shadow-card">
      <div className="flex items-center justify-between border-b border-border p-5">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg gradient-teal shadow-teal">
            <Bell className="h-5 w-5 text-primary-foreground" />
          </div>
          <div>
            <h2 className="font-semibold text-foreground">Active Alerts</h2>
            <p className="text-xs text-muted-foreground">
              Real-time notifications
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {criticalCount > 0 && (
            <span className="rounded-full bg-destructive px-2.5 py-1 text-xs font-medium text-destructive-foreground">
              {criticalCount} Critical
            </span>
          )}
          {warningCount > 0 && (
            <span className="rounded-full bg-warning px-2.5 py-1 text-xs font-medium text-warning-foreground">
              {warningCount} Warning
            </span>
          )}
        </div>
      </div>

      <ScrollArea className="h-[320px]">
        <div className="space-y-3 p-5">
          {isLoading ? (
            Array.from({ length: 3 }).map((_, i) => (
              <div
                key={i}
                className="h-20 rounded-lg animate-shimmer"
              />
            ))
          ) : isError ? (
            <div className="rounded-lg border border-destructive/20 bg-destructive/5 p-4 text-sm text-muted-foreground">
              Unable to load alerts. {error instanceof Error ? error.message : "Check the analytics API connection."}
            </div>
          ) : data?.alerts.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-success/10 mb-3">
                <Info className="h-6 w-6 text-success" />
              </div>
              <p className="text-sm font-medium text-foreground">
                All Systems Normal
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                No active alerts at this time
              </p>
            </div>
          ) : (
            data?.alerts.map((alert, index) => (
              <AlertItem key={index} alert={alert} />
            ))
          )}
        </div>
      </ScrollArea>
    </div>
  );
}
