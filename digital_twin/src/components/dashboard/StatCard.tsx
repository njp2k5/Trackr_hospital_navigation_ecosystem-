import { cn } from "@/lib/utils";
import { LucideIcon } from "lucide-react";

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: LucideIcon;
  trend?: {
    value: number;
    direction: "up" | "down";
  };
  variant?: "default" | "primary" | "warning" | "critical";
  className?: string;
  delay?: number;
}

const variantStyles = {
  default: {
    container: "bg-card",
    icon: "bg-accent text-accent-foreground",
  },
  primary: {
    container: "bg-card",
    icon: "gradient-teal text-primary-foreground shadow-teal",
  },
  warning: {
    container: "bg-card border-warning/20",
    icon: "bg-warning/10 text-warning",
  },
  critical: {
    container: "bg-card border-destructive/20",
    icon: "bg-destructive/10 text-destructive",
  },
};

export function StatCard({
  title,
  value,
  subtitle,
  icon: Icon,
  trend,
  variant = "default",
  className,
  delay = 0,
}: StatCardProps) {
  const styles = variantStyles[variant];

  return (
    <div
      className={cn(
        "relative overflow-hidden rounded-xl border p-6 shadow-card transition-all duration-300 hover:shadow-card-hover",
        styles.container,
        className
      )}
      style={{
        animationDelay: `${delay}ms`,
      }}
    >
      <div className="flex items-start justify-between">
        <div className="space-y-2">
          <p className="text-sm font-medium text-muted-foreground">{title}</p>
          <div className="flex items-baseline gap-2">
            <p className="text-3xl font-bold tracking-tight text-foreground">
              {value}
            </p>
            {trend && (
              <span
                className={cn(
                  "text-xs font-medium",
                  trend.direction === "up" ? "text-success" : "text-destructive"
                )}
              >
                {trend.direction === "up" ? "↑" : "↓"} {trend.value}%
              </span>
            )}
          </div>
          {subtitle && (
            <p className="text-xs text-muted-foreground">{subtitle}</p>
          )}
        </div>
        <div
          className={cn(
            "flex h-12 w-12 items-center justify-center rounded-xl",
            styles.icon
          )}
        >
          <Icon className="h-6 w-6" />
        </div>
      </div>
    </div>
  );
}
