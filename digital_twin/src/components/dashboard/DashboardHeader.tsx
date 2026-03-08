import { Activity, RefreshCw } from "lucide-react";
import { useHealthStatus } from "@/hooks/useHospitalData";
import { StatusIndicator } from "./StatusIndicator";
import { Button } from "@/components/ui/button";
import { useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { cn } from "@/lib/utils";

export function DashboardHeader() {
  const { data: health, isLoading } = useHealthStatus();
  const queryClient = useQueryClient();
  const [isRefreshing, setIsRefreshing] = useState(false);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await queryClient.invalidateQueries();
    setTimeout(() => setIsRefreshing(false), 1000);
  };

  const currentTime = new Date().toLocaleTimeString("en-US", {
    hour: "2-digit",
    minute: "2-digit",
  });

  const currentDate = new Date().toLocaleDateString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  return (
    <header className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div className="flex items-center gap-4">
        <div className="flex h-12 w-12 items-center justify-center rounded-xl gradient-teal shadow-teal">
          <Activity className="h-6 w-6 text-primary-foreground" />
        </div>
        <div>
          <h1 className="text-2xl font-semibold tracking-tight text-foreground">
            Hospital Analytics
          </h1>
          <p className="text-sm text-muted-foreground">{currentDate}</p>
        </div>
      </div>

      <div className="flex items-center gap-4">
        <div className="flex items-center gap-3 rounded-lg bg-card px-4 py-2 shadow-card">
          <StatusIndicator
            status={
              isLoading ? "offline" : health?.status === "healthy" ? "healthy" : "warning"
            }
            size="sm"
          />
          <div className="text-sm">
            <span className="text-muted-foreground">System: </span>
            <span className="font-medium text-foreground">
              {isLoading ? "Connecting..." : health?.status || "Unknown"}
            </span>
          </div>
        </div>

        <div className="hidden sm:flex items-center gap-2 text-sm text-muted-foreground">
          <span className="font-mono text-foreground">{currentTime}</span>
          <span>Live</span>
        </div>

        <Button
          variant="outline"
          size="icon"
          onClick={handleRefresh}
          className="border-border hover:bg-accent hover:border-primary/30"
        >
          <RefreshCw
            className={cn("h-4 w-4", isRefreshing && "animate-spin")}
          />
        </Button>
      </div>
    </header>
  );
}
