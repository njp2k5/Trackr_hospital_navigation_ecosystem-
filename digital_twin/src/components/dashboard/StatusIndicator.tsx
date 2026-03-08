import { cn } from "@/lib/utils";

interface StatusIndicatorProps {
  status: "healthy" | "warning" | "critical" | "offline";
  label?: string;
  showPulse?: boolean;
  size?: "sm" | "md" | "lg";
}

const statusConfig = {
  healthy: {
    bg: "bg-success",
    ring: "bg-success/30",
    text: "text-success",
  },
  warning: {
    bg: "bg-warning",
    ring: "bg-warning/30",
    text: "text-warning",
  },
  critical: {
    bg: "bg-destructive",
    ring: "bg-destructive/30",
    text: "text-destructive",
  },
  offline: {
    bg: "bg-muted-foreground",
    ring: "bg-muted-foreground/30",
    text: "text-muted-foreground",
  },
};

const sizeConfig = {
  sm: { dot: "h-2 w-2", ring: "h-4 w-4" },
  md: { dot: "h-3 w-3", ring: "h-6 w-6" },
  lg: { dot: "h-4 w-4", ring: "h-8 w-8" },
};

export function StatusIndicator({
  status,
  label,
  showPulse = true,
  size = "md",
}: StatusIndicatorProps) {
  const config = statusConfig[status];
  const sizeStyles = sizeConfig[size];

  return (
    <div className="flex items-center gap-2">
      <div className="relative flex items-center justify-center">
        {showPulse && status !== "offline" && (
          <span
            className={cn(
              "absolute rounded-full animate-pulse-ring",
              sizeStyles.ring,
              config.ring
            )}
          />
        )}
        <span
          className={cn("rounded-full", sizeStyles.dot, config.bg)}
        />
      </div>
      {label && (
        <span className={cn("text-sm font-medium capitalize", config.text)}>
          {label}
        </span>
      )}
    </div>
  );
}
